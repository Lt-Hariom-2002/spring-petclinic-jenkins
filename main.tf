provider "aws" {
  region     = "us-east-1"
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_SECRET_KEY
}

# ---------------------------
# 1️⃣ MySQL Server
# ---------------------------
resource "aws_instance" "mysql" {
  ami                    = "ami-0c02fb55956c7d316"  # Amazon Linux 2 (us-east-1)
  instance_type          = "t2.micro"
  key_name               = "hariom"                 # Your EC2 key pair name in AWS
  vpc_security_group_ids = [aws_security_group.mysql_sg.id]
  tags = {
    Name = "mysql-server"
  }
}

# ---------------------------
# 2️⃣ Maven/App Server
# ---------------------------
resource "aws_instance" "maven" {
  ami                    = "ami-0c02fb55956c7d316"
  instance_type          = "t2.micro"
  key_name               = "hariom"
  vpc_security_group_ids = [aws_security_group.maven_sg.id]
  tags = {
    Name = "maven-server"
  }
}

# ---------------------------
# 3️⃣ Security Groups
# ---------------------------

resource "aws_security_group" "mysql_sg" {
  name        = "mysql-sg"
  description = "Allow MySQL and SSH"

  ingress {
    description = "MySQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "maven_sg" {
  name        = "maven-sg"
  description = "Allow HTTP, SSH"

  ingress {
    description = "HTTP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------------------
# 4️⃣ Outputs
# ---------------------------

output "mysql_server_ip" {
  value = aws_instance.mysql.public_ip
}

output "maven_server_ip" {
  value = aws_instance.maven.public_ip
}

output "mysql_server_dns" {
  value = aws_instance.mysql.public_dns
}

output "maven_server_dns" {
  value = aws_instance.maven.public_dns
}

