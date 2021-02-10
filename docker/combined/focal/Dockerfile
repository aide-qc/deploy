FROM ubuntu:20.04

WORKDIR /home/dev

RUN apt-get update && apt-get install -y ca-certificates git gcc-10 g++-10 libblas-dev \ 
            liblapack-dev gfortran-10 python3 python3-pip libpython3-dev \
            libcurl4-openssl-dev libssl-dev \
    && python3 -m pip install cmake \
    && cd /home/dev && git clone --recursive https://github.com/eclipse/xacc \
    && cd xacc && mkdir build && cd build \
    && CC=gcc-10 CXX=g++-10 cmake .. -DXACC_CPACK_DEB_PLATFORM=focal -DCMAKE_INSTALL_PREFIX=/usr/local/aideqc/qcor \
    && ls && make -j$(nproc) install \
    && cpack 

run apt-get update && apt-get install -y wget gnupg lsb-release ninja-build git && wget -qO- https://aide-qc.github.io/deploy/aide_qc/debian/PUBLIC-KEY.gpg | apt-key add - \
    && wget -qO- "https://aide-qc.github.io/deploy/aide_qc/debian/$(lsb_release -cs)/aide-qc.list" | tee -a /etc/apt/sources.list.d/aide-qc.list \
    && apt-get update && apt-get install -y aideqc-llvm \
    && ln -sf /usr/local/aideqc/llvm/bin/llvm-config /usr/bin/ 

RUN cd /home/dev && git clone https://github.com/ornl-qci/qcor \
   && cd qcor && mkdir build && cd build \
   && which cmake && cmake --version \
   && CC=gcc-10 CXX=g++-10 cmake .. -G Ninja -DQCOR_CPACK_DEB_PLATFORM=focal -DMLIR_DIR=/usr/local/aideqc/llvm/lib/cmake/mlir -DXACC_DIR=/usr/local/aideqc/qcor -DCMAKE_INSTALL_PREFIX=/usr/local/aideqc/qcor \
   && cmake  --build . --target install \ 
   && cpack 
