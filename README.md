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
The first task that the **_entrypoint.sh_** executes is to create a management user by running the **_add-user.sh_** passing in the values stored in the ** * WILDFLY_MANAGEMENT_USER * ** and **  * WILDFLY_MANAGEMENT_PASSWORD * ** environment variables.  

Once the user has been created the placeholders in the ***host-slave.xml*** are replaced with the values of ***WILDFLY_MANAGEMENT_USER*** and ***WILDFLY_MANAGEMENT_PASSWORD***.  The placeholder for the ***SERVER_GROUP*** is also replaced with the value from the ***SERVER_GROUP*** environment variable.

***entrypoint.sh*** now executes 2 running processes:
* Thread 1 : Start Wildfly in domain mode
* Thread 2 : Wait for the Domain Controller to be available then deploy a war

###### Thread 2 : WaitFor and War Deployment ######

This thread will only execute the wait and deploment if the ***CONTROLLER_TYPE*** environment variable value is set to ***domain***.

The first task that thread 2 executes is the ***wait-for-it.sh*** script. The script listens on ***localhost:9990***  and waits until the domain controller is available, When it is available the script prints "Wildfly Domain is up"

The next task is to call the * ** jboss-cli.sh ** * and deploy the * ** node-info.war ** * to the * ** main-server-group ** *: 

> jboss-cli.sh --connect --user=admin --password=admin --command="deploy /opt/jboss/wildfly/node-info.war --server-groups=main-server-group"

#### Running The Domain Controller ####
In order to setup a domain, you need to start the domain controller first. The domain controller defines two server groups called main-server-group and other-server-group, but does not include any servers.

> docker run --rm -it -p 9990:9990 --name=dc sleepingtalent/wildfly-domain-with-app --host-config host-master.xml -b 0.0.0.0 -bmanagement 0.0.0.0

#### Running The Host Controller ####

The host controller defines one server called server-one with auto-start=true. When starting the host controller, you have to provide specific parameters:

* ** The name of the link to the domain controller must be domain-controller. **
* ** Add the name of the server group for server-one using the environment variable * SERVER_GROUP *  **
* ** CONTROLLER_TYPE must be set to * host * **

> docker run --rm -it -p 8080 --link dc:domain-controller -e CONTROLLER_TYPE=host -e SERVER_GROUP=main-server-group sleepingtalent/wildfly-domain-with-app --host-config host-slave.xml

#### Environment Variables ####

Here's a list of all environment variables which are processed by the docker image:

* ** WILDFLY_MANAGEMENT_USER ** : User for the management endpoint. Defaults to "admin".
* ** WILDFLY_MANAGEMENT_PASSWORD ** : Password for the management endpoint. Defaults to "admin".
* ** SERVER_GROUP ** : Group for the server when starting a host controller. Mandatory when starting a host controller
* ** CONTROLLER_TYPE ** : Defines the controller type to start defaults to *domain*