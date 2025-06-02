OS=$(uname)
CONFIG_DIR="$HOME/.config/Code/User"

if [[ "$OS" == "Darwin" ]]; then
  SETTINGS_URL="https://raw.githubusercontent.com/Crushoverride007/scripts/main/vscode-setup/settings-macos.json"
  CONFIG_DIR="$HOME/Library/Application Support/Code/User"
elif [[ "$OS" == "Linux" ]]; then
  SETTINGS_URL="https://raw.githubusercontent.com/Crushoverride007/scripts/main/vscode-setup/settings-linux.json"
  CONFIG_DIR="$HOME/.config/Code/User"
fi

mkdir -p "$CONFIG_DIR"
curl -fsSL "$SETTINGS_URL" -o "$CONFIG_DIR/settings.json"
