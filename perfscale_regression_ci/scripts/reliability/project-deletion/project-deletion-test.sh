#!/bin/bash

##########################################################################################
## Author: skordas@redhat.com                                                           ##
## Description: Tests for deleting priojects under different conditions.                ##
## Polarion Test case: OCP-18155                                                        ##
## https://polarion.engineering.redhat.com/polarion/#/project/OSE/workitem?id=OCP-18155 ##
## Run:                                                                                 ##
## ./project-deletion-test.sh delete_node                                               ##
##           to run test project deletion where node where pods are running are down    ##
##########################################################################################

### TODO - REMOVE THIS SECTION BEFORE PR ###
# - [x] add exports - or just get the names from exported variables.
# - [x] Load the cluster
# - [x] get number of nodes before test - to compare after test
# - [x] get node to put down
# - [ ] check if on that node is down
# - [ ] remove the node - (delete machine)
# - [x] start deletion
# - [x] add timeout for deletion
# - [ ] check if everything is deleted - if not - Test Failed.
# - [ ] check if all nodes are back - if not - Test Failed.
# - [ ] Add something for logging instead of echo:
# - [ ] Check if all steps are in correct order
# - [ ] Remove comment from set -x
# - [ ] Change set -x as parrametter - will be used in prow - not here.
# - [ ] change for some timouts to be more realistic.
# - [ ] check all logs - to not leave some silliness 
############### END OF TODO ################

set -x
set -e

test=$1
tests=("delete_node")

## STEP 0 - before - checking if correct parameters is passed
if [[ ${tests[*]} =~ $test ]]; then
	echo "OK"
else
	echo "Please read the description of the script and pass correct parameter"
	exit 1
fi

# NAME - used for labeling project
# NAMESPACE - name for projects
# PARAMETERS - number of projects to delete
# DELETION_TIMEOUT - Time out for deletion of projects in minutes

export NAME=${NAME:-"project-deletion-tests"}
export NAMESPACE=${NAMESPACE:-"project-to-delete"}
export PARAMETERS=${PARAMETERS:-15}
export DELETION_TIMEOUT=${DELETION_TIMEOUT:-2}

# Sleep time in seconds between checks
sleep_time=5

## STEP 1 - Load cluster
echo "Loading cluster"
pushd ../../scalability/ || exit
./loaded-projects.sh
popd || exit

## STEP 2 - Break something!
case $test in
	delete_node)
		echo "Running test, when node, where pods are running is down"
	  number_or_running_worker_nodes=$(oc get nodes | grep worker | grep -c Ready)
		./break-the-machine.sh
		;;
esac

## STEP 3 - Delete projects
echo "Deleting projects"

oc project default
oc delete project -l kube-burner-job="$NAME" --wait=false

timeout=$(date -d "+$DELETION_TIMEOUT minutes" +%s)

set +e
while sleep $sleep_time; do
	number_of_terminating_projects=$(oc get projects | grep -c Terminating)
	echo "Number of Terminating projects: $number_of_terminating_projects"
	if [[ $number_of_terminating_projects -eq 0 ]]; then
		echo "All projects are deleted!"
		echo "Continue with test"
    break
  else
  	if [[ $timeout < $(date +%s) ]]; then
  		echo "Not all project were deleted"
  		echo "Test failed!"
  		exit 1
  	fi
  	echo "Sleep $sleep_time before next check."
  	continue
	fi
done
set -e

## STEP 4 - Be sure what you brake before deletion will work fine before moving forward.
case $test in
  delete_node)
  	echo "Checking if all nodes are available."
  	./break-the-machine-recovery.sh "$number_or_running_worker_nodes"
  	;;
esac

