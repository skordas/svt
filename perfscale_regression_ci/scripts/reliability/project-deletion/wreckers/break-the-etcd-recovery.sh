#!/bin/bash

##########################################################################################
## Author: skordas@redhat.com                                                           ##
## Description: Support script for project deletion test - check after test.            ##
## Test case: Project deletion when ETCD is down                                        ##
## Polarion Test case: OCP-18155                                                        ##
## https://polarion.engineering.redhat.com/polarion/#/project/OSE/workitem?id=OCP-18155 ##
##########################################################################################

# Variables exported in ../project-deletion-test.sh or in PROW ref file.
# MASTER_NODE_WITH_ETCD

no_xtrace=$1
sleep_time=5 # Sleep time in seconds between checks.
wait_timeout=5 # Timeout in minutes

function log {
  echo -e "[$(date "+%F %T")]: $*"
}

function get_number_available_etcd_pods {
  number_of_pods=$(oc get pods -o wide -n openshif-etcd | grep "$MASTER_NODE_WITH_ETCD" | great -c Ready)
  echo "$number_of_pods"
}

if [[ $no_xtrace != "true" ]]; then
  set -x
fi

log "Moving back etcd-pod manifest..."
oc debug node/"$MASTER_NODE_WITH_ETCD" -- chroot /host mv /root/etcd-pod.yaml /etc/kubernetes/manifests/

timeout=$(date -d "+$wait_timeout minutes" +%s)

while sleep $sleep_time; do
  available_etcd_pods=get_number_available_etcd_pods
  if [[ $available_etcd_pods -eq $NUMBER_OF_ETCD_PODS ]]; then
    log "ETCD on $MASTER_NODE_WITH_ETCD node is up again"
    log "Continue with test..."
    break
  else
    if [[ $timeout < $(date +%s) ]]; then
      log "ETCD on $MASTER_NODE_WITH_ETCD node is not up!"
      log "Test failed"
      exit 1
    fi
    log "Sleep $sleep_time seconds before next check"
  fi
done
