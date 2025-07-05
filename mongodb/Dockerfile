FROM ubuntu:22.04

RUN apt update \
    && apt install -y \
    sudo \
    python3 \
    git \
    vim \
    libxml2-dev \
    libssl-dev \
    libcurl3-dev \
    libkrb5-dev \
    libsasl2-dev \
    libldap-dev \
    python3.10-venv \
    wget \
    curl \
    fzf \
    jq \
    bat \
    openssh-client \
    tmux \
    curl \
    wget \
    unzip \
    build-essential \
    python3-pip

RUN pip3 install \
    python-dateutil \
    psutil \
    pymongo \
    packaging

RUN useradd \
    -rm \
    -d /home/ubuntu \
    -s /bin/bash \
    -g root \
    -G sudo \
    -u 1001 ubuntu
RUN passwd -d ubuntu
USER ubuntu
WORKDIR /home/ubuntu
ENV USER=ubuntu

RUN mkdir -p /home/ubuntu/.local/bin
ENV PATH=$PATH:/home/ubuntu/.local/bin

# # Install mongodbtoolchain
RUN curl -o toolchain_installer.sh http://mongodbtoolchain.build.10gen.cc/installer.sh \
    && chmod +x toolchain_installer.sh \
    && ./toolchain_installer.sh \
    && rm toolchain_installer.sh
# # ENV PATH=$PATH:/opt/mongodbtoolchain/v5/bin/

# Get the workspace git repository
ADD git@github.com:silviasuhu/workspace.git /home/ubuntu/.workspace
RUN sudo chmod +x /home/ubuntu/.workspace/common/scripts/bin/* \
    && sudo chmod +x /home/ubuntu/.workspace/mongodb/scripts/bin/*

# Install evergreen CLI
RUN curl -o evergreen https://evg-bucket-evergreen.s3.amazonaws.com/evergreen/clients/evergreen_f15fc12fcc2146aad2cd6453c2ccfea6046b25be/linux_amd64/evergreen \
    && chmod +x evergreen \
    && sudo mv evergreen /usr/local/bin/evergreen

# Install fss
ADD --chown=ubuntu: git@github.com:silviasuhu/fss.git /home/ubuntu/.fss
RUN echo "/home/ubuntu/.workspace/common/fss/*" > /home/ubuntu/.fss.conf \
    && echo "/home/ubuntu/.workspace/mongodb/fss/*" >> /home/ubuntu/.fss.conf

# Install oh-my-posh
RUN curl -s https://ohmyposh.dev/install.sh | bash -s
# RUN /home/ubuntu/.local/bin/oh-my-posh font install meslo

# Install diff-so-fancy
ADD --chown=ubuntu: git@github.com:so-fancy/diff-so-fancy.git /home/ubuntu/.diff-so-fancy
RUN sudo chmod +x /home/ubuntu/.diff-so-fancy/diff-so-fancy \
    && sudo ln -s /home/ubuntu/.diff-so-fancy/diff-so-fancy /usr/local/bin/.

# Setup tmux
RUN mkdir -p $HOME/.tmux/plugins
ADD git@github.com:tmux-plugins/tpm.git /home/ubuntu/.tmux/plugins/tpm

# Install mrlog
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y 
ADD --chown=ubuntu: git@github.com:markbenvenuto/mrlog.git /home/ubuntu/.mrlog
WORKDIR /home/ubuntu/.mrlog
RUN . /home/ubuntu/.cargo/env \
    && /home/ubuntu/.cargo/bin/cargo build --release \
    && ln -s /home/ubuntu/.mrlog/target/release/mrlog /home/ubuntu/.local/bin/mrlog
WORKDIR /home/ubuntu

# Install mongo shell
RUN wget https://downloads.mongodb.com/compass/mongosh-2.5.3-linux-arm64.tgz \
    && tar -xzf mongosh-2.5.3-linux-arm64.tgz \
    && mv mongosh-2.5.3-linux-arm64/bin/mongosh /home/ubuntu/.local/bin/mongosh \
    && rm -rf mongosh-2.5.3-linux-arm64* \
    && sudo chmod +x /home/ubuntu/.local/bin/mongosh

# Install MongoDB Command Line Tools
RUN wget https://fastdl.mongodb.org/tools/db/mongodb-database-tools-amazon2-aarch64-100.12.2.tgz \
    && tar -xzf mongodb-database-tools-amazon2-aarch64-100.12.2.tgz \
    && mv mongodb-database-tools-amazon2-aarch64-100.12.2/bin/* /home/ubuntu/.local/bin/ \
    && rm -rf mongodb-database-tools-amazon2-aarch64-100.12.2* \
    && chmod +x /home/ubuntu/.local/bin/*

# Install m
RUN wget https://raw.githubusercontent.com/aheckmann/m/master/bin/m \
    && mv ./m /home/ubuntu/.local/bin/m \
    && chmod +x /home/ubuntu/.local/bin/m

# Install mlaunch
RUN pip3 install mtools

# Install asdf, which is required by mtools
ADD --chown=ubuntu: git@github.com:asdf-vm/asdf.git /home/ubuntu/.asdf

# Install forgit
ADD --chown=ubuntu: git@github.com:wfxr/forgit.git /home/ubuntu/.forgit

# Setup dot files
RUN ln -s /home/ubuntu/.workspace/mongodb/bashrc_lnx /home/ubuntu/.bash_profile \
    && ln -s /home/ubuntu/.workspace/mongodb/gitignore /home/ubuntu/.gitignore \
    && cp /home/ubuntu/.workspace/mongodb/gitconfig /home/ubuntu/.gitconfig \
    && cp /home/ubuntu/.workspace/mongodb/evergreen.yml /home/ubuntu/.evergreen.yml \
    && ln -s /home/ubuntu/.workspace/common/vim/vimrc /home/ubuntu/.vimrc \
    && ln -s /home/ubuntu/.workspace/common/tmux/tmux.conf /home/ubuntu/.tmux.conf

RUN echo 'source ~/.bash_profile' >> /home/ubuntu/.bashrc

RUN mkdir devel

RUN sudo sysctl -w kernel.core_pattern=dump_%e.%p.core