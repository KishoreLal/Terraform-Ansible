resource "aws_key_pair" "sample"{
    key_name = "terraform_key"
    public_key = file("/root/.ssh/id_rsa.pub")
}
 
resource "aws_instance" "jenkins"{
    ami = var.aws_amis[var.aws_region]
    instance_type = "t2.micro"
    key_name = "terraform_key"
    iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
    vpc_security_group_ids = [aws_security_group.web_ssh.id]
    subnet_id = aws_subnet.public_subnet.id 
    //associate_public_ip_address = true 
    tags = {
        Name = "Jenkins Server"
    }
    /*connection {
        type = "ssh"
        user = "ec2-user"
	private_key = file("/root/.ssh/id_rsa")
        password = ""
        host = self.public_ip
    } 
    provisioner "remote-exec" {
        inline = [
        "sudo yum install httpd -y",
        "sudo service httpd start",
        "cd /var/www/html",
        "echo 'Hello Welcome' >> index.html",
        ]
    }*/
}

resource "aws_instance" "web_server"{
    ami = var.aws_amis[var.aws_region]
    instance_type = "t2.micro"
    key_name = "terraform_key"
    iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
    vpc_security_group_ids = [aws_security_group.web_ssh.id]
    subnet_id = aws_subnet.public_subnet.id 
    //associate_public_ip_address = true 
    tags = {
        Name = "Web Server"
    }
}

resource "aws_iam_role" "ec2_role" {
    name = "ec2_role"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
tags = {
      Name = "ec2_role"
  }
}
resource "aws_iam_instance_profile" "ec2_profile" {
    name = "ec2_profile"
    role = aws_iam_role.ec2_role.name
}
resource "aws_iam_role_policy" "s3_backend_policy"{
    name = "s3_backend_policy"
    role = aws_iam_role.ec2_role.name
    policy = file("./s3_backend_policy.json")
}

resource "aws_security_group" "web_ssh"{
    name = "TCP SSH Security Group"
    description = "Allow SSH Access to the instance"
    vpc_id = aws_vpc.main_vpc.id 
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["106.198.40.115/32"]
    }
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["106.198.40.115/32"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "Web-SSh Security Group"
    }
}

resource "aws_vpc" "main_vpc"{
     cidr_block = "10.0.0.0/16"
     tags = {
         Name = "Terraform VPC"
     }
 }
 resource "aws_internet_gateway" "main_gw"{
     vpc_id = aws_vpc.main_vpc.id
     tags = {
         Name = "Main IG"
     }
 }
 resource "aws_subnet" "public_subnet"{
     vpc_id = aws_vpc.main_vpc.id 
     cidr_block = "10.0.0.0/24"
     map_public_ip_on_launch = "true"
     tags = {
         Name = "Public Subnet"
     }
 }
 resource "aws_subnet" "private_subnet"{
     vpc_id = aws_vpc.main_vpc.id 
     cidr_block = "10.0.1.0/24"
     tags = {
         Name = "Private Subnet"
     }
 }
 resource "aws_route_table" "Main_route"{
     vpc_id = aws_vpc.main_vpc.id 
     route {
         cidr_block = "0.0.0.0/0"
         gateway_id = aws_internet_gateway.main_gw.id
     }
     tags = {
         Name = "Terraform_Route"
     }
 }
resource "aws_route_table_association" "rt_associate"{
    route_table_id = aws_route_table.Main_route.id
    subnet_id = aws_subnet.public_subnet.id
}
