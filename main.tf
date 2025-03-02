provider "aws" {
  region     = ""
  access_key = ""
  secret_key = ""
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

# Lambda function
resource "aws_lambda_function" "lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "test"
  role             = ""
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

# SNS topic 
resource "aws_sns_topic" "topic" {
  name = "note"
}

# SNS subscription for Lambda
resource "aws_sns_topic_subscription" "subscription" {
  topic_arn = aws_sns_topic.topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.lambda.arn
}

# EC2 security group for SSH access
resource "aws_security_group" "ec2-sg" {
  name        = "demo"
  description = "Security group to allow traffic to EC2"

  ingress {
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

# EC2 instance
resource "aws_instance" "ec2" {
  ami             = ""
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.ec2-sg.name]

  tags = {
    Name = "WebServer"
  }
}