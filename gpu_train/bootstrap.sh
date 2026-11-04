#!/usr/bin/env bash
# 从 GitHub Release 拉干净训练集 → 逐卷校验 + 断点续传 → 拼接 → sha256 校验 → 解压
# 公开仓库，无需 token；网络被限速时靠 curl -C - 续传直到每卷 sha256 通过。
# 用法: bash bootstrap.sh   (可覆盖: REPO= TAG= DEST= MAX_RETRY= )
set -euo pipefail

REPO="${REPO:-ceshi3hao/niemoli-voice-dataset}"
TAG="${TAG:-v2.0-clean}"
DEST="${DEST:-$PWD/niemoli-voice}"
MAX_RETRY="${MAX_RETRY:-40}"
PART_PREFIX="niemoli-clean-train-pack.part_"
BASE="https://github.com/$REPO/releases/download/$TAG"

mkdir -p "$DEST/parts"
cd "$DEST"
echo "[1/6] Release: $REPO@$TAG   目录: $DEST"

echo "[2/6] 取 MANIFEST.md"
if [ ! -s MANIFEST.md ]; then
    curl -fL --retry 5 --retry-delay 2 -o MANIFEST.md "$BASE/MANIFEST.md"
fi
ZIP_SHA="$(grep -oE '[a-f0-9]{64}' MANIFEST.md | head -1)"
MAP="$(awk '/^## 分卷清单/{f=1;next} f && /^niemoli-clean-train-pack\.part_/{print}' MANIFEST.md)"
[ -n "$MAP" ] || { echo "MANIFEST 中没有分卷清单"; exit 1; }
NPART="$(printf '%s\n' "$MAP" | wc -l)"
echo "     $NPART 卷，zip sha256: ${ZIP_SHA:0:16}..."

echo "[3/6] 逐卷下载（带断点续传与 sha256 校验）"
while read -r name want sha; do
    [ -n "$name" ] || continue
    f="parts/$name"
    if [ -f "$f" ] && echo "$sha  $f" | sha256sum -c - >/dev/null 2>&1; then
        echo "  SKIP $name (已完整)"; continue
    fi
    for i in $(seq 1 "$MAX_RETRY"); do
        cur=0; [ -f "$f" ] && cur="$(stat -c%s "$f")"
        if [ "$cur" -gt "$want" ]; then rm -f "$f"; cur=0; fi
        if [ "$cur" -eq "$want" ] && echo "$sha  $f" | sha256sum -c - >/dev/null 2>&1; then break; fi
        curl -fL -C - --connect-timeout 20 --max-time 180 --retry 2 --retry-delay 2 \
             -o "$f" "$BASE/$name" >/dev/null 2>&1 || true
        new=0; [ -f "$f" ] && new="$(stat -c%s "$f")"
        if [ "$new" -eq "$want" ] && echo "$sha  $f" | sha256sum -c - >/dev/null 2>&1; then
            echo "  OK   $name ($((new/1000000)) MB, $i 次请求)"; break
        fi
        if [ "$i" -eq "$MAX_RETRY" ]; then
            echo "  FAIL $name 期望 $want 字节，实得 $new"; exit 1
        fi
        sleep 2
    done
done < <(printf '%s\n' "$MAP")

echo "[4/6] 拼接还原"
# shellcheck disable=SC2086
cat parts/${PART_PREFIX}* > pack.zip
echo "     pack.zip $(stat -c%s pack.zip) 字节"

echo "[5/6] 整包 sha256 校验"
echo "$ZIP_SHA  pack.zip" | sha256sum -c -

echo "[6/6] 解压"
unzip -q -o pack.zip

echo
echo "完成。数据目录: $DEST/niemoli-clean-train-pack"
echo "下一步: python3 $DEST/niemoli-clean-train-pack/gpu_train/prepare_dataset.py"
echo "        （先用 分组试听/ 锁定聂莫黎，剔除同 CV 的聂莫琪）"
