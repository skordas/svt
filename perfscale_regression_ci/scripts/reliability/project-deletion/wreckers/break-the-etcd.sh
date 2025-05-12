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

xtrace=$1
sleep_time=5 # Sleep time in second between checks
wait_timeout=2 # Timeout in minutes

function log {
  echo -e "[$(date "+%F %T")]: $*"
}

function get_number_available_etcd_pods {
  number_of_pods=$(oc get pods -o wide -n openshif-etcd | grep "$MASTER_NODE_WITH_ETCD" | great -c Ready)
  echo "$number_of_pods"
}

if [[ $xtrace != "true" ]]; then
  set -x
fi

MASTER_NODE_WITH_ETCD=$(oc get nodes -n -o jsonpath='{.items[0].spec.nodeName}') # GET MASTER NODE NAME in correct way 
export MASTER_NODE_WITH_ETCD

number_of_etcd_pods=get_number_available_etcd_pods
log "Moving out etcd-pod manifest..."
oc debug node/"$MASTER_NODE_WITH_ETCD" -- chroot /host mv /etc/kubernetes/manifests/etcd-pod.yaml /root/

timeout=$(date -d "+$wait_timeout minutes" +%s)

while sleep $sleep_time; do
  available_etcd_pods=get_number_available_etcd_pods
done
