echo -e "\nStarting compilation...\n"
# ENV
CONFIG=vendor/sixteen_defconfig
KERNEL_DIR=$(pwd)
PARENT_DIR="$(dirname "$KERNEL_DIR")"
KERN_IMG="$KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb"
export KBUILD_BUILD_USER="hafizziq"
export KBUILD_BUILD_HOST="ubuntu"
export KBUILD_BUILD_TIMESTAMP="$(TZ=Asia/Kuala_Lumpur date)"
export PATH="$HOME/gcc/gcc-arm64/bin:$PATH"
export LD_LIBRARY_PATH="$HOME/gcc/gcc-arm64/lib:$LD_LIBRARY_PATH"
export KBUILD_COMPILER_STRING="$($HOME/gcc/gcc-arm64/bin/aarch64-elf-gcc --version | head -n 1 | cut -d ')' -f 2 | awk '{print $1}')"
export CROSS_COMPILE=$HOME/gcc/gcc-arm64/bin/aarch64-elf-
export CROSS_COMPILE_ARM32=$HOME/gcc/gcc-arm/bin/arm-eabi-
export out=out

# let's clean the output first before building
if [ -d $out ]; then
 echo -e "Cleaning out leftovers...\n"
 rm -rf $out
fi;

mkdir -p $out

# Functions
# sticker plox
function sticker() {
curl -s -X POST "https://api.telegram.org/bot$token/sendSticker" \
-d sticker="CAACAgUAAxkBAAECQa5gj_CEuD-DSeBNVc4xkVxLTQF6zQACmwEAAvQneFfl-dS0RNs7CR8E" \
-d chat_id=$chat_id
}

# Send info plox channel
function sendinfo() {
curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
-d chat_id="$chat_id" \
-d "disable_web_page_preview=true" \
-d "parse_mode=html" \
-d text="<b>• SixTeen Krumel •</b>%0ABuild started on <code>Ur bed</code>%0AFor device <b>Xiaomi Redmi Note 8/T</b>%0Abranch <code>$(git rev-parse --abbrev-ref HEAD)</code>%0AUnder commit <code>$(git log --pretty=format:'"%h : %s"' -1)</code>%0AUsing compiler: <code>${KBUILD_COMPILER_STRING}</code>%0AStarted on <code>$(date)</code>%0A<b>Build Status:</b>#$STS"
}

# Fin Error
function finerr() {
curl -s -X POST "https://api.telegram.org/bot$token/sendSticker" \
-d sticker="CAACAgUAAxkBAAECQbBgj_TChQX9TxDwjznYULukxzn3FQACQQQAAp3uyyd8NONSuiPU3x8E" \
-d chat_id=$chat_id
curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
-d chat_id="$chat_id" \
-d "disable_web_page_preview=true" \
-d "parse_mode=markdown" \
-d text="Build throw an error(s)"
exit 1
}

# Compile plox
function clang_build () {
echo -e ""
START=$(date +"%s")
make O=$out ARCH=arm64 $CONFIG > /dev/null
echo -e "${bold}Compiling with GCC${normal}\n$KBUILD_COMPILER_STRING"
echo -e "\nCompiling $ZIPNAME\n"
make -j$(nproc --all) O=$out \
ARCH=arm64 \
CC="aarch64-elf-gcc" \
AR="llvm-ar" \
NM="llvm-nm" \
LD="ld.lld" \
AS="llvm-as" \
OBJCOPY="llvm-objcopy" \
OBJDUMP="llvm-objdump" \
CROSS_COMPILE=$CROSS_COMPILE \
CROSS_COMPILE_ARM32=$CROSS_COMPILE_ARM32
END=$(date +"%s")
if ! [ -f "$out/arch/arm64/boot/Image.gz-dtb" ] && ! [ -f "$out/arch/arm64/boot/dtbo.img" ]; then
 finerr
 exit 1
fi
}

# Zipping
function zipping() {
echo -e "\nKernel compiled succesfully! Zipping up...\n"
ZIPNAME="Perawanx•Kernel•R•Ginklow-$(date '+%Y%m%d-%H%M').zip"
if [ ! -d AnyKernel3 ]; then
 git clone https://github.com/HafizZiq/AnyKernel3 --depth=1 -b perawanx
fi;
cp -f $out/arch/arm64/boot/Image.gz-dtb AnyKernel3
cp -f $out/arch/arm64/boot/dtbo.img AnyKernel3
cd AnyKernel3
zip -r9 "$HOME/$ZIPNAME" *
cd ..
rm -rf AnyKernel3
echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
echo -e "Zip: $ZIPNAME\n"
}

# Push kernel
function push() {
curl -F document=@$HOME/$ZIPNAME "https://api.telegram.org/bot$token/sendDocument" \
-F chat_id="$chat_id" \
-F "disable_web_page_preview=true" \
-F "parse_mode=html" \
-F caption="Build took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s)."
}

sticker
sendinfo
clang_build
zipping
DIFF=$(($END - $START))
while read -p "Upload? (y/n)" bchoice; do
case "$bchoice" in
 n|N)
  break
 ;;
 y|Y)
  push
  break
 ;;
 *)
  echo
  echo "Try again please!"
  echo
 ;;
esac
done
rm -rf $out
echo -e ""
exit 0
