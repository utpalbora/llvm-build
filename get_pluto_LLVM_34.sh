#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Provide branch of Pluto you want to clone!"
    exit 1
fi

if [ -e /proc/cpuinfo ]; then
    procs=`cat /proc/cpuinfo | grep processor | wc -l`
else
    procs=1
fi


BASE_DIR=`pwd`/pluto${1}
PLUTO_DIR=${BASE_DIR}/pluto
PLUTO_INSTALL=${BASE_DIR}/pluto_install
LLVM_GIT=${BASE_DIR}/llvm
LLVM_BUILD=${BASE_DIR}/llvm_build
LLVM_INSTALL=${BASE_DIR}/llvm_install


echo "Cloning Pluto ${1} branch"
# Clone pluto
if ! test -d ${PLUTO_DIR}; then
  git clone https://github.com/bondhugula/pluto.git -b ${1} ${PLUTO_DIR}
else
  git -C ${PLUTO_DIR} checkout ${1}
  git -C ${PLUTO_DIR} pull
fi

echo "Installing LLVM 3.4"
# Clone LLVM, Clang 3.4 release
if ! test -d ${LLVM_GIT}; then
  git clone https://git.llvm.org/git/llvm.git -b release_34 ${LLVM_GIT}
else
  git -C ${LLVM_GIT} pull
fi
if ! test -d ${LLVM_GIT}/tools/clang; then
  git clone https://git.llvm.org/git/clang.git -b release_34 ${LLVM_GIT}/tools/clang
else
  git -C ${LLVM_GIT}/tools/clang pull
fi

# Build LLVM/Clang 3.4 in Release mode
mkdir -p ${LLVM_BUILD} ${LLVM_INSTALL} ${PLUTO_INSTALL}
cd ${LLVM_BUILD}
cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX=${LLVM_INSTALL} -DCMAKE_BUILD_TYPE=Release -DLLVM_TARGETS_TO_BUILD="X86" ${LLVM_GIT}
make -j$procs install

# Install Pluto
echo "Installing Pluto ${1} branch"
cd ${PLUTO_DIR}
git submodule init
git submodule update
./apply_patches.sh
./autogen.sh
./configure --enable-debug --with-clang-prefix=${LLVM_INSTALL} --prefix=${PLUTO_INSTALL}
make -j$procs install;
