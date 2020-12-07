## My Config
This is my config about tmux/nvim/ranger

```bash
git clone --recursive https://github.com/yelog/.config.git ~/.config
```

## Import stuff
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
