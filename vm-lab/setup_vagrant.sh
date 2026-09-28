#!/usr/bin/env bash
# =============================================================================
#  setup_vagrant.sh  --  install Vagrant + a hypervisor setup, macOS and Linux
#
#  USAGE (run as your normal user - it asks for sudo only where it must)
#    curl -fsSL https://raw.githubusercontent.com/Crushoverride007/scripts/main/vm-lab/setup_vagrant.sh | bash
#    curl -fsSL .../vm-lab/setup_vagrant.sh | bash -s -- --provider libvirt -y
#
#  Windows: use setup_vagrant.ps1 instead.
#
#  It installs what is missing and asks before each install:
#    - Vagrant                       (Homebrew on macOS, HashiCorp's repo on Linux)
#    - the provider's Vagrant plugin (vmware / libvirt / parallels)
#    - libvirt + KVM, or VirtualBox, when that is the provider
#    - the Vagrant VMware Utility, when the provider is VMware
#
#  It can NOT install VMware Workstation/Fusion or Parallels Desktop: both
#  need an account login and a licence. It checks for them and says so.
#
#  FLAGS
#    --provider NAME   vmware_desktop | virtualbox | libvirt | parallels
#                      (default: what is already installed, else libvirt on
#                       Linux and virtualbox on macOS)
#    -y, --yes         install without asking
#    -h, --help        this text
# =============================================================================

# Everything lives inside main(), which is only called on the very last line,
# so a download cut short under "curl | bash" never runs half a script.
main() {
set -euo pipefail

PROVIDER=""
ASSUME_YES=0

if [ -t 1 ]; then
  B=$'\033[1m'; G=$'\033[32m'; Y=$'\033[33m'; R=$'\033[31m'; N=$'\033[0m'
else
  B=""; G=""; Y=""; R=""; N=""
fi
say()  { printf '%s\n' "${B}==>${N} $*"; }
ok()   { printf '  %s✓%s %s\n' "$G" "$N" "$*"; }
warn() { printf '  %s!%s %s\n' "$Y" "$N" "$*" >&2; }
die()  { printf '  %sx%s %s\n' "$R" "$N" "$*" >&2; exit 1; }

usage() {
  cat <<'EOF'
setup_vagrant.sh - install Vagrant and a hypervisor setup (macOS, Linux).

USAGE (as your normal user - not with sudo)
  curl -fsSL https://raw.githubusercontent.com/Crushoverride007/scripts/main/vm-lab/setup_vagrant.sh | bash
  curl -fsSL .../vm-lab/setup_vagrant.sh | bash -s -- --provider libvirt -y

Installs what is missing, asking before each install: Vagrant, the provider's
plugin, and libvirt/KVM, VirtualBox or the Vagrant VMware Utility as needed.
VMware Workstation/Fusion and Parallels Desktop must be installed by hand.

FLAGS
  --provider NAME   vmware_desktop | virtualbox | libvirt | parallels
                    (default: what is installed, else libvirt on Linux,
                     virtualbox on macOS)
  -y, --yes         install without asking
  -h, --help        this text
EOF
  exit 0
}

while [ $# -gt 0 ]; do
  case "$1" in
    --provider) PROVIDER="${2:?--provider needs a name}"; shift 2 ;;
    -y|--yes)   ASSUME_YES=1; shift ;;
    -h|--help)  usage ;;
    *)          die "unknown flag: $1   (try --help)" ;;
  esac
done
case "$PROVIDER" in
  ''|vmware_desktop|virtualbox|libvirt|parallels) : ;;
  hyperv) die "hyperv is Windows-only - use setup_vagrant.ps1 there" ;;
  *) die "unknown provider '$PROVIDER' - use vmware_desktop, virtualbox, libvirt or parallels" ;;
esac

# Vagrant, its plugins and the boxes are per user: as root they would all end
# up in root's home. sudo is used below only for system packages.
if [ "$(id -u)" = "0" ] && [ "${LAB_ALLOW_ROOT:-0}" != "1" ]; then
  die "run this as your normal user, not with sudo - it asks for sudo itself where needed"
fi

# ---- platform ---------------------------------------------------------------
OS="$(uname -s)"
ARCH="$(uname -m)"
DISTRO=""
case "$OS" in
  Darwin) PLATFORM=macos ;;
  Linux)
    PLATFORM=linux
    grep -qi microsoft /proc/version 2>/dev/null && \
      die "this is WSL. Vagrant there cannot drive your Windows hypervisor properly -
      run setup_vagrant.ps1 from PowerShell instead."
    if [ -r /etc/os-release ]; then
      # shellcheck disable=SC1091
      . /etc/os-release
      case " ${ID:-} ${ID_LIKE:-} " in
        *" debian "*|*" ubuntu "*)                 DISTRO=debian ;;
        *" fedora "*)                              DISTRO=fedora ;;
        *" rhel "*|*" centos "*|*" rocky "*|*" almalinux "*) DISTRO=rhel ;;
        *" arch "*)                                DISTRO=arch ;;
      esac
    fi
    ;;
  *) die "unsupported OS '$OS' - on Windows use setup_vagrant.ps1" ;;
esac
ok "platform: $PLATFORM${DISTRO:+ ($DISTRO)}, $ARCH"

# ---- helpers ------------------------------------------------------------------
TTY=""
if [ "$ASSUME_YES" -eq 0 ] && { : </dev/tty >/dev/tty; } 2>/dev/null; then TTY=/dev/tty; fi
confirm() { # confirm "question" -> 0 yes / 1 no
  [ "$ASSUME_YES" -eq 1 ] && return 0
  if [ -z "$TTY" ]; then
    warn "no terminal to ask on - re-run with -y to install without asking"
    return 1
  fi
  local a=""
  read -r -p "  $1 [Y/n]: " a < "$TTY" || a=""
  case "$(printf '%s' "${a%$'\r'}" | tr 'A-Z' 'a-z')" in ''|y|yes) return 0 ;; *) return 1 ;; esac
}
have() { command -v "$1" >/dev/null 2>&1; }
need_sudo() {
  have sudo || die "sudo is needed to install system packages"
  sudo -v || die "sudo was refused"
}
need_brew() {
  have brew && return 0
  die "Homebrew is needed on macOS. Install it first:
      /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
}
pkg_install() { # pkg_install PKG... (Linux system packages)
  need_sudo
  case "$DISTRO" in
    debian) sudo apt-get update -qq && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$@" ;;
    fedora|rhel) sudo dnf install -y "$@" ;;
    arch)   sudo pacman -S --needed --noconfirm "$@" ;;
    *)      die "do not know how to install packages on this distro - install $* by hand" ;;
  esac
}
# Download a HashiCorp release file and check it against the published SHA256SUMS.
hc_download() { # hc_download PRODUCT VERSION FILE DEST
  local base="https://releases.hashicorp.com/$1/$2"
  curl -fsSL --retry 3 "$base/$3" -o "$4"
  local want
  want="$(curl -fsSL --retry 3 "$base/$1_$2_SHA256SUMS" | awk -v f="$3" '$2==f{print $1}')"
  [ -n "$want" ] || die "no checksum published for $3"
  local got
  if have sha256sum; then got="$(sha256sum "$4" | awk '{print $1}')"; else got="$(shasum -a 256 "$4" | awk '{print $1}')"; fi
  [ "$got" = "$want" ] || die "checksum mismatch for $3 - not installing it"
}
hc_latest() { # hc_latest PRODUCT -> version
  curl -fsSL "https://checkpoint-api.hashicorp.com/v1/check/$1" | sed -n 's/.*"current_version":"\([^"]*\)".*/\1/p'
}

# ---- 1. Vagrant ---------------------------------------------------------------
say "Vagrant"
if have vagrant; then
  ok "$(vagrant --version | head -1)"
elif confirm "Vagrant is not installed. Install it now?"; then
  if [ "$PLATFORM" = macos ]; then
    need_brew
    brew install --cask hashicorp/tap/hashicorp-vagrant
  else
    need_sudo
    case "$DISTRO" in
      debian)
        sudo apt-get update -qq
        sudo apt-get install -y gnupg curl lsb-release
        curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor --yes -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
          | sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null
        pkg_install vagrant
        ;;
      fedora)
        sudo dnf install -y dnf-plugins-core
        sudo dnf config-manager addrepo --from-repofile=https://rpm.releases.hashicorp.com/fedora/hashicorp.repo 2>/dev/null \
          || sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
        pkg_install vagrant
        ;;
      rhel)
        sudo dnf install -y dnf-plugins-core
        sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
        pkg_install vagrant
        ;;
      arch) pkg_install vagrant ;;
      *) die "install Vagrant by hand: https://developer.hashicorp.com/vagrant/install" ;;
    esac
  fi
  have vagrant || die "Vagrant was installed but is not on PATH yet - open a new terminal and re-run"
  ok "$(vagrant --version | head -1)"
else
  die "Vagrant is required - install it from https://developer.hashicorp.com/vagrant/install"
fi

# ---- 2. which provider --------------------------------------------------------
PLUGINS="$(vagrant plugin list 2>/dev/null || true)"
has_plugin() { printf '%s\n' "$PLUGINS" | grep -q "^$1 "; }
vmware_installed() {
  if [ "$PLATFORM" = macos ]; then [ -d "/Applications/VMware Fusion.app" ]
  else have vmware || have vmrun; fi
}
if [ -z "$PROVIDER" ]; then
  if [ "$PLATFORM" = macos ]; then
    if   have prlctl;          then PROVIDER=parallels
    elif vmware_installed;     then PROVIDER=vmware_desktop
    else                            PROVIDER=virtualbox
    fi
  else
    if   has_plugin vagrant-libvirt || have virsh; then PROVIDER=libvirt
    elif vmware_installed;     then PROVIDER=vmware_desktop
    elif have VBoxManage;      then PROVIDER=virtualbox
    else                            PROVIDER=libvirt   # free, and built into the kernel
    fi
  fi
fi
say "provider: $PROVIDER"

install_plugin() { # install_plugin NAME
  if has_plugin "$1"; then ok "$1 plugin installed"; return 0; fi
  if confirm "Install the $1 Vagrant plugin?"; then
    vagrant plugin install "$1"
    ok "$1 plugin installed"
  else
    warn "skipped: vagrant plugin install $1"
  fi
}

# ---- 3. the provider ----------------------------------------------------------
case "$PROVIDER" in
  vmware_desktop)
    if vmware_installed; then
      ok "VMware $([ "$PLATFORM" = macos ] && echo Fusion || echo Workstation) found"
    else
      warn "VMware is not installed, and this script cannot install it (it needs a Broadcom"
      warn "account). It is free for personal use: https://www.vmware.com/products/desktop-hypervisor"
      warn "Install it, then re-run this script."
    fi
    # The plugin talks to this background service; without it nothing works.
    if { [ "$PLATFORM" = macos ] && [ -d /opt/vagrant-vmware-desktop ]; } || \
       { [ "$PLATFORM" = linux ] && systemctl is-active --quiet vagrant-vmware-utility 2>/dev/null; }; then
      ok "Vagrant VMware Utility running"
    elif confirm "Install the Vagrant VMware Utility (needed by the VMware plugin)?"; then
      if [ "$PLATFORM" = macos ]; then
        need_brew
        brew install --cask vagrant-vmware-utility
      else
        ver="$(hc_latest vagrant-vmware-utility)"
        [ -n "$ver" ] || die "could not look up the latest Vagrant VMware Utility version"
        tmp="$(mktemp -d)"
        case "$DISTRO" in
          debian) f="vagrant-vmware-utility_${ver}-1_amd64.deb" ;;
          fedora|rhel) f="vagrant-vmware-utility-${ver}-1.x86_64.rpm" ;;
          *) die "install the Vagrant VMware Utility by hand: https://developer.hashicorp.com/vagrant/install/vmware" ;;
        esac
        hc_download vagrant-vmware-utility "$ver" "$f" "$tmp/$f"
        pkg_install "$tmp/$f"
        rm -rf "$tmp"
        sudo systemctl enable --now vagrant-vmware-utility 2>/dev/null || true
      fi
      ok "Vagrant VMware Utility installed"
    fi
    install_plugin vagrant-vmware-desktop
    ;;

  virtualbox)
    if have VBoxManage; then
      ok "VirtualBox $(VBoxManage --version 2>/dev/null | head -1)"
    elif confirm "VirtualBox is not installed. Install it now?"; then
      if [ "$PLATFORM" = macos ]; then
        need_brew
        brew install --cask virtualbox
        warn "macOS may block the VirtualBox kernel extension: allow it in"
        warn "System Settings > Privacy & Security, then reboot."
      else
        case "$DISTRO" in
          debian) pkg_install virtualbox ;;
          arch)   pkg_install virtualbox virtualbox-host-modules-arch ;;
          *) die "install VirtualBox by hand for this distro: https://www.virtualbox.org/wiki/Linux_Downloads" ;;
        esac
      fi
      have VBoxManage && ok "VirtualBox installed"
    fi
    ;;

  libvirt)
    [ "$PLATFORM" = linux ] || die "libvirt is Linux-only - on macOS use parallels, vmware_desktop or virtualbox"
    if [ ! -e /dev/kvm ]; then
      warn "/dev/kvm is missing: hardware virtualisation is off in the BIOS/UEFI, or this is"
      warn "a VM without nested virtualisation. libvirt VMs will be very slow or fail."
    fi
    # The plugin compiles against libvirt's headers, so virsh alone is not enough.
    if have virsh && [ -e /usr/include/libvirt/libvirt.h ]; then
      ok "libvirt found"
    elif confirm "Install libvirt + KVM (and the headers the plugin builds against)?"; then
      case "$DISTRO" in
        debian) pkg_install qemu-kvm libvirt-daemon-system libvirt-clients libvirt-dev ebtables \
                            dnsmasq-base libxslt-dev libxml2-dev zlib1g-dev ruby-dev build-essential pkg-config ;;
        fedora|rhel) pkg_install @virtualization libvirt-devel gcc make pkgconf-pkg-config ;;
        arch)   pkg_install libvirt qemu-base dnsmasq iptables-nft base-devel pkgconf ;;
        *) die "install libvirt by hand: https://vagrant-libvirt.github.io/vagrant-libvirt/installation.html" ;;
      esac
      sudo systemctl enable --now libvirtd 2>/dev/null || true
      ok "libvirt installed"
    fi
    # Vagrant talks to libvirt as you, which needs the libvirt group.
    if id -nG "$(id -un)" | tr ' ' '\n' | grep -qx libvirt; then
      ok "$(id -un) is in the libvirt group"
    elif getent group libvirt >/dev/null && confirm "Add $(id -un) to the libvirt group (needed to run VMs without sudo)?"; then
      need_sudo
      sudo usermod -aG libvirt "$(id -un)"
      warn "log out and back in (or reboot) for the libvirt group to take effect"
    fi
    install_plugin vagrant-libvirt
    ;;

  parallels)
    [ "$PLATFORM" = macos ] || die "parallels is macOS-only"
    if have prlctl; then
      ok "Parallels Desktop found"
    else
      warn "Parallels Desktop is not installed, and this script cannot install it (it needs"
      warn "a licence - Pro or Business edition for Vagrant). https://www.parallels.com"
    fi
    install_plugin vagrant-parallels
    ;;
esac

cat <<EOF

${G}Done.${N} Build a lab with:

  curl -fsSL https://raw.githubusercontent.com/Crushoverride007/scripts/main/vm-lab/install_lab.sh | bash -s -- --provider $PROVIDER

EOF
}

main "$@"
