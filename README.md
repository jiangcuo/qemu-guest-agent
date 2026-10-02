# qemu-guest-agent

Windows 版 QEMU guest agent（qemu-ga）安装包，提供 x86_64 和 ARM64 两种架构。

- 从 QEMU 正式版本源码构建，版本见 [`VERSION`](VERSION)
- x86_64 在 `windows-latest` 上用 MSYS2 UCRT64 构建，ARM64 在 `windows-11-arm` 上用 MSYS2 CLANGARM64 原生构建
- 安装包用 WiX v5 生成：`qemu-ga-x86_64.msi`、`qemu-ga-arm64.msi`，另附未打包的 zip
- 安装路径、服务名和 UpgradeCode 与上游/virtio-win 的 qemu-ga 相同，可直接覆盖升级

## 本地构建

在 MSYS2 UCRT64 / CLANGARM64 shell 中：

```sh
pacboy -S toolchain:p glib2:p ninja:p pkgconf:p python:p python-pip:p tools-git:p
pacman -S git make bison flex diffutils
scripts/build.sh
wix build installer/qemu-ga.wxs -arch x64 -d Version=11.1.2 -d StageDir=stage -d InstallVss=1 -o qemu-ga-x86_64.msi
```

## GitHub CI

- **Build**：每次 push / PR 构建两个架构，并在虚拟机里实际安装、检查服务、卸载。
  默认分支上如果该版本还没有 release，会自动创建 `v<版本>` release。
- **Update QEMU**：每周一检查 QEMU 最新正式版本，有新版本就提交到默认分支并构建、发布。
