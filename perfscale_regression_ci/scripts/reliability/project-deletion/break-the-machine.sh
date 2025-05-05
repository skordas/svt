#!/bin/bash

##########################################################################################
## Author: skordas@redhat.com                                                           ##
## Description: Support script for project deletion test.                               ##
## Test case: Project deletion when one of nodes where pods are running are down        ##
## Polarion Test case: OCP-18155                                                        ##
## https://polarion.engineering.redhat.com/polarion/#/project/OSE/workitem?id=OCP-18155 ##
##########################################################################################

# Variables are exported in ./project-deletion-test.sh or in PROW ref file.

echo "Getting machine where pods is running"
node_name=$(oc get pods -n "${NAMESPACE}-1" -o jsonpath='{.items[0].spec.nodeName}')
echo "Node to delete: $node_name"
machine_name=$(oc get nodes -o jsonpath="{.items[?(@.metadata.name=='$node_name')].metadata.annotations.machine\.openshift\.io/machine}")
machine_name=$(echo "$machine_name" | cut -f 2 -d "/")
echo "Machine to delete $machine_name"
oc delete machine "$machine_name" -n openshift-machine-api --wait=false
oc get machines -n openshift-machine-api
oc get nodes
