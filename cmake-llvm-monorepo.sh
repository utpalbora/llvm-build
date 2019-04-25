#!/bin/bash -eux

if [[ "$1" == "-h" ]]; then
  echo "Usage: $0 path_to_llvm-project git_branch"
  echo "example: $0 /home/username/base release/8.x"
  exit 0
fi


BRANCH=${2:-master}
export CC=$HOME/bin/clang
export CXX=$HOME/bin/clang++
export AR=$HOME/bin/llvm-ar
export NM=$HOME/bin/llvm-nm
export RANLIB=$HOME/bin/llvm-ranlib
export LLVM_SRC=${1:-`pwd`}
export LLVM_BUILD=${LLVM_SRC}/build
export CFLAGS='-O3 -DNDEBUG -gmlt -march=native -fno-omit-frame-pointer'
export CXXFLAGS="${CFLAGS}"
export LDFLAGS="-fuse-ld=gold -Wl,-rpath=$HOME/lib64 -Wl,-rpath=$HOME/lib"

if ! test -d ${LLVM_SRC}; then
    git clone https://github.com/llvm/llvm-project.git ${LLVM_SRC} -b ${BRANCH}
else
  git -C $LLVM_SRC fetch origin
  git -C $LLVM_SRC checkout --track origin/${BRANCH} -B ${BRANCH}
  git -C $LLVM_SRC pull
fi

mkdir -p ${LLVM_BUILD}
cd ${LLVM_BUILD}

cmake \
  -DCMAKE_CXX_CLANG_TIDY="clang-tidy;-style=file;-checks=*" \
  -DBUILD_SHARED_LIBS=OFF \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=On \
  -DCMAKE_C_COMPILER=$CC \
  -DCMAKE_CXX_COMPILER=$CXX \
  -DCMAKE_AR=$AR \
  -DCMAKE_NM=$NM \
  -DCMAKE_RANLIB=$RANLIB \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_ENABLE_ASSERTIONS=On \
  -DCMAKE_INSTALL_PREFIX=/home/`whoami`/installs/llvm-$(date +'%Y-%m-%d') \
  -DLLVM_BINUTILS_INCDIR=/usr/include \
  -DCMAKE_EXE_LINKER_FLAGS="-fuse-ld=gold" \
  -DCMAKE_MODULE_LINKER_FLAGS="" \
  -DCMAKE_SHARED_LINKER_FLAGS="" \
  -DCMAKE_C_FLAGS="" \
  -DCMAKE_CXX_FLAGS="" \
  -DCMAKE_ASM_FLAGS="" \
  -DCMAKE_C_FLAGS_RELEASE= \
  -DCMAKE_CXX_FLAGS_RELEASE= \
  -DCMAKE_C_COMPILER_EXTERNAL_TOOLCHAIN="" \
  -DCMAKE_SYSROOT="" \
  -DCMAKE_C_COMPILER_TARGET="" \
  -DCMAKE_ASM_COMPILER_TARGET="" \
  -DLLVM_LIBDIR_SUFFIX=64 \
  -DLLVM_TARGETS_TO_BUILD="X86" \
  -DLLVM_CCACHE_BUILD=ON \
  -DLLVM_ENABLE_LLD=OFF \
  -DLLVM_ENABLE_CXX1Y=ON \
  -DLLVM_ENABLE_CXX1Z=ON \
  -DLLVM_ENABLE_LIBCXX=ON \
  -DLIBCXX_ABI_UNSTABLE=ON \
  -DLIBCXX_ENABLE_ASSERTIONS=ON \
  -DLIBCXXABI_ENABLE_ASSERTIONS=ON \
  -DLLVM_INCLUDE_GO_TESTS=OFF \
  -DLLVM_ENABLE_PROJECTS="llvm;clang;libcxx;polly;libcxxabi;lld;lldb;openmp;libclc;clang-tools-extra;compiler-rt" \
 ${LLVM_SRC}/llvm

make -j `nproc`
make install
