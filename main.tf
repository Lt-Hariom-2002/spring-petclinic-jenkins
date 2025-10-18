provider "aws" {
  region = "us-east-1"
}


resource "aws_instance" "mysql_server" {
  ami           = "ami-0341d95f75f311023"
  instance_type = "t3.micro"
  security_groups = ["launch-wizard-1"]  # Reference the existing security group
  key_name      = "hariom"
}

resource "aws_instance" "maven_server" {
  ami           = "ami-0341d95f75f311023"
  instance_type = "t3.micro"
  security_groups = ["launch-wizard-1"]  # Reference the existing security group
  key_name      = "hariom"
}






output "mysql_server_ip" {
  value = aws_instance.mysql.public_ip
}

output "maven_server_ip" {
  value = aws_instance.maven.public_ip
}



