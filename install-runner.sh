#!/bin/bash
exec > >(tee /var/log/user-data.log) 2>&1

cd /home/ec2-user
mkdir actions-runner && cd actions-runner

chown -R ec2-user:ec2-user /home/ec2-user/actions-runner

curl -o actions-runner-linux-x64-2.313.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.313.0/actions-runner-linux-x64-2.313.0.tar.gz

tar xzf ./actions-runner-linux-x64-2.313.0.tar.gz

sudo dnf makecache --refresh
sudo dnf -y install lld
yum install libicu -y


sudo -u ec2-user ./config.sh --url "{{GITHUB_REPO_URL}}" --token "{{GITHUB_TOKEN}}" 


sudo -u ec2-user yes "" | ./config.sh --url "{{GITHUB_REPO_URL}}" --token "{{GITHUB_TOKEN}}"

./svc.sh install ec2-user
./svc.sh start

