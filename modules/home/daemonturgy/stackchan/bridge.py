#!/usr/bin/env python3
"""Stack-chan ↔ Sideriod bridge via XiaoZhi MCP relay.

Connects outbound to the XiaoZhi WebSocket relay and acts as an MCP server,
exposing sideriod's tools so Stack-chan can call them during conversation.
"""

import asyncio
import json
import logging
import os
import aiohttp

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger(__name__)

XIAOZHI_WSS = os.environ.get(
    "XIAOZHI_WSS",
    "wss://api.XiaoZhi.me/mcp/?token=eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9"
    ".eyJ1c2VySWQiOjg0NzUyMSwiYWdlbnRJZCI6MTc5NjI2MSwiZW5kcG9pbnRJZCI6Im"
    "FnZW50XzE3OTYyNjEiLCJwdXJwb3NlIjoibWNwLWVuZHBvaW50IiwiaWF0IjoxNzc3O"
    "TQyMDE5LCJleHAiOjE4MDk0OTk2MTl9.3ALl6jeDk6NH_76jAUJ50ZdDw3vLl6t_HBX"
    "U3U7Juq-_fNBqHWfE-TGHWZCSMzCcVh3aT2UHOafi2QBQ_S7VAA",
)
SIDERIOD_URL = os.environ.get("SIDERIOD_URL", "http://localhost:8765/mcp")
RECONNECT_DELAY = 20
HEARTBEAT_INTERVAL = 50


class SideriodClient:
    def __init__(self, url: str):
        self.url = url
        self.session_id: str | None = None
        self.tools: list = []

    async def _post(self, payload: dict, timeout_secs: int = 30) -> dict:
        headers = {
            "Content-Type": "application/json",
            "Accept": "application/json, text/event-stream",
        }
        if self.session_id:
            headers["mcp-session-id"] = self.session_id
        timeout = aiohttp.ClientTimeout(total=timeout_secs)
        async with aiohttp.ClientSession(timeout=timeout) as sess:
            async with sess.post(self.url, json=payload, headers=headers) as resp:
                self.session_id = resp.headers.get("mcp-session-id", self.session_id)
                text = await resp.text()
                for line in text.splitlines():
                    if line.startswith("data: "):
                        return json.loads(line[6:])
        return {}

    async def initialize(self) -> list:
        await self._post({
            "jsonrpc": "2.0", "method": "initialize", "id": 1,
            "params": {
                "protocolVersion": "2024-11-05",
                "capabilities": {},
                "clientInfo": {"name": "stackchan-bridge", "version": "0.1"},
            },
        })
        await self._post({"jsonrpc": "2.0", "method": "notifications/initialized"})
        result = await self._post({"jsonrpc": "2.0", "method": "tools/list", "id": 2})
        self.tools = result.get("result", {}).get("tools", [])
        log.info("Loaded %d tools: %s", len(self.tools), [t["name"] for t in self.tools])
        return self.tools

    async def call_tool(self, name: str, arguments: dict) -> tuple[str, bool]:
        """Returns (text, is_error)."""
        # Pulse requires {"params": {"refresh": true}} — supply default if omitted
        if name == "sideriod_get_pulse" and "params" not in arguments:
            arguments = {"params": {"refresh": True}}
        result = await self._post(
            {
                "jsonrpc": "2.0", "method": "tools/call", "id": 3,
                "params": {"name": name, "arguments": arguments},
            },
            timeout_secs=60,
        )
        if "error" in result:
            msg = result["error"].get("message", "unknown error")
            log.error("Sideriod error [%s]: %s", name, msg)
            return msg, True
        content = result.get("result", {}).get("content", [])
        return (content[0].get("text", "") if content else ""), False


async def handle(msg: dict, sideriod: SideriodClient) -> dict | None:
    method = msg.get("method")
    msg_id = msg.get("id")

    if method == "initialize":
        return {
            "jsonrpc": "2.0", "id": msg_id,
            "result": {
                "protocolVersion": "2024-11-05",
                "capabilities": {"tools": {}},
                "serverInfo": {"name": "stackchan-sideriod", "version": "0.1"},
            },
        }
    if method == "notifications/initialized":
        return None
    if method == "tools/list":
        return {"jsonrpc": "2.0", "id": msg_id, "result": {"tools": sideriod.tools}}
    if method == "tools/call":
        params = msg.get("params", {})
        name = params.get("name", "")
        arguments = params.get("arguments", {})
        text, is_error = await sideriod.call_tool(name, arguments)
        return {
            "jsonrpc": "2.0", "id": msg_id,
            "result": {
                "content": [{"type": "text", "text": text}],
                "isError": is_error,
            },
        }
    log.warning("Unhandled method: %s", method)
    return None


async def connect_once(wss_url: str, sideriod: SideriodClient):
    timeout = aiohttp.ClientTimeout(total=None, connect=10)
    async with aiohttp.ClientSession(timeout=timeout) as sess:
        async with sess.ws_connect(wss_url) as ws:
            log.info("Connected to XiaoZhi relay")

            async def heartbeat():
                while True:
                    await asyncio.sleep(HEARTBEAT_INTERVAL)
                    try:
                        await ws.ping()
                    except Exception:
                        break

            hb = asyncio.create_task(heartbeat())
            try:
                async for msg in ws:
                    if msg.type == aiohttp.WSMsgType.TEXT:
                        data = json.loads(msg.data)
                        log.info("← %s", data.get("method", repr(data)[:80]))
                        try:
                            response = await handle(data, sideriod)
                        except Exception as e:
                            log.error("handle() error: %s", e)
                            if data.get("id") is not None:
                                response = {
                                    "jsonrpc": "2.0", "id": data["id"],
                                    "error": {"code": -32603, "message": str(e)},
                                }
                            else:
                                response = None
                        if response:
                            log.info("→ id=%s", response.get("id"))
                            await ws.send_str(json.dumps(response))
                    elif msg.type in (aiohttp.WSMsgType.CLOSE, aiohttp.WSMsgType.ERROR):
                        log.warning("WebSocket %s: %s", msg.type.name, msg.data)
                        break
            finally:
                hb.cancel()


async def main():
    sideriod = SideriodClient(SIDERIOD_URL)
    await sideriod.initialize()
    while True:
        try:
            await connect_once(XIAOZHI_WSS, sideriod)
        except Exception as e:
            log.warning("Connection lost: %s", e)
        log.info("Reconnecting in %ds...", RECONNECT_DELAY)
        await asyncio.sleep(RECONNECT_DELAY)


if __name__ == "__main__":
    asyncio.run(main())
