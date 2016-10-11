#!/bin/sh

# Create default app server users
if [[ ! -z "${WILDFLY_MANAGEMENT_USER}" ]] && [[ ! -z "${WILDFLY_MANAGEMENT_PASSWORD}" ]]
then
	echo "adding jboss users..."
    ${JBOSS_HOME}/bin/add-user.sh --silent -e -u ${WILDFLY_MANAGEMENT_USER} -p ${WILDFLY_MANAGEMENT_PASSWORD}
    sed -i "s/@WILDFLY_MANAGEMENT_USER@/${WILDFLY_MANAGEMENT_USER}/" ${JBOSS_HOME}/domain/configuration/host-slave.xml
    sed -i "s/@WILDFLY_MANAGEMENT_PASSWORD@/`echo ${WILDFLY_MANAGEMENT_PASSWORD} | base64`/" ${JBOSS_HOME}/domain/configuration/host-slave.xml
fi

# Set server group
sed -i "s/@SERVER_GROUP@/${SERVER_GROUP}/" ${JBOSS_HOME}/domain/configuration/host-slave.xml

# Unset the temporary env variables
unset ${WILDFLY_MANAGEMENT_USER} ${WILDFLY_MANAGEMENT_PASSWORD}

#exec ${JBOSS_HOME}/bin/domain.sh "$@"
{
if [ "${CONTROLLER_TYPE}" = "domain" ]
then
	echo "running additional setup for domain controller"
	${JBOSS_HOME}/wait-for-it.sh localhost:9990 -- echo "Wildfly Domain is up"
	${JBOSS_HOME}/bin/jboss-cli.sh --connect --user=admin --password=admin --command="deploy /opt/jboss/wildfly/node-info.war --server-groups=main-server-group"
fi	
} & exec ${JBOSS_HOME}/bin/domain.sh "$@"
