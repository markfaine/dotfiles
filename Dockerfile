FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    git \
    curl \
    zsh \
    tmux \
    neovim \
    build-essential \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user and add to sudo group
RUN useradd -m -s /bin/zsh testuser && usermod -aG sudo testuser

# Switch to the testuser
USER testuser
WORKDIR /home/testuser

# Install Rust and Cargo as testuser
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Set a clean PATH
ENV PATH="/home/testuser/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Install Tuckr as testuser
RUN /home/testuser/.cargo/bin/cargo install tuckr

# Create a dummy .zshrc to prevent interactive setup
RUN touch /home/testuser/.zshrc

CMD ["tail", "-f", "/dev/null"]