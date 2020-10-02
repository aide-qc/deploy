from ubuntu:20.04

workdir /home/dev

run apt-get update && apt-get install -y git gcc-10 g++-10 libblas-dev \ 
            liblapack-dev gfortran-10 python3 python3-pip libpython3-dev \
            libcurl4-openssl-dev libssl-dev \
    && python3 -m pip install cmake \
    && cd /home/dev && git clone --recursive https://github.com/eclipse/xacc \
    && cd xacc && mkdir build && cd build \
    && CC=gcc-10 CXX=g++-10 cmake .. -DXACC_CPACK_DEB_PLATFORM=focal -DCMAKE_INSTALL_PREFIX=/usr/local/xacc \
    && ls && make -j$(nproc) install \
    && cpack 