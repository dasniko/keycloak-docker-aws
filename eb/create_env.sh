#!/usr/bin/env bash

env=${1:-demo}

eb create ${env} \
  --cfg ${env} \
  --cname dasniko-kc-${env}
