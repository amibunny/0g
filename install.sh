#!/bin/bash

echo -e "\n🚀 Starting 0G Storage Node Installation..."

# Update and install dependencies
sudo apt-get update && sudo apt-get upgrade -y
sudo apt install curl iptables build-essential git wget lz4 jq make protobuf-compiler cmake gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev screen ufw -y

# Install Rust
curl https://sh.rustup.rs -sSf | sh -s -- -y
source $HOME/.cargo/env
echo -e "✅ Rust installed: $(rustc --version)"

# Install Go
GO_VER=1.24.3
wget https://go.dev/dl/go$GO_VER.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go$GO_VER.linux-amd64.tar.gz
rm go$GO_VER.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc
echo -e "✅ Go installed: $(go version)"

# Clone repo
cd $HOME
git clone https://github.com/0glabs/0g-storage-node.git
cd 0g-storage-node
git checkout v1.1.0
git submodule update --init

# Build
cargo build --release

# Download config file
CONFIG_DIR="$HOME/0g-storage-node/run"
CONFIG_FILE="$CONFIG_DIR/config.toml"
mkdir -p "$CONFIG_DIR"
curl -o "$CONFIG_FILE" https://raw.githubusercontent.com/Mayankgg01/0G-Storage-Node-Guide/main/config.toml

# Ask for private key
echo -e "\n🔐 Enter your PRIVATE KEY (without 0x):"
read -r PRIVATE_KEY

# Inject the key
sed -i "s|miner_key = \".*\"|miner_key = \"$PRIVATE_KEY\"|" "$CONFIG_FILE"

echo -e "\n✅ Private key added to config.toml"

# Setup systemd
sudo tee /etc/systemd/system/zgs.service > /dev/null <<EOF
[Unit]
Description=ZGS Node
After=network.target

[Service]
User=$USER
WorkingDirectory=$HOME/0g-storage-node/run
ExecStart=$HOME/0g-storage-node/target/release/zgs_node --config $HOME/0g-storage-node/run/config.toml
Restart=on-failure
RestartSec=10
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# Start service
sudo systemctl daemon-reload
sudo systemctl enable zgs
sudo systemctl start zgs

echo -e "\n🎉 ZGS Node Started!"
echo -e "🧾 To check status: sudo systemctl status zgs"
