#!/usr/bin/env bash

set -e

# Turn colors in this script off by setting the NO_COLOR variable in your
# environment to any value:
#
# $ NO_COLOR=1 test.sh
NO_COLOR=${NO_COLOR:-""}
if [ -z "$NO_COLOR" ]; then
  header=$'\e[1;33m'
  reset=$'\e[0m'
else
  header=''
  reset=''
fi

strimzi_version=`curl https://github.com/strimzi/strimzi-kafka-operator/releases/latest |  awk -F 'tag/' '{print $2}' | awk -F '"' '{print $1}' 2>/dev/null`

function header_text {
  echo "$header$*$reset"
}

header_text "Using Strimzi Version:                  ${strimzi_version}"

header_text "Strimzi install"
kubectl create namespace kafka
curl -L "https://github.com/strimzi/strimzi-kafka-operator/releases/download/${strimzi_version}/strimzi-cluster-operator-${strimzi_version}.yaml" \
  | sed 's/namespace: .*/namespace: kafka/' \
  | kubectl -n kafka create -f -

# Wait for the CRD we need to actually be active
kubectl wait crd --timeout=-1s kafkas.kafka.strimzi.io --for=condition=Established

header_text "Applying Strimzi Cluster file"
kubectl -n kafka create -f "https://raw.githubusercontent.com/strimzi/strimzi-kafka-operator/${strimzi_version}/examples/kafka/kafka-persistent-single.yaml"
header_text "Waiting for Strimzi to become ready"
kubectl wait kafka --all --timeout=-1s --for=condition=Ready -n kafka