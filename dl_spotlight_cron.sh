#!/bin/bash

# 💡 自動切換到腳本所在的目錄（這樣儲存資料夾才會建立在對的地方）
cd "$(dirname "$0")"

# 💡 確保 cron 找得到 curl 和 jq 的路徑
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
LOG_FILE="/tmp/cron_download.log"

SAVE_DIR="$HOME/Downloads/bing_wallpapers"
API_URL="https://peapix.com/spotlight/feed"
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

mkdir -p "$SAVE_DIR"

response=$(curl -s -A "$USER_AGENT" "$API_URL")

if [ -z "$response" ] || [ "$response" == "null" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ❌ 錯誤：無法從 API 獲取資料。" >> $LOG_FILE
    exit 1
fi

image_url=$(echo "$response" | jq -r '.[0].imageUrl')
title=$(echo "$response" | jq -r '.[0].title')
date=$(echo "$response" | jq -r '.[0].date')

if [ "$image_url" == "null" ] || [ -z "$image_url" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ❌ 錯誤：找不到 imageUrl" >> $LOG_FILE
    exit 1
fi

safe_title=$(echo "$title" | tr '/\\:*?"<>|' '_')
file_ext="${image_url##*.}"
file_ext="${file_ext%%\?*}"

if [ -n "$date" ] && [ "$date" != "null" ]; then
    file_name="${date}_${safe_title}.${file_ext}"
else
    file_name="${safe_title}.${file_ext}"
fi

file_path="${SAVE_DIR}/${file_name}"

# 下載圖片並將結果記錄到日誌中
curl -s -A "$USER_AGENT" -o "$file_path" "$image_url"

if [ $? -eq 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 🎉 成功下載: $file_name" >> $LOG_FILE
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ❌ 下載失敗: $image_url" >> $LOG_FILE
fi
