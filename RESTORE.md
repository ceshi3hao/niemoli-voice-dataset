# 还原方法（GPU 服务器上）

最省事：用仓库主分支的脚本，它会自动下载分卷、逐卷断点续传、校验 sha256、拼接、解压。

    git clone https://github.com/ceshi3hao/niemoli-voice-dataset.git
    cd niemoli-voice-dataset
    bash gpu_train/bootstrap.sh

手动还原：把下面 10 个 part_* 下载到同一目录，保持文件名与顺序不变：

    cat niemoli-clean-train-pack.part_* > niemoli-clean-train-pack.zip
    sha256sum niemoli-clean-train-pack.zip
    # 期望: 8086d3c27ffae9f1fb36e0c59f0912f1ed946c97386c9c9b752ca42941380617
    unzip -q niemoli-clean-train-pack.zip

解压后得到 niemoli-clean-train-pack/，接着：

    python3 gpu_train/prepare_dataset.py     # 默认只用 382 条高音质
    cat gpu_train/train_params.md            # GPT-SoVITS 参数

注意：全部素材都没有角色标注，开训前必须试听 分组试听/ 锁定聂莫黎并剔除聂莫琪（同一配音演员）。

## 逐卷校验
每卷大小与 sha256 见 MANIFEST.md 的「分卷清单」段；网络被限速时用 curl -C - 断点续传。
