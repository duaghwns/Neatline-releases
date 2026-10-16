#!/bin/bash
# Neatline 설치 (업데이트도 같은 명령):
#   curl -fsSL https://raw.githubusercontent.com/duaghwns/Neatline-releases/main/install.sh | bash
set -euo pipefail

REPO="duaghwns/Neatline-releases"
URL="https://github.com/$REPO/releases/latest/download/Neatline.zip"

if [ "$(uname)" != "Darwin" ]; then
    echo "Neatline은 macOS 전용이에요."
    exit 1
fi
MAJOR=$(sw_vers -productVersion | cut -d. -f1)
if [ "$MAJOR" -lt 14 ]; then
    echo "macOS 14(Sonoma) 이상이 필요해요. 지금 버전: $(sw_vers -productVersion)"
    exit 1
fi

# 응용 프로그램 폴더에 쓸 수 없으면 내 계정의 응용 프로그램 폴더로
DEST="/Applications"
if [ ! -w "$DEST" ]; then
    DEST="$HOME/Applications"
    mkdir -p "$DEST"
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "⬇️  Neatline 내려받는 중…"
curl -fL --progress-bar "$URL" -o "$TMP/Neatline.zip"
ditto -x -k "$TMP/Neatline.zip" "$TMP"
if [ ! -d "$TMP/Neatline.app" ]; then
    echo "내려받은 파일이 올바르지 않아요. 잠시 뒤 다시 해 주세요."
    exit 1
fi

if pgrep -x Neatline >/dev/null 2>&1; then
    echo "실행 중인 Neatline을 종료해요…"
    osascript -e 'quit app "Neatline"' >/dev/null 2>&1 || true
    sleep 2
    pkill -x Neatline 2>/dev/null || true
fi

# 이전 버전은 잠시 옮겨 두었다가, 설치에 실패하면 되돌린다 (설정·기록은 그대로 남는다)
if [ -d "$DEST/Neatline.app" ]; then
    mv "$DEST/Neatline.app" "$TMP/Neatline-old.app"
fi
if ! ditto "$TMP/Neatline.app" "$DEST/Neatline.app"; then
    [ -d "$TMP/Neatline-old.app" ] && mv "$TMP/Neatline-old.app" "$DEST/Neatline.app"
    echo "설치하지 못했어요. 이전 버전은 그대로예요."
    exit 1
fi
# 인터넷에서 받은 앱 표시를 지워서 처음 열 때 막히지 않게 한다
xattr -dr com.apple.quarantine "$DEST/Neatline.app" 2>/dev/null || true

VER=$(defaults read "$DEST/Neatline.app/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo "")
echo "✅ Neatline $VER 설치 완료: $DEST/Neatline.app"
open "$DEST/Neatline.app"
