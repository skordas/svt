#!/bin/bash

##########################################################################################
## Author: skordas@redhat.com                                                           ##
## Description: Support script for project deletion test - check after test.            ##
## Test case: Project deletion when one of nodes where pods are running are down        ##
## Polarion Test case: OCP-18155                                                        ##
## https://polarion.engineering.redhat.com/polarion/#/project/OSE/workitem?id=OCP-18155 ##
##########################################################################################

# Variables are exported in ../project-deletion-test.sh or in PROW ref file.

number_of_expected_working_nodes=$1
wait_timeout=10 # Timeout in minutes
sleep_time=30 # Sleep time in seconds between checks.

function log {
    echo -e "[$(date "+%F %T")]: $*"
}

timeout=$(date -d "+$wait_timeout minutes" +%s)

while sleep $sleep_time; do
  if [[ $number_of_expected_working_nodes -eq $(oc get nodes | grep worker | grep -c Ready) ]]; then
    log "All nodes are back"
    break
  else
    if [[ $timeout < $(date +%s) ]]; then
      log "Not all nodes are ready"
      log "Test failed"
      oc get nodes
      oc get machineset -n openshift-machine-api
      oc get machines -n openshift-machine-api
      exit 1
    fi
    log "Sleep $sleep_time seconds before next check."
    continue
  fi
done
