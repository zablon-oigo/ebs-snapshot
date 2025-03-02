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

resource "aws_sns_topic" "topic" {
    name="note"
    lambda_failure_feedback_role_arn = ""
    lambda_success_feedback_role_arn = ""
    lambda_success_feedback_sample_rate = "100"
}
resource "aws_sns_topic_subscription" "subscription" {
    topic_arn=aws_sns_topic.topic.arn
    protocol = "lambda"
    endpoint=aws_lambda_function.lambda.arn
}
resource "aws_lambda_function" "lambda"{
    filename = "lambda_fucntion.zip"
    function_name="test"
    role=""
    handler="lambda_function.lambda_handler"
    runtime="python3.9"
    source_code_hash=filebase64("lambda_funtion.zip")   
}