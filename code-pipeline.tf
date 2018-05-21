resource "aws_s3_bucket" "tf_bucket" {
  bucket = "tf-code-pipeline-bucket"
  acl    = "private"
}

resource "aws_iam_role" "codepipeline_role" {
  name = "code-pipeline-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "codepipeline_policy"
  role = "${aws_iam_role.codepipeline_role.id}"

  policy = <<EOF
{
    "Statement": [
        {
            "Action": [
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:GetBucketVersioning"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "s3:PutObject"
            ],
            "Resource": [
                "arn:aws:s3:::codepipeline*",
                "arn:aws:s3:::elasticbeanstalk*"
            ],
            "Effect": "Allow"
        },
        {
            "Action": [
								"codecommit:BatchGet*",
                "codecommit:Get*",
                "codecommit:Describe*",
                "codecommit:List*",
                "codecommit:GitPull",
                "codecommit:CancelUploadArchive",
                "codecommit:UploadArchive"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "codedeploy:CreateDeployment",
                "codedeploy:GetApplicationRevision",
                "codedeploy:GetDeployment",
                "codedeploy:GetDeploymentConfig",
                "codedeploy:RegisterApplicationRevision"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "elasticbeanstalk:*",
                "ec2:*",
                "elasticloadbalancing:*",
                "autoscaling:*",
                "cloudwatch:*",
                "s3:*",
                "sns:*",
                "cloudformation:*",
                "rds:*",
                "sqs:*",
                "ecs:*",
                "iam:PassRole"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "lambda:InvokeFunction",
                "lambda:ListFunctions"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "opsworks:CreateDeployment",
                "opsworks:DescribeApps",
                "opsworks:DescribeCommands",
                "opsworks:DescribeDeployments",
                "opsworks:DescribeInstances",
                "opsworks:DescribeStacks",
                "opsworks:UpdateApp",
                "opsworks:UpdateStack"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "cloudformation:CreateStack",
                "cloudformation:DeleteStack",
                "cloudformation:DescribeStacks",
                "cloudformation:UpdateStack",
                "cloudformation:CreateChangeSet",
                "cloudformation:DeleteChangeSet",
                "cloudformation:DescribeChangeSet",
                "cloudformation:ExecuteChangeSet",
                "cloudformation:SetStackPolicy",
                "cloudformation:ValidateTemplate",
                "iam:PassRole"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "codebuild:BatchGetBuilds",
                "codebuild:StartBuild"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ],
    "Version": "2012-10-17"
}
EOF
}

resource "aws_iam_role" "cloudformation_role" {
  name = "cloudformation-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudformation.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "cloudformation_policy" {
  name = "codepipeline_policy"
  role = "${aws_iam_role.cloudformation_role.id}"

  policy = <<EOF
{
	"Statement": [
	  {
			"Action": [
				"s3:GetObject",
				"s3:GetObjectVersion",
				"s3:GetBucketVersioning"
			],
			"Resource": "*",
			"Effect": "Allow"
		},
		{
			"Action": [
				"s3:PutObject"
			],
			"Resource": [
				"arn:aws:s3:::codepipeline*"
			],
			"Effect": "Allow"
		},
		{
			"Action": [
				"lambda:*"
			],
			"Resource": [
				"arn:aws:lambda:${var.region}:${var.account_id}:function:*"
			],
			"Effect": "Allow"
		},
		{
			"Action": [
				"apigateway:*"
			],
			"Resource": [
				"arn:aws:apigateway:${var.region}::*"
			],
			"Effect": "Allow"
		},
		{
			"Action": [
				"iam:GetRole",
				"iam:CreateRole",
				"iam:DeleteRole",
				"iam:PutRolePolicy"
			],
			"Resource": [
				"arn:aws:iam::${var.account_id}:role/*"
			],
			"Effect": "Allow"
		},
		{
			"Action": [
				"iam:AttachRolePolicy",
				"iam:DeleteRolePolicy",
				"iam:DetachRolePolicy"
			],
			"Resource": [
				"arn:aws:iam::${var.account_id}:role/*"
			],
			"Effect": "Allow"
		},
		{
			"Action": [
				"iam:PassRole"
			],
			"Resource": [
				"*"
			],
			"Effect": "Allow"
		},
		{
			"Action": [
				"cloudformation:CreateChangeSet"
			],
			"Resource": [
				"arn:aws:cloudformation:${var.region}:aws:transform/Serverless-2016-10-31"
			],
			"Effect": "Allow"
		},
		{
			"Action": [
				"codedeploy:CreateApplication",
				"codedeploy:DeleteApplication",
				"codedeploy:RegisterApplicationRevision"
			],
			"Resource": [
				"arn:aws:codedeploy:${var.region}:${var.account_id}:application:*"
			],
			"Effect": "Allow"
		},
		{
			"Action": [
				"codedeploy:CreateDeploymentGroup",
				"codedeploy:CreateDeployment",
				"codedeploy:GetDeployment"
			],
			"Resource": [
				"arn:aws:codedeploy:${var.region}:${var.account_id}:deploymentgroup:*"
			],
			"Effect": "Allow"
		},
		{
			"Action": [
				"codedeploy:GetDeploymentConfig"
			],
			"Resource": [
				"arn:aws:codedeploy:${var.region}:${var.account_id}:deploymentconfig:*"
			],
			"Effect": "Allow"
		}
	],
	"Version": "2012-10-17"
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = "${aws_iam_role.cloudformation_role.id}"
  policy_arn = "arn:aws:iam::aws:policy/AWSLambdaExecute"
}

resource "aws_codepipeline" "tf_pipeline" {
  name     = "tf-pipeline"
  role_arn = "${aws_iam_role.codepipeline_role.arn}"

  artifact_store {
    location = "${aws_s3_bucket.tf_bucket.bucket}"
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["code"]

      configuration {
        RepositoryName = "${aws_codecommit_repository.code_repo.repository_name}"
        BranchName     = "master"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["code"]
      output_artifacts = ["build"]
      version          = "1"

      configuration {
        ProjectName = "${aws_codebuild_project.code_build.name}"
      }
    }
  }

  stage {
    name = "PrepareDeploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CloudFormation"
      input_artifacts = ["build"]
      version         = "1"

      configuration {
        ActionMode    = "CHANGE_SET_REPLACE"
        StackName     = "MyBetaStack"
        ChangeSetName = "MyChangeSet"
        TemplatePath  = "build::outputSamTemplate.yaml"
        Capabilities  = "CAPABILITY_IAM"
        RoleArn       = "${aws_iam_role.cloudformation_role.arn}"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name     = "Deploy"
      category = "Deploy"
      owner    = "AWS"
      provider = "CloudFormation"
      version  = "1"

      configuration {
        ActionMode    = "CHANGE_SET_EXECUTE"
        StackName     = "MyBetaStack"
        ChangeSetName = "MyChangeSet"
      }
    }
  }
}
