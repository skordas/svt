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

xtrace=$1

function log {
    echo -e "[$(date "+%F %T")]: $*"
}

if [[ $xtrace != "true" ]]; then
  set -x
fi

log "Moving back etcd-pod manifest..."
oc debug node/"$MASTER_NODE_WITH_ETCD" -- chroot /host mv /root/etcd-pod.yaml /etc/kubernetes/manifests/
