FROM jboss/keycloak:4.5.0.Final

LABEL maintainer="Niko Köbler, https://www.n-k.de, @dasniko"

# install awscli (we need this in the customized docker-entrypoint.sh)
USER root
RUN curl -O https://bootstrap.pypa.io/get-pip.py && python get-pip.py && pip install awscli --upgrade
USER jboss

# configure high-availability
COPY keycloak-ha.cli /tmp/keycloak-ha.cli
RUN /opt/jboss/keycloak/bin/jboss-cli.sh --file=/tmp/keycloak-ha.cli && rm -rf /opt/jboss/keycloak/standalone/configuration/standalone_xml_history
# uncomment next line if you want to see the modified standalone-ha.xml printed on console
# RUN cat /opt/jboss/keycloak/standalone/configuration/standalone-ha.xml

# add customized docker-entrypoint.sh
ADD docker-entrypoint.sh /opt/jboss/tools/

# our implemented spi's (for demo purpose it's the demo user-spi from https://github.com/dasniko/keycloak-user-spi-demo)
ADD --chown=jboss https://github.com/dasniko/keycloak-user-spi-demo/releases/download/1/keycloak-demo-user-spi.jar /opt/jboss/keycloak/standalone/deployments

# and some customized theme(s) (for demo purpose, it's only the sunrise theme, coming with keycloak demo)
COPY themes /opt/jboss/keycloak/themes

# 8080 for http
# 7600 for jgroups
EXPOSE 8080 7600
