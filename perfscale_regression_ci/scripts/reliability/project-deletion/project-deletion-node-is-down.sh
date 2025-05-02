#!/bin/bash

##########################################################################################
## Author: skordas@redhat.com                                                           ##
## Description: Test for deleting projects when node where pods are running is down.    ##
## Polarion Test case: OCP-18155                                                        ##
## https://polarion.engineering.redhat.com/polarion/#/project/OSE/workitem?id=OCP-18155 ##
##########################################################################################

### TODO - REMOVE THIS SECTION BEFORE PR ###
# - [x] add exports - or just get the names from exported variables.
# - [x] Load the cluster
# - [ ] get node to put down
# - [ ] check if on that node is down
# - [ ] remove the node - (delete machine)
# - [x] start deletion
# - [x] add timeout for deletion
# - [ ] check if everything is deleted - if not - Test Failed.
# - [ ] check if all nodes are back - if not - Test Failed.
############### END OF TODO ################

# NAME - used for labeling project
# NAMESPACE - name for projects
# PARAMETERS - number of projects to delete
# DELETION_TIMEOUT - Time out for deletion of projects in minutes

set -ex

export NAME=${NAME:-"project-deletion-node-is-down"}
export NAMESPACE=${NAMESPACE:-"project-to-delete"}
export PARAMETERS=${PARAMETERS:-15}
export DELETION_TIMEOUT=${DELETION_TIMEOUT:-2}

echo "Loading cluster"
pushd ../../scalability/ || exit

./loaded-projects.sh

popd || exit

echo "sleep 5"
sleep 5

echo "Deleting projects"

oc project default
oc delete project -l kube-burner-job="$NAME" --wait=false

timeout=$(date -d "+$DELETION_TIMEOUT minutes" +%s)
while (( $timeout > $(date +%s) )); do
	oc get projects | grep -c Terminating
	echo $?
	sleep 5
done
