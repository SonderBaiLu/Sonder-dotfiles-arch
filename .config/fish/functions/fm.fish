function fm --description '在当前目录（或指定路径）打开 nautilus 文件管理器'
    # nautilus 常驻 gapplication-service（hypr startup 启动），调用走 D-Bus 秒回，不阻塞终端
    nautilus $argv
end
