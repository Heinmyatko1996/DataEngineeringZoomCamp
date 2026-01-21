terraform {
  required_providers {
    local = {
      source = "hashicorp/local"
    }
  }
}

resource "local_file" "hello" {
  content              = "hello world"
  filename             = "hello.txt"
  file_permission      = "0644"
  directory_permission = "0755"
}
