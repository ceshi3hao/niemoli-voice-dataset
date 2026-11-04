#!/usr/bin/env bash
# 从 GitHub Release 拉取干净训练集 → 还原 → 校验 → 解压
# 用法: bash bootstrap.sh   (可覆盖: REPO= TAG= DEST= )
set -euo pipefail

REPO="${REPO:-ceshi3hao/niemoli-voice-dataset}"
TAG="${TAG:-v2.0-clean}"
PATTERN="niemoli-clean-train-pack.part_"
DEST="${DEST:-$PWD/niemoli-voice}"

mkdir -p "$DEST/parts"
cd "$DEST"
echo "[1/5] 目标目录: $DEST  Release: $REPO@$TAG"

API="https://api.github.com/repos/$REPO/releases/tags/$TAG"

echo "[2/5] 下载分卷"
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    echo "    使用 GitHub CLI (已登录)"
    gh release download "$TAG" --repo "$REPO" --pattern "${PATTERN}*" --dir parts --clobber
else
    echo "    使用公开 API + curl (无需 token)"
    curl -fsSL "$API" \
      | python3 -c "import json,sys; d=json.load(sys.stdin); [print(a['browser_download_url']) for a in d['assets'] if a['name'].startswith('$PATTERN')]" \
      > parts/urls.txt
    [ -s parts/urls.txt ] || { echo "未找到分卷，检查 Release tag 或网络"; exit 1; }
    while IFS= read -r u; do
        f="parts/$(basename "$u")"
        echo "    -> $f"
        curl -fL --retry 5 --retry-delay 3 -C - -o "$f" "$u"
    done < parts/urls.txt
fi

# 同时取 MANIFEST 用于校验
curl -fsSL "https://github.com/$REPO/releases/download/$TAG/MANIFEST.md" -o MANIFEST.md || true

echo "[3/5] 拼接还原"
# shellcheck disable=SC2086
cat parts/${PATTERN}* > pack.zip
ls -lh pack.zip

echo "[4/5] sha256 校验"
EXP=""
if [ -f MANIFEST.md ]; then
    EXP="$(grep -oE '[a-f0-9]{64}' MANIFEST.md | head -1 || true)"
fi
if [ -n "$EXP" ]; then
    echo "$EXP  pack.zip" | sha256sum -c -
else
    echo "    MANIFEST 未取到，跳过校验（不推荐）"
fi

echo "[5/5] 解压"
unzip -q -o pack.zip
echo
echo "完成。数据目录: $DEST/niemoli-clean-train-pack"
echo "下一步: python3 $DEST/niemoli-clean-train-pack/gpu_train/prepare_dataset.py"
