#!/bin/bash
jenkins_url=`aws ssm get-parameter --name "jenkins_url" --query 'Parameter.Value' --output text --region us-east-2`
jenkins_user=`aws ssm get-parameter --name "jenkins_user" --query 'Parameter.Value' --output text --region us-east-2`
jenkins_token=`aws ssm get-parameter --name "jenkins_token" --query 'Parameter.Value' --with-decryption --output text --region us-east-2`
agent_ip=`hostname -I | tr -d '.' | xargs`
/usr/bin/java -jar /home/ec2-user/jenkins-cli.jar -s ${jenkins_url} -auth ${jenkins_user}:${jenkins_token} -webSocket delete-node ${agent_ip}