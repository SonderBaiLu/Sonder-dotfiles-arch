function ai --description "启动 aider，先用 fzf 选模型（云端 claude / 本地 qwen）"
    set -l choice (printf '%s\n' \
        '云端  claude-opus-4-8  (new-api.kunkunout.com)' \
        '本地  qwen3.8-flash-next-iq2_xs  (127.0.0.1:8080)' \
        | fzf --prompt='Aider 模型 » ' --height=40% --reverse --no-info --border)
    test -z "$choice"; and return

    if string match -q '云端*' -- $choice
        aic $argv
    else
        ail $argv
    end
end
