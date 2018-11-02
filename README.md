# Keycloak Docker image for AWS usage

This Docker image is intended for use in _AWS_, e.g. _ElasticBeanstalk_, and it's only for demo purposes, not for production usage.
But it can be a good start to cope with your challenges.

**If you use this image in production environments, you are fully responsible on your own!**

The image makes use of_AWS SecretsManager_ and obtains secrets and credentials from there for the Keycloak admin user and the database configuration.

Because AWS doesn't provide UDP and/or multicast on the network, this image makes use of the `JDBC_PING` implmentation of JGroups to establish the HA/cluster connectivity/communication.

There is also a custom User SPI ([dasniko/keycloak-user-spi-demo](https://github.com/dasniko/keycloak-user-spi-demo)) and a custom theme involved, also only for demo purposes.
