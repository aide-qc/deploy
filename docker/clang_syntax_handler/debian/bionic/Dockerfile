FROM ubuntu:18.04

# This will build the clang-syntax-handler package

run apt-get update && apt-get install -y wget gnupg && wget -qO- https://aide-qc.github.io/deploy/xacc/debian/bionic/PUBLIC-KEY.gpg | apt-key add - \
    && echo "deb https://aide-qc.github.io/deploy/xacc/debian/bionic ./" > /etc/apt/sources.list.d/xacc-bionic.list \
    && apt-get update && apt-get install -y xacc ninja-build \
    && python3 -m pip install cmake \
    && git clone https://github.com/hfinkel/llvm-project-csp llvm \

    && export PATH=$PATH:/root/.local/bin && cd llvm && mkdir build && cd build \
    && cmake -G Ninja ../llvm -DCMAKE_INSTALL_PREFIX=/usr/local/xacc/llvm -DBUILD_SHARED_LIBS=TRUE \
            -DLLVM_ENABLE_DUMP=TRUE -DCMAKE_BUILD_TYPE=Release -DLLVM_TARGETS_TO_BUILD="X86" \
            -DLLVM_ENABLE_PROJECTS=clang -DCPACK_DEBIAN_PACKAGE_MAINTAINER="Alex McCaskey" \
            -DCPACK_SET_DESTDIR="on" -DCPACK_DEBIAN_PACKAGE_NAME="clang-syntax-handler" \
    && cmake --build . --target install \
    && cpack -G DEB 
    