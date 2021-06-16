## My Config
This is my config about tmux/nvim/ranger

```bash
git clone --recursive https://github.com/yelog/.config.git ~/.config
```

## Import stuff
### neovim
```bash
# Download source code
git clone https://github.com/neovim/neovim.git
# install cmake and dependency
sudo yum install -y cmake gcc-c++ libtool unzip
# compile with cmake
make CMAKE_BUILD_TYPE=Release
# install
make install
# vim-plug
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
```

### lazygit
```bash
yum install dnf
dnf install 'dnf-command(copr)'
dnf copr enable atim/lazygit -y
dnf install -y lazygit
```

### neofetch
```bash
dnf copr enable konimex/neofetch
dnf install neofetch
```

### zsh
[github](https://github.com/ohmyzsh/ohmyzsh.git)
```bash
# 安装zsh
brew install zsh zsh-completions
# 设置 zsh 为默认shell
chsh -s $(which zsh)
# 查检-需要关闭终端重新打开后生效
echo $SHELL
# 1、通过curl方式安装：
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# 2、通过wget方式安装
sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# 修改配置文件
ln ~/.config/zsh/zshrc ~/.zshrc
# 下载主题
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
# autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
# history
 git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search
# syntax
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```
### neovim
[install](https://github.com/neovim/neovim/wiki/Installing-Neovim)

### ranger

```bash
pip install ranger-fm

```
### tmux
[install tmux](https://github.com/tmux/tmux/wiki/Installing)

```bash
ln ~/.config/tmux/tmux.conf ~/.tmux.conf
```

### rainbarf
```bash
# Download source code
git clone https://github.com/creaktive/rainbarf.git
# install dependency
yum install -y perl-Module-Build perl-Test-Simple
# install
perl Build.PL
./Build test
./Build install
```

