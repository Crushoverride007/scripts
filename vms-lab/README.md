# VMs-Labs

One command to build Ubuntu 24.04 VMs with Vagrant: a whole networked lab, or a single clean VM.

Run these as **your normal user, not with `sudo`**. Vagrant stores boxes, plugins and the VMware licence per user, so running it as root leaves VMs your own account can't manage.

## Requirements

- [Vagrant](https://developer.hashicorp.com/vagrant/install)
- A hypervisor. The scripts pick the one your machine is set up for; `--provider` overrides that.

| Provider | Windows | Linux | macOS | Extra setup | Status |
|---|:---:|:---:|:---:|---|---|
| `vmware_desktop` | ✓ | ✓ | ✓ | `vagrant plugin install vagrant-vmware-desktop` + [Vagrant VMware Utility](https://developer.hashicorp.com/vagrant/install/vmware) | tested (Windows) |
| `virtualbox` | ✓ | ✓ | ✓ | none | untested |
| `libvirt` (KVM) | | ✓ | | libvirt + `vagrant plugin install vagrant-libvirt` (see below) | untested |
| `parallels` | | | ✓ | Parallels Desktop Pro/Business + `vagrant plugin install vagrant-parallels` | untested |
| `hyperv` | ✓ | | | Administrator shell | experimental: no fixed IPs, so the share and tunnel don't work |

  On Apple Silicon Macs, Vagrant downloads the ARM build of the Ubuntu box automatically.

  libvirt on Debian/Ubuntu:
  ```bash
  sudo apt-get install -y qemu-kvm libvirt-daemon-system libvirt-dev ebtables dnsmasq
  sudo usermod -aG libvirt "$USER"    # then log out and back in
  vagrant plugin install vagrant-libvirt
  ```
- Windows only: [Git for Windows](https://git-scm.com/download/win), which provides the bash the scripts run in. The Windows command offers to install it for you.

## A multi-VM lab

Every VM gets a host-only IP, a data disk at `/srv/labdata`, an NFS share (`~/live_share`) from the primary, and a self-healing SSH tunnel to the primary.

**Linux / macOS / WSL / Git Bash**

```bash
curl -fsSL https://raw.githubusercontent.com/Crushoverride007/scripts/main/install_lab.sh | bash
```

Unattended, with 3 headless servers:

```bash
curl -fsSL https://raw.githubusercontent.com/Crushoverride007/scripts/main/install_lab.sh | bash -s -- -y --count 3 --flavour server --up
```

**Windows** (works in cmd, PowerShell 5 or 7, and Windows Terminal)

```powershell
powershell -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/Crushoverride007/scripts/main/install_lab.ps1 | iex"
```

With flags, add them at the end, inside the quotes:

```powershell
powershell -ExecutionPolicy Bypass -c "& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Crushoverride007/scripts/main/install_lab.ps1))) -y --count 3 --flavour server --up"
```

If Git for Windows is missing, the script offers to install it with winget.

The script asks about each VM, warns if the total won't fit on your PC, writes `lab.yml`, validates it and builds. With `-y` or no terminal it asks nothing and only **prepares** the lab. Add `--up` to build as well. Run with `--help` to see every flag.

The login created on every VM gets a **random password** unless you pass `--password`. It is printed at the end and saved in `lab.yml`.

## One VM

```bash
curl -fsSL https://raw.githubusercontent.com/Crushoverride007/scripts/main/install_vm.sh | bash -s -- --server --name web1 --ram 2
curl -fsSL https://raw.githubusercontent.com/Crushoverride007/scripts/main/install_vm.sh | bash -s -- --desktop
```

```powershell
powershell -ExecutionPolicy Bypass -c "& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Crushoverride007/scripts/main/install_vm.ps1))) --server --name web1"
```

`--server` is the stock box with nothing added. `--desktop` adds the Ubuntu desktop packages and nothing else. You log in as `vagrant` / `vagrant`.

## Pinning a version

By default the scripts download from `main`. To make builds reproducible, pin a tag or commit:

```bash
curl -fsSL https://raw.githubusercontent.com/Crushoverride007/scripts/v1.0/install_lab.sh | LAB_REF=v1.0 bash
```

`LAB_REPO`, `LAB_REF`, `LAB_PATH` and `LAB_RAW_BASE` choose where the project files come from.

## Changing a lab

`lab.yml` is the only file you normally edit. The Vagrantfile is machinery.

| You want to | Do |
|---|---|
| apply edits to running VMs | `vagrant provision` (`vagrant up` does not re-provision) |
| add a node | add an entry under `nodes:`, then `vagrant up` |
| remove a node | `vagrant destroy -f <name>` **first**, then delete its entry. Delete the entry first and the VM is orphaned. |
| headless servers | `desktop: false` (no GUI packages, no auto-login) |
| no demo web page | `demo: false` (the tunnel still points at `tunnel_target_port`) |

### Disks

- **`disk:`** sets the size of a separate data disk, mounted at `/srv/labdata`. You get exactly the size you ask for.
- **Root disk:** the box's own 64 GB sparse disk, left as it is. A fresh VM uses about 7 GB of it. It can't be made smaller, because VMware can't shrink a cloned disk.

A `box fix:` message on the first run is expected. It patches a stray disk slot in the bento box that crashes `vagrant-vmware-desktop` 3.0.5 when a second disk is attached. The original file is kept as `<box>.vmx.pre-lab-disk-fix`.

## Security

- **Network:** no port forwards. The demo service binds to the host-only interface only.
- **sshd:**
  - public-key login only
  - `AllowUsers` limited to the lab user and `vagrant`
  - only `-L` forwards, and only to the single tunnel target
- **Private key:** one shared ed25519 keypair is generated on the host. It lives in `.vagrant/`, which is git-ignored, so never commit it.
- **NFS:** the share is exported to the lab subnet with `no_root_squash`. That's fine on an isolated host-only network, but don't reuse it on a shared one.

## Windows notes

- The `.ps1` launchers find Git Bash for you. Typing plain `bash` in cmd or PowerShell starts WSL instead.
- In a clone, `install_lab.cmd` and `install_vm.cmd` do the same job.
- Keep the Vagrantfile saved with LF line endings. `.gitattributes` makes sure it is. It refuses to run with CRLF.
