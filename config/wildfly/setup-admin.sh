#!/bin/bash
# WildFly Admin User Configuration Script

WILDFLY_HOME=/opt/jboss/wildfly

# Wait for WildFly to be ready
sleep 10

# Add admin user
$WILDFLY_HOME/bin/add-user.sh -u ${WILDFLY_USER:-admin} -p ${WILDFLY_PASS:-admin} --silent

echo "WildFly admin user configured: ${WILDFLY_USER:-admin}"
