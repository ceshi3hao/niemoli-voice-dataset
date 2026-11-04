#!/usr/bin/env python3
"""
GPT-SoVITS 训练前数据准备：响度归一化 + 长句按静音点切分。
只依赖 numpy + 标准库 wave（WAV 为 PCM s16le），不需要 librosa/soundfile。

用法:
  python3 prepare_dataset.py                     # 默认只用 382 条高音质
  python3 prepare_dataset.py --include-normal   # 并入 967 条窄带素材
  python3 prepare_dataset.py --root /path/to/niemoli-clean-train-pack
"""
import argparse
import os
import wave
import glob
import numpy as np

SR = 44100
MAX_GAIN = 4.0
TARGET_PEAK = 0.89          # 约 -1 dBFS
MAX_LEN = 12.0              # 超过则在静音点切开
SEG_MAX = 10.0
SEG_MIN = 2.5
FRAME = 0.02                # 20ms 帧
SIL_RMS = 0.008


def load_wav(path):
    with wave.open(path, "rb") as w:
        assert w.getnchannels() == 1 and w.getsampwidth() == 2, path
        sr = w.getframerate()
        x = np.frombuffer(w.readframes(w.getnframes()), dtype="<i2").astype(np.float32) / 32768.0
    if sr != SR:
        # 线性重采样（本包实际均为 44100，此分支仅作兜底）
        n = int(len(x) * SR / sr)
        x = np.interp(np.linspace(0, len(x) - 1, n), np.arange(len(x)), x).astype(np.float32)
    return x


def save_wav(path, x):
    y = np.clip(x, -1.0, 1.0)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((y * 32767).astype("<i2").tobytes())


def normalize(x):
    peak = float(np.max(np.abs(x))) if x.size else 0.0
    if peak < 1e-6:
        return x
    return x * min(TARGET_PEAK / peak, MAX_GAIN)


def frame_rms(x):
    fl = int(FRAME * SR)
    n = x.size // fl
    if n == 0:
        return np.array([0.0])
    f = x[:n * fl].reshape(n, fl)
    return np.sqrt(np.mean(f * f, axis=1))


def split_long(x):
    """把长音频在静音点切成 <=SEG_MAX 的片段；找不到静音点则硬切。"""
    total = len(x) / SR
    if total <= MAX_LEN:
        return [x]
    rms = frame_rms(x)
    out, start = [], 0
    while (len(x) - start) / SR > MAX_LEN:
        lo = start + int(SEG_MIN * SR)
        hi = min(start + int(SEG_MAX * SR), len(x))
        f_lo, f_hi = lo // (int(FRAME * SR)), hi // (int(FRAME * SR))
        cut = hi
        if f_hi > f_lo:
            seg = rms[f_lo:f_hi]
            quiet = np.where(seg < SIL_RMS)[0]
            if quiet.size:
                # 取区间中部最静音的点，避免切出尾巴
                mid = quiet[np.argmin(np.abs(quiet - quiet.size / 2))]
                cut = (f_lo + int(mid)) * int(FRAME * SR)
            else:
                cut = (f_lo + int(np.argmin(seg))) * int(FRAME * SR)
        if cut - start < int(SEG_MIN * SR):
            cut = min(start + int(SEG_MAX * SR), len(x))
        out.append(x[start:cut])
        start = cut
    if (len(x) - start) / SR >= 1.0:
        out.append(x[start:])
    return out


def main():
    ap = argparse.ArgumentParser()
    here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    ap.add_argument("--root", default=here)
    ap.add_argument("--out", default=None)
    ap.add_argument("--include-normal", action="store_true")
    a = ap.parse_args()

    srcs = [os.path.join(a.root, "A_可直接训练", "高音质_纸4为主")]
    if a.include_normal:
        srcs.append(os.path.join(a.root, "A_可直接训练", "普通音质_按代"))
    files = []
    for s in srcs:
        files += sorted(glob.glob(os.path.join(s, "**", "*.wav"), recursive=True))
    if not files:
        raise SystemExit("没找到 WAV，检查 --root 是否指向解压后的 niemoli-clean-train-pack")

    out = a.out or os.path.join(a.root, "dataset_ready")
    os.makedirs(out, exist_ok=True)
    lines, durations, n_seg = [], [], 0
    for i, p in enumerate(files):
        x = normalize(load_wav(p))
        for j, seg in enumerate(split_long(x)):
            if len(seg) / SR < 1.0:
                continue
            name = f"nm_{i:04d}_{j:02d}.wav"
            save_wav(os.path.join(out, name), seg)
            d = len(seg) / SR
            durations.append(d)
            lines.append(f"{name}\t{d:.2f}\t{os.path.relpath(p, a.root)}")
            n_seg += 1

    with open(os.path.join(out, "filelist.txt"), "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    print(f"输入 {len(files)} 条 -> 输出 {n_seg} 片段")
    print(f"总时长 {sum(durations)/60:.1f} 分钟, 平均 {np.mean(durations):.2f}s, "
          f"范围 {min(durations):.2f}~{max(durations):.2f}s")
    print(f"输出目录: {out}")
    print("下一步: 试听 分组试听/ 锁定聂莫黎，按 素材可用性清单.csv 剔除其他角色与聂莫琪")


if __name__ == "__main__":
    main()
