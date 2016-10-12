### WildFly Domain ###

This repository contains a Dockerfile to setup a WildFly domain. 

It's based on the idea to have a generic docker image which is used to start both a domain controller and an arbitrary number of host controllers.

#### Image Configuration ####
The DockerFile and Resouces used to build this image can be found at the following location:
> [DockerFile and Resources](https://github.com/SleepingTalent/wildfly-domain-docker)

When the image is built from the docker file, **_node-info.war_** and **_wait-for-it.sh_** are copied to the **_/opt/jboss/wildfly/ directory_**

The DockerFile also replaces the contents of the **_/opt/jboss/wildfly/domain/configuration/_** with the files contained within **_domain/configuration/*_**

Finally **_entrypoint.sh_** is copied to  **_/opt/jboss/wildfly/bin/_**

Ports _8080_,  _9990_,  _9999_ are exposed

##### Running entrypoint.sh #####
The first task that the **_entrypoint.sh_** executes is to create a management user by running the **_add-user.sh_** passing in the values stored in the ***WILDFLY_MANAGEMENT_USER*** and ***WILDFLY_MANAGEMENT_PASSWORD*** environment variables.  

Once the user has been created the placeholders in the ***host-slave.xml*** are replaced with the values of ***WILDFLY_MANAGEMENT_USER*** and ***WILDFLY_MANAGEMENT_PASSWORD***.  The placeholder for the ***SERVER_GROUP*** is also replaced with the value from the ***SERVER_GROUP*** environment variable.

***entrypoint.sh*** now executes 2 running processes:
* Thread 1 : Start Wildfly in domain mode
* Thread 2 : Wait for the Domain Controller to be available then deploy a war

###### Thread 2 : WaitFor and War Deployment ######

This thread will only execute the wait and deploment if the **_CONTROLLER_TYPE_** environment variable value is set to **_domain_**.

The first task that thread 2 executes is a sleep taking the value from **_WAIT_TIME_SECS_** environment variable, this should allow the domain to start fully.  

As a final check the **_wait-for-it.sh_** script is run. The script listens on **_localhost:9990_**  and waits until the domain controller is available, When it is available the script prints "Wildfly Domain is up"

The next task is to call the **_jboss-cli.sh_** and deploy the artifact specified by **_ARTIFACT_NAME_** to the **_SERVER_GROUP_** value: 

>${JBOSS_HOME}/bin/jboss-cli.sh --connect --user=admin --password=admin --command="deploy /opt/jboss/wildfly/${ARTIFACT_NAME} --server-groups=${SERVER_GROUP}"

#### Running The Domain Controller ####
In order to setup a domain, you need to start the domain controller first. The domain controller defines two server groups called main-server-group and other-server-group, but does not include any servers.

> docker run --rm -it -p 9990:9990 --name=dc sleepingtalent/wildfly-domain-with-app --host-config host-master.xml -b 0.0.0.0 -bmanagement 0.0.0.0

#### Running The Host Controller ####

The host controller defines one server called server-one with auto-start=true. When starting the host controller, you have to provide specific parameters:

* **The name of the link to the domain controller must be domain-controller.**
* **Add the name of the server group for server-one using the environment variable _SERVER_GROUP_**
* **CONTROLLER_TYPE must be set to _host_**
* **DOMAIN_HOST must be set to _domain ip address_**

> docker run --rm -it -p 8080:8080 -e CONTROLLER_TYPE=host -e DOMAIN_HOST=192.168.99.100 --name=hc sleepingtalnet/wildfly-domain-with-app --host-config host-slave.xml

#### Environment Variables ####

Here's a list of all environment variables which are processed by the docker image:

* **WILDFLY_MANAGEMENT_USER** : User for the management endpoint. Defaults to "admin".
* **WILDFLY_MANAGEMENT_PASSWORD** : Password for the management endpoint. Defaults to "admin".
* **SERVER_GROUP** : Group for the server when starting a host controller, also used when deploying an artifact to the domain. Defaults to "main-server-group"
* **DOMAIN_HOST** : Defines the ip address of the machine where the *domain controller* is running
* **CONTROLLER_TYPE** : Defines the controller type to start defaults to **_domain_**
* **WAIT_TIME_SECS** : Defines the time to wait before attempting to deploy the artifact. Defaults to "30"
* **ARTIFACT_NAME** : Defines the name of the artifact to copy and deploy. Defaults to  "node-info.war"