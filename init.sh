#!/bin/bash
#!/bin/bash

# Check if the current system is macOS
if [[ "$(uname -a)" == *"Darwin"* ]]; then
  # map ideavim
  ln -s ~/.config/ideavimrc ~/.ideavimrc
  # map hammerspoon
  ln -s ~/.config/hammerspoon ~/.hammerspoon
  # map zsh
  ln -s ~/.config/zsh/zshrc ~/.zshrc

  # map mcp
  ln -s ~/.config/mcp/mcpservers.json ~/mcpservers.json

  brew install zsh
  # set default zsh
  chsh -s /usr/local/bin/zsh

fi
