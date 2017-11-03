#!/usr/bin/env bash

#!/bin/bash
set -euo pipefail

IMAGE_NAMES="sidecar-fluentd-es"

# move to top level of git repo, check dirty status
cd $(git rev-parse --show-toplevel)
set +e
git diff --quiet --ignore-submodules; is_dirty=$?
set -e

if [[ $is_dirty != 0 ]]
then
  echo "dirty: git repository $(pwd) has local changes"
fi

# override region with environment variable
AWS_REGION=${AWS_REGION:-us-east-1}
ECR_DOMAIN=191682557156.dkr.ecr.${AWS_REGION}.amazonaws.com


## fixed
# VERSION=0.2.3

## if unset, use tag
# VERSION=${VERSION:-$(git show -s --pretty=format:%h)}

## if unset, use changeset id
VERSION=${VERSION:-$(git describe --tags --always --dirty)}

## if unset, generate random
# VERSION=${VERSION:-$(openssl rand -base64 12 |md5 |head -c12;echo)}

function build {
  set +e
  time docker build -f "Dockerfile.$1" -t $1 .
  if [[ $? != 0 ]]
  then
    echo "BUILD $1 FAILED"
    exit
  fi
  set -e
}

function push {
  eval "$(aws ecr get-login --no-include-email)"
  FULL_IMAGE_NAME=${ECR_DOMAIN}/${1}:${VERSION}
  echo pushing $FULL_IMAGE_NAME
  docker tag ${1}  ${FULL_IMAGE_NAME}
  docker push  ${FULL_IMAGE_NAME}
}

for image_name in $IMAGE_NAMES
do
  build $image_name
done


PUSH=${1:-}
if [ "$PUSH" == "push" ]
then
  for image_name in $IMAGE_NAMES
  do
    push $image_name
  done
fi
