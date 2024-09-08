variable "vm_name" {
  default = "debian-11.0.0-amd64"
}

variable "numvcpus" {
  default = "1"
}

variable "memsize" {
  default = "1024"
}

variable "disk_size" {
  default = "40960"
}

variable "iso_url" {
   default  = "https://cdimage.debian.org/cdimage/archive/11.0.0/amd64/iso-cd/debian-11.0.0-amd64-netinst.iso"
}

variable "iso_checksum" {
  default = "ae6d563d2444665316901fe7091059ac34b8f67ba30f9159f7cef7d2fdc5bf8a"
}

variable "ssh_username" {
  default = "packer"
}

variable "ssh_password" {
  default = "packer"
}

variable "boot_wait" {
  default = "5s"
}

source "virtualbox-iso" "debian_virtualbox" {
  boot_command     = ["e<down><down><down><end>priority=critical auto=true preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg<leftCtrlOn>x<leftCtrlOff>"]
  boot_wait        = var.boot_wait
  disk_size        = var.disk_size
  headless         = false
  guest_os_type    = "Debian_64"
  http_directory   = "http"
  iso_checksum     = var.iso_checksum
  iso_url          = var.iso_url
  shutdown_command = "echo 'packer'|sudo -S shutdown -P now"
  ssh_password     = var.ssh_password
  ssh_port         = 22
  ssh_username     = var.ssh_username
  ssh_timeout      = "30m"
  vm_name          = var.vm_name
  iso_interface    = "sata"
  vboxmanage       = [
    ["modifyvm", "{{.Name}}", "--memory", var.memsize],
    ["modifyvm", "{{.Name}}", "--cpus", var.numvcpus],
    ["modifyvm", "{{.Name}}", "--firmware", "EFI"]
  ]
}

build {
  sources = ["source.virtualbox-iso.debian_virtualbox"]

  provisioner "shell" {
    execute_command = "echo 'packer'|{{.Vars}} sudo -S -E bash '{{.Path}}'"
    inline = [
      "apt -y update && apt -y upgrade",
      "apt -y install python3-pip",
      "pip3 --no-cache-dir install ansible"
    ]
  }

  provisioner "ansible-local" {
    playbook_file = "scripts/setup.yml"
  }

  provisioner "shell" {
    execute_command = "echo 'packer'|{{.Vars}} sudo -S -E bash '{{.Path}}'"
    scripts = ["scripts/cleanup.sh"]
  }
}
