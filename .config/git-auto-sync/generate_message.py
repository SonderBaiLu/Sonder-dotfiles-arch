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
PROMPT_TEMPLATE = """你是 git 提交信息生成助手。根据下面的改动写出**一条**提交信息。

硬性要求（违反任何一条输出都会被程序丢弃）：
- 以 conventional commit 前缀开头：feat: / fix: / docs: / refactor: / chore: / style: / perf:
- 正文必须是中文
- 只输出一行，不超过 50 个汉字
- 说明实际改了什么（对象 + 动作）
- 不要引号、markdown、编号、解释或署名，不要输出英文句子

正确示例：
feat: 修改快捷键描述与命令参数
docs: 新增 docs 知识库并同步 README 目录

错误示例（禁止）：
docs: Add documentation for machine setup
This document provides a detailed guide

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


def build_prompt(rev: str | None = None) -> str:
    if rev:
        stat = git("show", "--stat", "--no-color", "--format=", rev)[-4000:]
        patch = git("show", "--no-color", "--no-ext-diff", "--format=", rev)[:8000]
    else:
        stat = git("diff", "--cached", "--stat", "--no-color")[-4000:]
        patch = git("diff", "--cached", "--no-color", "--no-ext-diff")[:8000]
    return PROMPT_TEMPLATE.format(stat=stat.strip(), patch=patch.strip())


# conventional commit 前缀（feat:/fix(scope): 等）
CONVENTIONAL_RE = re.compile(
    r"^(feat|fix|refactor|docs|style|chore|perf|test|build|ci)(\([^)]*\))?:", re.I
)


def clean(text: str) -> str:
    """清洗模型输出；不合格式返回空串，让调用方走中文 fallback。"""
    lines = [line.strip() for line in text.strip().splitlines() if line.strip()]
    if not lines:
        return ""
    line = lines[0]
    line = re.sub(r"^(提交信息|commit message)[:：]\s*", "", line, flags=re.I)
    line = line.strip("`'\"“”‘’ -")
    if not line:
        return ""
    has_cjk = bool(re.search(r"[\u4e00-\u9fff]", line))
    if CONVENTIONAL_RE.match(line):
        # 前缀合格但正文纯英文（7B 模型偶发不守指令）→ 丢弃走 fallback
        return line[:80] if has_cjk else ""
    # 有中文但缺前缀 → 自动补 chore:；纯英文 → 丢弃
    return f"chore: {line}"[:80] if has_cjk else ""


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
    rev = sys.argv[1] if len(sys.argv) > 1 else None
    try:
        message = request_message(build_prompt(rev))
    except Exception:
        return 1

    if not message:
        return 1
    print(message)
    return 0


if __name__ == "__main__":
    sys.exit(main())
