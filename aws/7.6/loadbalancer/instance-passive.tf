// FGTVM active instance

resource "aws_network_interface" "passiveeth0" {
  description = "passive-port1"
  subnet_id   = aws_subnet.publicsubnet.id
  private_ips = [var.passiveport1]
}

resource "aws_network_interface" "passiveeth1" {
  description       = "passive-port2"
  subnet_id         = aws_subnet.privatesubnet.id
  private_ips       = [var.passiveport2]
  source_dest_check = false
}

resource "aws_network_interface_sg_attachment" "passivepublicattachment" {
  depends_on           = [aws_network_interface.passiveeth0]
  security_group_id    = aws_security_group.public_allow.id
  network_interface_id = aws_network_interface.passiveeth0.id
}

resource "aws_network_interface_sg_attachment" "passiveinternalattachment" {
  depends_on           = [aws_network_interface.passiveeth1]
  security_group_id    = aws_security_group.allow_all.id
  network_interface_id = aws_network_interface.passiveeth1.id
}


resource "aws_instance" "fgtpassive" {
  depends_on = [aws_instance.fgtactive]
  //it will use region, architect, and license type to decide which ami to use for deployment
  ami               = var.fgtami[var.region][var.arch][var.license_type]
  instance_type     = var.size
  availability_zone = var.az
  key_name          = var.keyname
  user_data = templatefile("${var.bootstrap-passive}", {
    type          = "${var.license_type}"
    license_file  = "${var.license2}"
    format        = "${var.license_format}"
    port1_ip      = "${var.passiveport1}"
    port1_mask    = "${var.passiveport1mask}"
    port2_ip      = "${var.passiveport2}"
    port2_mask    = "${var.passiveport2mask}"
    active_peerip = "${var.activeport1}"
    defaultgwy    = "${var.passiveport1gateway}"
    adminsport    = "${var.adminsport}"
    presharekey   = "${var.presharekey}"

  })
  iam_instance_profile = var.iam

  root_block_device {
    volume_type = "gp2"
    volume_size = "2"
  }

  ebs_block_device {
    device_name = "/dev/sdb"
    volume_size = "30"
    volume_type = "gp2"
  }

  network_interface {
    network_interface_id = aws_network_interface.passiveeth0.id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.passiveeth1.id
    device_index         = 1
  }

  tags = {
    Name = "FortiGateVM Passive"
  }
}