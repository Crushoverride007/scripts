#!/usr/bin/env bash
# =============================================================================
#  install_lab.sh  --  create a multi-VM lab with one command
#
#  USAGE (run as your normal user - NOT with sudo)
#    curl -fsSL https://raw.githubusercontent.com/Crushoverride007/scripts/main/install_lab.sh | bash
#    curl -fsSL .../install_lab.sh | bash -s -- -y --count 3 --up     # fully unattended
#    bash install_lab.sh
#
#  Windows PowerShell:
#    powershell -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/Crushoverride007/scripts/main/install_lab.ps1 | iex"
#
#  It checks your platform and prerequisites, downloads the Vagrant project,
#  asks about each VM in turn, warns if the total will not fit on this PC,
#  writes lab.yml, then builds.
#
#  With no terminal (or -y) it uses the defaults and never asks. It then only
#  PREPARES the lab; add --up to build it too.
#
#  FLAGS set the DEFAULTS for the questions; you can still override per VM.
#    --dir PATH        where to put the project       (default: ./vms-lab)
#    --count N         how many VMs                    (default: 2)
#    --names A,B,C     VM names                        (default: ubuntu-node-1..N)
#    --ram GB          RAM per VM, in GB. Accepts 4, 4GB or 512MB
#                                               (default: 4 desktop / 2 server)
#    --cpus N          vCPUs per VM                    (default: 2)
#    --disk SIZE       data disk per VM       (default: 20GB, any size -
#                    this is a separate disk, not the root one)
#    --flavour NAME    desktop | server                (default: desktop)
#    --provider NAME   vmware_desktop|virtualbox|hyperv
#    --subnet A.B.C    host-only subnet                (default: 192.168.56)
#    --box NAME        override the Vagrant box
#    --user NAME       login created on every VM       (default: Mouhcine)
#    --password PASS   its password               (default: random, printed)
#    --no-demo         skip the demo web page
#    --no-up           prepare only, do not boot
#    --up              build without asking
#    --local           use a local copy of the project instead of fetching it
#    -y, --yes         no questions at all
#    -h, --help        usage
#
#  ENVIRONMENT
#    LAB_REPO          owner/repo to download from  (default: Crushoverride007/scripts)
#    LAB_REF           branch, tag or commit        (default: main)
#    LAB_PATH          folder in the repo           (default: vms-lab)
#    LAB_RAW_BASE      full URL, overrides all three
# =============================================================================

# Everything lives inside main(), which is only called on the very last line.
# With "curl | bash", bash runs the script as it arrives: if the download is
# cut short, a half-received main() is never called, so nothing half-runs.
main() {
set -euo pipefail

LAB_REPO="${LAB_REPO:-Crushoverride007/scripts}"
LAB_REF="${LAB_REF:-main}"
LAB_PATH="${LAB_PATH-vms-lab}"
RAW_BASE="${LAB_RAW_BASE:-https://raw.githubusercontent.com/${LAB_REPO}/${LAB_REF}${LAB_PATH:+/$LAB_PATH}}"

D_DIR="./vms-lab"
D_COUNT=2
D_NAMES=""
D_RAM=""                     # in GB; empty = pick by flavour (4 desktop, 2 server)
D_CPUS=2
# :disk is the size of the VM's DATA disk, which is attached and formatted
# separately from the root disk. Any size works and is honoured exactly.
# The root disk is the box's own (64 GB, sparse) and is not user-controlled -
# VMware cannot shrink a cloned virtual disk, so it was never adjustable.
D_DISK="20GB"
D_FLAVOUR="desktop"
D_PROVIDER="vmware_desktop"
D_SUBNET="192.168.56"
D_BOX=""
D_USER="Mouhcine"
D_PASS=""                    # empty = generate a random one
D_DEMO=1
D_LOCAL=0
ASSUME_YES=0
FORCE_UP=0
FORCE_NO_UP=0

# ---- output ------------------------------------------------------------------
if [ -t 1 ]; then
  B=$'\033[1m'; G=$'\033[32m'; Y=$'\033[33m'; R=$'\033[31m'; C=$'\033[36m'; N=$'\033[0m'
else
  B=""; G=""; Y=""; R=""; C=""; N=""
fi
say()  { printf '%s\n' "${B}==>${N} $*"; }
ok()   { printf '  %s✓%s %s\n' "$G" "$N" "$*"; }
warn() { printf '  %s!%s %s\n' "$Y" "$N" "$*" >&2; }
die()  { printf '  %sx%s %s\n' "$R" "$N" "$*" >&2; exit 1; }

usage() {
  # Embedded, not read from $0: when piped ("curl ... | bash -s -- --help")
  # $0 is "bash", so self-extraction would fail.
  cat <<'EOF'
install_lab.sh - create a multi-VM lab with one command.

USAGE (as your normal user - not with sudo)
  curl -fsSL https://raw.githubusercontent.com/Crushoverride007/scripts/main/install_lab.sh | bash
  curl -fsSL .../install_lab.sh | bash -s -- -y --count 3 --up
  bash install_lab.sh

  Windows PowerShell:
  powershell -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/Crushoverride007/scripts/main/install_lab.ps1 | iex"

It checks your platform and prerequisites, downloads the Vagrant project, asks
about each VM in turn, warns if the total will not fit on this PC, writes
lab.yml, then builds. With no terminal (or -y) it asks nothing and only
prepares the lab - add --up to build it as well.

FLAGS (these set the DEFAULTS; per-VM answers can still override)
  --dir PATH        where to put the project       (default: ./vms-lab)
  --count N         how many VMs                    (default: 2)
  --names A,B,C     VM names                        (default: ubuntu-node-1..N)
  --ram GB          RAM per VM. Accepts 4, 4GB or 512MB (default: 4 desktop, 2 server)
  --cpus N          vCPUs per VM                    (default: 2)
  --disk SIZE       data disk per VM               (default: 20GB, any size)
  --flavour NAME    desktop | server                (default: desktop)
                    server = headless, no GUI packages installed
  --provider NAME   vmware_desktop|virtualbox|hyperv
  --subnet A.B.C    host-only subnet                (default: 192.168.56)
  --box NAME        override the Vagrant box        (default: bento/ubuntu-24.04)
  --user NAME       login created on every VM       (default: Mouhcine)
  --password PASS   its password                    (default: random, printed at the end)
  --no-demo         skip the demo web page
  --no-up           prepare only, do not boot
  --up              build without asking
  --local           use a local copy of the project instead of fetching it
  -y, --yes         no questions at all
  -h, --help        this text

ENVIRONMENT
  LAB_REPO          owner/repo to download from (default: Crushoverride007/scripts)
  LAB_REF           branch, tag or commit       (default: main) - pin a tag for
                    reproducible builds
  LAB_PATH          folder inside the repo      (default: vms-lab)
  LAB_RAW_BASE      full URL, overrides the three above (mirrors, testing)
EOF
  exit 0
}

# ---- flags -------------------------------------------------------------------
while [ $# -gt 0 ]; do
  case "$1" in
    --dir)      D_DIR="${2:?--dir needs a path}"; shift 2 ;;
    --count)    D_COUNT="${2:?--count needs a number}"; shift 2 ;;
    --names)    D_NAMES="${2:?--names needs a,b,c}"; shift 2 ;;
    --ram)      D_RAM="${2:?--ram needs GB, e.g. 4}"; shift 2 ;;
    --cpus)     D_CPUS="${2:?--cpus needs a number}"; shift 2 ;;
    --disk)     D_DISK="${2:?--disk needs a size}"; shift 2 ;;
    --flavour|--flavor) D_FLAVOUR="${2:?--flavour needs desktop or server}"; shift 2 ;;
    --provider) D_PROVIDER="${2:?--provider needs a name}"; shift 2 ;;
    --subnet)   D_SUBNET="${2:?--subnet needs a.b.c}"; shift 2 ;;
    --box)      D_BOX="${2:?--box needs a name}"; shift 2 ;;
    --user)     D_USER="${2:?--user needs a name}"; shift 2 ;;
    --password) D_PASS="${2:?--password needs a value}"; shift 2 ;;
    --no-demo)  D_DEMO=0; shift ;;
    --no-up)    FORCE_NO_UP=1; shift ;;
    --up)       FORCE_UP=1; shift ;;
    --local)    D_LOCAL=1; shift ;;
    -y|--yes)   ASSUME_YES=1; shift ;;
    -h|--help)  usage ;;
    *)          die "unknown flag: $1   (try --help)" ;;
  esac
done
[ "$FORCE_UP" -eq 1 ] && [ "$FORCE_NO_UP" -eq 1 ] && die "--up and --no-up contradict each other"

# ---- never as root -----------------------------------------------------------
# Vagrant keeps boxes, plugins and the VMware licence per user. Run as root and
# the boxes land in root's ~/.vagrant.d, the VM files end up owned by root, and
# your own "vagrant up" later cannot touch them. There is nothing here that
# needs root, so refuse it rather than make a mess that is painful to undo.
if [ "$(id -u 2>/dev/null || echo 1000)" = "0" ] && [ "${LAB_ALLOW_ROOT:-0}" != "1" ]; then
  die "do not run this as root or with sudo - Vagrant must run as your own user.
      Use:  curl -fsSL <url>/install_lab.sh | bash
      (set LAB_ALLOW_ROOT=1 if you really do run Vagrant as root)"
fi

# ---- helpers used before the questions are asked ---------------------------
# Defined up here because the "this PC:" line below already needs mb_to_gb.

# RAM is asked for in GB because that is how people think about it: nobody
# wants to work out that "2 GB" is 2048. Accepts 4, 4GB, 4gb or 512MB, and
# always returns whole MB, which is what lab.yml and Vagrant want.
to_mb() { # to_mb VALUE
  local v="$1" n u
  n="$(printf '%s' "$v" | tr -cd '0-9.')"
  u="$(printf '%s' "$v" | tr -cd 'A-Za-z' | tr 'a-z' 'A-Z')"
  case "$n" in
    ''|.|*.*.*|*[!0-9.]*) die "RAM should look like 4, 4GB or 512MB - got '$v'" ;;
  esac
  case "$u" in
    ''|G|GB) awk -v n="$n" 'BEGIN{printf "%d", n*1024}' ;;
    M|MB)    awk -v n="$n" 'BEGIN{printf "%d", n}' ;;
    T|TB)    awk -v n="$n" 'BEGIN{printf "%d", n*1024*1024}' ;;
    *)       die "RAM unit must be GB, MB or TB - got '$v'" ;;
  esac
}

# 31801 -> "31.1 GB" ; 2048 -> "2 GB"
mb_to_gb() {
  awk -v m="${1:-0}" 'BEGIN{
    if      (m >= 1048576 && m % 1048576 == 0) printf "%d TB", m/1048576
    else if (m >= 1048576)                      printf "%.1f TB", m/1048576
    else if (m % 1024 == 0)                      printf "%d GB", m/1024
    else                                        printf "%.1f GB", m/1024
  }'
}

# ---- host capacity ----------------------------------------------------------
# 0 means "could not detect" - the warning is then skipped rather than guessed.
detect_host() {
  local os ram_bytes
  os="$(uname -s 2>/dev/null || echo unknown)"

  # WSL reports itself as Linux, so uname alone would compare the lab's RAM
  # against the WSL VM's RAM rather than the real host's. Ask Windows directly
  # when we can, and say which numbers we ended up with.
  if [ "$os" = "Linux" ] && grep -qi microsoft /proc/version 2>/dev/null; then
    HOST_PLATFORM="wsl"
    if command -v powershell.exe >/dev/null 2>&1; then
      ram_bytes="$(powershell.exe -NoProfile -Command '(Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory' 2>/dev/null | tr -d '\r[:space:]')"
      case "$ram_bytes" in ''|*[!0-9]*) ram_bytes=0 ;; esac
      HOST_RAM_MB=$(( ram_bytes / 1024 / 1024 ))
    else
      HOST_RAM_MB=0
    fi
    if [ "$HOST_RAM_MB" -eq 0 ]; then
      # no powershell.exe: fall back, but this is the WSL VM's memory only
      ram_bytes="$(awk '/MemTotal/{print $2 * 1024}' /proc/meminfo 2>/dev/null || echo 0)"
      HOST_RAM_MB=$(( ram_bytes / 1024 / 1024 ))
      HOST_RAM_IS_VM=1
    fi
    HOST_CPUS="$(nproc 2>/dev/null || echo 0)"
  else
    case "$os" in
      Darwin)
        HOST_PLATFORM="macos"
        ram_bytes="$(sysctl -n hw.memsize 2>/dev/null || echo 0)"
        HOST_RAM_MB=$(( ram_bytes / 1024 / 1024 ))
        HOST_CPUS="$(sysctl -n hw.ncpu 2>/dev/null || echo 0)"
        ;;
      Linux)
        HOST_PLATFORM="linux"
        ram_bytes="$(awk '/MemTotal/{print $2 * 1024}' /proc/meminfo 2>/dev/null || echo 0)"
        HOST_RAM_MB=$(( ram_bytes / 1024 / 1024 ))
        HOST_CPUS="$(nproc 2>/dev/null || echo 0)"
        ;;
      *)
        HOST_PLATFORM="windows"
        if command -v powershell >/dev/null 2>&1; then
          ram_bytes="$(powershell -NoProfile -Command '(Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory' 2>/dev/null | tr -d '\r[:space:]')"
          case "$ram_bytes" in ''|*[!0-9]*) ram_bytes=0 ;; esac
          HOST_RAM_MB=$(( ram_bytes / 1024 / 1024 ))
        else
          HOST_RAM_MB=0
        fi
        HOST_CPUS="$(printf '%s' "${NUMBER_OF_PROCESSORS:-0}")"
        ;;
    esac
  fi

  case "$HOST_RAM_MB" in ''|*[!0-9]*) HOST_RAM_MB=0 ;; esac
  case "$HOST_CPUS"     in ''|*[!0-9]*) HOST_CPUS=0 ;; esac
  measure_disk
}

# Measure the drive the project will actually land on, not wherever the script
# happened to be invoked from: --dir D:/labs must check D:, not C:.
measure_disk() {
  local probe="${1:-$DIR}"
  [ -n "$probe" ] || probe="."
  while [ ! -d "$probe" ] && [ -n "$probe" ] && [ "$probe" != "/" ] && [ "$probe" != "." ]; do
    probe="$(dirname "$probe")"
  done
  FREE_DISK_MB="$(df -Pm "$probe" 2>/dev/null | awk 'NR==2{print $4}')"
  case "$FREE_DISK_MB" in ''|*[!0-9]*) FREE_DISK_MB=0 ;; esac
  FREE_DISK_WHERE="$probe"
}

# "2048,4096,4096" or "4096" -> one default per VM, space separated
expand_list() { # expand_list VALUE COUNT
  local v="$1" n="$2" c out="" i
  c="$(printf '%s' "$v" | tr ',' '\n' | grep -c . || true)"
  if [ "$c" = "1" ]; then
    i=1; while [ "$i" -le "$n" ]; do out="$out${out:+ }$v"; i=$(( i + 1 )); done
  else
    [ "$c" = "$n" ] || die "\"$v\" gives $c value(s) but there are $n VMs - give one, or one per VM"
    out="$(printf '%s' "$v" | tr ',' ' ')"
  fi
  printf '%s' "$out"
}

# ---- prerequisites ----------------------------------------------------------
say "checking prerequisites"

DIR="$D_DIR"
detect_host
if [ "$HOST_RAM_MB" -gt 0 ]; then
  ok "this PC: $(mb_to_gb "$HOST_RAM_MB") RAM, ${HOST_CPUS} CPU cores, $(mb_to_gb "$FREE_DISK_MB") free disk on ${FREE_DISK_WHERE}"
fi

case "${HOST_PLATFORM:-unknown}" in
  wsl)
    warn "running under WSL."
    warn "Vagrant must be installed INSIDE WSL, not only on Windows, or it will not be found here."
    if [ "${HOST_RAM_IS_VM:-0}" = "1" ]; then
      warn "could not reach Windows for the real RAM - the figure above is the WSL VM's, not the PC's."
    fi
    ;;
  windows)
    ok "running under Git Bash / MSYS on Windows"
    ;;
esac

command -v vagrant >/dev/null 2>&1 || {
  printf '\n%sVagrant is not installed.%s\n\n' "$R" "$N" >&2
  cat >&2 <<'EOF'
  Install it, then re-run this script:

    Windows : https://developer.hashicorp.com/vagrant/downloads
    macOS   : brew install --cask vagrant
    Debian  : https://developer.hashicorp.com/vagrant/install#linux
    Fedora  : sudo dnf install -y vagrant

  You also need a hypervisor:
    vmware_desktop (default) : VMware Workstation Pro or Fusion Pro
                               + the Vagrant VMware Utility
    virtualbox               : https://www.virtualbox.org
EOF
  exit 1
}
ok "vagrant $(vagrant --version 2>/dev/null | head -1)"

case "$D_PROVIDER" in
  vmware_desktop)
    # Capture first: "vagrant plugin list | grep -q" can report failure under
    # pipefail when grep exits early and vagrant gets SIGPIPE.
    PLUGINS="$(vagrant plugin list 2>/dev/null || true)"
    if printf '%s\n' "$PLUGINS" | grep -q vagrant-vmware-desktop; then
      ok "vagrant-vmware-desktop plugin installed"
    else
      warn "vagrant-vmware-desktop plugin is missing."
      warn "install it with:  vagrant plugin install vagrant-vmware-desktop"
      warn "(the Vagrantfile will refuse to build until you do)"
    fi
    # The plugin talks to a separate background service. Without it every
    # command fails with "Failed to connect to the Vagrant VMware Utility".
    UTIL_STATE="unknown"
    case "${HOST_PLATFORM:-}" in
      windows)
        if command -v sc.exe >/dev/null 2>&1; then
          # On Windows the service is named VagrantVMware (its display name is
          # vagrant-vmware-utility, which sc.exe query does not accept).
          SC_OUT="$(sc.exe query VagrantVMware 2>/dev/null || true)"
          if printf '%s\n' "$SC_OUT" | grep -q RUNNING; then UTIL_STATE=ok; else UTIL_STATE=missing; fi
        fi ;;
      linux)
        if command -v systemctl >/dev/null 2>&1; then
          if systemctl is-active --quiet vagrant-vmware-utility 2>/dev/null; then UTIL_STATE=ok; else UTIL_STATE=missing; fi
        fi ;;
      macos)
        if [ -d /opt/vagrant-vmware-desktop ]; then UTIL_STATE=ok; else UTIL_STATE=missing; fi ;;
    esac
    case "$UTIL_STATE" in
      ok)      ok "Vagrant VMware Utility service found" ;;
      missing) warn "the Vagrant VMware Utility service does not seem to be running."
               warn "install it from https://developer.hashicorp.com/vagrant/install/vmware" ;;
    esac
    ;;
  virtualbox|hyperv) ok "provider: $D_PROVIDER (built into Vagrant)" ;;
  *) die "unknown provider '$D_PROVIDER' - use vmware_desktop, virtualbox or hyperv" ;;
esac

case "$D_FLAVOUR" in
  desktop|server) : ;;
  *) die "--flavour must be desktop or server" ;;
esac

# ---- validation helpers -----------------------------------------------------
is_uint()   { case "$1" in ''|*[!0-9]*) return 1 ;; *) return 0 ;; esac; }
check_disk() { # check_disk VALUE - validates only, sets DISK_ERR on failure
  local n u mb
  DISK_ERR=""
  n="$(printf '%s' "$1" | tr -cd '0-9.')"
  # Vagrant's disk size must be a whole number: "1.5GB" is rejected by the
  # provider with "is not an integer", so refuse it here rather than writing a
  # lab.yml that will not validate.
  case "$n" in
    ''|.*|*.*|*.*.*|*[!0-9.]*) DISK_ERR="a disk has to be a whole number like 20, 20GB or 1TB"; return 1 ;;
  esac
  u="$(printf '%s' "$1" | tr -cd 'A-Za-z' | tr 'a-z' 'A-Z')"
  # 10# forces decimal, so a leading zero is not read as octal ("064").
  case "$u" in
    T|TB)    mb=$(( 10#$n * 1048576 )) ;;
    ''|G|GB) mb=$(( 10#$n * 1024 )) ;;
    *)       DISK_ERR="a disk unit has to be GB or TB - got '$1'"; return 1 ;;
  esac
  [ "$mb" -gt 0 ] || { DISK_ERR="a disk of 0 does not exist - give it some gigabytes"; return 1; }
  return 0
}
# Disk follows the same rule as RAM: a bare number means GB. Typing "25" and
# being told off for a missing unit is needless friction.
# Vagrant's disk size must carry a unit, so a bare number has to gain one.
disk_norm() { # disk_norm VALUE
  local d="$1" n u
  n="$(printf '%s' "$d" | tr -cd '0-9.')"
  u="$(printf '%s' "$d" | tr -cd 'A-Za-z' | tr 'a-z' 'A-Z')"
  case "$n" in
    ''|.*|*.*|*.*.*|*[!0-9.]*) die "disk should be a whole number like 25, 25GB or 2TB - got '$d'" ;;
  esac
  case "$u" in
    ''|G|GB) printf '%sGB' "$((10#$n))" ;;
    T|TB)    printf '%sTB' "$((10#$n))" ;;
    *)       die "disk unit must be GB or TB - got '$d'" ;;
  esac
}
# Three octets, each 0-255: the VMs get .11, .12, ... on top of it.
check_subnet() {
  local s="$1" o
  case "$s" in
    *[!0-9.]*|.*|*.|*..*) die "subnet must look like 192.168.56 - got '$s'" ;;
  esac
  [ "$(printf '%s' "$s" | tr -cd '.' | wc -c | tr -d ' ')" = "2" ] \
    || die "subnet is the first three parts only, like 192.168.56 - got '$s'"
  for o in $(printf '%s' "$s" | tr '.' ' '); do
    [ "$((10#$o))" -le 255 ] || die "subnet part '$o' is over 255"
  done
}
# A VM name becomes a hostname, a Vagrant machine name and a YAML value, so it
# has to be a valid hostname label: letters, digits and dashes, no leading or
# trailing dash, at most 63 characters.
is_vm_name() {
  case "$1" in
    ''|-*|*-|*[!A-Za-z0-9-]*) return 1 ;;
  esac
  [ "${#1}" -le 63 ]
}
is_login() {
  case "$1" in
    ''|[0-9-]*|*[!A-Za-z0-9_-]*) return 1 ;;
  esac
  [ "${#1}" -le 32 ]
}
# Letters and digits only, so it survives YAML, chpasswd and any shell quoting.
# Under pipefail tr is killed by SIGPIPE once head has enough, hence "|| true".
gen_password() {
  local p
  p="$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom 2>/dev/null | head -c 16 || true)"
  [ "${#p}" -eq 16 ] || p="lab$(date +%s)$$"
  printf '%s' "$p"
}

is_uint "$D_COUNT" || die "--count must be a whole number"
[ "$D_COUNT" -ge 1 ] || die "--count must be at least 1"
check_subnet "$D_SUBNET"
is_login "$D_USER" || die "--user must be a login name: letters, digits, - and _, not starting with a digit"
case "$D_PASS" in *$'\n'*) die "--password cannot contain a newline" ;; esac
# --ram/--cpus/--disk accept one value for every VM, or one per VM comma-separated
for pair in "ram:$D_RAM" "cpus:$D_CPUS" "disk:$D_DISK"; do
  key="${pair%%:*}"; val="${pair#*:}"
  [ -n "$val" ] || continue
  for one in $(printf '%s' "$val" | tr ',' ' '); do
    case "$key" in
      ram)  to_mb "$one" >/dev/null ;;
      disk) check_disk "$one" || die "--disk $one: $DISK_ERR" ;;
      *)    is_uint "$one" || die "--$key values must be numbers, got '$one'" ;;
    esac
  done
done
if [ -n "$D_NAMES" ]; then
  case "$D_NAMES" in
    *[!A-Za-z0-9,-]*) die "--names: use letters, digits and - only, separated by commas (got '$D_NAMES')" ;;
  esac
  NAMES_COUNT="$(printf '%s' "$D_NAMES" | tr ',' '\n' | grep -c . || true)"
  [ "$NAMES_COUNT" -eq "$D_COUNT" ] || die "--names has $NAMES_COUNT names but --count is $D_COUNT"
  for one in $(printf '%s' "$D_NAMES" | tr ',' ' '); do
    is_vm_name "$one" || die "--names: '$one' is not a valid hostname (letters, digits and -)"
  done
fi

# ---- questions --------------------------------------------------------------
# Prompts read /dev/tty, not stdin: in "curl ... | bash" stdin is the pipe, so
# testing -t 0 would silently skip every question and leave bare defaults.
TTY=""
if [ "$ASSUME_YES" -eq 0 ] && { : </dev/tty >/dev/tty; } 2>/dev/null; then
  TTY="/dev/tty"
fi

# Windows terminals deliver CR as well as LF, and "read -r" strips only the
# newline. Left alone, every typed answer arrives as "3\r" and fails validation.
trim_cr() { printf '%s' "${1%$'\r'}"; }

ask() { # ask VAR "question" "default"
  local __var="$1" __q="$2" __d="$3" __ans=""
  if [ -n "$TTY" ]; then
    read -r -p "  ${__q} [${__d}]: " __ans < "$TTY" || __ans=""
    __ans="$(trim_cr "$__ans")"
  fi
  [ -z "$__ans" ] && __ans="$__d"
  printf -v "$__var" '%s' "$__ans"
}
ask_yn() { # ask_yn VAR "question" "default y|n" -> sets VAR to 1 or 0
  local __var="$1" __q="$2" __d="$3" __ans=""
  if [ -n "$TTY" ]; then
    read -r -p "  ${__q} [${__d}]: " __ans < "$TTY" || __ans=""
    __ans="$(trim_cr "$__ans")"
  fi
  [ -z "$__ans" ] && __ans="$__d"
  case "$(printf '%s' "$__ans" | tr 'A-Z' 'a-z')" in
    y|yes) printf -v "$__var" '%s' 1 ;;
    *)     printf -v "$__var" '%s' 0 ;;
  esac
}

ask DIR "Where should the project live?" "$D_DIR"
# "~/labs" typed at the prompt is not expanded by the shell, so do it here.
case "$DIR" in "~"|"~/"*) DIR="${HOME}${DIR#\~}" ;; esac
measure_disk "$DIR"   # now that we know the target drive, re-measure free space
if [ "$FREE_DISK_MB" -gt 0 ] && [ "${FREE_DISK_WHERE}" != "$DIR" ]; then
  ok "target drive ${FREE_DISK_WHERE}: $(mb_to_gb "$FREE_DISK_MB") free"
fi
# Checked now, before any questions, so nobody answers twenty prompts only to
# be told the folder was taken.
if [ -e "$DIR" ] && [ -n "$(ls -A "$DIR" 2>/dev/null)" ]; then
  die "$DIR already exists and is not empty. Pick another --dir, or empty it first."
fi

ask COUNT "How many VMs?" "$D_COUNT"
is_uint "$COUNT" || die "VM count must be a whole number"
[ "$COUNT" -ge 1 ] || die "VM count must be at least 1"
if [ -n "$D_NAMES" ] && [ "$COUNT" != "$D_COUNT" ]; then
  die "--names gives $D_COUNT names but you asked for $COUNT VMs"
fi

ask FLAVOUR "desktop or server?" "$D_FLAVOUR"
case "$FLAVOUR" in desktop|server) : ;; *) die "flavour must be desktop or server" ;; esac
# Both flavours use the same box: bento/ubuntu-24.04 is a server image that
# ships for every provider here. "desktop" means the Vagrantfile installs a GUI
# on top of it; "server" means it installs none. The box is decided only now,
# after the question, so answering "server" actually takes effect.
BOX="${D_BOX:-bento/ubuntu-24.04}"
if [ -z "$D_RAM" ]; then
  [ "$FLAVOUR" = "server" ] && D_RAM=2 || D_RAM=4
fi

# ---- names ------------------------------------------------------------------
RAM_DEF=$(expand_list "$D_RAM"  "$COUNT")
CPU_DEF=$(expand_list "$D_CPUS" "$COUNT")
DISK_DEF=$(expand_list "$D_DISK" "$COUNT")

nth() { printf '%s' "$1" | cut -d' ' -f"$2"; }

VM_NAMES=""
NAME_IT=0
if [ -z "$D_NAMES" ]; then
  ask_yn NAME_IT "Name the VMs yourself? (Enter keeps ubuntu-node-1..$COUNT)" "n"
fi
i=1
while [ "$i" -le "$COUNT" ]; do
  if [ -n "$D_NAMES" ]; then
    DEFAULT_NAME="$(printf '%s' "$D_NAMES" | cut -d, -f"$i")"
  else
    DEFAULT_NAME="ubuntu-node-$i"
  fi
  ENTRY="$DEFAULT_NAME"
  if [ "$NAME_IT" = "1" ] || [ -n "$D_NAMES" ]; then
    for try in 1 2 3; do
      ask ENTRY "  name for VM $i" "$DEFAULT_NAME"
      if ! is_vm_name "$ENTRY"; then
        printf '     (letters, digits and - only, not starting or ending with -)\n'
      elif printf ',%s,' "$VM_NAMES" | grep -qi ",$ENTRY,"; then
        printf '     (%s is already used by another VM)\n' "$ENTRY"
      else
        break
      fi
      [ "$try" = "3" ] && die "no valid name for VM $i"
    done
  fi
  VM_NAMES="$VM_NAMES${VM_NAMES:+,}$ENTRY"
  i=$(( i + 1 ))
done
say "VMs: $(printf '%s' "$VM_NAMES" | tr ',' ' ')"

# ---- resources, asked per VM ------------------------------------------------
RAM_LIST=""; CPU_LIST=""; DISK_LIST=""
i=1
while [ "$i" -le "$COUNT" ]; do
  ENTRY="$(printf '%s' "$VM_NAMES" | cut -d, -f"$i")"
  say "resources for $ENTRY"
  RAM_MB=""
  CPU_N=""
  DISK_N=""
  # Re-prompt rather than aborting: a typo, or a character mangled on the way
  # in from the terminal, should not throw away everything typed so far.
  for try in 1 2 3; do
    [ "$try" != "1" ] && printf '     (that value was not accepted, try again)\n'
    ask V_RAM "  RAM (GB) for $ENTRY" "$(nth "$RAM_DEF" "$i")"
    # In a subshell: to_mb calls die on bad input, which would otherwise exit
    # the whole script (silently, with stderr hidden) instead of re-prompting.
    if ( to_mb "$V_RAM" ) >/dev/null 2>&1; then
      RAM_MB="$(to_mb "$V_RAM")"
      break
    fi
    [ "$try" = "3" ] && die "RAM for $ENTRY: '$V_RAM' is not a size - try 4 or 4GB"
  done
  [ "$RAM_MB" -ge 512 ]    || die "RAM for $ENTRY must be at least 512 MB"
  [ "$RAM_MB" -le 1048576 ] || die "RAM for $ENTRY is $(mb_to_gb "$RAM_MB") - that looks like a mistake"
  for try in 1 2 3; do
    [ "$try" != "1" ] && printf '     (not a number, try again)\n'
    ask V_CPU "  vCPUs for $ENTRY" "$(nth "$CPU_DEF" "$i")"
    is_uint "$V_CPU" && [ "$V_CPU" -ge 1 ] && { CPU_N="$V_CPU"; break; }
    [ "$try" = "3" ] && die "vCPUs for $ENTRY: '$V_CPU' is not a number"
  done
  for try in 1 2 3; do
    [ "$try" != "1" ] && printf '     (%s)\n' "$DISK_ERR"
    ask V_DISK "  disk (GB) for $ENTRY" "$(nth "$DISK_DEF" "$i")"
    if check_disk "$V_DISK"; then
      DISK_N="$(disk_norm "$V_DISK")"
      break
    fi
    [ "$try" = "3" ] && die "disk for $ENTRY: '$V_DISK' is not a size - try 25 or 25GB"
  done
  RAM_LIST="$RAM_LIST${RAM_LIST:+,}$RAM_MB"
  CPU_LIST="$CPU_LIST${CPU_LIST:+,}$CPU_N"
  DISK_LIST="$DISK_LIST${DISK_LIST:+,}$DISK_N"
  i=$(( i + 1 ))
done

ask PROVIDER "Provider (vmware_desktop/virtualbox/hyperv)" "$D_PROVIDER"
case "$PROVIDER" in
  vmware_desktop|virtualbox|hyperv) : ;;
  *) die "unknown provider '$PROVIDER'" ;;
esac
ask SUBNET "Host-only subnet" "$D_SUBNET"
check_subnet "$SUBNET"
[ $(( 10 + COUNT )) -le 254 ] || die "$COUNT VMs do not fit in one subnet (addresses start at .11)"
ask_yn DEMO "Install the demo web page (proves the tunnel in a browser)?" \
  "$([ "$D_DEMO" = 1 ] && echo y || echo n)"

# ---- the login on every VM --------------------------------------------------
# A fixed, published password on a sudo account is a bad default once this
# script is public, so the default is a random one, printed at the end and
# kept in lab.yml.
for try in 1 2 3; do
  ask LAB_USER "Login to create on every VM" "$D_USER"
  is_login "$LAB_USER" && break
  printf '     (letters, digits, - and _, not starting with a digit or -)\n'
  [ "$try" = "3" ] && die "no valid login name"
done
LAB_PASS="$D_PASS"
PASS_GENERATED=0
if [ -z "$LAB_PASS" ] && [ -n "$TTY" ]; then
  read -r -s -p "  Password for $LAB_USER (Enter = generate a random one): " LAB_PASS < "$TTY" || LAB_PASS=""
  printf '\n'
  LAB_PASS="$(trim_cr "$LAB_PASS")"
fi
if [ -z "$LAB_PASS" ]; then
  LAB_PASS="$(gen_password)"
  PASS_GENERATED=1
fi

# ---- capacity check ---------------------------------------------------------
sum_csv() { printf '%s' "$1" | tr ',' '\n' | awk '{s+=$1} END{printf "%d", s+0}'; }

TOTAL_RAM=$(sum_csv "$RAM_LIST")
TOTAL_CPU=$(sum_csv "$CPU_LIST")
# Every data disk is created at exactly the size asked for, so this total is the
# storage the lab will actually have. The root disks are the box's own, sparse,
# and are not counted here.
# One awk for the whole sum: a bash while-read loop would run in a subshell and
# lose the total, and reassigning IFS to split a comma list is fragile.
TOTAL_DISK_MB=$(printf '%s\n' "$DISK_LIST" | tr ',' '\n' | awk '
  function mb(s,   n) {
    n = s; gsub(/[^0-9.]/, "", n)
    if (toupper(s) ~ /T/) return n * 1024 * 1024
    return n * 1024
  }
  { total += mb($0) }
  END { printf "%d", total + 0 }
')

say "summary"
printf '    %-16s %-6s %-6s %-8s\n' VM RAM vCPU disk
i=1
while [ "$i" -le "$COUNT" ]; do
  printf '    %-16s %-6s %-6s %-8s\n' \
    "$(printf '%s' "$VM_NAMES" | cut -d, -f"$i")" \
    "$(mb_to_gb "$(printf '%s' "$RAM_LIST" | cut -d, -f"$i")")" \
    "$(printf '%s' "$CPU_LIST"  | cut -d, -f"$i")" \
    "$(printf '%s' "$DISK_LIST" | cut -d, -f"$i")"
  i=$(( i + 1 ))
done
printf '    %-16s %-6s %-6s %-8s\n' "TOTAL" "$(mb_to_gb "$TOTAL_RAM")" "$TOTAL_CPU" "$(mb_to_gb "$TOTAL_DISK_MB")"
printf '    %s, %s, box %s\n' "$FLAVOUR" "$PROVIDER" "$BOX"
echo

OVER=0
if [ "$HOST_RAM_MB" -gt 0 ] && [ "$TOTAL_RAM" -ge "$HOST_RAM_MB" ]; then
  OVER=1
  printf '  %s%s RAM WILL NOT FIT%s\n' "$R" "$B" "$N" >&2
  printf '    you asked for %s across %s VMs, this PC has %s\n' \
    "$(mb_to_gb "$TOTAL_RAM")" "$COUNT" "$(mb_to_gb "$HOST_RAM_MB")" >&2
  printf '    the %s difference is what Windows/macOS and the hypervisor need\n' \
    "$(mb_to_gb "$(( TOTAL_RAM - HOST_RAM_MB ))")" >&2
  printf '    lower the per-VM RAM, use fewer VMs, or expect very slow swapping\n' >&2
fi
if [ "$HOST_CPUS" -gt 0 ] && [ "$TOTAL_CPU" -gt $(( HOST_CPUS * 2 )) ]; then
  printf '  %s!%s %s vCPU requested on %s cores - heavy overcommit\n' \
    "$Y" "$N" "$TOTAL_CPU" "$HOST_CPUS" >&2
  OVER=$(( OVER + 2 ))
fi
if [ "$FREE_DISK_MB" -gt 0 ] && [ "$TOTAL_DISK_MB" -ge "$FREE_DISK_MB" ]; then
  printf '  %s%s DISK MAY NOT FIT%s\n' "$R" "$B" "$N" >&2
  printf '    the data disks hold %s and only %s is free here.\n' \
    "$(mb_to_gb "$TOTAL_DISK_MB")" "$(mb_to_gb "$FREE_DISK_MB")" >&2
  printf '    they are sparse too, so a fresh lab uses a few hundred MB on each.\n' >&2
  printf '    this only bites once a VM has data on it.\n' >&2
  OVER=$(( OVER + 4 ))
fi
if [ "$OVER" -gt 0 ]; then
  printf '\n' >&2
  if [ -n "$TTY" ]; then
    read -r -p "  Continue anyway? [y/N]: " cont < "$TTY" || cont=""
    cont="$(trim_cr "$cont")"
    case "$(printf '%s' "$cont" | tr 'A-Z' 'a-z')" in
      y|yes) warn "continuing as asked" ;;
      *)     die "stopped. lower the RAM/disk, or re-run with different answers." ;;
    esac
  else
    # no terminal, so nothing can be asked: -y / CI means do not block, but say
    # it loudly rather than silently proceeding
    warn "no terminal to ask on, so continuing. Lower the values if this stalls."
  fi
fi

# ---- download ---------------------------------------------------------------
# --local: copy the project from disk instead of fetching it, so the lab can be
# tried before it is published. Looks next to this script first (a clone of the
# repo: install_lab.sh + vms-lab/), then in the current folder.
SRC_DIR=""
if [ "$D_LOCAL" -eq 1 ]; then
  SCRIPT_DIR=""
  case "${BASH_SOURCE[0]:-}" in
    */*) SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" ;;
    ?*)  SCRIPT_DIR="$(pwd)" ;;
  esac
  for cand in ${SCRIPT_DIR:+"$SCRIPT_DIR/$LAB_PATH" "$SCRIPT_DIR"} "./$LAB_PATH" "."; do
    if [ -f "$cand/Vagrantfile" ]; then SRC_DIR="$(cd "$cand" && pwd)"; break; fi
  done
  [ -n "$SRC_DIR" ] || die "--local was given but no Vagrantfile was found next to the script or in $(pwd)
      Run this from a clone of the repo, or drop --local to fetch it from $LAB_REPO."
  say "using the local project (--local): $SRC_DIR"
else
  command -v curl >/dev/null 2>&1 || die "curl is required to download the project"
fi

# Download into a temporary folder beside the target and move it into place
# only once every file has arrived. A dropped connection then leaves nothing
# behind, instead of a half-filled folder that blocks the next attempt.
PARENT="$(dirname "$DIR")"
mkdir -p "$PARENT"
STAGE="$(mktemp -d "$PARENT/.vms-lab-download.XXXXXX")"
trap 'rm -rf "$STAGE"' EXIT

say "downloading the project into $DIR"
get() { # get NAME -> STAGE/NAME, returns non-zero on a miss
  if [ -n "$SRC_DIR" ]; then
    [ -f "$SRC_DIR/$1" ] && cp "$SRC_DIR/$1" "$STAGE/$1"
  else
    curl -fsSL --retry 3 "${RAW_BASE}/$1" -o "$STAGE/$1"
  fi
}
fetch() { # required file
  if get "$1"; then
    ok "$1"
  else
    printf '\n  %sx%s could not get %s\n      from %s\n\n' "$R" "$N" "$1" "${SRC_DIR:-$RAW_BASE}" >&2
    printf '  Check that the file is published there, or point somewhere else:\n' >&2
    printf '      LAB_REPO=owner/repo  LAB_REF=main  LAB_PATH=vms-lab\n' >&2
    printf '      LAB_RAW_BASE=https://example.com/path/to/project\n' >&2
    printf '  or try a local clone:   bash install_lab.sh --local\n\n' >&2
    exit 1
  fi
}
fetch_optional() { # a miss here must NOT exit the script
  if get "$1" 2>/dev/null; then ok "$1 (optional)"; else rm -f "$STAGE/$1"; fi
  return 0
}

fetch Vagrantfile
fetch_optional README.md
fetch_optional lab.yml.example
# CRLF breaks every guest script in the Vagrantfile (and it refuses to load).
# A mirror or a git checkout with autocrlf can introduce it, so fix it here.
if grep -q $'\r' "$STAGE/Vagrantfile"; then
  tr -d '\r' < "$STAGE/Vagrantfile" > "$STAGE/Vagrantfile.lf" && mv "$STAGE/Vagrantfile.lf" "$STAGE/Vagrantfile"
  warn "the Vagrantfile had CRLF line endings - converted to LF"
fi
printf '%s\n' ".vagrant/" "*.log" ".DS_Store" "lab.yml" > "$STAGE/.gitignore"

# ---- write lab.yml ----------------------------------------------------------
say "writing lab.yml"
# YAML single quotes: the only character that needs escaping is ' itself.
yq() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }
{
  printf '# generated by install_lab.sh on %s\n' "$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo unknown)"
  printf '# edit this file to change the lab; vagrant provision applies it\n'
  printf '# it holds the VM password - keep it out of git (.gitignore does)\n\n'
  printf 'box: %s\n'                 "$(yq "$BOX")"
  printf 'provider: %s\n'            "$PROVIDER"
  printf 'subnet: "%s"\n'            "$SUBNET"
  printf 'desktop: %s\n'             "$([ "$FLAVOUR" = desktop ] && echo true || echo false)"
  printf 'gui: %s\n'                 "$([ "$FLAVOUR" = desktop ] && echo true || echo false)"
  printf 'no_sleep: true\n'
  printf 'check_host_power: true\n'
  printf 'new_user: %s\n'            "$(yq "$LAB_USER")"
  printf 'new_pass: %s\n'            "$(yq "$LAB_PASS")"
  printf 'demo: %s\n'                "$([ "$DEMO" = 1 ] && echo true || echo false)"
  printf 'web_port: 8080\n'
  printf 'tunnel_port: 18080\n'
  printf 'tunnel_target_port: null\n'
  printf '\nnodes:\n'
  i=1
  while [ "$i" -le "$COUNT" ]; do
    [ "$i" -eq 1 ] && role="primary" || role="peer"
    printf '  - name: %s\n'    "$(printf '%s' "$VM_NAMES" | cut -d, -f"$i")"
    printf '    role: %s\n'    "$role"
    printf '    ip: "%s.%s"\n' "$SUBNET" "$(( 10 + i ))"
    printf '    ram: %s\n'     "$(printf '%s' "$RAM_LIST"  | cut -d, -f"$i")"
    printf '    cpus: %s\n'    "$(printf '%s' "$CPU_LIST"  | cut -d, -f"$i")"
    printf '    disk: %s\n'    "$(printf '%s' "$DISK_LIST" | cut -d, -f"$i")"
    i=$(( i + 1 ))
  done
} > "$STAGE/lab.yml"
chmod 600 "$STAGE/lab.yml" 2>/dev/null || true
ok "lab.yml written"

# Move into place. rmdir first: the target may exist as an empty folder, and
# mv into an existing folder would nest the stage inside it.
[ -d "$DIR" ] && rmdir "$DIR"
mv "$STAGE" "$DIR"
trap - EXIT

# ---- verify -----------------------------------------------------------------
say "verifying the configuration"
cd "$DIR"
# Capture first, then test the captured status. "vagrant validate | sed" would
# report sed's status (always 0) and let a broken config through to vagrant up.
if VOUT="$(vagrant validate 2>&1)"; then
  printf '%s\n' "$VOUT" | sed 's/^/  /'
  ok "configuration is valid"
else
  printf '%s\n' "$VOUT" | sed 's/^/  /'
  die "the generated configuration did not validate - fix $DIR/lab.yml and re-run: vagrant validate"
fi

show_login() {
  if [ "$PASS_GENERATED" = "1" ]; then
    printf '  Login on every VM : %s / %s   (generated - also in lab.yml)\n' "$LAB_USER" "$LAB_PASS"
  else
    printf '  Login on every VM : %s   (password as given; also in lab.yml)\n' "$LAB_USER"
  fi
}

# ---- build ------------------------------------------------------------------
if [ "$FORCE_NO_UP" -eq 1 ]; then
  say "done. build later with:  cd $DIR && vagrant up"
  show_login
  exit 0
fi
if [ "$FORCE_UP" -eq 1 ]; then
  go="y"
elif [ -n "$TTY" ]; then
  read -r -p "  Build them now? [y/N]: " go < "$TTY" || go=""
  go="$(trim_cr "$go")"
else
  go="n"
fi
case "$(printf '%s' "$go" | tr 'A-Z' 'a-z')" in
  y|yes) : ;;
  *)
    say "done. build later with:  cd $DIR && vagrant up"
    [ -z "$TTY" ] && [ "$FORCE_UP" -eq 0 ] && warn "no terminal (or -y) and no --up, so nothing was built"
    show_login
    exit 0
    ;;
esac

say "building - about 8-10 min per VM"
if [ "$COUNT" -ge 3 ]; then
  warn "$COUNT VMs at once will strain the host; using --no-parallel"
  vagrant up --no-parallel
else
  vagrant up
fi

cat <<EOF

${G}Your lab is up.${N}

  cd $DIR
  vagrant status
  vagrant ssh $(printf '%s' "$VM_NAMES" | cut -d, -f1)
  vagrant provision              # apply lab.yml changes to running VMs
  vagrant destroy -f <name>      # remove one (destroy BEFORE editing lab.yml)

  Shared folder : ~/live_share  (NFS, from the primary)
  Tunnel        : 127.0.0.1:18080 on the first peer (+1 for each next peer)
EOF
show_login
}

main "$@"
