#!/usr/bin/env bash

set -e

export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
export dir=/tmp

if [ -n "$ACT" ]; then
  echo "127.0.0.1 fedora" | sudo tee -a /etc/hosts
fi

if command -v dnf; then
  sudo dnf upgrade -y
  sudo dnf install -y python3-pip bc make kpartx flex bison gcc gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu openssl-devel
elif command -v apt; then
  sudo add-apt-repository -y universe
  sudo apt upgrade -y
  sudo apt install -y python3-pip bc make kpartx flex bison gcc gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu libssl-dev
  python3 -m pip install uv
  python3 -m uv python install 3.13
  python3 -m uv python pin 3.13
  export PATH=$(echo ~/.local/share/uv/python/cpython-3.13.*/bin):$PATH
fi

if [ ! -d $dir/linux ]; then
  git clone https://github.com/mainlining/linux --branch danila/spacewar-testing $dir/linux --depth 1
fi
if [ ! -d $dir/pmbootstrap ]; then
  git clone https://gitlab.postmarketos.org/postmarketOS/pmbootstrap $dir/pmbootstrap --depth 1
fi
if [ ! -d $dir/pmaports ]; then
  git config --global user.email gmankab@gmail.com
  git config --global user.name gmanka
  git clone https://gitlab.postmarketos.org/postmarketOS/pmaports.git $dir/pmaports
  cd $dir/pmaports
  git remote add mainlining https://github.com/mainlining/pmaports
  git fetch mainlining danila/spacewar-mr
  git merge mainlining/danila/spacewar-mr -X theirs -m merge
fi

mkdir ~/.config || true
echo """
[pmbootstrap]
aports = $dir/pmaports
device = nothing-spacewar
ui = gnome-mobile
""" | tee ~/.config/pmbootstrap_v3.cfg

cd $dir/linux
yes '' | python3 $dir/pmbootstrap/pmbootstrap.py init
shopt -s expand_aliases
source $dir/pmbootstrap/helpers/envkernel.sh
make defconfig sc7280.config
make -j$(nproc)
pmbootstrap build linux-postmarketos-qcom-sc7280 --force --envkernel
pmbootstrap install --password 147147 --filesystem btrfs
if [ -n "$GITHUB_WORKSPACE" ]; then
  pmbootstrap shutdown
fi

mkdir $dir/artifacts || true
mkdir $dir/artifacts-compressed || true
cp ~/.local/var/pmbootstrap/chroot_rootfs_nothing-spacewar/boot/boot.img $dir/artifacts/nothing-spacewar-boot.img
cp ~/.local/var/pmbootstrap/chroot_native/home/pmos/rootfs/nothing-spacewar.img $dir/artifacts/nothing-spacewar.img
xz -c $dir/artifacts/nothing-spacewar-boot.img > $dir/artifacts-compressed/nothing-spacewar-boot.img.xz
xz -c $dir/artifacts/nothing-spacewar.img > $dir/artifacts-compressed/nothing-spacewar.img.xz

