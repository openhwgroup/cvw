cd <some directory to download qemu>
git clone https://github.com/qemu/qemu
cd qemu
git checkout dbdc621be937d9efe3e4dff994e54e8eea051f7a
git apply wallyVirtIO.patch # located in riscv-wally/wally-pipelined/linux-testgen/wallyVirtIO.patch
sudo apt install ninja-build # or your equivalent
sudo apt install libglib2.0-dev # or your equivalent
sudo apt install libpixman-1-dev libcairo2-dev libpango1.0-dev libjpeg8-dev libgif-dev
./configure --target-list=riscv64-softmmu
make --jobs
