provider "ibm" {
  region          = "us-south"
  bluemix_api_key = "${var.bluemix_api_key}"
}
locals {
  prefix      = "pfqlamp03"
  simple_name = "${local.prefix}"
}

resource "ibm_is_vpc" "vpc" {
  name = "${local.simple_name}"
}

resource "ibm_is_subnet" "subnet" {
  name            = "${local.simple_name}"
  vpc             = "${ibm_is_vpc.vpc.id}"
  zone            = "${var.zone}"
  ipv4_cidr_block = "${var.ipv4_cidr_block}"
}

data "ibm_is_image" "os" {
  name = "${var.image_name}"
}

data "ibm_is_ssh_key" "sshkey" {
  name = "${var.ssh_key_name}"
}

resource "ibm_is_security_group" "sg" {
  name = "${local.simple_name}"
  vpc  = "${ibm_is_vpc.vpc.id}"
}

resource "ibm_is_security_group_rule" "egress" {
  group     = "${ibm_is_security_group.sg.id}"
  direction = "egress"
  remote    = "0.0.0.0/0"
}

resource "ibm_is_security_group_rule" "ssh" {
  group     = "${ibm_is_security_group.sg.id}"
  direction = "ingress"
  remote    = "0.0.0.0/0"

  tcp = {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "icmp" {
  group     = "${ibm_is_security_group.sg.id}"
  direction = "ingress"
  remote    = "0.0.0.0/0"

  icmp = {
    code = 0
    type = 8
  }
}

resource "ibm_is_security_group_rule" "http" {
  group     = "${ibm_is_security_group.sg.id}"
  direction = "ingress"
  remote    = "0.0.0.0/0"

  tcp = {
    port_min = 80
    port_max = 80
  }
}

resource "ibm_is_security_group_rule" "https" {
  group     = "${ibm_is_security_group.sg.id}"
  direction = "ingress"
  remote    = "0.0.0.0/0"

  tcp = {
    port_min = 443
    port_max = 443
  }
}

resource "ibm_is_instance" "instance" {
  name    = "${local.simple_name}"
  image   = "${data.ibm_is_image.os.id}"
  profile = "${var.profile}"

  primary_network_interface = {
    port_speed      = "1000"
    subnet          = "${ibm_is_subnet.subnet.id}"
    security_groups = ["${ibm_is_security_group.sg.id}"]
  }

  vpc       = "${ibm_is_vpc.vpc.id}"
  zone      = "${var.zone}"
  keys      = ["${data.ibm_is_ssh_key.sshkey.id}"]
  user_data = "${file("cloud-config.yaml")}"
}

resource "ibm_is_floating_ip" "floatingip" {
  name   = "${local.simple_name}"
  target = "${ibm_is_instance.instance.primary_network_interface.0.id}"

  connection {
    type        = "ssh"
    user        = "root"
    host        = "${ibm_is_floating_ip.floatingip.0.address}"
    private_key = "${file("~/.ssh/id_rsa")}"
  }

  provisioner "file" {
    source      = "bootstrapmin.sh"
    destination = "/bootstrapmin.sh"
  }
  provisioner "remote-exec" {
    inline      = [
      "bash -x /bootstrapmin.sh",
    ]
  }
}

locals {
  ip="${ibm_is_floating_ip.floatingip.address}"
}
# this is displayed after ever terraform apply, just copy/paste it
output "sshCommand" {
  value = "ssh root@${local.ip}"
}
output "ip" {
  value = "${local.ip}"
}

resource "ibm_is_instance" "private" {
  name    = "${local.simple_name}private"
  image   = "${data.ibm_is_image.os.id}"
  profile = "${var.profile}"

  primary_network_interface = {
    port_speed      = "1000"
    subnet          = "${ibm_is_subnet.subnet.id}"
    security_groups = ["${ibm_is_security_group.sg.id}"]
  }

  vpc       = "${ibm_is_vpc.vpc.id}"
  zone      = "${var.zone}"
  keys      = ["${data.ibm_is_ssh_key.sshkey.id}"]
  user_data = "${file("cloud-config.yaml")}"
}

output "private_ip" {
  value = "${ibm_is_instance.private.primary_network_interface.0.primary_ipv4_address}"
}
output "sshCommandprivate" {
  value = "ssh -J root@${local.ip} root@${ibm_is_instance.private.primary_network_interface.0.primary_ipv4_address}"
}