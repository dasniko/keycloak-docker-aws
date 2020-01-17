FROM quay.io/keycloak/keycloak:8.0.1

LABEL maintainer="Niko Köbler, https://www.n-k.de, @dasniko"

USER root
# install awscli, we need this in the aws-entrypoint.sh
RUN microdnf install -y python3 && microdnf clean all
RUN curl -O https://bootstrap.pypa.io/get-pip.py && python3 get-pip.py && pip install awscli --upgrade
# install jq, we need this in the aws-entrypoint.sh
RUN curl -L https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -o jq && chmod +x ./jq && cp jq /usr/bin
USER jboss

# default realm (will be imported through envvar)
COPY --chown=jboss:root demo-realm.json /opt/jboss/keycloak/
ENV KEYCLOAK_IMPORT /opt/jboss/keycloak/demo-realm.json

# and some customized theme(s) (for demo purpose, it's only the sunrise theme, coming with keycloak demo)
COPY themes /opt/jboss/keycloak/themes

# our implemented spi's (for demo purpose it's the demo user-spi from https://github.com/dasniko/keycloak-user-spi-demo)
#ADD --chown=jboss:root https://github.com/dasniko/keycloak-user-spi-demo/releases/download/1/keycloak-demo-user-spi.jar /opt/jboss/keycloak/standalone/deployments

# add customized tools (aws-entrypoint.sh and jgroups configuration cli)
COPY tools /opt/jboss/tools
COPY startup-scripts /opt/jboss/startup-scripts

# 8080 for http
# 7600 for jgroups
EXPOSE 8080 7600

ENTRYPOINT [ "/opt/jboss/tools/aws-entrypoint.sh" ]
