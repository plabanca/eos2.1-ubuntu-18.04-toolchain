FROM ubuntu:18.04 AS build

RUN apt update && apt install -y \
    autoconf2.13        \
    build-essential     \
    gdb                 \
    bzip2               \
    cargo               \
    clang-9             \
    git                 \
    libgmp-dev          \
    libpq-dev           \
    lld-8               \
    lldb-8              \
    ninja-build         \
    nodejs              \
    npm                 \
    pkg-config          \
    postgresql-server-dev-all \
    python2.7-dev       \
    python3-dev         \
    rustc               \
    zlib1g-dev          \
    software-properties-common \
    lsb-release \
    wget \ 
    sudo \
    && update-alternatives --install /usr/bin/clang clang /usr/bin/clang-9 100 \
    && update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-9 100

RUN wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null \
    && apt-add-repository "deb https://apt.kitware.com/ubuntu/ $(lsb_release -cs) main" \
    && apt -y update \
    && apt install -y cmake

ENV INSTALL_PREFIX=/usr/local

RUN wget --quiet https://boostorg.jfrog.io/artifactory/main/release/1.72.0/source/boost_1_72_0.tar.bz2 \
    && tar xf boost_1_72_0.tar.bz2 \
    && rm boost_1_72_0.tar.bz2 \
    && cd boost_1_72_0 \
    && ./bootstrap.sh  --prefix=$INSTALL_PREFIX \
    && ./b2 toolset=clang link=static threading=multi --with-iostreams --with-date_time --with-filesystem --with-system --with-program_options --with-chrono --with-test -q -j$(nproc) install

RUN git clone --recursive https://github.com/EOSIO/eos --branch release/2.1.x --single-branch \
    && cd eos \
    && git submodule update --init --recursive \
    && scripts/eosio_build.sh -y \
    && cd build \
    && cmake -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX . \
    && make install 

RUN wget --quiet https://github.com/EOSIO/eosio.cdt/releases/download/v1.8.1/eosio.cdt_1.8.1-1-ubuntu-18.04_amd64.deb \
  && apt install -y ./eosio.cdt_1.8.1-1-ubuntu-18.04_amd64.deb \
  && rm ./eosio.cdt_1.8.1-1-ubuntu-18.04_amd64.deb

# Set enviroment variables
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV CC=/usr/bin/clang
ENV CXX=/usr/bin/clang++
ENV EOS_BUILD_DIR=/eos/build
