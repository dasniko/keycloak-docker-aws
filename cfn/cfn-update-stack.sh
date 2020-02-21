#!/usr/bin/env bash

aws cloudformation update-stack \
  --stack-name keycloak \
  --template-body file://template-stack.yml \
  --capabilities CAPABILITY_NAMED_IAM
