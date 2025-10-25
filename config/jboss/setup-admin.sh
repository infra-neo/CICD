#!/bin/bash
# JBoss Admin User Configuration Script

JBOSS_HOME=/opt/jboss/wildfly

# Wait for JBoss to be ready
sleep 10

# Add admin user
$JBOSS_HOME/bin/add-user.sh -u ${JBOSS_USER:-admin} -p ${JBOSS_PASS:-admin} --silent

echo "JBoss admin user configured: ${JBOSS_USER:-admin}"
