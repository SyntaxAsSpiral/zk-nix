"""Wake zrrh before forwarding inference to adeck's LM Studio server."""
import asyncio
import json
import logging
import os
import socket
import time

import aiohttp
from aiohttp import web

HOP = {'connection', 'keep-alive', 'proxy-authenticate', 'proxy-authorization',
       'te', 'trailer', 'transfer-encoding', 'upgrade', 'host', 'content-length'}
INFERENCE = {'/v1/chat/completions', '/v1/completions', '/v1/embeddings',
             '/v1/responses', '/api/v0/chat/completions', '/api/v0/completions',
             '/api/v0/embeddings', '/api/v1/chat', '/api/v1/models/load'}


class Wake:
    def __init__(self):
        self.lock = asyncio.Lock()
        self.checked = 0

    async def reachable(self):
        try:
            _, writer = await asyncio.wait_for(
                asyncio.open_connection('192.168.0.110', 22), 1)
        except (OSError, asyncio.TimeoutError):
            return False
        writer.close()
        try:
            await writer.wait_closed()
        except OSError:
            pass
        return True

    async def connected(self):
        if not await self.reachable():
            return False
        process = await asyncio.create_subprocess_exec(
            os.environ['LMS'], 'link', 'status', '--json',
            stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.DEVNULL)
        try:
            output, _ = await asyncio.wait_for(process.communicate(), 5)
        except asyncio.TimeoutError:
            process.kill()
            await process.wait()
            return False
        try:
            return any(p.get('deviceName') == 'zrrh' and p.get('status') == 'connected'
                       for p in json.loads(output).get('peers', []))
        except (ValueError, AttributeError):
            return False

    def send(self):
        mac = bytes.fromhex('60cf8461d800')
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
            sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
            sock.sendto(b'\xff' * 6 + mac * 16, ('192.168.0.255', 9))

    async def ready(self):
        async with self.lock:
            if time.monotonic() - self.checked < 2:
                return
            if await self.connected():
                self.checked = time.monotonic()
                return
            logging.info('Waking zrrh via router LAN')
            deadline = time.monotonic() + 120
            while time.monotonic() < deadline:
                self.send()
                await asyncio.sleep(3)
                if await self.connected():
                    self.checked = time.monotonic()
                    logging.info('zrrh reconnected to LM Link')
                    return
            raise web.HTTPServiceUnavailable(text='zrrh did not reconnect to LM Link within 120 seconds.\n')


def headers(values):
    excluded = HOP | {v.strip().lower() for v in values.get('Connection', '').split(',')}
    return [(k, v) for k, v in values.items() if k.lower() not in excluded]


async def relay(request):
    websocket = request.headers.get('Upgrade', '').lower() == 'websocket'
    if (request.method == 'POST' and request.path in INFERENCE) or websocket:
        await request.app['wake'].ready()
    url = request.app['upstream'] + request.raw_path
    client = request.app['client']
    try:
        if websocket:
            # SDK connections may issue inference over the same WebSocket.
            protocols = [p.strip() for p in request.headers.get('Sec-WebSocket-Protocol', '').split(',') if p.strip()]
            ws_headers = [(k, v) for k, v in headers(request.headers)
                          if not k.lower().startswith('sec-websocket-')]
            async with client.ws_connect(url, headers=ws_headers, protocols=protocols,
                                         max_msg_size=0) as upstream:
                downstream = web.WebSocketResponse(protocols=[upstream.protocol] if upstream.protocol else [], max_msg_size=0)
                await downstream.prepare(request)

                async def pump(source, target, wake=False):
                    async for msg in source:
                        if wake:
                            await request.app['wake'].ready()
                        if msg.type == aiohttp.WSMsgType.TEXT:
                            await target.send_str(msg.data)
                        elif msg.type == aiohttp.WSMsgType.BINARY:
                            await target.send_bytes(msg.data)

                tasks = [asyncio.create_task(pump(downstream, upstream, True)),
                         asyncio.create_task(pump(upstream, downstream))]
                try:
                    done, _ = await asyncio.wait(tasks, return_when=asyncio.FIRST_COMPLETED)
                    for task in done:
                        task.result()
                finally:
                    for task in tasks:
                        task.cancel()
                    await asyncio.gather(*tasks, return_exceptions=True)
                    await downstream.close()
                return downstream
        body = await request.read()
        async with client.request(request.method, url, headers=headers(request.headers),
                                  data=body, allow_redirects=False) as upstream:
            response = web.StreamResponse(status=upstream.status, headers=headers(upstream.headers))
            await response.prepare(request)
            async for chunk in upstream.content.iter_any():
                await response.write(chunk)
            await response.write_eof()
            return response
    except (aiohttp.ClientError, asyncio.TimeoutError):
        raise web.HTTPBadGateway(text='LM Studio upstream unavailable.\n')


async def lifespan(app):
    async with aiohttp.ClientSession(auto_decompress=False,
                                    timeout=aiohttp.ClientTimeout(total=None, sock_connect=10, sock_read=600)) as client:
        app['client'] = client
        yield


def make_app(wake=None, upstream='http://127.0.0.1:1235'):
    app = web.Application(client_max_size=64 * 1024 * 1024)
    app['wake'] = wake or Wake()
    app['upstream'] = upstream
    app.cleanup_ctx.append(lifespan)
    app.router.add_route('*', '/{path:.*}', relay)
    return app


if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO)
    web.run_app(make_app(), host='0.0.0.0', port=1234, access_log=None)
