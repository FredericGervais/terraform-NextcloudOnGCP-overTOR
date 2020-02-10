


resource "null_resource" "get_eschalot" {

  provisioner "local-exec" {
    command = "git clone https://github.com/ReclaimYourPrivacy/eschalot.git"
  }
}

resource "null_resource" "make_eschalot" {
    depends_on = [null_resource.get_eschalot]

  provisioner "local-exec" {
    command = "make -C ./eschalot"
  }
}

data "external" "get_onion_address" {
    depends_on = [null_resource.make_eschalot]

    program = ["bash", "generate.sh", "generate_private_key", "${var.onion-address}"]
}




