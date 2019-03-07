# Keycloak Docker image for AWS usage

This Docker image is intended for use in _AWS_, e.g. _ElasticBeanstalk_, and it's _only for demo purposes, not for production usage._
But it can be a good start to cope with your challenges.

**If you use this image in production environments, you are fully responsible on your own!**

The image makes use of _AWS SecretsManager_ and obtains secrets and credentials from there for the Keycloak admin user and the database configuration.
Therefore, the original `docker-entrypoint.sh` script is modified at the top calling our own `aws.sh` script, setting all these envvars at runtime.
We only need to provide the two envvars `KEYCLOAK_ADMIN_USER_SECRET` and `KEYCLOAK_DB_SECRET` with the names of the proper secrets.

Because AWS doesn't provide UDP and/or multicast on the network, this image makes use of the `JDBC_PING` implmentation of JGroups to establish the HA/cluster connectivity/communication, if the envvar `JGROUPS_DISCOVERY_PROTOCOL` is set to `JDBC_PING`.

For configuration of the number of cache-owners, set the envvars `CACHE_OWNERS_SESSIONS`, `CACHE_OWNERS_AUTH_SESSIONS` and `CACHE_OWNERS_LOGIN_FAILURES` to the desired values.

There is also a custom User SPI ([dasniko/keycloak-user-spi-demo](https://github.com/dasniko/keycloak-user-spi-demo)) and a custom theme involved, also only for demo purposes.
