#
# Cloudresty DockyDEB
#

# Base Image
FROM    debian:bookworm-slim

# Image details
LABEL   org.opencontainers.image.authors="Cloudresty" \
        org.opencontainers.image.url="https://hub.docker.com/r/cloudresty/dockydeb" \
        org.opencontainers.image.source="https://github.com/cloudresty/dockydeb" \
        org.opencontainers.image.version="1.1.2" \
        org.opencontainers.image.revision="1.1.2" \
        org.opencontainers.image.vendor="Cloudresty" \
        org.opencontainers.image.licenses="MIT" \
        org.opencontainers.image.title="dockydeb" \
        org.opencontainers.image.description="Debian Based Debugging Container"

ENV     LC_ALL=C.UTF-8, LANG=C.UTF-8

# Update and Upgrade
RUN     apt-get update && \
        apt-get upgrade -y && \
        apt-get clean

# Install Packages
RUN     apt-get install -y \
        curl \
        dnsutils \
        git \
        iputils-ping \
        gnupg \
        htop \
        btop \
        jq \
        net-tools \
        ncdu \
        telnet \
        unzip \
        vim \
        wget \
        zsh \
        zip

# Set zsh as default shell
RUN     chsh -s $(which zsh)

# Install Oh My Zsh
RUN     apt-get install -y zsh && \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

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
