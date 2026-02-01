FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive
ARG GH_TOKEN
ENV MISE_GITHUB_TOKEN="${GH_TOKEN:-}"
ENV GITHUB_TOKEN="${GH_TOKEN:-}"
ENV GH_TOKEN="${GH_TOKEN:-}"

RUN apt-get update && apt-get install -y \
    git \
    curl \
    zsh \
    tmux \
    neovim \
    build-essential \
    sudo \
    yacc \
    make \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user and add to sudo group
RUN useradd -m -s /bin/zsh mfaine && usermod -aG sudo mfaine

# Switch to the mfaine
USER mfaine
WORKDIR /home/mfaine

# Install Rust and Cargo as mfaine
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Set a clean PATH
ENV PATH="/home/mfaine/.local/bin:/home/mfaine/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Install Tuckr as mfaine
RUN /home/mfaine/.cargo/bin/cargo install tuckr

# Install mise as mfaine
RUN curl https://mise.run | sh

# Install zim as mfaine
RUN curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh

# Create a dummy .zshrc to prevent interactive setup
RUN touch /home/mfaine/.zshrc

CMD ["tail", "-f", "/dev/null"]
