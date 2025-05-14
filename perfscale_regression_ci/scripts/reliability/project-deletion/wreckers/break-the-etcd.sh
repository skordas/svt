#!/bin/bash

##########################################################################################
## Author: skordas@redhat.com                                                           ##
## Description: Support script for project deletion test.                               ##
## Test case: Project deletion when ETCD is down                                        ##
## Polarion Test case: OCP-18155                                                        ##
## https://polarion.engineering.redhat.com/polarion/#/project/OSE/workitem?id=OCP-18155 ##
##########################################################################################

# Variables exported in ../project-deletion-test.sh or in PROW ref file.
# MASTER_NODE_WITH_ETCD

no_xtrace=$1
sleep_time=5 # Sleep time in seconds between checks
wait_timeout=5 # Timeout in minutes

function log {
  echo -e "[$(date "+%F %T")]: $*"
}

function get_number_available_etcd_pods {
  number_of_pods=$(oc get pods -o wide -n openshift-etcd | grep "$MASTER_NODE_WITH_ETCD" | grep -c Running)
  echo "$number_of_pods"
}

if [[ $no_xtrace != "true" ]]; then
  set -x
fi

MASTER_NODE_WITH_ETCD=$(oc get nodes -o jsonpath='{.items[?(@.metadata.labels.node-role\.kubernetes\.io/master)].metadata.name}' | cut -d ' ' -f 1)
export MASTER_NODE_WITH_ETCD

NUMBER_OF_ETCD_PODS=get_number_available_etcd_pods
export NUMBER_OF_ETCD_PODS

# # Can't use jsonpath - can't filter by two variables.
# https://github.com/kubernetes/kubernetes/issues/20352
#
# oc get pods -n openshift-etcd -o jsonpath='{.items[?(@.metadata.labels.app=="guard" && @.spec.nodeName=="ip-10-0-15-91.us-west-1.compute.internal")].metadata.name}'
#
# oc get pods -n openshift-etcd -o json | jq -r '.items[] | select(.spec.nodeName=="ip-10-0-15-91.us-west-1.compute.internal" and .metadata.labels.app=="guard").metadata.name'
#
# oc get pods -n openshift-etcd -o json | jq -r '.items[] | select(.spec.nodeName=="$MASTER_NODE_WITH_ETCD" and .metadata.labels.app=="guard").status.containerStatuses[].ready'
# oc get pods -n openshift-etcd -o json | jq -r '.items[] | select(.spec.nodeName=="ip-10-0-15-91.us-west-1.compute.internal" and .metadata.labels.app=="guard").status.containerStatuses[].ready'
# true
log "Current available ETCD pods: $NUMBER_OF_ETCD_PODS"
log "Moving out etcd-pod manifest..."
oc debug node/"$MASTER_NODE_WITH_ETCD" -- chroot /host mv /etc/kubernetes/manifests/etcd-pod.yaml /root/

timeout=$(date -d "+$wait_timeout minutes" +%s)

while sleep $sleep_time; do
  available_etcd_pods=get_number_available_etcd_pods
  log "Current available ETCD pods: $available_etcd_pods"
  if [[ $available_etcd_pods -eq 0 ]]; then
    log "ETCD on $MASTER_NODE_WITH_ETCD node is down"
    log "Continue with the test..."
    break
  else
    if [[ $timeout < $(date +%s) ]]; then
      log "ETCD on $MASTER_NODE_WITH_ETCD node is not down"
      log "Test failed"
      exit 1
    fi
    log "Sleep $sleep_time seconds before next check."
  fi
done
