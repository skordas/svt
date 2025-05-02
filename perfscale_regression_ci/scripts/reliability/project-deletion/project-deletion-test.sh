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
# - [x] remove the node - (delete machine)
# - [x] check if on that node is down
# - [x] check if all nodes are back - if not - Test Failed.
# - [x] Add something for logging instead of echo:
# - [x] Check if all steps are in correct order
# - [x] Change set -x as parrametter - will be used in prow - not here. - to not make mess - ex. if $2 is true - then do not set up
# - [ ] change for some timouts to be more realistic.
# - [ ] check all logs - to not leave some silliness 
# - [ ] With every new added test - add description into header of this script.
# - [ ] add test when master-api is down or etcd
# - [ ] add test when builds are in progress
# - [ ] add test when changing machineset - probably this one is covered by the first one - when node is not available.
# - [ ] remove passing number_or_running_worker_nodes into break the macihne script - remove it also in the script
# - [ ] add info at the end that we finished whole test with sucess
# - [ ] add some info into break the machine recovery info that we expecting at the beggining (add log)
# - [ ] add log if failed - info about passed time
############### END OF TODO ################

test=$1
xtrace=$2
tests=("delete_node")

if [[ $xtrace != "true" ]]; then
  set -x
fi

set -e

function log {
    echo -e "[$(date "+%F %T")]: $*"
}

## STEP 0 - before - checking if correct parameters is passed
if [[ ${tests[*]} =~ $test ]]; then
	log "========  Test to run: $test  ===="
else
	log "Please read the description of the script and pass correct parameter"
	exit 1
fi

declare number_or_running_worker_nodes # used for test when node where pods are is not available

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
log "Loading cluster...."
pushd ../../scalability/ || exit
./loaded-projects.sh
popd || exit

## STEP 2 - Break something!
case $test in
	delete_node)
		log "Running test: Delete projects - node where pods are running is down."
	  number_or_running_worker_nodes=$(oc get nodes | grep worker | grep -c Ready)
		./break-the-machine.sh "$number_or_running_worker_nodes"
		;;
esac

## STEP 3 - Delete projects
log "Deleting projects..."

oc project default
oc delete project -l kube-burner-job="$NAME" --wait=false

timeout=$(date -d "+$DELETION_TIMEOUT minutes" +%s)

set +e
while sleep $sleep_time; do
	number_of_terminating_projects=$(oc get projects | grep -c Terminating)
	log "Number of Terminating projects: $number_of_terminating_projects"
	if [[ $number_of_terminating_projects -eq 0 ]]; then
		log "All projects are deleted!"
		log "Continue with test..."
    break
  else
  	if [[ $timeout < $(date +%s) ]]; then
  		log "Not all project were deleted"
  		log "Test failed!"
  		exit 1
  	fi
  	log "Sleep $sleep_time seconds before next check."
  	continue
	fi
done
set -e

## STEP 4 - Be sure what you broke before deletion will work fine before moving forward.
case $test in
  delete_node)
  	log "Checking if all nodes are available."
  	./break-the-machine-recovery.sh "$number_or_running_worker_nodes"
  	;;
esac

