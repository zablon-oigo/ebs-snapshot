provider "aws" {
  region     = "${var.region}"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
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
  role             = "${var.lambda_role}"
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

# SNS topic 
		

resource "aws_sns_topic" "topic" {
  name = "note"
  lambda_success_feedback_sample_rate = "100"           
  lambda_success_feedback_role_arn = "${var.feedback_role_arn}"          
  lambda_failure_feedback_role_arn  ="${var.feedback_role_arn}"  
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
  ami             = "${var.ami}"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.ec2-sg.name]

  tags = {
    Name = "WebServer"
  }
}

# CloudWatch Event Rule
resource "aws_cloudwatch_event_rule" "event" {
  name        = "t3st"
  schedule_expression = "rate(1 hour)"
  event_pattern = <<EOF
    {
  "source": [
    "aws.ec2"
  ],
  "detail-type": [
    "EC2 Instance State-change Notification"
  ],
  "detail": {
    "state": [
      "stopped"
    ],
    "instance-id": [
      "${aws_instance.ec2.id}"
      ]
  }
}
EOF
}		

# SNS Destination to Lambda Function
resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.event.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.topic.arn
}

resource "aws_lambda_function_event_invoke_config" "sns" {
  function_name = aws_lambda_function.lambda.function_name
  destination_config {
    on_failure {
      destination = aws_sns_topic.topic.arn
    }
    on_success {
      destination = aws_sns_topic.topic.arn
    }
  }
}


# Cloudwatch Event Target to Lambda Function
resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.event.name
  target_id = "SendToLambda"
  arn       = aws_lambda_function.lambda.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.event.arn
}			
