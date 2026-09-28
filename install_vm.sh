#!/usr/bin/env bash
# =============================================================================
#  install_vm.sh  --  one clean Ubuntu 24.04 VM
#
#  USAGE (run as your normal user - NOT with sudo)
#    curl -fsSL https://raw.githubusercontent.com/Crushoverride007/scripts/main/install_vm.sh | bash -s -- --desktop
#    curl -fsSL .../install_vm.sh | bash -s -- --server --name web1 --ram 2
#    bash install_vm.sh --server
#
#  Windows PowerShell:
#    powershell -ExecutionPolicy Bypass -c "& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Crushoverride007/scripts/main/install_vm.ps1))) --server"
#
#  It writes a small Vagrantfile into ./NAME and boots it. --server is a stock
#  box with nothing added. --desktop adds the Ubuntu desktop packages and
#  nothing else. No users, no services, no configuration.
#
#  FLAGS
#    --desktop        Ubuntu 24.04 with a GNOME desktop   (default)
#    --server         Ubuntu 24.04 server, headless
#    --name NAME      hostname and folder name          (default: ubuntu-vm)
#    --ip A.B.C.D     host-only IP                      (default: 192.168.56.20)
#    --ram SIZE       RAM: 4, 4GB or 4096MB             (default: 8GB desktop
#                                                          2GB server)
#    --cpus N         vCPUs                             (default: 4 desktop
#                                                          2 server)
#    --disk SIZE      grow the root disk to SIZE        (default: box size, 64GB)
#    --box NAME       override the box                  (default: bento/ubuntu-24.04)
#    --provider NAME  vmware_desktop|virtualbox|hyperv  (default: vmware_desktop)
#    --no-window      boot with the hypervisor window closed
#    --no-up          write the Vagrantfile but do not boot
#    -h, --help       this text
# =============================================================================

# Everything lives inside main(), which is only called on the very last line.
# With "curl | bash", bash runs the script as it arrives: if the download is
# cut short, a half-received main() is never called, so nothing half-runs.
main() {
set -euo pipefail

KIND="desktop"
VM_NAME="ubuntu-vm"
VM_IP="192.168.56.20"
VM_RAM=""
VM_CPUS=""
VM_DISK=""
VM_BOX=""
PROVIDER="vmware_desktop"
GUI=""
NO_UP=0
# bento/ubuntu-24.04 ships a 64 GB root disk. A disk can only be grown, never
# shrunk (VMware answers "Shrinking disks is not supported"), so anything
# smaller than this is refused up front instead of silently ignored.
BENTO_DISK_GB=64

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
  # Embedded, not read from $0: when piped ("curl ... | bash -s -- --help")
  # $0 is "bash", so self-extraction would fail.
  cat <<'EOF'
install_vm.sh - one clean Ubuntu 24.04 VM.

USAGE (as your normal user - not with sudo)
  curl -fsSL https://raw.githubusercontent.com/Crushoverride007/scripts/main/install_vm.sh | bash -s -- --desktop
  curl -fsSL .../install_vm.sh | bash -s -- --server --name web1 --ram 2
  bash install_vm.sh --server

--server is a stock box with nothing added. --desktop adds the Ubuntu desktop
packages and nothing else. Log in as vagrant / vagrant.

FLAGS
  --desktop        Ubuntu 24.04 with a GNOME desktop   (default)
  --server         Ubuntu 24.04 server, headless
  --name NAME      hostname and folder name          (default: ubuntu-vm)
  --ip A.B.C.D     host-only IP                      (default: 192.168.56.20)
  --ram SIZE       RAM: 4, 4GB or 4096MB             (default: 8GB desktop / 2GB server)
  --cpus N         vCPUs                             (default: 4 desktop / 2 server)
  --disk SIZE      grow the root disk to SIZE, e.g. 100GB (default: the box's 64GB)
  --box NAME       override the box                  (default: bento/ubuntu-24.04)
  --provider NAME  vmware_desktop|virtualbox|hyperv  (default: vmware_desktop)
  --no-window      boot with the hypervisor window closed
  --no-up          write the Vagrantfile but do not boot
  -h, --help       this text
EOF
  exit 0
}

while [ $# -gt 0 ]; do
  case "$1" in
    --desktop)  KIND="desktop"; shift ;;
    --server)   KIND="server";  shift ;;
    --name)     VM_NAME="${2:?--name needs a value}"; shift 2 ;;
    --ip)       VM_IP="${2:?--ip needs an address}"; shift 2 ;;
    --ram)      VM_RAM="${2:?--ram needs a size}"; shift 2 ;;
    --cpus)     VM_CPUS="${2:?--cpus needs a number}"; shift 2 ;;
    --disk)     VM_DISK="${2:?--disk needs a size}"; shift 2 ;;
    --box)      VM_BOX="${2:?--box needs a name}"; shift 2 ;;
    --provider) PROVIDER="${2:?--provider needs a name}"; shift 2 ;;
    --no-window) GUI=0; shift ;;
    --no-up)    NO_UP=1; shift ;;
    -h|--help)  usage ;;
    *)          die "unknown flag: $1   (try --help)" ;;
  esac
done

# ---- never as root -----------------------------------------------------------
# Vagrant keeps boxes, plugins and the VMware licence per user; under sudo the
# VM ends up owned by root and your own "vagrant" cannot manage it afterwards.
if [ "$(id -u 2>/dev/null || echo 1000)" = "0" ] && [ "${LAB_ALLOW_ROOT:-0}" != "1" ]; then
  die "do not run this as root or with sudo - Vagrant must run as your own user.
      Use:  curl -fsSL <url>/install_vm.sh | bash -s -- --server
      (set LAB_ALLOW_ROOT=1 if you really do run Vagrant as root)"
fi

# ---- defaults per flavour ---------------------------------------------------
# Both flavours use bento/ubuntu-24.04: it is a server image published for
# every provider here. (There is no "ubuntu/24.04" box on Vagrant Cloud.)
: "${VM_BOX:=bento/ubuntu-24.04}"
case "$KIND" in
  desktop) : "${VM_RAM:=8}"; : "${VM_CPUS:=4}"; : "${GUI:=1}" ;;
  server)  : "${VM_RAM:=2}"; : "${VM_CPUS:=2}"; : "${GUI:=0}" ;;
esac

# ---- validation -------------------------------------------------------------
# RAM matches install_lab.sh: GB unless a unit says otherwise. A bare number of
# 128 or more can only have meant MB (the old --ram 8192 style), so take it so.
to_mb() {
  local v="$1" n u
  n="$(printf '%s' "$v" | tr -cd '0-9.')"
  u="$(printf '%s' "$v" | tr -cd 'A-Za-z' | tr 'a-z' 'A-Z')"
  case "$n" in ''|.|*.*.*|*[!0-9.]*) die "--ram should look like 4, 4GB or 4096MB - got '$v'" ;; esac
  case "$u" in
    '') awk -v n="$n" 'BEGIN{ if (n >= 128) printf "%d", n; else printf "%d", n*1024 }' ;;
    G|GB) awk -v n="$n" 'BEGIN{printf "%d", n*1024}' ;;
    M|MB) awk -v n="$n" 'BEGIN{printf "%d", n}' ;;
    *) die "--ram unit must be GB or MB - got '$v'" ;;
  esac
}
to_gb() { # whole GB from 100, 100GB or 1TB; empty on bad input
  local v="$1" n u
  n="$(printf '%s' "$v" | tr -cd '0-9.')"
  u="$(printf '%s' "$v" | tr -cd 'A-Za-z' | tr 'a-z' 'A-Z')"
  case "$n" in ''|*[!0-9]*) return 1 ;; esac
  case "$u" in
    ''|G|GB) printf '%s' "$((10#$n))" ;;
    T|TB)    printf '%s' "$((10#$n * 1024))" ;;
    *) return 1 ;;
  esac
}

case "$PROVIDER" in vmware_desktop|virtualbox|hyperv) : ;; *) die "unknown provider '$PROVIDER' - use vmware_desktop, virtualbox or hyperv" ;; esac
case "$VM_NAME" in ''|-*|*-|*[!A-Za-z0-9-]*) die "--name must be a hostname: letters, digits and - (not at either end)" ;; esac
[ "${#VM_NAME}" -le 63 ] || die "--name is longer than 63 characters"
case "$VM_CPUS" in ''|*[!0-9]*|0) die "--cpus must be a whole number of at least 1" ;; esac
case "$VM_BOX" in *[!A-Za-z0-9._/-]*) die "--box '$VM_BOX' does not look like a box name" ;; esac
VM_RAM_MB="$(to_mb "$VM_RAM")"
[ "$VM_RAM_MB" -ge 512 ] || die "--ram must be at least 512MB"
# The IP goes straight into the Vagrantfile, so it must be a real dotted quad.
case "$VM_IP" in *[!0-9.]*|.*|*.|*..*) die "--ip must look like 192.168.56.20" ;; esac
[ "$(printf '%s' "$VM_IP" | tr -cd '.' | wc -c | tr -d ' ')" = "3" ] || die "--ip must look like 192.168.56.20"
for o in $(printf '%s' "$VM_IP" | tr '.' ' '); do
  [ "$((10#$o))" -le 255 ] || die "--ip part '$o' is over 255"
done
DISK_GB=""
if [ -n "$VM_DISK" ]; then
  DISK_GB="$(to_gb "$VM_DISK")" || die "--disk must be a whole size like 100, 100GB or 1TB - got '$VM_DISK'"
  if [ "$VM_BOX" = "bento/ubuntu-24.04" ] && [ "$DISK_GB" -le "$BENTO_DISK_GB" ]; then
    die "--disk $VM_DISK: this box's disk is already ${BENTO_DISK_GB}GB and disks can only grow.
      Leave --disk out to keep ${BENTO_DISK_GB}GB (sparse - it only uses what is written),
      or give something bigger, like --disk 100GB."
  fi
  [ "$PROVIDER" = "hyperv" ] && warn "disk resizing on hyperv is untested here"
fi

# ---- prerequisites ----------------------------------------------------------
say "checking prerequisites"
command -v vagrant >/dev/null 2>&1 || {
  printf '\n%sVagrant is not installed.%s\n\n' "$R" "$N" >&2
  printf '  Windows : https://developer.hashicorp.com/vagrant/downloads\n' >&2
  printf '  macOS   : brew install --cask vagrant\n' >&2
  printf '  Linux   : https://developer.hashicorp.com/vagrant/install#linux\n' >&2
  exit 1
}
ok "vagrant $(vagrant --version 2>/dev/null | head -1)"

case "$PROVIDER" in
  vmware_desktop)
    # Capture first: "vagrant plugin list | grep -q" can fail under pipefail
    # when grep exits early and vagrant gets SIGPIPE.
    PLUGINS="$(vagrant plugin list 2>/dev/null || true)"
    if printf '%s\n' "$PLUGINS" | grep -q vagrant-vmware-desktop; then
      ok "vagrant-vmware-desktop plugin installed"
    else
      warn "vagrant-vmware-desktop plugin is missing - install it with:"
      warn "  vagrant plugin install vagrant-vmware-desktop"
      warn "It also needs the Vagrant VMware Utility service:"
      warn "  https://developer.hashicorp.com/vagrant/install/vmware"
    fi
    ;;
  virtualbox|hyperv) ok "provider: $PROVIDER" ;;
esac

if [ -e "$VM_NAME" ] && [ -n "$(ls -A "$VM_NAME" 2>/dev/null)" ]; then
  die "./$VM_NAME already exists and is not empty. Use a different --name."
fi

# ---- write the Vagrantfile --------------------------------------------------
say "creating ./$VM_NAME"
CREATED=0
[ -d "$VM_NAME" ] || CREATED=1
mkdir -p "$VM_NAME"
# If anything below fails, do not leave a half-written folder that blocks the
# next attempt with "already exists".
trap '[ "$CREATED" = 1 ] && rm -rf "$VM_NAME"' EXIT

GUI_RUBY=$([ "$GUI" -eq 1 ] && echo true || echo false)
VF="${VM_NAME}/Vagrantfile"

cat > "$VF" <<VAGRANTFILE
# Generated by install_vm.sh - a stock $KIND VM.
# Edit it freely; it is short on purpose.

Vagrant.configure("2") do |config|
  config.vm.box = "$VM_BOX"
  config.vm.hostname = "$VM_NAME"

  # Host-only network: reachable from the host and other lab VMs, not the internet.
  config.vm.network "private_network", ip: "$VM_IP"

  config.vm.provider "$PROVIDER" do |v|
VAGRANTFILE

case "$PROVIDER" in
  vmware_desktop)
    cat >> "$VF" <<VAGRANTFILE
    v.gui = $GUI_RUBY
    v.vmx["displayName"] = "$VM_NAME"
    v.vmx["memsize"]     = "$VM_RAM_MB"
    v.vmx["numvcpus"]    = "$VM_CPUS"
  end
VAGRANTFILE
    ;;
  virtualbox)
    cat >> "$VF" <<VAGRANTFILE
    v.gui    = $GUI_RUBY
    v.name   = "$VM_NAME"
    v.memory = $VM_RAM_MB
    v.cpus   = $VM_CPUS
  end
VAGRANTFILE
    ;;
  hyperv)
    cat >> "$VF" <<VAGRANTFILE
    v.vmname = "$VM_NAME"
    v.memory = $VM_RAM_MB
    v.cpus   = $VM_CPUS
  end
VAGRANTFILE
    ;;
esac

if [ -n "$DISK_GB" ]; then
  # Growing the virtual disk does not grow the partition or filesystem inside
  # it, so the space would sit unused. The provisioner extends the root
  # partition, then LVM (bento uses it) or the filesystem, to fill the disk.
  cat >> "$VF" <<VAGRANTFILE

  # Root disk grown to ${DISK_GB}GB (the box ships ${BENTO_DISK_GB}GB), then filled below.
  config.vm.disk :disk, size: "${DISK_GB}GB", primary: true
VAGRANTFILE
  cat >> "$VF" <<'VAGRANTFILE'
  config.vm.provision "grow-root", type: "shell", inline: <<-'SHELL'
    set -e
    command -v growpart >/dev/null 2>&1 || { apt-get update -qq; apt-get install -y -qq cloud-guest-utils; }
    SRC="$(findmnt -no SOURCE /)"
    if command -v lvs >/dev/null 2>&1 && lvs "$SRC" >/dev/null 2>&1; then
      VG="$(lvs --noheadings -o vg_name "$SRC" | tr -d ' ')"
      PART="$(pvs --noheadings -o pv_name -S vg_name="$VG" | head -n1 | tr -d ' ')"
    else
      PART="$SRC"
    fi
    PART="$(readlink -f "$PART")"
    DISK="/dev/$(lsblk -no PKNAME "$PART" | head -n1)"
    NUM="$(cat "/sys/class/block/$(basename "$PART")/partition")"
    growpart "$DISK" "$NUM" || true          # exit 1 just means "already full size"
    if [ "$PART" != "$(readlink -f "$SRC")" ]; then
      pvresize "$PART"
      lvextend -r -l +100%FREE "$SRC" || true  # no free extents = already done
    else
      resize2fs "$SRC" 2>/dev/null || xfs_growfs / || true
    fi
    df -h /
  SHELL
VAGRANTFILE
fi

if [ "$KIND" = "desktop" ]; then
  GUEST_PKG=""
  [ "$PROVIDER" = "vmware_desktop" ] && GUEST_PKG="open-vm-tools-desktop"
  cat >> "$VF" <<VAGRANTFILE

  # The box is a server image; this adds the Ubuntu desktop and nothing else.
  # Log in on the VM window as vagrant / vagrant.
  config.vm.provision "desktop", type: "shell", inline: <<-SHELL
    export DEBIAN_FRONTEND=noninteractive
    if ! dpkg -s ubuntu-desktop-minimal >/dev/null 2>&1; then
      apt-get update -qq
      apt-get install -y -qq ubuntu-desktop-minimal $GUEST_PKG
    fi
    systemctl set-default graphical.target
    systemctl restart gdm3
  SHELL
VAGRANTFILE
fi

printf '\nend\n' >> "$VF"

printf '%s\n' ".vagrant/" "*.log" ".DS_Store" > "${VM_NAME}/.gitignore"
ok "Vagrantfile written"

say "verifying"
cd "$VM_NAME"
# Capture first, then test the captured status. "vagrant validate | sed" would
# report sed's status (always 0) and let a broken Vagrantfile through to vagrant up.
if VOUT="$(vagrant validate 2>&1)"; then
  printf '%s\n' "$VOUT" | sed 's/^/  /'
  ok "configuration is valid"
else
  printf '%s\n' "$VOUT" | sed 's/^/  /'
  cd ..
  die "generated Vagrantfile did not validate - please report this"
fi
cd ..
# From here on the folder is valid and worth keeping, even if vagrant up fails.
trap - EXIT

# ---- build ------------------------------------------------------------------
if [ "$NO_UP" -eq 1 ]; then
  say "done. boot it later with:  cd $VM_NAME && vagrant up"
  exit 0
fi

if [ "$KIND" = "desktop" ]; then
  say "building $VM_NAME (desktop) - first run downloads the box and the desktop, allow 15-20 min"
else
  say "building $VM_NAME (server) - first run downloads the box, allow 5-10 min"
fi
( cd "$VM_NAME" && vagrant up )

cat <<EOF

${G}$VM_NAME is up.${N}

  cd $VM_NAME
  vagrant ssh              # log in as 'vagrant' (password: vagrant)
  vagrant halt             # stop it
  vagrant up               # start it again
  vagrant destroy -f       # delete it completely

  VM: $KIND, $VM_RAM_MB MB RAM, $VM_CPUS vCPU, disk ${DISK_GB:-$BENTO_DISK_GB}GB, ip $VM_IP
EOF
}

main "$@"
