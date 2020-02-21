#!/usr/bin/env bash

aws cloudformation create-stack \
  --stack-name keycloak \
  --template-body file://template-stack.yml \
  --capabilities CAPABILITY_NAMED_IAM
