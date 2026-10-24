#!/bin/sh
# lf 预览器。
# lf 调用时传入三个参数：$1 文件路径、$2 预览栏宽度（字符）、$3 高度（字符）。
# 图片/视频用 chafa 渲染成彩色块（alacritty 没有图形协议，这是唯一可行的图片预览方式）；
# 文本、PDF、压缩包直接输出内容，其余类型只显示 file 的类型描述。

set -u

path=$1
width=${2:-80}
height=${3:-24}

[ -f "$path" ] || exit 0
mime=$(file -bL --mime-type -- "$path" 2>/dev/null) || exit 0

case $mime in
	image/*)
		chafa --format symbols --colors full --size "${width}x${height}" --animate off -- "$path" 2>/dev/null
		;;
	video/*)
		thumb=$(mktemp --suffix=.png) || exit 0
		trap 'rm -f "$thumb"' EXIT INT TERM
		if ffmpegthumbnailer -i "$path" -o "$thumb" -s 512 -q 6 >/dev/null 2>&1; then
			chafa --format symbols --colors full --size "${width}x${height}" --animate off -- "$thumb" 2>/dev/null
		fi
		;;
	application/pdf)
		pdftotext -l 2 -layout -- "$path" - 2>/dev/null | head -n "$height" | expand -t 4 | cut -c1-"$width"
		;;
	application/zip | application/x-tar | application/gzip | application/x-bzip2 | \
		application/x-xz | application/x-zstd | application/x-7z-compressed | application/x-rar)
		bsdtar -tf "$path" 2>/dev/null | head -n "$height"
		;;
	*)
		# 没有可靠 MIME 的纯文本（脚本、配置等）回退到内容预览。
		if file -bL -- "$path" 2>/dev/null | grep -qi 'text'; then
			head -c 200000 -- "$path" 2>/dev/null | head -n "$height" | expand -t 4 | cut -c1-"$width"
		else
			file -bL -- "$path" 2>/dev/null
		fi
		;;
esac
