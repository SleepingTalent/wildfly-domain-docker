#!/bin/sh

# Create default app server users
if [[ ! -z "${WILDFLY_MANAGEMENT_USER}" ]] && [[ ! -z "${WILDFLY_MANAGEMENT_PASSWORD}" ]]
then
	echo "add-user-process: creating jboss users"
    ${JBOSS_HOME}/bin/add-user.sh --silent -e -u ${WILDFLY_MANAGEMENT_USER} -p ${WILDFLY_MANAGEMENT_PASSWORD}
    sed -i "s/@WILDFLY_MANAGEMENT_USER@/${WILDFLY_MANAGEMENT_USER}/" ${JBOSS_HOME}/domain/configuration/host-slave.xml
    sed -i "s/@WILDFLY_MANAGEMENT_PASSWORD@/`echo ${WILDFLY_MANAGEMENT_PASSWORD} | base64`/" ${JBOSS_HOME}/domain/configuration/host-slave.xml
	echo "add-user-process: jboss users have been created and host-slave.xml has been updated"
fi

# Set server group
sed -i "s/@SERVER_GROUP@/${SERVER_GROUP}/" ${JBOSS_HOME}/domain/configuration/host-slave.xml

# Unset the temporary env variables
unset ${WILDFLY_MANAGEMENT_USER} ${WILDFLY_MANAGEMENT_PASSWORD}

#exec ${JBOSS_HOME}/bin/domain.sh "$@"
{
if [ "${CONTROLLER_TYPE}" = "domain" ]
then
	echo "artifact-deploy-process: sleeping for ${WAIT_TIME_SECS} seconds"
	sleep ${WAIT_TIME_SECS}
	echo "artifact-deploy-process: waking up"
	echo "artifact-deploy-process: checking that the domain has started"
	${JBOSS_HOME}/wait-for-it.sh localhost:9990 -- echo "wildfly domain has started"
	echo "artifact-deploy-process: starting deployment"
	#${JBOSS_HOME}/bin/jboss-cli.sh --connect --user=admin --password=admin --command="deploy /opt/jboss/wildfly/node-info.war --server-groups=${SERVER_GROUP}"
	${JBOSS_HOME}/bin/jboss-cli.sh --connect --user=admin --password=admin --command="deploy /opt/jboss/wildfly/${ARTIFACT_NAME} --server-groups=${SERVER_GROUP}"
	echo "artifact-deploy-process: deployment complete"
fi	
} & exec ${JBOSS_HOME}/bin/domain.sh "$@"
