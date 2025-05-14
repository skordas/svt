#!/bin/bash

##########################################################################################
## Author: skordas@redhat.com                                                           ##
## Description: Tests for deleting priojects under different conditions.                ##
## Polarion Test case: OCP-18155                                                        ##
## https://polarion.engineering.redhat.com/polarion/#/project/OSE/workitem?id=OCP-18155 ##
## Run:                                                                                 ##
## ./project-deletion-test.sh delete_node                                               ##
##           to run test project deletion where node where pods are running are down    ##
##                                                                                      ##
## set 'true' as a second parameter to not print comands as they are executed           ##  
##########################################################################################

### TODO - REMOVE THIS SECTION BEFORE PR ###
# - [ ] in break the etcd script figure out how to get name of master node.
# - [ ] Script etcd is down!
# - [ ] Check if all ETCD can be down.
# - [ ] add test when builds are in progress
# - [ ] add test when changing machineset - probably this one is covered by the first one - when node is not available.
# - [ ] add step in wreckers - at the beginning - log the thing which will be done in this script
# - [ ] check all logs - to not leave some silliness 
# - [ ] With every new added test - add description into header of this script.
# - [ ] Instead of getting value of number_or_running_worker_nodes - export that value in script to be available to all subprocesses 
#       and store that as 'global' variable.
# - [ ] Continue with THE test not just test.
# - [ ] check exit code of every break script - if something wrong - then finish the test before even running it
# - [ ] add clean up script - add it before loading cluster - that can be some leftovers
# - [ ] Add 'timeout' comment to log when it is happening - not only Test failed - explain that timeout finished the script
############### END OF TODO ################

test=$1
no_xtrace=$2
tests=("delete_node" "etcd_is_down")

declare sleep_time=5 # Sleep time in seconds between checks
declare number_or_running_worker_nodes # used for test when node where pods are is not available
export delete_project_test_passed=false # To store main test result through the script.

export MASTER_NODE_WITH_ETCD="" # Used for passing name of master node with ETCD to put down - later used in recovery script.
export NUMBER_OF_ETCD_PODS="" # Used for passing number of ETCD nodes - later used in recovery script. 
export NAME=${NAME:-"project-deletion-tests"} # Used for labeling project
export NAMESPACE=${NAMESPACE:-"project-to-delete"} # Name for projects
export PARAMETERS=${PARAMETERS:-15} # Number of projects to delete
export DELETION_TIMEOUT=${DELETION_TIMEOUT:-5} # Time out for deletion of projects in minutes

function log {
  echo -e "[$(date "+%F %T")]: $*"
}

if [[ $no_xtrace != "true" ]]; then
  set -x
fi

## STEP 0 - before - checking if correct parameter is passed
if [[ ${tests[*]} =~ $test ]]; then
	log "========  Test to run: $test  ========"
else
	log "Please read the description of the script and pass correct parameter"
	exit 1
fi

## STEP 1 - Load cluster
log "Loading cluster...."
pushd ../../scalability/ || exit
./loaded-projects.sh
popd || exit

## STEP 2 - Break something!
case $test in
	delete_node)
		log "Running test: Delete projects - node where pods are running is down."
	  number_or_running_worker_nodes=$(oc get nodes | grep worker | grep -c Ready)
		./wreckers/break-the-machine.sh "$no_xtrace"
		;;
	etcd_is_down)
		log "Running test: Delete projects - one of etcd is down"
		./wreckers/break-the-etcd.sh "$no_xtrace"
		;;
esac

## STEP 3 - Delete projects
log "Deleting projects..."
oc project default
oc delete project -l kube-burner-job="$NAME" --wait=false

timeout=$(date -d "+$DELETION_TIMEOUT minutes" +%s)

while sleep $sleep_time; do
	number_of_terminating_projects=$(oc get projects | grep -c Terminating)
	log "Number of Terminating projects: $number_of_terminating_projects"
	if [[ $number_of_terminating_projects -eq 0 ]]; then
		delete_project_test_passed=true
		log "All projects are deleted!"
		log "Continue with test..."
    break
  else
  	if [[ $timeout < $(date +%s) ]]; then
  		log "Not all project were deleted"
  		log "!!!!!!!!  Test failed  !!!!!!!!"
  	fi
  	log "Sleep $sleep_time seconds before next check."
  	continue
	fi
done

## STEP 4 - Be sure what you broke before deletion will work fine before moving forward.
case $test in
  delete_node)
  	log "Checking if all nodes are available."
  	./wreckers/break-the-machine-recovery.sh "$number_or_running_worker_nodes" "$no_xtrace"
  	;;
  etcd_is_down)
  	log "Recover ETCD failover"
  	./wreckers/break-the-etcd-recovery.sh "$no_xtrace"
  	;;
esac

## STEP 5 - after - verification of results
if [[ $delete_project_test_passed == true ]]; then
	log "TEST: $test PASSED!!!"
	log "========     END OF THE TEST     ========"
else
	log "TEST: $test FAILED!!!"
  oc get projects
  oc get nodes
  oc get machineset -n openshift-machine-api
  oc get machines -n openshift-machine-api
  exit 1
fi

