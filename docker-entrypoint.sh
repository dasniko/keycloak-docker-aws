#!/bin/bash

##################
# Add admin user #
##################

# for security reasons, we only store credentials in AWS SecretsManager and obtain the info from there at runtime
# of course, the running EC2 instance needs access to SecretsManager via IAM instance policies
if [ $KEYCLOAK_USER_SECRET ]; then
  SECRET=$(aws secretsmanager get-secret-value --secret-id $KEYCLOAK_USER_SECRET --query 'SecretString' --region eu-central-1 --output text)
  export KEYCLOAK_USER=$(echo $SECRET | jq .username -r)
  export KEYCLOAK_PASSWORD=$(echo $SECRET | jq .password -r)
fi
if [ $KEYCLOAK_USER ] && [ $KEYCLOAK_PASSWORD ]; then
    /opt/jboss/keycloak/bin/add-user-keycloak.sh --user $KEYCLOAK_USER --password $KEYCLOAK_PASSWORD
fi

############
# Hostname #
############

if [ "$KEYCLOAK_HOSTNAME" != "" ]; then
    SYS_PROPS="-Dkeycloak.hostname.provider=fixed -Dkeycloak.hostname.fixed.hostname=$KEYCLOAK_HOSTNAME"

    if [ "$KEYCLOAK_HTTP_PORT" != "" ]; then
        SYS_PROPS+=" -Dkeycloak.hostname.fixed.httpPort=$KEYCLOAK_HTTP_PORT"
    fi

    if [ "$KEYCLOAK_HTTPS_PORT" != "" ]; then
        SYS_PROPS+=" -Dkeycloak.hostname.fixed.httpsPort=$KEYCLOAK_HTTPS_PORT"
    fi
fi

################
# Realm import #
################

if [ "$KEYCLOAK_IMPORT" ]; then
    SYS_PROPS+=" -Dkeycloak.import=$KEYCLOAK_IMPORT"
fi

########################
# JGroups bind options #
########################

if [ -z "$BIND" ]; then
    BIND=$(hostname -i)
fi
if [ -z "$BIND_OPTS" ]; then
    for BIND_IP in $BIND
    do
        BIND_OPTS+=" -Djboss.bind.address=$BIND_IP -Djboss.bind.address.private=$BIND_IP "
    done
fi
SYS_PROPS+=" $BIND_OPTS"

#################
# Configuration #
#################

# If the "-c" parameter is not present, append the HA profile.
if echo "$@" | egrep -v -- "-c "; then
    SYS_PROPS+=" -c standalone-ha.xml"
fi

##############
# DB secrets #
##############

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

############
# DB setup #
############

# Lower case DB_VENDOR
DB_VENDOR=`echo $DB_VENDOR | tr A-Z a-z`

# Detect DB vendor from default host names
if [ "$DB_VENDOR" == "" ]; then
    if (getent hosts postgres &>/dev/null); then
        export DB_VENDOR="postgres"
    elif (getent hosts mysql &>/dev/null); then
        export DB_VENDOR="mysql"
    elif (getent hosts mariadb &>/dev/null); then
        export DB_VENDOR="mariadb"
    fi
fi

# Detect DB vendor from legacy `*_ADDR` environment variables
if [ "$DB_VENDOR" == "" ]; then
    if (printenv | grep '^POSTGRES_ADDR=' &>/dev/null); then
        export DB_VENDOR="postgres"
    elif (printenv | grep '^MYSQL_ADDR=' &>/dev/null); then
        export DB_VENDOR="mysql"
    elif (printenv | grep '^MARIADB_ADDR=' &>/dev/null); then
        export DB_VENDOR="mariadb"
    fi
fi

# Default to H2 if DB type not detected
if [ "$DB_VENDOR" == "" ]; then
    export DB_VENDOR="h2"
fi

# Set DB name
case "$DB_VENDOR" in
    postgres)
        DB_NAME="PostgreSQL";;
    mysql)
        DB_NAME="MySQL";;
    mariadb)
        DB_NAME="MariaDB";;
    h2)
        DB_NAME="Embedded H2";;
    *)
        echo "Unknown DB vendor $DB_VENDOR"
        exit 1
esac

# Append '?' in the beggining of the string if JDBC_PARAMS value isn't empty
export JDBC_PARAMS=$(echo ${JDBC_PARAMS} | sed '/^$/! s/^/?/')

# Convert deprecated DB specific variables
function set_legacy_vars() {
  local suffixes=(ADDR DATABASE USER PASSWORD PORT)
  for suffix in "${suffixes[@]}"; do
    local varname="$1_$suffix"
    if [ ${!varname} ]; then
      echo WARNING: $varname variable name is DEPRECATED replace with DB_$suffix
      export DB_$suffix=${!varname}
    fi
  done
}
set_legacy_vars `echo $DB_VENDOR | tr a-z A-Z`

# Configure DB

echo "========================================================================="
echo ""
echo "  Using $DB_NAME database"
echo ""
echo "========================================================================="
echo ""

if [ "$DB_VENDOR" != "h2" ]; then
    /bin/sh /opt/jboss/tools/databases/change-database.sh $DB_VENDOR
fi

/opt/jboss/tools/x509.sh
/opt/jboss/tools/jgroups.sh $JGROUPS_DISCOVERY_PROTOCOL $JGROUPS_DISCOVERY_PROPERTIES

##################
# Start Keycloak #
##################

# to be able to communicate vai JGroups in EC2 Dockerized environment (e.g. ElasticBeanstalk, we need the hostname from the runnint instance, see also keycloak-ha.cli, we do this via the EC2 meta-data service, available in every EC2 instance)
export EC2_HOSTNAME=$(curl http://169.254.169.254/latest/meta-data/local-hostname)
SYS_PROPS+=" -Djboss.node.name=$EC2_HOSTNAME"

exec /opt/jboss/keycloak/bin/standalone.sh $SYS_PROPS $@
exit $?
