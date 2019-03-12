#!/bin/bash

##############################
# Set admin user credentials #
##############################

# for security reasons, we only store credentials in AWS SecretsManager and obtain the info from there at runtime
# of course, the running EC2 instance needs access to SecretsManager via IAM instance policies
if [ "$KEYCLOAK_ADMIN_USER_SECRET" ]; then
  SECRET=$(aws secretsmanager get-secret-value --secret-id $KEYCLOAK_ADMIN_USER_SECRET --query 'SecretString' --region eu-central-1 --output text)
  export KEYCLOAK_USER=$(echo $SECRET | jq .username -r)
  export KEYCLOAK_PASSWORD=$(echo $SECRET | jq .password -r)
fi


#############
# DB params #
#############

# again we obtain the database connection credentails from AWS SecretsManager
if [ $KEYCLOAK_DB_SECRET ]; then
  SECRET=$(aws secretsmanager get-secret-value --secret-id $KEYCLOAK_DB_SECRET --query 'SecretString' --region eu-central-1 --output text)
  export DB_VENDOR=$(echo $SECRET | jq .engine -r)
  export DB_ADDR=$(echo $SECRET | jq .host -r)
  export DB_PORT=$(echo $SECRET | jq .port -r)
  export DB_DATABASE=$(echo $SECRET | jq .dbname -r)
  export DB_USER=$(echo $SECRET | jq .username -r)
  export DB_PASSWORD=$(echo $SECRET | jq .password -r)
fi


#########################
# JGroups communication #
#########################

# to be able to communicate via JGroups in EC2 Dockerized environment (e.g. ElasticBeanstalk, we need the hostname from the running instance, see also JDBC_PING.cli, we do this via the EC2 meta-data service, available in every EC2 instance)
if [ "$JGROUPS_DISCOVERY_PROTOCOL" != "" ]; then
  export EC2_HOSTNAME=$(curl http://169.254.169.254/latest/meta-data/local-hostname)
  SYS_PROPS=" -Djboss.node.name=$EC2_HOSTNAME"
else
  SYS_PROPS=" -Djboss.node.name=$(hostname)"
fi


############################
# call original entrypoint #
############################

exec /opt/jboss/tools/docker-entrypoint.sh $SYS_PROPS $@
exit $?
