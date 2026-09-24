import asyncio
import importlib.util
import unittest
from pathlib import Path
from unittest.mock import patch, MagicMock, AsyncMock
from aiohttp import web
from aiohttp.test_utils import TestClient, TestServer

spec = importlib.util.spec_from_file_location('relay', Path(__file__).with_name('inference-wake.py'))
relay = importlib.util.module_from_spec(spec)
spec.loader.exec_module(relay)


class Tests(unittest.IsolatedAsyncioTestCase):
    async def test_disconnected_peer_wakes_and_rechecks(self):
        wake = relay.Wake()
        wake.connected = AsyncMock(side_effect=[False, True])
        wake.send = MagicMock()
        with patch.object(relay.asyncio, 'sleep', new=AsyncMock()):
            await wake.ready()
        wake.send.assert_called_once()
        self.assertEqual(wake.connected.await_count, 2)

    async def test_stale_link_without_lan_is_disconnected(self):
        wake = relay.Wake()
        wake.reachable = AsyncMock(return_value=False)
        with patch.object(relay.asyncio, 'create_subprocess_exec') as spawn:
            self.assertFalse(await wake.connected())
            spawn.assert_not_called()

    async def test_gate_stream_and_metadata(self):
        gate = asyncio.Event()
        received = []
        class Wake:
            async def ready(self):
                await gate.wait()
        async def upstream(request):
            received.append(await request.read())
            response = web.StreamResponse(headers={'Content-Type': 'text/event-stream'})
            await response.prepare(request)
            await response.write(b'data: first\n\n')
            await response.write(b'data: [DONE]\n\n')
            return response
        app = web.Application()
        app.router.add_route('*', '/{path:.*}', upstream)
        async with TestServer(app) as server:
            async with TestClient(TestServer(relay.make_app(Wake(), str(server.make_url('')).rstrip('/')))) as client:
                result = await client.get('/v1/models')
                self.assertEqual(result.status, 200)
                await result.read()
                pending = asyncio.create_task(client.post('/v1/chat/completions', data=b'{"model":"test"}'))
                await asyncio.sleep(.05)
                self.assertEqual(received, [b''])
                gate.set()
                result = await pending
                self.assertEqual(await result.read(), b'data: first\n\ndata: [DONE]\n\n')
                self.assertEqual(received[-1], b'{"model":"test"}')

    async def test_client_disconnect_aborts_upstream(self):
        started = asyncio.Event()
        aborted = asyncio.Event()

        class Wake:
            async def ready(self):
                pass

        async def upstream(request):
            started.set()
            try:
                await asyncio.Event().wait()
            except asyncio.CancelledError:
                aborted.set()
                raise

        app = web.Application()
        app.router.add_route('*', '/{path:.*}', upstream)
        async with TestServer(app) as server:
            proxy = TestServer(relay.make_app(Wake(), str(server.make_url('')).rstrip('/')))
            async with TestClient(proxy) as client:
                pending = asyncio.create_task(client.post('/v1/chat/completions', data=b'{}'))
                await asyncio.wait_for(started.wait(), 2)
                pending.cancel()
                with self.assertRaises(asyncio.CancelledError):
                    await pending
                await asyncio.wait_for(aborted.wait(), 2)

    async def test_wake_timeout_does_not_forward(self):
        class Wake:
            async def ready(self):
                raise web.HTTPServiceUnavailable()
        async with TestClient(TestServer(relay.make_app(Wake(), 'http://127.0.0.1:1'))) as client:
            result = await client.post('/v1/embeddings', json={})
            self.assertEqual(result.status, 503)

    async def test_websocket_roundtrip(self):
        class Wake:
            async def ready(self):
                pass
        async def upstream(request):
            ws = web.WebSocketResponse()
            await ws.prepare(request)
            async for msg in ws:
                await ws.send_str(msg.data)
            return ws
        app = web.Application()
        app.router.add_get('/sdk', upstream)
        async with TestServer(app) as server:
            async with TestClient(TestServer(relay.make_app(Wake(), str(server.make_url('')).rstrip('/')))) as client:
                async with client.ws_connect('/sdk') as ws:
                    await ws.send_str('hello')
                    self.assertEqual((await ws.receive()).data, 'hello')

    def test_magic_packet(self):
        sock = MagicMock()
        with patch.object(relay.socket, 'socket') as factory:
            factory.return_value.__enter__.return_value = sock
            relay.Wake().send()
        sock.sendto.assert_called_once_with(b'\xff' * 6 + bytes.fromhex('60cf8461d800') * 16,
                                           ('192.168.0.255', 9))


if __name__ == '__main__':
    unittest.main()
