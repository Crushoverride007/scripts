# Load Powerlevel10k instant prompt as early as possible
[[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]] && source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"


# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

export PATH="/opt/homebrew/opt/bison/bin:$PATH"
export PATH="/opt/homebrew/opt/llvm/bin:$PATH"


eval "$(rbenv init -)"

# Source Oh My Zsh
source "$ZSH/oh-my-zsh.sh"



# Disabling the annoying brew auto update
export HOMEBREW_NO_AUTO_UPDATE=1

# Adding better ls command
alias ls="eza --color=always --long --no-filesize --icons=always --no-time --no-user --no-permissions"

# History settings
HISTFILE=~/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000
HIST_STAMPS="dd.mm.yyyy"
setopt SHARE_HISTORY

# PATH configuration for different tools and applications
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
export PATH="$PATH:$HOME/.emacs.d/doom/bin"
export PATH="/opt/homebrew/opt/php@7.4/bin:$PATH"
export PATH="/opt/homebrew/opt/php@7.4/sbin:$PATH"
export PATH="${PATH}:/usr/local/mysql/bin/"
export PATH="$PNPM_HOME:$PATH"
export PATH="$PATH:/usr/local/microsoft/powershell/7:/usr/local/bin"
export PATH=/opt/homebrew/bin:$PATH
export PATH="$PATH:/Users/senkvs/.bin"

# Ruby gems PATH
path+=(
    $(ruby -e 'puts File.join(Gem.user_dir, "bin")')
)
PATH=$PATH:$(ruby -e 'puts Gem.bindir')

# Alias for various functionality
alias run-script-admin='open https://mouhcine-mesmouki7.myshopify.com/admin'
alias run-script-anouar='open https://accounts.shopify.com/store-login'
alias run-script-editor='open https://mouhcine-mesmouki7.myshopify.com/admin/themes/121737084985/editor'
alias run-script-gmail='open https://mail.google.com/mail/u/4/\?ogbl\#inbox'
alias run-script-settings='open https://mouhcine-mesmouki7.myshopify.com/admin/settings/general'
alias msfconsole='/opt/metasploit-framework/bin/msfconsole'
alias sqlmap='python3 ~/Documents/GitHub/sqlmap-dev/sqlmap.py'
alias cde='open -a codeedit'
alias netflix='open https://www.netflix.com'
alias syspref='open -a System\ Preferences'
alias encrypto='open -a Encrypto'
alias chrome="open -a Google\ Chrome"
alias safari="open -a Safari"
alias keychain="open -a Keychain\ Access"
alias docs="open -a Microsoft\ Word"
alias ppt="open -a Microsoft\ PowerPoint"
alias ls='lsd'
alias l='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias lt='ls --tree'
alias textedit="open -a TextEdit"
alias notes="open -a Notes"
alias cat='bat' # Batcat
alias mosint="~/go/bin/mosint"
alias myip="curl http://ipecho.net/plain; echo"
alias usage='du -h -d1'
alias ifconfig='ifconfig | grep -A1 "inet "'


#GIT 

alias gc="git commit -m"
alias gca="git commit -a -m"
alias gp="git push origin HEAD"
alias gpu="git pull origin"
alias gst="git status"
alias glog="git log --graph --topo-order --pretty='%w(100,0,6)%C(yellow)%h%C(bold)%C(black)%d %C(cyan)%ar %C(green)%an%n%C(bold)%C(white)%s %N' --abbrev-commit"
alias gdiff="git diff"
alias gco="git checkout"
alias gb='git branch'
alias gba='git branch -a'
alias gadd='git add'
alias ga='git add -p'
alias gcoall='git checkout -- .'
alias gr='git remote'
alias gre='git reset'

# Method to force quit apps from terminal
quitapp() {
    osascript -e "quit app \"$1\""
}


# Save the zinit installation check before sourcing powerlevel10k zinit wrapper

# Check if zinit is installed
if [[ ! -f "$HOME/.local/share/zinit/zinit.git/zinit.zsh" ]]; then
    echo "Warning: Zinit is not installed. Please run the following command to install it:"
    echo "git clone https://github.com/zdharma-continuum/zinit.git ~/.local/share/zinit/zinit.git"
    exit 1  # Exit if Zinit is not installed
fi

# Source Zinit and load Powerlevel10k
source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
zinit light romkatv/powerlevel10k


if [[ ! -f "$HOME/.local/share/zinit/zinit.git/zinit.zsh" ]]; then
  echo "Warning: Zinit is not installed. Please run the following command to install it:"
  echo "git clone https://github.com/zdharma-continuum/zinit.git ~/.local/share/zinit/zinit.git"
  exit 1  # Exit if Zinit is not installed
else
  source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
fi

# Zinit plugins
zinit light-mode for \
  zdharma-continuum/zinit-annex-as-monitor \
  zdharma-continuum/zinit-annex-bin-gem-node \
  zdharma-continuum/zinit-annex-patch-dl \
  zdharma-continuum/zinit-annex-rust

zinit light zdharma-continuum/fast-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions
zinit light sindresorhus/pure
zinit light zsh-users/zsh-completions



#Plugins for Zsh

plugins=(
zsh-navigation-tools
zsh-interactive-cd
themes
direnv
colored-man-pages
zsh-syntax-highlighting
themes
zsh-interactive-cd
vscode
torrent
systemadmin
gcloud
colorize
aliases	
git
extract
zsh-autosuggestions
sudo
web-search
copypath
copyfile
history
macos
laravel
)



# Other tools and configurations
# PNPM
export PNPM_HOME="$HOME/Library/pnpm"

# Broot
source "$HOME/.config/broot/launcher/bash/br"

# iTerm2 Shell Integration
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Homebrew NVM
source $(brew --prefix nvm)/nvm.sh

# Fig post block
[[ -f "$HOME/.fig/shell/zshrc.post.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.post.zsh"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# --- TheFuck ---

# thefuck alias

eval $(thefuck --alias)
eval $(thefuck --alias fk)

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
