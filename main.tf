terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  zone = "ru-central1-a"
}

resource "yandex_compute_instance" "vm-ha" {
  name = "vm-ha"
  hostname = "vm-ha"
  resources {
    cores  = 2
    memory = 2
  }
  boot_disk {
    initialize_params {
      image_id = "fd80le4b8gt2u33lvubr"
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
	ip_address = "192.168.10.11"
    nat       = true
  }
  metadata = {
    ssh-keys = "centos:${file("~/.ssh/id_ed25519.pub")}"
  }
}

resource "yandex_compute_instance" "vm-backend1" {
  name = "vm-backend1"
  hostname = "vm-backend1"
  resources {
    cores  = 2
    memory = 2
  }
  boot_disk {
    initialize_params {
      image_id = "fd80le4b8gt2u33lvubr"
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
	ip_address = "192.168.10.12"
    nat       = true
  }
  metadata = {
    ssh-keys = "centos:${file("~/.ssh/id_ed25519.pub")}"
  }
}

resource "yandex_compute_instance" "vm-backend2" {
  name = "vm-backend2"
  hostname = "vm-backend2"
  resources {
    cores  = 2
    memory = 2
  }
  boot_disk {
    initialize_params {
      image_id = "fd80le4b8gt2u33lvubr"
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
	ip_address = "192.168.10.13"
    nat       = true
  }
  metadata = {
    ssh-keys = "centos:${file("~/.ssh/id_ed25519.pub")}"
  }
}

resource "yandex_compute_instance" "vm-backend3" {
  name = "vm-backend3"
  hostname = "vm-backend3"
  resources {
    cores  = 2
    memory = 2
  }
  boot_disk {
    initialize_params {
      image_id = "fd80le4b8gt2u33lvubr"
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
	ip_address = "192.168.10.14"
    nat       = true
  }
  metadata = {
    ssh-keys = "centos:${file("~/.ssh/id_ed25519.pub")}"
  }
}

resource "yandex_vpc_network" "network-1" {
  name = "network-1"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet-1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_compute_instance" "vm-ctrl" {
  name = "vm-ctrl"
  hostname="vm-ctrl"
  resources {
    cores  = 2
    memory = 2
  }
  connection {
      type = "ssh"
      host = yandex_compute_instance.vm-ctrl.network_interface.0.nat_ip_address
      private_key = "${file(var.ssh_key_private)}"
  }
  boot_disk {
    initialize_params {
      image_id = "fd80le4b8gt2u33lvubr"
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
	ip_address = "192.168.10.10"
    nat       = true
  }
  metadata = {
    ssh-keys = "centos:${file("~/.ssh/id_ed25519.pub")}"
  }
  provisioner "file" {
	source="scripts/vm-ctrl.sh"
	destination="/tmp/vm-ctrl.sh"
  }
  provisioner "remote-exec" {
	inline=[
	"chmod +x /tmp/vm-ctrl.sh",
	"sudo /tmp/vm-ctrl.sh"
	]
  }
  provisioner "file" {
    source="ansible/"
    destination="/tmp"
  }
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u user -i self.public_ip --private-key ${var.ssh_key_private} site.yml"
  }
}

output "internal_ip_address_vm_ctrl" {
  value = yandex_compute_instance.vm-ctrl.network_interface.0.ip_address
}

output "internal_ip_address_vm_ha" {
  value = yandex_compute_instance.vm-ha.network_interface.0.ip_address
}

output "internal_ip_address_vm_backend1" {
  value = yandex_compute_instance.vm-backend1.network_interface.0.ip_address
}

output "internal_ip_address_vm_backend2" {
  value = yandex_compute_instance.vm-backend2.network_interface.0.ip_address
}

output "internal_ip_address_vm_backend3" {
  value = yandex_compute_instance.vm-backend3.network_interface.0.ip_address
}

output "external_ip_address_vm_ctrl" {
  value = yandex_compute_instance.vm-ctrl.network_interface.0.nat_ip_address
}

output "external_ip_address_vm_ha" {
  value = yandex_compute_instance.vm-ha.network_interface.0.nat_ip_address
}

output "external_ip_address_vm_backend1" {
  value = yandex_compute_instance.vm-backend1.network_interface.0.nat_ip_address
}

output "external_ip_address_vm_backend2" {
  value = yandex_compute_instance.vm-backend2.network_interface.0.nat_ip_address
}

output "external_ip_address_vm_backend3" {
  value = yandex_compute_instance.vm-backend3.network_interface.0.nat_ip_address
}
