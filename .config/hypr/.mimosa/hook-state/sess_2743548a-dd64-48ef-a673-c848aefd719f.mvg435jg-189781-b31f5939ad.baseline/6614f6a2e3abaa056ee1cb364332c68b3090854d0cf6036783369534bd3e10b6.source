#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Playerctl

music_icon="audio-x-generic"

# 下一曲（playerctl 走 MPRIS 协议，作用于当前活动播放器）
play_next() {
  playerctl next
  show_music_notification
}

# 上一曲
play_previous() {
  playerctl previous
  show_music_notification
}

# 播放/暂停切换；稍候 0.1s 等播放器状态更新后再弹通知
toggle_play_pause() {
  playerctl play-pause
  sleep 0.1
  show_music_notification
}

# 停止播放
stop_playback() {
  playerctl stop
  notify-send -e -u low -i $music_icon " Playback:" " Stopped"
}

# 按播放器当前状态弹出歌曲信息通知
show_music_notification() {
  status=$(playerctl status)
  if [[ "$status" == "Playing" ]]; then
    song_title=$(playerctl metadata title)
    song_artist=$(playerctl metadata artist)
    notify-send -e -u low -i $music_icon "Now Playing:" "$song_title by $song_artist"
  elif [[ "$status" == "Paused" ]]; then
    notify-send -e -u low -i $music_icon " Playback:" " Paused"
  fi
}

# 命令行分发：参数对应 binds.lua 的多媒体快捷键
case "$1" in
"--nxt")
  play_next
  ;;
"--prv")
  play_previous
  ;;
"--pause")
  toggle_play_pause
  ;;
"--stop")
  stop_playback
  ;;
*)
  echo "Usage: $0 [--nxt|--prv|--pause|--stop]"
  exit 1
  ;;
esac
