function ail --description "aider 直连本地 qwen（127.0.0.1:8080 OpenAI 兼容接口）"
    set -lx AIDER_MODEL openai/qwen3.8-flash-next-iq2_xs
    set -lx AIDER_OPENAI_API_BASE http://127.0.0.1:8080/v1
    set -lx AIDER_OPENAI_API_KEY dummy
    aider $argv
end
