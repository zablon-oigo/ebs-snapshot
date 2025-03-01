provider "aws" {
    region=""
    secret_key = ""
    access_key = ""
}

resource "aws_security_group" "ec2-sg"{
    name ="demo"
    description = "Security group to allow traffic to EC2"
    ingress {
        from_port = 22
        to_port = 22
        protocol="tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port=0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
resource "aws_instance" "ec2" {
    ami = ""
    instance_type = "t2.micro"
    security_groups = ["${aws_security_group.ec2-sg.name}"]
    tags={
        Name="WebServer"
    }
}