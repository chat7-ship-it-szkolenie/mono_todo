"""MCP server built automatically from the TODO backend OpenAPI spec."""

import os
from typing import Optional

import httpx
from fastmcp import FastMCP

BACKEND_URL = os.environ.get("BACKEND_URL", "http://localhost:8000")


class _State:
    token: Optional[str] = None


_state = _State()


class _BearerAuth(httpx.Auth):
    """Injects the stored JWT into every request."""

    def auth_flow(self, request: httpx.Request):
        if _state.token:
            request.headers["Authorization"] = f"Bearer {_state.token}"
        yield request


async def _capture_token(response: httpx.Response) -> None:
    """Store JWT whenever a successful /auth/login response arrives."""
    if response.url.path == "/auth/login" and response.status_code == 200:
        await response.aread()
        try:
            data = response.json()
            if "access_token" in data:
                _state.token = data["access_token"]
        except Exception:
            pass


client = httpx.AsyncClient(
    base_url=BACKEND_URL,
    auth=_BearerAuth(),
    event_hooks={"response": [_capture_token]},
)

openapi_spec = httpx.get(f"{BACKEND_URL}/openapi.json").json()

mcp = FastMCP.from_openapi(
    openapi_spec=openapi_spec,
    client=client,
    name="todo-api",
)

if __name__ == "__main__":
    mcp.run()
