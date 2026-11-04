#!/usr/bin/env python3
"""根据暂存区改动，用本地 ollama 模型生成一行中文 commit message。"""

from __future__ import annotations

import json
import re
import subprocess
import sys
import urllib.parse
import urllib.request

OLLAMA_HOST = "127.0.0.1"
OLLAMA_PORT = 11434
OLLAMA_PATH = "/api/generate"
MODEL = "qwen2.5:7b"
PROMPT_TEMPLATE = """你是 git 提交信息生成助手。根据下面的改动写出**一条**中文提交信息。

要求：
- 只输出提交信息本身，一行，不超过 50 个汉字
- 说明实际改了什么（对象 + 动作），例如「更新 Hyprland 快捷键与 nvim 插件配置」
- 需要时可用 conventional commit 前缀：feat/fix/refactor/docs/style/chore/perf
- 不要引号、markdown、编号、解释或署名

改动统计：
{stat}

改动内容（截断）：
{patch}
"""


class _NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def git(*args: str) -> str:
    return subprocess.run(
        ["git", *args], capture_output=True, text=True, check=False
    ).stdout


def build_prompt() -> str:
    stat = git("diff", "--cached", "--stat", "--no-color")[-4000:]
    patch = git("diff", "--cached", "--no-color", "--no-ext-diff")[:8000]
    return PROMPT_TEMPLATE.format(stat=stat.strip(), patch=patch.strip())


def clean(text: str) -> str:
    lines = [line.strip() for line in text.strip().splitlines() if line.strip()]
    if not lines:
        return ""
    line = lines[0]
    line = re.sub(r"^(提交信息|commit message)[:：]\s*", "", line, flags=re.I)
    line = line.strip("`'\"“”‘’ -")
    return line[:80]


def ollama_endpoint() -> str:
    """只允许访问本机固定端口的 ollama，拒绝其他协议、主机和路径。"""
    url = f"http://{OLLAMA_HOST}:{OLLAMA_PORT}{OLLAMA_PATH}"
    parsed = urllib.parse.urlsplit(url)
    if (
        parsed.scheme != "http"
        or parsed.hostname != OLLAMA_HOST
        or parsed.port != OLLAMA_PORT
        or parsed.path != OLLAMA_PATH
    ):
        raise ValueError("unexpected ollama endpoint")
    return url


def request_message(prompt: str) -> str:
    payload = json.dumps(
        {
            "model": MODEL,
            "prompt": prompt,
            "stream": False,
            "keep_alive": "15m",
            "options": {"temperature": 0.2, "num_predict": 48},
        }
    ).encode()

    request = urllib.request.Request(
        ollama_endpoint(), data=payload, headers={"Content-Type": "application/json"}
    )
    opener = urllib.request.build_opener(_NoRedirect)
    with opener.open(request, timeout=60) as response:
        return clean(json.load(response).get("response", ""))


def main() -> int:
    try:
        message = request_message(build_prompt())
    except Exception:
        return 1

    if not message:
        return 1
    print(message)
    return 0


if __name__ == "__main__":
    sys.exit(main())
