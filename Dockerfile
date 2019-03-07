FROM quay.io/keycloak/keycloak:5.0.0

LABEL maintainer="Niko Köbler, https://www.n-k.de, @dasniko"

# install awscli (we need this in the customized docker-entrypoint.sh)
USER root
RUN curl -O https://bootstrap.pypa.io/get-pip.py && python get-pip.py && pip install awscli --upgrade
USER jboss

# and some customized theme(s) (for demo purpose, it's only the sunrise theme, coming with keycloak demo)
COPY themes /opt/jboss/keycloak/themes

# our implemented spi's (for demo purpose it's the demo user-spi from https://github.com/dasniko/keycloak-user-spi-demo)
ADD --chown=jboss https://github.com/dasniko/keycloak-user-spi-demo/releases/download/1/keycloak-demo-user-spi.jar /opt/jboss/keycloak/standalone/deployments

# add customized tools (docker-entrypoint.sh and jgroups configuration cli)
COPY tools /opt/jboss/tools
COPY startup-scripts /opt/jboss/startup-scripts

# 8080 for http
# 7600 for jgroups
EXPOSE 8080 7600
