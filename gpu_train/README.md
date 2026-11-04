# gpu_train · GPU 服务器开训说明

## 0. 前提

| 项 | 建议 |
| --- | --- |
| GPU | RTX 4090 24G（约 ¥1.86/h）足够；本机无 NVIDIA 卡，PyTorch `cuda available: False` |
| 镜像 | PyTorch 2.1+ / CUDA 12.1 / Python 3.10 |
| 框架 | GPT-SoVITS（或虚拟歌姬音库）；**不用 RVC、不用 Demucs/CS** |
| 人声分离 | 只用 UVR5 的 MDX（`UVR-MDX-NET-Inst_HQ_3.onnx` / `UVR-MDX-NET-Voc_FT.onnx`），仅在处理 B 类 B 站素材时才需要 |

## 1. 拉数据

```bash
bash gpu_train/bootstrap.sh
```

脚本会：从 GitHub Release `v2.0-clean` 下载所有 `part_*` → `cat` 还原 zip → 按 MANIFEST 校验 sha256 → 解压。
有 `gh` 且已登录就用 `gh release download`，否则走公开 API + curl，无需 token。

## 2. 准备数据集

```bash
python3 gpu_train/prepare_dataset.py                        # 默认只用 382 条高音质
python3 gpu_train/prepare_dataset.py --include-normal       # 把 967 条窄带也并进来
```

做三件事：峰值归一化到 -1 dBFS（限制最大增益 4×）、>12s 长句在静音点切成 3~10s、输出 `dataset_ready/` 与 `filelist.txt`。

> 窄带素材（有效带宽 8kHz）与纸4 高音质混训会让模型学到两套不一致的音色。**建议先用高音质跑基线，确认音色对了再考虑把普通音质统一重采样到 16kHz 后低权重补量**。

## 3. 试听锁定说话人（不可跳过）

播放 `分组试听/组00~组11/` 每组 3 条，找到聂莫黎；用 `素材可用性清单.csv` 的 `声纹组` + `音质档` 列筛出对应文件，从 `dataset_ready/` 里剔除其他角色与聂莫琪。

## 4. 训练

见 `train_params.md`。简版：GPT-SoVITS s1 用 `s1longer.yaml`（bs 10~11 / 10 epochs），s2 用 `s2.json`（bs 12~14 / 100~150 epochs），DPO 阶段 bs ≤ 6。

## 5. 8 代情绪段

本包只含纸1~4 游戏原声。纸5/6/7/8/9 的语音是运行时热更新，APK 里 0 条。
8 代崩溃/癫狂情绪段需另取 B 站 `B站_聂莫黎台词部分_纸8.wav`（37min）等素材，先用 UVR5-MDX 分离再补入。
