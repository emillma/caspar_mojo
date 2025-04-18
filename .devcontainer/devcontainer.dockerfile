FROM ghcr.io/modular/magic:jammy-cuda-12.6.3

ENV DEBIAN_FRONTEND=noninteractive

# WORKDIR /root
RUN apt clean && apt update
RUN apt install -y  build-essential cmake git wget
RUN echo "export PATH=$PATH:/root/.vscode-server/data/User/globalStorage/modular-mojotools.vscode-mojo-nightly/magic-data-home/envs/max/bin" >> /root/.bashrc
# RUN magic self-update --force
# # Latex (from https://github.com/blang/latex-docker/blob/master/Dockerfile.ubuntu)
# RUN apt install -y locales && locale-gen en_US.UTF-8 && update-locale
# RUN apt update && apt install -y libfontconfig1 texlive-full python3-pygments gnuplot  fonts-firacode
# # cudss 
# RUN apt-get install -y libeigen3-dev  libatlas-base-dev libgoogle-glog-dev libgflags-dev libsuitesparse-dev
# WORKDIR /include
# RUN wget https://developer.download.nvidia.com/compute/cudss/0.3.0/local_installers/cudss-local-repo-ubuntu2204-0.3.0_0.3.0-1_amd64.deb
# RUN dpkg -i cudss-local-repo-ubuntu2204-0.3.0_0.3.0-1_amd64.deb
# RUN cp /var/cudss-local-repo-ubuntu2204-0.3.0/cudss-*-keyring.gpg /usr/share/keyrings/
# RUN apt-get update
# RUN apt-get -y install cudss

# # ceres
# # RUN git clone https://github.com/ceres-solver/ceres-solver --recurse-submodules
# RUN git clone https://github.com/adam-ce/ceres-solver.git --recurse-submodules
# WORKDIR /include/ceres-solver
# RUN git submodule update --init --recursive
# WORKDIR /usr/lib/x86_64-linux-gnu
# RUN ln libcudss.so libcudss.so.0.3.0
# RUN ln libcudss_commlayer_openmpi.so libcudss_commlayer_openmpi.so.0.3.0
# RUN ln libcudss_commlayer_nccl.so libcudss_commlayer_nccl.so.0.3.0
# WORKDIR /include/ceres-solver/build
# RUN cmake .. && make -j
# RUN make install

# # gtsam
# WORKDIR /include
# RUN git clone https://github.com/borglab/gtsam.git
# RUN apt install -y libboost-all-dev
# WORKDIR /include/gtsam/build
# RUN cmake .. && make -j
# # RUN apt install -y moreutils

# # python
# ARG python=python3.11
# # RUN apt install -y software-properties-common --fix-missing
# # RUN add-apt-repository -y ppa:deadsnakes/ppa 
# RUN apt update && apt install -y ${python} ${python}-distutils ${python}-dev ${python}-venv python3-pip
# # RUN ${python} -m ensurepip --upgrade 
# RUN pip3 install --upgrade pip setuptools
# RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/${python} 1
# RUN update-alternatives --install /usr/bin/python python /usr/bin/${python} 1
# # RUN update-alternatives --install /usr/bin/pip pip /usr/local/bin/pip3 1

# # RUN pip3 install black mypy
# RUN pip3 install numpy scipy numba
# RUN pip3 install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu128
# RUN pip3 install plotly
# RUN pip3 install tqdm
# RUN pip3 install foxglove_websocket foxglove_schemas_protobuf mypy-protobuf mcap mcap-protobuf-support

# WORKDIR /include
# RUN git clone https://github.com/symforce-org/symforce.git
# WORKDIR /include/symforce
# RUN apt install -y libgmp-dev libspdlog-dev libeigen3-dev
# RUN pip3 install --upgrade pip setuptools
# RUN pip3 install -r dev_requirements.txt
# RUN pip3 install .

# WORKDIR /include
# RUN git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git 
# RUN echo "export PATH=/include/depot_tools:$PATH" >> /root/.bashrc
# RUN apt install -y curl 
# RUN curl -ssL https://magic.modular.com/9b51ba45-3152-4afa-8626-984b0bc752e5 | bash
# RUN echo "\n" >> /root/.bashrc
# SHELL ["/bin/bash", "-c"]
# RUN bash -c "source /root/.bashrc"
# SHELL ["/bin/sh", "-c"]


# WORKDIR /include
# RUN git clone https://github.com/symforce-org/symforce.git --recurse-submodules
# WORKDIR /include/symforce
# RUN pip3 install symforce
# RUN apt install -y libgmp-dev libspdlog-dev libeigen3-dev
# RUN pip3 install --upgrade pip setuptools
# RUN pip3 install -r dev_requirements.txt
# # RUN pip3 install -r dev_requirements.txt
# RUN pip3 install .


# colmap
# WORKDIR /include
# RUN git clone https://github.com/colmap/colmap
# RUN apt install -y git cmake \
#     ninja-build \
#     build-essential \
#     libboost-program-options-dev \
#     libboost-graph-dev \
#     libboost-system-dev \
#     libflann-dev \
#     libfreeimage-dev \
#     libmetis-dev \
#     libgoogle-glog-dev \
#     libgtest-dev \
#     libgmock-dev \
#     libsqlite3-dev \
#     libglew-dev \
#     qtbase5-dev \
#     libqt5opengl5-dev \ 
#     libcgal-dev 

# RUN apt install -y \
# nvidia-cuda-toolkit \
# nvidia-cuda-toolkit-gcc
# WORKDIR /include/colmap/build
# RUN cmake .. -GNinja -DCMAKE_CUDA_ARCHITECTURES=89
# RUN ninja
# RUN ninja install
# WORKDIR /include/colmap/pycolmap
# RUN pip3 install .


# gitconfig
RUN git config --global core.fileMode false
RUN git config --global core.autocrlf true
RUN git config --global --add safe.directory "*"
RUN git config --global user.email "emil.martens@gmail.com"
RUN git config --global user.name "Emil Martens"

# remote display
WORKDIR /root
RUN echo "export DISPLAY=host.docker.internal:0.0" >> .bashrc
RUN echo "export LIBGL_ALWAYS_INDIRECT=1" >> .bashrc
RUN echo "export DEBUGPY_PROCESS_SPAWN_TIMEOUT=1200" >> ~/.profile
