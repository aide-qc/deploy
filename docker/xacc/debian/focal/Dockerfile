from ubuntu:20.04

workdir /home/dev

run apt-get update && apt-get install -y git gcc-9 g++-9 libblas-dev \ 
            liblapack-dev gfortran-9 python3 python3-pip libpython3-dev \
            libcurl4-openssl-dev libssl-dev
run python3 -m pip install cmake 

run cd /home/dev && git clone --recursive https://github.com/eclipse/xacc \
    && cd xacc && mkdir build && cd build \
    && cmake .. -DXACC_CPACK_DEB_PLATFORM=focal -DCMAKE_INSTALL_PREFIX=/usr/local/xacc \
    && make -j$(nproc) install \
    && cpack 