# 还原方法（GPU 服务器上）

最简单：直接用包内的 gpu_train/bootstrap.sh，它会自动下载分卷、拼接、校验、解压。

手动还原：把下面所有 part_* 下载到同一目录，保持文件名与顺序不变：

    cat niemoli-clean-train-pack.part_* > niemoli-clean-train-pack.zip
    sha256sum niemoli-clean-train-pack.zip
    # 期望: 8086d3c27ffae9f1fb36e0c59f0912f1ed946c97386c9c9b752ca42941380617
    unzip -q niemoli-clean-train-pack.zip

解压后得到 niemoli-clean-train-pack/，接着：

    python3 gpu_train/prepare_dataset.py     # 默认只用 382 条高音质
    cat gpu_train/train_params.md            # GPT-SoVITS 参数

注意：全部素材都没有角色标注，开训前必须试听 分组试听/ 锁定聂莫黎并剔除聂莫琪（同一配音演员）。
