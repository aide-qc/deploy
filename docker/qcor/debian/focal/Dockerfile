FROM ubuntu:20.04

run apt-get update && apt-get install -y wget gnupg lsb-release ninja-build && wget -qO- https://aide-qc.github.io/deploy/aide_qc/debian/PUBLIC-KEY.gpg | apt-key add - \
    && wget -qO- "https://aide-qc.github.io/deploy/aide_qc/debian/$(lsb_release -cs)/aide-qc.list" | tee -a /etc/apt/sources.list.d/aide-qc.list \
    && apt-get update && apt-get install -y xacc aideqc-llvm \
    && ln -sf /usr/local/aideqc/llvm/bin/llvm-config /usr/bin/ 

RUN git clone https://github.com/ornl-qci/qcor \
   && cd qcor && mkdir build && cd build \
   && which cmake && cmake --version \
   && CC=gcc-10 CXX=g++-10 cmake .. -G Ninja -DQCOR_CPACK_DEB_PLATFORM=focal -DMLIR_DIR=/usr/local/aideqc/llvm/lib/cmake/mlir -DXACC_DIR=/usr/local/aideqc/qcor -DCMAKE_INSTALL_PREFIX=/usr/local/aideqc/qcor \
   && cmake  --build . --target install \ 
   && cpack 
