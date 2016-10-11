### WildFly Domain ###
This repository contains a Dockerfile to setup a WildFly domain. 

It's based on the idea to have a generic docker image which is used to start both a domain controller and an arbitrary number of host controllers.

The DockerFile and Resouces used to build this image can be found at the following location. 

[DockerFile and Resources](https://github.com/SleepingTalent/wildfly-domain-docker)

#### Running The Domain Controller ####
In order to setup a domain, you need to start the domain controller first. The domain controller defines two server groups called main-server-group and other-server-group, but does not include any servers.

'''
docker run --rm -it -p 9990:9990 --name=dc sleepingtalent/wildfly-domain-with-app --host-config host-master.xml -b 0.0.0.0 -bmanagement 0.0.0.0
'''

#### Running The Host Controller ####

The host controller defines one server called server-one with auto-start=true. When starting the host controller, you have to provide specific parameters:

* **The name of the link to the domain controller must be domain-controller.**
* **Add the name of the server group for server-one using the environment variable _SERVER_GROUP_**
* **CONTROLLER_TYPE must be set to _host_**

'''
docker run --rm -it -p 8080 --link dc:domain-controller -e CONTROLLER_TYPE=host -e SERVER_GROUP=main-server-group sleepingtalent/wildfly-domain-with-app --host-config host-slave.xml
'''

#### Environment Variables ####

Here's a list of all environment variables which are processed by the docker image:

* **WILDFLY_MANAGEMENT_USER** : User for the management endpoint. Defaults to "admin".
* **WILDFLY_MANAGEMENT_PASSWORD** : Password for the management endpoint. Defaults to "admin".
* **SERVER_GROUP** : Group for the server when starting a host controller. Mandatory when starting a host controller
* **CONTROLLER_TYPE** : Defines the controller type to start defaults to _domain_