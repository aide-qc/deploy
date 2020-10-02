FROM ubuntu:20.04

run apt-get update && apt-get install -y wget gnupg && wget -qO- https://aide-qc.github.io/deploy/xacc/debian/focal/PUBLIC-KEY.gpg | apt-key add - \
    && echo "deb https://aide-qc.github.io/deploy/xacc/debian/focal ./" > /etc/apt/sources.list.d/xacc-focal.list \
    && echo "deb https://aide-qc.github.io/deploy/clang_syntax_handler/debian/focal ./" > /etc/apt/sources.list.d/clang-syntax-handler-focal.list \
    && apt-get update && apt-get install -y xacc clang-syntax-handler \
    && ln -sf /usr/local/xacc/llvm/bin/llvm-config /usr/bin/ 

run apt-get install -y git ninja-build && git clone https://github.com/ornl-qci/qcor \
   && cd qcor && mkdir build && cd build \
   && /root/.local/bin/cmake .. -G Ninja -DQCOR_CPACK_DEB_PLATFORM=focal -DXACC_DIR=/usr/local/xacc -DCMAKE_INSTALL_PREFIX=/usr/local/xacc \
   && /root/.local/bin/cmake  --build . --target install \ 
   && /root/.local/bin/cpack 