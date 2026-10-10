function adobe-wine
    set -gx WINEPREFIX "$HOME/wine/ps-prefix"
    set -gx WINEARCH win64

    if not contains "$HOME/wine/wine-adobe/bin" $PATH
        set -gx PATH "$HOME/wine/wine-adobe/bin" $PATH
    end

    if test (count $argv) -eq 0
        wine wineboot --init
    else
        wine $argv
    end
end
