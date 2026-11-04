# MANIFEST · niemoli-clean-train-pack

SHA256: 8086d3c27ffae9f1fb36e0c59f0912f1ed946c97386c9c9b752ca42941380617
SIZE_BYTES: 888479139
RELEASE_TAG: v2.0-clean
REPO: ceshi3hao/niemoli-voice-dataset
PART_COUNT: 10

## 内容
整理后的干净训练集：A 类 1349 条可用 WAV（高音质 382 / 普通音质 967）、分组试听 36 条、
审查报告/看板/逐文件判定清单，以及 GPU 服务器一键脚本 gpu_train/。
不含短音效 169、BGM 31、质检异常 17、长剧情 4、上一批混音素材 17。

## 还原
    cat niemoli-clean-train-pack.part_* > niemoli-clean-train-pack.zip
    sha256sum niemoli-clean-train-pack.zip    # 应等于 8086d3c27ffae9f1fb36e0c59f0912f1ed946c97386c9c9b752ca42941380617
    unzip -q niemoli-clean-train-pack.zip

GPU 服务器推荐直接用仓库主分支的 gpu_train/bootstrap.sh（带逐卷校验 + 断点续传）。

## 分卷清单 (name size_bytes sha256)
niemoli-clean-train-pack.part_00 94371840 2eb7f5cf9831e81c3fcf2759328bec3d84ebc74788f411bc765c98a829c7796d
niemoli-clean-train-pack.part_01 94371840 462bdaf8b1638e7dab3f155cc6632976e40396b20488d1452fe493b022ccf7ef
niemoli-clean-train-pack.part_02 94371840 7831500d42c4af1dc12b5b5b5a30ba080ddd336e3ae396c487db949dcfd1d6aa
niemoli-clean-train-pack.part_03 94371840 a8ea08c21217662ddb51ee8837797121921b8ad0b40a0dc3d5231aa1189d3b27
niemoli-clean-train-pack.part_04 94371840 f01becb61b1f71bbffb0afd2be003ec6f869cfdf655ff27c4763eec9044ce100
niemoli-clean-train-pack.part_05 94371840 308a62b3d4e552abf94110e1a6e886287189ca50c5e1888bf14ddd7528bd36e6
niemoli-clean-train-pack.part_06 94371840 0d9de9fc296b60867ec66bf336613e88373695495345aa8aa9dbe60a1013a0ef
niemoli-clean-train-pack.part_07 94371840 b196ca3b861d374712552ac86e960d42a1de9988dcd3ffab785779fe90b35442
niemoli-clean-train-pack.part_08 94371840 d1550b90d121051875cb110e9bed7e0e72ea17fdf76e10436e4bfbcf4e7250e1
niemoli-clean-train-pack.part_09 39132579 bf5a3b4b8d3b56474e5edd5cc2a9c839ddb3f024488f91389e291cd35470ec1c
