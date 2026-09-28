# scripts

My one-command installers and dotfiles.

```
docker/      install_docker.sh
python/      install_python.sh
terraform/   install_terraform.sh
user/        setup_user.sh
vagrant/     setup_vagrant, install_lab, install_vm (+ lab/ Vagrantfile)
alacritty/ coc/ fish/ git/ karabiner/ neofetch/ nvim/ zed/
visual_studio_code-settings/ shallow-backup.conf    dotfiles
```

## docker, terraform, python, user

These install system packages, so they run as root:

```bash
curl -fsSL https://raw.githubusercontent.com/Crushoverride007/scripts/main/docker/install_docker.sh | sudo bash
curl -fsSL https://raw.githubusercontent.com/Crushoverride007/scripts/main/terraform/install_terraform.sh | sudo bash
curl -fsSL https://raw.githubusercontent.com/Crushoverride007/scripts/main/python/install_python.sh | sudo bash
curl -fsSL https://raw.githubusercontent.com/Crushoverride007/scripts/main/user/setup_user.sh | sudo bash -s <username>
```

On macOS, run `install_python.sh` without `sudo`, because Homebrew refuses to run as root.

## vagrant/

Ubuntu 24.04 VMs with Vagrant. Run these as **your normal user, not with sudo**; see [vagrant/README.md](vagrant/README.md) for details.

| Step | macOS / Linux | Windows (cmd or PowerShell) |
|---|---|---|
| **Set up a machine** (once) | `curl -fsSL https://raw.githubusercontent.com/Crushoverride007/scripts/main/vagrant/setup_vagrant.sh \| bash` | `powershell -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/Crushoverride007/scripts/main/vagrant/setup_vagrant.ps1 \| iex"` |
| **Build a lab** | `curl -fsSL https://raw.githubusercontent.com/Crushoverride007/scripts/main/vagrant/install_lab.sh \| bash` | `powershell -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/Crushoverride007/scripts/main/vagrant/install_lab.ps1 \| iex"` |
| **Build one VM** | `curl -fsSL https://raw.githubusercontent.com/Crushoverride007/scripts/main/vagrant/install_vm.sh \| bash -s -- --server` | `powershell -ExecutionPolicy Bypass -c "& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Crushoverride007/scripts/main/vagrant/install_vm.ps1))) --server"` |
