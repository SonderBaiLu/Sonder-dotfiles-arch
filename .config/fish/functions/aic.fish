function aic --description "aider 直连云端 claude-opus-4-8（kunkunout 中转）"
    set -lx AIDER_MODEL openai/claude-opus-4-8
    set -lx AIDER_OPENAI_API_BASE https://new-api.kunkunout.com/v1
    set -lx AIDER_OPENAI_API_KEY sk-KsZeCbU4WSCdVeyLn5jPgUTVMfZ0eSkrMAcJCIwJR1mWvZ4f
    aider $argv
end
