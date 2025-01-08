#!/bin/bash

# 安装 zsh
if ! command -v zsh &> /dev/null; then
    if command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y zsh expect
    elif command -v yum &> /dev/null; then
        sudo yum -y install zsh expect
    elif command -v brew &> /dev/null; then
        brew install zsh expect
    else
        echo "无法安装 zsh，请手动安装"
        exit 1
    fi
fi

# 如果已经安装了 oh-my-zsh，先备份并删除
if [ -d ~/.oh-my-zsh ]; then
    mv ~/.oh-my-zsh ~/.oh-my-zsh.backup
    mv ~/.zshrc ~/.zshrc.backup
fi

# 创建 expect 脚本
cat > install_zsh.exp << 'EOF'
#!/usr/bin/expect -f
set timeout -1
spawn sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
expect "Do you want to change your default shell to zsh? \\\[Y/n\\\]"
send "y\r"
expect eof
EOF

# 使用 expect 运行安装脚本
chmod +x install_zsh.exp
./install_zsh.exp

# 删除临时的 expect 脚本
rm install_zsh.exp

# 安装插件
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# 修改 .zshrc 配置
sed -i.bak 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting command-not-found)/' ~/.zshrc

echo "安装完成！请执行以下操作："
echo "1. 输入 'zsh' 启动新的 zsh 会话"
echo "2. 如果喜欢当前配置，可以退出终端并重新连接"
