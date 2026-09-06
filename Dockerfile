#
# Cloudresty DockyDEB
#

# Base Image
FROM    debian:trixie-slim

# Image details
LABEL   org.opencontainers.image.authors="Cloudresty" \
        org.opencontainers.image.url="https://hub.docker.com/r/cloudresty/dockydeb" \
        org.opencontainers.image.source="https://github.com/cloudresty/dockydeb" \
        org.opencontainers.image.version="1.2.27" \
        org.opencontainers.image.revision="1.2.27" \
        org.opencontainers.image.vendor="Cloudresty" \
        org.opencontainers.image.licenses="MIT" \
        org.opencontainers.image.title="dockydeb" \
        org.opencontainers.image.description="Debian Based Debugging Container"

ENV     LC_ALL=C.UTF-8 \
        LANG=C.UTF-8

# Install the debugging toolkit.
#
# Updated, installed and cleaned in a single layer so the apt lists never reach
# the published image — left behind they cost 21 MB for no benefit.
RUN     apt-get update && \
        apt-get upgrade -y && \
        DEBIAN_FRONTEND=noninteractive apt-get install -y \
        \
        `# Shell, editors and terminal` \
        zsh \
        bash-completion \
        less \
        nano \
        vim \
        tmux \
        moreutils \
        \
        `# Networking: inspection, capture, connectivity` \
        bind9-dnsutils \
        conntrack \
        curl \
        ethtool \
        iperf3 \
        iproute2 \
        iputils-arping \
        iputils-ping \
        iputils-tracepath \
        mtr-tiny \
        net-tools \
        netcat-openbsd \
        ngrep \
        nmap \
        socat \
        tcpdump \
        telnet \
        traceroute \
        wget \
        whois \
        \
        `# TLS and trust` \
        ca-certificates \
        gnupg \
        openssl \
        \
        `# Processes, syscalls and resources` \
        btop \
        htop \
        iotop \
        lsof \
        ltrace \
        ncdu \
        procps \
        psmisc \
        strace \
        \
        `# Files, text and inspection` \
        binutils \
        bsdextrautils \
        diffutils \
        fd-find \
        file \
        jq \
        ripgrep \
        tree \
        \
        `# Archives` \
        bzip2 \
        unzip \
        xz-utils \
        zip \
        zstd \
        \
        `# Data clients and transfer` \
        git \
        postgresql-client \
        redis-tools \
        rsync \
        sqlite3 \
        && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/*

# Debian ships fd as 'fdfind' to avoid a name clash; expose the usual name too.
RUN     ln -s "$(command -v fdfind)" /usr/local/bin/fd

# Set zsh as default shell
RUN     chsh -s $(which zsh)

# Install Oh My Zsh
RUN     sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install Powerlevel10K Theme
RUN     git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# Set Powerlevel10K Theme
RUN     sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/g' ~/.zshrc

# Install ZSH Plugins
RUN     git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions && \
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Set ZSH Plugins
RUN     sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/g' ~/.zshrc

# Copy and source .p10k.zsh
COPY    .p10k.zsh /root/.p10k.zsh
RUN     echo "source ~/.p10k.zsh" >> ~/.zshrc

# Set up DockyDEB welcome message
COPY    20-welcome /etc/update-motd.d/20-welcome
RUN     chmod +x /etc/update-motd.d/20-welcome && \
        echo "/etc/update-motd.d/20-welcome" >> ~/.zshrc && \
        echo exit | script -qec zsh /dev/null

# Set Workdir
WORKDIR /root
