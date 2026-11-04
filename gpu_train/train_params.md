# GPT-SoVITS 训练参数（高质量取向）

约束：**不用 RVC、不用 Demucs/demu CS**；人声分离只用 UVR5 的 MDX；底模用 GPT-SoVITS 或虚拟歌姬音库。

## 硬件

| 项 | 建议 |
| --- | --- |
| GPU | **RTX 4090 24G**，约 ¥1.86/小时，够用且皮实 |
| 不推荐 | RTX 5060Ti / 5090（sm_120，PyTorch 兼容坑多，要等新版 CUDA）；CPU 训练不可行 |
| 显存占用 | s2 `batch_size=12~14` 在 24G 上留有余量；DPO 阶段降到 ≤6 |

## 数据前处理

- 采样率：本包 WAV 是 44.1kHz，但纸1/2/3 有效带宽只有 8kHz。**建议统一重采样到 32kHz 再喂 GPT-SoVITS**，与底模一致，也避免高频假象。
- 响度：峰值归一化到 -1 dBFS（`prepare_dataset.py` 已做）。
- 切片：3~10s 最佳，`>12s` 长句在静音点切开（`prepare_dataset.py` 已做）。
- **先只用 382 条高音质跑基线**，音色对了再考虑补 926 条窄带（降采样到 16kHz、低权重）。

## 阶段参数

| 阶段 | 配置 | batch_size | epochs | 备注 |
| --- | --- | --- | --- | --- |
| s1（文本语义） | `s1longer.yaml` | 10~11 | **10** | 不要盲目加轮数，s1 过拟合会让韵律发死 |
| s2（声学/音色） | `s2.json` | **12~14** | **100~150** | 高质量核心；每 10 epoch 存一次 checkpoint，用试听挑最好的，别只看 loss |
| DPO（可选） | SoVITS DPO | **≤6** | 少量 | 数据少时容易崩，非必需 |

命令形态（在 GPT-SoVITS 根目录，路径按实际安装调整）：

```bash
python s1_train.py --config configs/s1longer.yaml
python s2_train.py --config configs/s2.json
```

s2.json 里要改的关键项：`batch_size`、`epochs`、`save_every_epoch`、`text_low_lr_rate`、`if_save_latest`、`if_save_every_weights`，以及 `train` 段的 `exp_dir` / `name`。

## 避坑

1. **别把 1570 条全喂进去**：其中 200 条是短音效/BGM，17 条有电平异常，另有 926 条窄带会拉低音质。
2. **别按声纹组整组取人**：分组是按代聚的（组02 89% 纸1、组09 94.3% 纸4），不是按说话人。
3. **聂莫黎 / 聂莫琪同 CV**：靠语气剔除莫琪，否则音色被污染。
4. **UVR5 MDX 只用于 B 类**：本包 A 类是游戏内原声干音，无 BGM，不需要再分离；重复分离反而伤音质。CPU 上 MDX 分离 60s 音频约需 103s，没必要浪费 GPU 时间。
5. **checkpoint 用耳朵选**：s2 后期 loss 继续降但音色可能变糊，按试听挑。

## 评估

用一段没进训练集的黎姐台词做推理，对比：音色相似度、高频清晰度（纸4 数据应该更亮）、情绪张力（8 代情绪段需另补 B 站素材）。
