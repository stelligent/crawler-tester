resource "aws_instance" "example" {
  ami           = "ami-0ce2d536d6a5675cf"
  instance_type = "t2.micro"
  key_name      = "alight-demo"
  subnet_id     = "subnet-d4dff1f5"

  # Reference the new security group
  vpc_security_group_ids = [aws_security_group.alight_demo.id]

  # IAM role to allow EC2 to send logs to CloudWatch
  iam_instance_profile = aws_iam_instance_profile.ec2_cloudwatch_profile.name

  tags = {
    Name = "AlghtDemo",
    RDS = aws_db_instance.example.id
  }
  user_data = <<-EOF
          #cloud-config
          bootcmd:
            - cd /home/ec2-user/src
            - nohup node app.js > /dev/null 2>&1 &
          EOF
}
resource "aws_security_group" "alight_demo" {
  name        = "alight-demo"
  description = "Security group for alight-demo"

  # Example ingress rule: allowing TCP traffic on port 22 (SSH)
  # Modify as per your requirements
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Caution: This allows SSH from any IP. Narrow this down for production.
  }

  # Default egress: Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alight-demo"
  }
}

resource "aws_iam_role" "ec2_cloudwatch_role" {
  name = "ec2_cloudwatch_role_alight_demo"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
      },
    ],
  })
}

resource "aws_iam_role_policy" "ec2_cloudwatch_policy" {
  name = "ec2_cloudwatch_policy"
  role = aws_iam_role.ec2_cloudwatch_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ],
        Effect = "Allow",
        Resource = "*",
      },
    ],
  })
}


resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_cloudwatch_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy" "ssm_runas_policy" {
  name        = "SSMRunAsPolicy"
  description = "Policy to allow RunAs during SSM sessions"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:UpdateInstanceInformation",
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "iam:CreateServiceLinkedRole",
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "iam:AWSServiceName": "ssm.amazonaws.com"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ssm_runas_policy_attachment" {
  policy_arn = aws_iam_policy.ssm_runas_policy.arn
  role       = aws_iam_role.ec2_cloudwatch_role.id
}

resource "aws_iam_role_policy_attachment" "rds_read_only" {
  role       = aws_iam_role.ec2_cloudwatch_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSReadOnlyAccess"
}

resource "aws_iam_instance_profile" "ec2_cloudwatch_profile" {
  name = "ec2_cloudwatch_profile_alight_demo"
  role = aws_iam_role.ec2_cloudwatch_role.name
}
