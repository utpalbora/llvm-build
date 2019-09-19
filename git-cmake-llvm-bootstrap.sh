#!/bin/bash -eux
#sudo apt-get install -fmy gcc g++ binutils binutils-dev autoconf automake make m4 libtool flex bison build-essential ninja-build cmake ccache gawk texinfo git subversion libglpk-dev libgmp-dev libmpfr-dev libmpfrc++-dev zlib1g-dev libxml2 pkg-config python perl tcl

if [[ "$1" == "-h" ]]; then
  echo "Usage: $0 path_to_parent_of_llvm git_branch"
  echo "example: $0 /home/username/base release_70"
  exit 0
fi

BRANCH=${2:-master}
export BASE=${1:-`pwd`}
export LLVM_SRC=${BASE}/llvm
export LLVM_BUILD=${BASE}/build/${2:-ninja}
export POLLY_SRC=${LLVM_SRC}/tools/polly
export CLANG_SRC=${LLVM_SRC}/tools/clang
export LLD_SRC=${LLVM_SRC}/tools/lld
export COMPILER_RT_SRC=${LLVM_SRC}/projects/compiler-rt
export OMP_SRC=${LLVM_SRC}/projects/openmp
export LIBCXX_SRC=${LLVM_SRC}/projects/libcxx
export LIBCXXABI_SRC=${LLVM_SRC}/projects/libcxxabi
export CLANG_EXTRA_SRC=${CLANG_SRC}/tools/extra
export TEST_SUITE=${LLVM_SRC}/projects/test-suite

cloneStart=$(date +%s%6N)
for GPath in ${LLVM_SRC} ${POLLY_SRC} ${CLANG_SRC} ${LLD_SRC} ${COMPILER_RT_SRC} ${OMP_SRC} ${LIBCXX_SRC} ${LIBCXXABI_SRC} ${CLANG_EXTRA_SRC} ${TEST_SUITE} ;
do (
    if ! test -d ${GPath}; then
      if [ "$GPath" = "${CLANG_EXTRA_SRC}" ]; then
        git clone https://git.llvm.org/git/clang-tools-extra.git ${CLANG_EXTRA_SRC} -b ${BRANCH}
      else
        git clone https://git.llvm.org/git/`basename ${GPath}`.git ${GPath} -b ${BRANCH}
      fi
    else
        git -C $GPath fetch origin
        git -C $GPath checkout --track origin/${BRANCH} -B ${BRANCH}
        git -C $GPath pull
    fi
);
done
cloneEnd=$(date +%s%6N)
cloneTime=$(echo "scale=3; (${cloneEnd:-0}-${cloneStart:-0})/1000000"|bc)
echo "Time taken to fetch LLVM source :  $cloneTime seconds"

mkdir -p ${LLVM_BUILD}
cd ${LLVM_BUILD}

if [ ! -d /usr/include/asm ]; then
  sudo ln -sf /usr/include/x86_64-linux-gnu/asm /usr/include/asm
  #sudo ln -s /usr/include/asm-generic /usr/include/asm
fi

compileStart=$(date +%s%6N)
if [ ! -f $HOME/bin/clang ]; then
export CC=gcc
export CXX=g++
#export LDFLAGS="-fuse-ld=gold"
if which cmake ; then
  cmake -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=$HOME \
  -DCMAKE_EXE_LINKER_FLAGS="-fuse-ld=gold" \
  -DLLVM_LIBDIR_SUFFIX=64 \
  -DLLVM_TARGETS_TO_BUILD="X86" \
  ${LLVM_SRC}
  cmake --build . --target install
  cmake --build . --target clean
else
    ${LLVM_SRC}/configure --prefix=/home/`whoami` --enable-optimized
    #--enable-assertions is debug build with assertions
    #--disable-optimized is debug build
    #--enable-optimized is release build
    #--enable-jit is for jit functionality
    #--enable-targets=x86, x86_64
    #--enable-doxygen

    make -j `nproc`
    make install
    make clean
fi
fi

#bootstrap
export CC=$HOME/bin/clang
export CXX=$HOME/bin/clang++
export CFLAGS='-O3 -DNDEBUG -gmlt -march=native -fno-omit-frame-pointer'
export CXXFLAGS="$CFLAGS"
export LDFLAGS="-fuse-ld=gold -Wl,-rpath=$HOME/lib64 -Wl,-rpath=$HOME/lib"

if which cmake ; then
  cmake -G Ninja \
  -DBUILD_SHARED_LIBS=OFF \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_FLAGS_RELEASE= \
  -DCMAKE_CXX_FLAGS_RELEASE= \
  -DCMAKE_INSTALL_PREFIX=/home/`whoami`/installs/llvm-$(date +'%Y-%m-%d') \
  -DLIBCXX_ABI_UNSTABLE=ON \
  -DLIBCXX_ENABLE_ASSERTIONS=ON \
  -DLIBCXXABI_ENABLE_ASSERTIONS=ON \
  -DLLVM_ENABLE_CXX1Y=ON \
  -DLLVM_ENABLE_CXX1Z=ON \
  -DLLVM_BINUTILS_INCDIR=/usr/include \
  -DLLVM_CCACHE_BUILD=ON \
  -DLLVM_ENABLE_LIBCXX=ON \
  -DLLVM_ENABLE_LLD=OFF \
  -DLLVM_ENABLE_ASSERTIONS=ON \
  -DLLVM_INCLUDE_GO_TESTS=ON \
  -DLLVM_LIBDIR_SUFFIX=64 \
  -DLLVM_TARGETS_TO_BUILD="X86" \
  ${LLVM_SRC}
  cmake --build . --target install
#  -DLLVM_USE_SANITIZER='Address;Undefined;Thread;Memory' \
else
    ${LLVM_SRC}/configure --enable-assertions --enable-debug-runtime
    #--prefix=/home/`whoami`/installs/llvm-$(date +'%Y-%m-%d'
    #--enable-assertions is debug build with assertions
    #--disable-optimized is debug build
    #--enable-optimized is release build
    #--enable-jit is for jit functionality
    #--enable-targets=x86, x86_64
    #--enable-doxygen

    make -j `nproc`
fi
compileEnd=$(date +%s%6N)
compileTime=$(echo "scale=3; (${compileEnd:-0}-${compileStart:-0})/1000000"|bc)
echo "Time taken to compile LLVM :  $compileTime seconds"
