#!/bin/bash

# Production-ready zsh & oh-my-zsh installation script
# Compatible with Debian 10+/Ubuntu 22+ and other distributions
# Includes additional productivity plugins for development environments
# Handles git installation and various error conditions

# Exit on error, but allow for proper cleanup
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Cleanup function for error handling
cleanup() {
    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        log_error "安装过程中发生错误 (错误代码: $EXIT_CODE)。正在清理..."
    fi
}

# Set trap for cleanup
trap cleanup EXIT

# Check and install package if not present
ensure_package_installed() {
    local package=$1
    local install_cmd=$2
    
    if ! command -v "$package" &> /dev/null; then
        log_info "正在安装 $package..."
        eval "$install_cmd" || {
            log_warning "安装 $package 失败。此功能可能不可用。"
            return 1
        }
        log_success "$package 安装成功"
        return 0
    else
        log_info "$package 已经安装"
        return 0
    fi
}

# Check internet connectivity
check_internet() {
    log_info "检查网络连接..."
    if ping -c 1 github.com &> /dev/null || ping -c 1 google.com &> /dev/null; then
        log_success "网络连接正常"
    else
        log_error "未检测到网络连接。此脚本需要网络连接来下载组件。"
        exit 1
    fi
}

# Detect package manager and set install commands
detect_package_manager() {
    if command -v apt &> /dev/null; then
        PKG_MANAGER="apt"
        INSTALL_CMD="sudo apt update && sudo apt install -y"
        CNF_PKG="command-not-found"
        FZF_PKG="fzf"
        AUTOJUMP_PKG="autojump"
        DIRENV_PKG="direnv"
    elif command -v apt-get &> /dev/null; then
        PKG_MANAGER="apt-get"
        INSTALL_CMD="sudo apt-get update && sudo apt-get install -y"
        CNF_PKG="command-not-found"
        FZF_PKG="fzf"
        AUTOJUMP_PKG="autojump"
        DIRENV_PKG="direnv"
    elif command -v dnf &> /dev/null; then
        PKG_MANAGER="dnf"
        INSTALL_CMD="sudo dnf -y install"
        CNF_PKG="PackageKit-command-not-found"
        FZF_PKG="fzf"
        AUTOJUMP_PKG="autojump"
        DIRENV_PKG="direnv"
    elif command -v yum &> /dev/null; then
        PKG_MANAGER="yum"
        INSTALL_CMD="sudo yum -y install"
        CNF_PKG="PackageKit-command-not-found"
        FZF_PKG="fzf"
        AUTOJUMP_PKG="autojump"
        DIRENV_PKG="direnv"
    elif command -v pacman &> /dev/null; then
        PKG_MANAGER="pacman"
        INSTALL_CMD="sudo pacman -Sy --noconfirm"
        CNF_PKG="pkgfile"
        FZF_PKG="fzf"
        AUTOJUMP_PKG="autojump"
        DIRENV_PKG="direnv"
    elif command -v zypper &> /dev/null; then
        PKG_MANAGER="zypper"
        INSTALL_CMD="sudo zypper install -y"
        CNF_PKG="command-not-found"
        FZF_PKG="fzf"
        AUTOJUMP_PKG="autojump"
        DIRENV_PKG="direnv"
    elif command -v brew &> /dev/null; then
        PKG_MANAGER="brew"
        INSTALL_CMD="brew install"
        CNF_PKG=""
        FZF_PKG="fzf"
        AUTOJUMP_PKG="autojump"
        DIRENV_PKG="direnv"
    else
        log_error "不支持的包管理器。请手动安装 zsh 和 git。"
        exit 1
    fi
    
    log_info "检测到包管理器: $PKG_MANAGER"
}

# Install an oh-my-zsh plugin
install_omz_plugin() {
    local plugin_name=$1
    local plugin_url=$2
    local plugin_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$plugin_name"
    
    if [ -d "$plugin_dir" ]; then
        log_info "插件 $plugin_name 已经安装"
        return 0
    fi
    
    log_info "安装 $plugin_name 插件..."
    git clone "$plugin_url" "$plugin_dir" &> /dev/null || {
        log_warning "安装 $plugin_name 插件失败"
        return 1
    }
    
    log_success "插件 $plugin_name 安装成功"
    return 0
}

# Add custom configuration to .zshrc
add_to_zshrc() {
    local content=$1
    if ! grep -q "$content" ~/.zshrc; then
        echo -e "\n# Added by zsh installer script\n$content" >> ~/.zshrc
        log_info "配置已添加到 .zshrc"
        return 0
    else
        log_info "配置已存在于 .zshrc"
        return 0
    fi
}

# Main installation function
main() {
    log_info "开始安装 zsh 和 oh-my-zsh 以及生产环境插件..."
    check_internet
    detect_package_manager
    
    # Install zsh
    ensure_package_installed "zsh" "$INSTALL_CMD zsh" || {
        log_error "安装 zsh 失败，这是必需的。退出。"
        exit 1
    }
    
    # Install git if not already installed
    ensure_package_installed "git" "$INSTALL_CMD git" || {
        log_error "安装 git 失败，这是必需的。退出。"
        exit 1
    }
    
    # Install curl or wget if neither is installed
    if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
        ensure_package_installed "curl" "$INSTALL_CMD curl" || {
            log_error "安装 curl 或 wget 失败，这是必需的。退出。"
            exit 1
        }
    fi
    
    # Install useful system utilities for better experience
    FZF_INSTALLED=false
    if [ -n "$FZF_PKG" ]; then
        ensure_package_installed "fzf" "$INSTALL_CMD $FZF_PKG" && FZF_INSTALLED=true
    fi
    
    AUTOJUMP_INSTALLED=false
    if [ -n "$AUTOJUMP_PKG" ]; then
        ensure_package_installed "autojump" "$INSTALL_CMD $AUTOJUMP_PKG" && AUTOJUMP_INSTALLED=true
    fi
    
    DIRENV_INSTALLED=false
    if [ -n "$DIRENV_PKG" ]; then
        ensure_package_installed "direnv" "$INSTALL_CMD $DIRENV_PKG" && DIRENV_INSTALLED=true
    fi
    
    # Back up existing oh-my-zsh installation
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    if [ -d ~/.oh-my-zsh ]; then
        log_info "备份现有 oh-my-zsh 安装..."
        mv ~/.oh-my-zsh ~/.oh-my-zsh.backup_$TIMESTAMP
        if [ -f ~/.zshrc ]; then
            mv ~/.zshrc ~/.zshrc.backup_$TIMESTAMP
        fi
        log_success "备份已创建，时间戳: $TIMESTAMP"
    fi
    
    # Install oh-my-zsh
    log_info "安装 oh-my-zsh..."
    if command -v curl &> /dev/null; then
        RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || {
            log_error "使用 curl 安装 oh-my-zsh 失败"
            exit 1
        }
    elif command -v wget &> /dev/null; then
        RUNZSH=no sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || {
            log_error "使用 wget 安装 oh-my-zsh 失败"
            exit 1
        }
    else
        log_error "未安装 curl 或 wget。无法下载 oh-my-zsh。"
        exit 1
    fi
    
    log_success "oh-my-zsh 安装成功"
    
    # Create plugin directory if it doesn't exist
    mkdir -p "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
    
    # Install standard plugins
    log_info "安装标准插件..."
    install_omz_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions.git"
    install_omz_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting.git"
    install_omz_plugin "zsh-history-substring-search" "https://github.com/zsh-users/zsh-history-substring-search.git"
    
    # Install z plugin (directory jumping)
    install_omz_plugin "z" "https://github.com/agkozak/zsh-z.git"
    
    # Install context-dependent plugins based on detected tools
    PLUGINS="git z zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search"
    
    # Add fzf plugin if fzf is installed
    if $FZF_INSTALLED || command -v fzf &> /dev/null; then
        PLUGINS="$PLUGINS fzf"
    fi
    
    # Add command-not-found plugin if the package is available
    if [ -n "$CNF_PKG" ]; then
        ensure_package_installed "$CNF_PKG" "$INSTALL_CMD $CNF_PKG" && PLUGINS="$PLUGINS command-not-found"
    fi
    
    # Add colored-man-pages plugin (doesn't require additional dependencies)
    PLUGINS="$PLUGINS colored-man-pages"
    
    # Add sudo plugin (doesn't require additional dependencies)
    PLUGINS="$PLUGINS sudo"
    
    # Check for docker and add plugin if present
    if command -v docker &> /dev/null; then
        PLUGINS="$PLUGINS docker"
    fi
    
    # Check for kubectl and add plugin if present
    if command -v kubectl &> /dev/null; then
        PLUGINS="$PLUGINS kubectl"
    fi
    
    # Check for terraform and add plugin if present
    if command -v terraform &> /dev/null; then
        PLUGINS="$PLUGINS terraform"
    fi
    
    # Check for autojump and add plugin if installed
    if $AUTOJUMP_INSTALLED || command -v autojump &> /dev/null; then
        PLUGINS="$PLUGINS autojump"
    fi
    
    # Check for direnv and add it if installed
    if $DIRENV_INSTALLED || command -v direnv &> /dev/null; then
        add_to_zshrc 'eval "$(direnv hook zsh)"'
    fi
    
    # Configure .zshrc
    log_info "配置 .zshrc 插件..."
    if [ -f ~/.zshrc ]; then
        # Update plugins line in .zshrc, handling different sed versions
        if grep -q "^plugins=(" ~/.zshrc; then
            # Try with GNU sed
            sed -i.bak "s/^plugins=(.*)/plugins=($PLUGINS)/" ~/.zshrc 2>/dev/null || \
            # Try with BSD sed if GNU sed fails
            sed -i '.bak' "s/^plugins=(.*)/plugins=($PLUGINS)/" ~/.zshrc 2>/dev/null || {
                log_error "修改 .zshrc 失败。请手动更新插件行。"
                log_info "添加这些插件: $PLUGINS"
            }
        else
            log_warning "在 .zshrc 中未找到插件行。手动添加。"
            echo "plugins=($PLUGINS)" >> ~/.zshrc
        fi
    else
        log_error "未找到 .zshrc 文件。这是意外情况，因为 oh-my-zsh 应该已经创建了它。"
        exit 1
    fi
    
    # Add history configuration for better history management
    log_info "添加历史记录配置..."
    add_to_zshrc '# History configuration
export HISTSIZE=100000
export SAVEHIST=100000
export HISTFILE=~/.zsh_history
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY'

    # Add better directory navigation
    log_info "添加目录导航配置..."
    add_to_zshrc '# Directory navigation
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT'

    # Add key bindings for history-substring-search
    if [[ "$PLUGINS" == *"zsh-history-substring-search"* ]]; then
        log_info "添加历史子字符串搜索键绑定..."
        add_to_zshrc '# Key bindings for history-substring-search
bindkey "^[[A" history-substring-search-up
bindkey "^[[B" history-substring-search-down'
    fi
    
    # Add aliases for common operations
    log_info "添加常用别名..."
    add_to_zshrc '# Useful aliases
alias ll="ls -la"
alias la="ls -a"
alias l="ls -l"
alias ..="cd .."
alias ...="cd ../.."
alias grep="grep --color=auto"
alias df="df -h"
alias du="du -h"
alias free="free -h"
alias mkdir="mkdir -p"
alias http-serve="python3 -m http.server 2>/dev/null || python -m SimpleHTTPServer 2>/dev/null"
alias ip-pub="curl -s https://ipinfo.io/ip || wget -qO- https://ipinfo.io/ip"
alias ports="netstat -tulpn | grep LISTEN"'

    # Check for common development tools and add aliases
    if command -v git &> /dev/null; then
        add_to_zshrc '# Git aliases
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gco="git checkout"
alias gl="git log --oneline --graph --decorate --all"
alias gf="git fetch"
alias gp="git pull"
alias gpush="git push"'
    fi

    if command -v docker &> /dev/null; then
        add_to_zshrc '# Docker aliases
alias dc="docker-compose"
alias dps="docker ps"
alias di="docker images"
alias dex="docker exec -it"
alias dlog="docker logs -f"'
    fi

    if command -v kubectl &> /dev/null; then
        add_to_zshrc '# Kubernetes aliases
alias k="kubectl"
alias kgp="kubectl get pods"
alias kgs="kubectl get services"
alias kgd="kubectl get deployments"
alias kgn="kubectl get nodes"
alias ka="kubectl apply -f"
alias kd="kubectl describe"
alias kl="kubectl logs -f"'
    fi
    
    # Add completions
    log_info "配置自动完成..."
    add_to_zshrc '# Completion settings
zstyle ":completion:*" menu select
zstyle ":completion:*" matcher-list "m:{a-zA-Z}={A-Za-z}"
zstyle ":completion:*" list-colors "${(s.:.)LS_COLORS}"
zstyle ":completion:*" auto-description "specify: %d"
zstyle ":completion:*" format "Completing %d"
zstyle ":completion:*" group-name ""
zstyle ":completion:*" verbose true'

    # Change default shell
    log_info "检查当前 shell..."
    if [ "$SHELL" != "$(which zsh)" ]; then
        log_info "将默认 shell 更改为 zsh..."
        if grep -q "$(which zsh)" /etc/shells; then
            chsh -s "$(which zsh)" || {
                log_warning "自动更改 shell 失败。您可能需要运行: chsh -s $(which zsh)"
            }
        else
            log_warning "$(which zsh) 不在 /etc/shells 中。正在添加..."
            echo "$(which zsh)" | sudo tee -a /etc/shells > /dev/null || {
                log_warning "将 zsh 添加到 /etc/shells 失败。您可能需要运行: sudo echo $(which zsh) >> /etc/shells"
            }
            chsh -s "$(which zsh)" || {
                log_warning "自动更改 shell 失败。您可能需要运行: chsh -s $(which zsh)"
            }
        fi
    else
        log_info "Shell 已经设置为 zsh"
    fi
    
    log_success "安装完成！"
    log_success "新增了以下生产环境常用插件和功能:"
    log_info "1. 自动提示和语法高亮"
    log_info "2. 历史搜索增强"
    log_info "3. 目录导航增强 (z 插件)"
    log_info "4. 彩色 man 页面"
    log_info "5. sudo 快捷键 (按两次 ESC 添加 sudo)"
    log_info "6. 针对 Git、Docker、Kubernetes 等的命令补全和别名"
    log_info "7. 增强的历史记录设置"
    log_info "8. 为常用操作添加的别名"
    log_info "9. 智能命令补全配置"
    
    if $FZF_INSTALLED; then
        log_info "10. 模糊查找器 (fzf) 集成"
    fi
    
    if $AUTOJUMP_INSTALLED; then
        log_info "11. 自动跳转 (autojump) 集成"
    fi
    
    if $DIRENV_INSTALLED; then
        log_info "12. direnv 环境管理集成"
    fi
    
    log_info "\n要开始使用增强的 zsh 环境，您可以："
    log_info "1. 运行 'zsh' 启动新的 zsh 会话"
    log_info "2. 注销并重新登录以使用 zsh 作为默认 shell"
    log_info "3. 重启终端"
}

# Run the main function
main
