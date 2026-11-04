# MANIFEST · niemoli-clean-train-pack

SHA256: 8086d3c27ffae9f1fb36e0c59f0912f1ed946c97386c9c9b752ca42941380617
SIZE_BYTES: 888479139
RELEASE_TAG: v2.0-clean
REPO: ceshi3hao/niemoli-voice-dataset

## 内容
整理后的干净训练集：A 类 1349 条可用 WAV（高音质 382 / 普通音质 967）、分组试听 36 条、
审查报告/看板/逐文件判定清单，以及 GPU 服务器一键脚本 gpu_train/。
不含短音效 169、BGM 31、质检异常 17、长剧情 4、上一批混音素材 17。

## 还原
cat niemoli-clean-train-pack.part_* > niemoli-clean-train-pack.zip
sha256sum niemoli-clean-train-pack.zip    # 应等于 8086d3c27ffae9f1fb36e0c59f0912f1ed946c97386c9c9b752ca42941380617
unzip -q niemoli-clean-train-pack.zip

## 分卷
纯字节 split（每卷 90 MiB），文件名 part_00 起顺序递增；不要改名、不要漏卷。
