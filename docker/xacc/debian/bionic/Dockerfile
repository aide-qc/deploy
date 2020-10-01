from xacc/deploy-base

workdir /home/dev

run cd /home/dev && git clone --recursive https://github.com/eclipse/xacc \
    && cd xacc && mkdir build && cd build \
    && cmake .. -DXACC_CPACK_DEB_PLATFORM=bionic -DCMAKE_INSTALL_PREFIX=/usr/local/xacc \
    && make -j$(nproc) install \
    && cpack 