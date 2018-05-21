resource "aws_security_group" "deny_ingress" {
  count       = "${var.management_ip != "" ? 1 : 0}"
  name        = "deny"
  description = "deny all inbound traffic"
  vpc_id      = "vpc-e283b399"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.management_ip}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_instance_profile" "monitoring_profile" {
  name = "monitoring_profile"
  role = "${aws_iam_role.monitoring_instance_role.name}"
}

resource "aws_iam_role" "monitoring_instance_role" {
  name = "monitoring_instance_role"
  path = "/"

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

resource "aws_iam_role" "monitoring_role" {
  name = "monitoring_role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
         {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${var.account_id}:role/monitoring_instance_role"
      },
      "Action": "sts:AssumeRole"
    }
    ]
}
EOF
}

resource "aws_iam_role_policy" "monitoring_policy" {
  name = "monitoring_policy"
  role = "${aws_iam_role.monitoring_role.id}"

  policy = <<EOF
{
    "Statement": [
        {
     "Action": [
       "iam:DeleteInstanceProfile",
       "iam:DeleteRole",
       "iam:DeleteRolePolicy",
       "iam:GetInstanceProfile",
       "iam:GetRole",
       "iam:GetRolePolicy",
       "iam:ListInstanceProfiles",
       "iam:ListInstanceProfilesForRole",
       "iam:ListRolePolicies",
       "iam:ListRoles",
       "iam:PutRolePolicy",
       "iam:UpdateRoleDescription",
        "iam:GenerateServiceLastAccessedDetails",
        "iam:GetServiceLastAccessedDetails",
        "iam:ListUsers",
        "iam:ListPolicies",
        "iam:ListGroups"
     ],
     "Effect": "Allow",
     "Resource": "*"
   }
    ],
    "Version": "2012-10-17"
}
EOF
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "web" {
  ami                    = "${data.aws_ami.ubuntu.id}"
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.deny_ingress.id}"]
  key_name               = "default"
  iam_instance_profile   = "${aws_iam_instance_profile.monitoring_profile.name}"

  provisioner "file" {
    source      = "repokid_config"
    destination = "/tmp/repokid.config"
  }

  provisioner "file" {
    source      = "aardvark_config"
    destination = "/tmp/aardvark.config"
  }

  connection {
    user        = "ubuntu"
    private_key = "${file(var.private_key)}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get install git -y --upgrade",
      "sudo apt-get install default-jre -y --upgrade",
      "sudo apt-get install python-dev -y --upgrade",
      "sudo apt-get install python-pip -y --upgrade",
      "sudo apt-get install build-essential chrpath libssl-dev libxft-dev -y",
      "sudo apt-get install libfreetype6 libfreetype6-dev -y",
      "sudo apt-get install libfontconfig1 libfontconfig1-dev -y",
      "wget https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2",
      "sudo tar xvjf phantomjs-2.1.1-linux-x86_64.tar.bz2",
      "sudo mv phantomjs-2.1.1-linux-x86_64 /usr/local/share",
      "sudo ln -sf /usr/local/share/phantomjs-2.1.1-linux-x86_64/bin/phantomjs /usr/local/bin",
      "sudo pip install setuptools --upgrade",
      "git clone https://github.com/Netflix-Skunkworks/aardvark.git",
      "git clone https://github.com/Netflix/repokid.git",
      "sudo mkdir /etc/aardvark",
      "sudo cp /tmp/aardvark.config /etc/aardvark/config.py",
      "cd aardvark",
      "sudo python setup.py develop",
      "sudo pip uninstall requests -y",
      "sudo pip install requests --upgrade",
      "sudo pip uninstall docopt -y",
      "sudo pip install docopt --upgrade",
      "cd ../repokid",
      "sudo python setup.py develop",
      "sudo mkdir /etc/repokid",
      "sudo cp /tmp/repokid.config /etc/repokid/config.json",
      "wget https://s3-us-west-2.amazonaws.com/dynamodb-local/dynamodb_local_latest.tar.gz",
      "sudo tar -xvzf dynamodb_local_latest.tar.gz",
      "nohup java -Djava.library.path=./DynamoDBLocal_lib -jar DynamoDBLocal.jar -sharedDb -inMemory -port 8010 &",
      "sleep 1",
      "aardvark create_db",
      "nohup aardvark start_api -b 0.0.0.0:5000 &",
      "sleep 1",
      "(crontab -l && echo '0 00 31 12 7 echo hello') | crontab",
      "(crontab -l && echo '0 01 * * 0-7 aardvark update -a ${var.account_id}') | crontab",
      "(crontab -l && echo '0 02 * * 0-7 repokid update_role_cache ${var.account_id}') | crontab",
      "(crontab -l && echo '0 03 * * 0-7 repokid repo_all_roles ${var.account_id}') | crontab",
      "touch ~/provisioned",
    ]
  }

  tags {
    Name = "Aardvark"
  }
}
