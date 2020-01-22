


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

resource "null_resource" "modify_generate_script" {
    depends_on = [null_resource.make_eschalot]

  provisioner "local-exec" {
    command = "sed -i 's/STRING/${var.onion-address}/g' generate.sh"
  }
}

data "external" "get_onion_address" {
    depends_on = [null_resource.modify_generate_script]

    program = ["bash", "generate.sh"]
}




