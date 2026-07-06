#!/bin/bash

# 💡 自動切換到腳本所在的目錄（這樣儲存資料夾才會建立在對的地方）
cd "$(dirname "$0")"

# 💡 確保 cron 找得到 curl 和 jq 的路徑
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
LOG_FILE="/tmp/cron_download.log"

# 設定參數
COUNTRY="us"
# SAVE_DIR="bing_wallpapers"
SAVE_DIR="$HOME/Downloads/bing_wallpapers"
API_URL="https://peapix.com/bing/feed?country=${COUNTRY}"

USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

# 1. 建立儲存資料夾
mkdir -p "$SAVE_DIR"

# echo "正在獲取最新圖片資訊 (${COUNTRY^^})..."

# 2. 獲取 API 回傳的 JSON 資料
# 使用 curl 抓取並存入變數
response=$(curl -s -A "$USER_AGENT" "$API_URL")

if [ -z "$response" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ❌ 錯誤：無法從小工具獲取資料。" >> $LOG_FILE
    exit 1
fi

# 3. 使用 jq 提取最新一筆的資料
# .[0] 代表陣列中的第一筆 (最新的一天)
image_url=$(echo "$response" | jq -r '.[0].imageUrl')
title=$(echo "$response" | jq -r '.[0].title')
date=$(echo "$response" | jq -r '.[0].date')

# 防呆檢查
if [ "$image_url" == "null" ] || [ -z "$image_url" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ❌ 錯誤：在 JSON 中找不到 'imageUrl' 欄位。" >> $LOG_FILE
    exit 1
fi

# echo "🎯 成功找到最新圖片：【$title】($date)"

# 4. 清理檔名（移除不合法字元，如 / \ : * ? " < > |）
# 在 Linux 中主要需處理 /，將其替換為底線
safe_title=$(echo "$title" | tr '/\\:*?"<>|' '_')

# 取得副檔名（預設為 jpg）
file_ext="${image_url##*.}"
# 移除可能帶有問號的網址參數 (例如 .jpg?v=1)
file_ext="${file_ext%%\?*}"

# 組合檔名
if [ -n "$date" ] && [ "$date" != "null" ]; then
    file_name="${date}_${safe_title}.${file_ext}"
    # without date
    # file_name="${safe_title}.${file_ext}"
else
    file_name="${safe_title}.${file_ext}"
fi

file_path="${SAVE_DIR}/${file_name}"

# 5. 開始下載圖片
# echo "正在下載 imageUrl: $image_url"
curl -s -A "$USER_AGENT" -o "$file_path" "$image_url"

if [ $? -eq 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 🎉 下載成功！檔案已儲存至：$file_path" >> $LOG_FILE
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ❌ 圖片下載失敗。" >> $LOG_FILE
fi
