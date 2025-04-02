cd /tmp/linux
source /tmp/pmbootstrap/helpers/envkernel.sh
make defconfig sc7280.config
make -j$(nproc)
python3 /tmp/pmbootstrap/pmbootstrap.py -v build linux-postmarketos-qcom-sc7280 --force --envkernel
python3 /tmp/pmbootstrap/pmbootstrap.py install --password 147147 --filesystem btrfs

