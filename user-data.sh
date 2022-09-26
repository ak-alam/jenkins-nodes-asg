#!/bin/bash
#Install java and git on agent node
sudo yum update -y
sudo yum install wget
sudo amazon-linux-extras install java-openjdk11 -y
sudo amazon-linux-extras install epel -y

#variable definitions 
jenkins_url=`aws ssm get-parameter --name "jenkins_url" --query 'Parameter.Value' --output text --region us-east-2`
jenkins_user=`aws ssm get-parameter --name "jenkins_user" --query 'Parameter.Value' --output text --region us-east-2`
jenkins_token=`aws ssm get-parameter --name "jenkins_token" --query 'Parameter.Value' --with-decryption --output text --region us-east-2`
agent_ip=`hostname -I | tr -d '.' | xargs`
agent_dir=/home/ec2-user/jnlp_dir
num_of_executors=1

#downloading scripts from s3
aws s3 sync s3://akbar-jenkins-scripts /home/ec2-user 2>&1 > /tmp/s3-sync.log
#coping delete script to tmp
cp /home/ec2-user/delete-node.sh /tmp/delete-node.sh
#coping systemd unit file to systemd folder
cp /home/ec2-user/delete-node.service /etc/systemd/system/delete-node.service
#execute permission
chmod +x /tmp/delete-node.sh

#dynamically changing values in 
sed -i "s|agent-name|${agent_ip}|g" /home/ec2-user/create-node.xml
sed -i "s|agent-dir|${agent_dir}|g" /home/ec2-user/create-node.xml
sed -i "s|num-of-executors|${num_of_executors}|g" /home/ec2-user/create-node.xml
sed -i "s|agent-label|${agent_ip}|g" /home/ec2-user/create-node.xml

#systemd serivce
systemctl daemon-reload
systemctl enable delete-node.service
systemctl start delete-node.service

#Download the jenkins cli client.
wget -q ${jenkins_url}/jnlpJars/jenkins-cli.jar -P /home/ec2-user/
#Node creation cli command
java -jar /home/ec2-user/jenkins-cli.jar -s $jenkins_url -auth ${jenkins_user}:${jenkins_token} -webSocket create-node $agent_ip < /home/ec2-user/create-node.xml

#Connecting agent to master node
#Download the agent jar file to connect to master
wget -q ${jenkins_url}/jnlpJars/agent.jar -P /home/ec2-user/jnlp_dir/
#Getting secret 
secret=`curl -s -u ${jenkins_user}:${jenkins_token} ${jenkins_url}/manage/computer/${agent_ip}/jenkins-agent.jnlp | sed 's/<[^>]*>//g' | cut -c  1-64`
# java -jar agent.jar -jnlpUrl ${jenkins_url}/manage/computer/${agent_ip}/jenkins-agent.jnlp -secret $secret -workDir "/home/ec2-user/jnlp_dir"
java -jar /home/ec2-user/jnlp_dir/agent.jar -jnlpUrl ${jenkins_url}/manage/computer/${agent_ip}/jenkins-agent.jnlp -secret $secret -workDir "/home/ec2-user/jnlp_dir"
