echo -e "\nStarting compilation...\n"
# ENV
R=n
while read -p "Cam patch? (y/n)" bchoice; do
case "$bchoice" in
 n|N)
  break
 ;;
 y|Y)
  R=y
  export CONFIG_THINLTO=y
  git cp -s 3679d8fbfbf11151109c71eb4308a21d4fb854ab
  break
 ;;
 *)
  echo
  echo "Try again please!"
  echo
 ;;
esac
done

CONFIG=vendor/sixteen_defconfig
KERNEL_DIR=$(pwd)
PARENT_DIR="$(dirname "$KERNEL_DIR")"
KERN_IMG="$KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb"
export KBUILD_BUILD_USER="hafizziq"
export KBUILD_BUILD_HOST="ubuntu"
export KBUILD_BUILD_TIMESTAMP="$(TZ=Asia/Kuala_Lumpur date)"
export PATH="$HOME/clang/proton/bin:$PATH"
export LD_LIBRARY_PATH="$HOME/clang/proton/lib:$LD_LIBRARY_PATH"
export KBUILD_COMPILER_STRING="$($HOME/clang/proton/bin/clang --version | head -n 1 | perl -pe 's/\((?:http|git).*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//' -e 's/^.*clang/clang/')"
export CROSS_COMPILE=$HOME/gcc/aarch64-linux-android-4.9/bin/aarch64-linux-android-
export CROSS_COMPILE_ARM32=$HOME/gcc/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-
export out=out

# let's clean the output first before building
if [ -d $out ]; then
 echo -e "Cleaning out leftovers...\n"
 rm -rf $out
fi;

mkdir -p $out

# Functions
clang_build () {
    make -j$(nproc --all) O=$out \
                          ARCH=arm64 \
                          CC="clang" \
                          AR="llvm-ar" \
                          NM="llvm-nm" \
                          LD="ld.lld" \
                          AS="llvm-as" \
                          OBJCOPY="llvm-objcopy" \
                          OBJDUMP="llvm-objdump" \
                          CLANG_TRIPLE=aarch64-linux-gnu- \
                          CROSS_COMPILE=$CROSS_COMPILE \
                          CROSS_COMPILE_ARM32=$CROSS_COMPILE_ARM32
}

# Build kernel
make O=$out ARCH=arm64 $CONFIG > /dev/null
echo -e "${bold}Compiling with CLANG${normal}\n$KBUILD_COMPILER_STRING"
clang_build
if [ -f "$out/arch/arm64/boot/Image.gz" ] && [ -f "$out/arch/arm64/boot/dtbo.img" ] && [ -f "$out/arch/arm64/boot/dts/qcom/trinket.dtb" ]; then
 echo -e "\nKernel compiled succesfully! Zipping up...\n"
 ZIPNAME="PerawanX☭•Q•Ginklow-$(date '+%Y%m%d-%H%M').zip"
 if [ ! -d AnyKernel3 ]; then
  git clone -q https://github.com/HafizZiq/AnyKernel3 --depth=1 -b perawanx
 fi;
 cp -f $out/arch/arm64/boot/Image.gz AnyKernel3
 cp -f $out/arch/arm64/boot/dtbo.img AnyKernel3
 cp -f $out/arch/arm64/boot/dts/qcom/trinket.dtb AnyKernel3/dtb
 cd AnyKernel3
 zip -r9 "$HOME/$ZIPNAME" *
 cd ..
 rm -rf AnyKernel3
 echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
 echo "Zip: $ZIPNAME"
 rm -rf $out
else
 echo -e "\nCompilation failed!"
fi;
if [ $R == y ]; then
 git rs --hard $(git log --pretty=oneline|head -n2|tail -n1|awk '{ print $1}')
fi;
exit 0
