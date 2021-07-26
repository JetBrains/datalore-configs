resource "aws_iam_user" "datalore" {
  name = var.name_prefix

  tags = {
    CreatedBy = "Terraform",
  }
}

resource "aws_iam_access_key" "datalore" {
  user = aws_iam_user.datalore.name
}

resource "aws_iam_user_policy" "datalore" {
  name = var.name_prefix
  user = aws_iam_user.datalore.name

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::${aws_s3_bucket.blob-storage.bucket}",
                "arn:aws:s3:::${aws_s3_bucket.blob-storage.bucket}/*",
                "arn:aws:s3:::${aws_s3_bucket.envs.bucket}",
                "arn:aws:s3:::${aws_s3_bucket.envs.bucket}/*",
                "arn:aws:s3:::${aws_s3_bucket.publishing.bucket}",
                "arn:aws:s3:::${aws_s3_bucket.publishing.bucket}/*"
            ]
        },
        {
            "Action": [
                "iam:PassRole",
                "ec2:DescribeInstances",
                "ec2:DescribeInstanceTypes",
                "ec2:DescribeImages"
            ],
            "Effect": "Allow",
            "Resource": "*"
        },
        {
            "Action": [
                "ec2:RunInstances",
                "ec2:TerminateInstances",
                "ec2:CreateTags"
            ],
            "Effect": "Allow",
            "Resource": [
                "arn:aws:ec2:*:*:subnet/${aws_subnet.agents.id}",
                "arn:aws:ec2:*:*:network-interface/*",
                "arn:aws:ec2:*:*:instance/*",
                "arn:aws:ec2:*:*:volume/*",
                "arn:aws:ec2:*::image/ami-*",
                "arn:aws:ec2:*:*:key-pair/*",
                "arn:aws:ec2:*:*:security-group/*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role" "agent" {
  name = "${var.name_prefix}_agent"

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
}
resource "aws_iam_policy" "agent_ecr" {
  name = "${var.name_prefix}_agent_ecr"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ecr:GetAuthorizationToken"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage"
      ],
      "Effect": "Allow",
      "Resource": "${aws_ecr_repository.computation-agent.arn}"
    },
    {
      "Action": [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage"
      ],
      "Effect": "Allow",
      "Resource": "${aws_ecr_repository.computation-agent-gpu.arn}"
    }
  ]
}
EOF
}
resource "aws_iam_policy" "agent_s3" {
  name = "${var.name_prefix}_agent_s3"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:Get*",
        "s3:List*"
      ],
      "Resource": "${aws_s3_bucket.envs.arn}/*"
    }
  ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "agent_ecr" {
  role       = aws_iam_role.agent.name
  policy_arn = aws_iam_policy.agent_ecr.arn
}
resource "aws_iam_role_policy_attachment" "agent_s3" {
  role       = aws_iam_role.agent.name
  policy_arn = aws_iam_policy.agent_s3.arn
}
resource "aws_iam_instance_profile" "agent" {
  name = "${var.name_prefix}_agent"
  role = aws_iam_role.agent.name
}

resource "aws_iam_role" "datalore" {
  name = "${var.name_prefix}_datalore"

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
}
resource "aws_iam_policy" "datalore_ecr" {
  name = "${var.name_prefix}_datalore"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::${aws_s3_bucket.blob-storage.bucket}",
        "arn:aws:s3:::${aws_s3_bucket.blob-storage.bucket}/*",
        "arn:aws:s3:::${aws_s3_bucket.envs.bucket}",
        "arn:aws:s3:::${aws_s3_bucket.envs.bucket}/*",
        "arn:aws:s3:::${aws_s3_bucket.publishing.bucket}",
        "arn:aws:s3:::${aws_s3_bucket.publishing.bucket}/*"
      ]
    },
    {
      "Action": [
        "ecr:GetAuthorizationToken"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ],
      "Effect": "Allow",
      "Resource": "${aws_ecr_repository.computation-agent.arn}"
    },
    {
      "Action": [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ],
      "Effect": "Allow",
      "Resource": "${aws_ecr_repository.computation-agent-gpu.arn}"
    }
  ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "datalore_ecr" {
  role       = aws_iam_role.datalore.name
  policy_arn = aws_iam_policy.datalore_ecr.arn
}
resource "aws_iam_instance_profile" "datalore" {
  name = "${var.name_prefix}_datalore"
  role = aws_iam_role.datalore.name
}
