FROM ubuntu:20.04

RUN apt-get update && apt-get install -y wget gnupg ca-certificates lsb-release \
    && wget -qO- https://aide-qc.github.io/deploy/aide_qc/debian/PUBLIC-KEY.gpg | apt-key add - \
    && wget -qO- "https://aide-qc.github.io/deploy/aide_qc/debian/$(lsb_release -cs)/aide-qc.list" | tee -a /etc/apt/sources.list.d/aide-qc.list \
    && apt-get update && apt-get install -y xacc aideqc-llvm \
    && ln -sf /usr/local/aideqc/llvm/bin/llvm-config /usr/bin/ 

RUN apt-get install -y git ninja-build && git clone https://github.com/ornl-qci/qcor \
   && cd qcor && mkdir build && cd build \
   && which cmake && cmake --version \
   && CC=gcc-10 CXX=g++-10 cmake .. -G Ninja -DQCOR_CPACK_DEB_PLATFORM=focal -DXACC_DIR=/usr/local/xacc -DCMAKE_INSTALL_PREFIX=/usr/local/xacc \
   && cmake  --build . --target install \ 
   && cpack 
