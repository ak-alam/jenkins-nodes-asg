# Jenkins Master Slave Node

## Requirements:
* Create Node
* Connect Node To Master
* Delete Node On Instance Termination



**I  will be using jenkins cli to perform this task and will use jnlp protocol for master slave connection.**

## prerequisites:
* Install java jdk (must be same version as master node)
* Jenkins cli client jar file to run the jenkins cli commands.
* Jenkins agent jar files to connect to master node.

### Creating Node(slave):
* Jenkins cli create node command accept node-config as standard input file and this config file contains all the details to create a node.

``` java -jar jenkins-cli.jar -s JENKINS_URL -webSocket create-node node_name < node-config.xml ```

### Connect Node To Master:
* extract the secret from ```JENKINS_URL/manage/computer/agent-name/jenkins-agent.jnlp```
* connect to master using ```java -jar agent.jar -jnlpUrl JENKINS_URL/manage/computer/agent-name/jenkins-agent.jnlp -secret $secret -workDir "/home/ec2-user/jnlp_dir"```

### Delete Node After Instance Termination
* delete using jenkins cli command ```java -jar jenkins-cli.jar -s JENKINS_URL -auth username:api-token -webSocket delete-node node-name```

### My approch to the problem.
* create a userdata script which will be pass into autoscaling launch template.
* the script will download all the prerequisites
* extracting variables and secrets from SSM parameters
* download the all the required files (delete script, config.xml. delete-service.service)
* dynamically override the values into the node creation config xml file
* start the systemd serivce (delete node on instance termination)
* download the client jar file and agent file to run jenkins cli commands
* connect to master using the jenkins cli command given above