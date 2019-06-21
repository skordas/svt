#!/bin/bash

MEMORY_LIMIT=$(cat external_vars.yaml | grep MEMORY_LIMIT | cut -d ' ' -f 2)
#JUMP_HOST="${2}"
iteration=$(cat external_vars.yaml | grep iteration | cut -d ' ' -f 2)
test_project_name=$(cat external_vars.yaml | grep test_project_name | cut -d ' ' -f 2)
test_project_number=$(cat external_vars.yaml | grep test_project_number | cut -d ' ' -f 2)
delete_test_project_before_test=$(cat external_vars.yaml | grep delete_test_project_before_test | cut -d ' ' -f 2)
STORAGE_CLASS_NAME=$(cat external_vars.yaml | grep STORAGE_CLASS_NAME | cut -d ' ' -f 2)
VOLUME_CAPACITY=$(cat external_vars.yaml | grep VOLUME_CAPACITY | cut -d ' ' -f 2)
test_build_number=$(cat external_vars.yaml | grep test_build_number | cut -d ' ' -f 2)
jdk_username=$(cat external_vars.yaml | grep jdk_username | cut -d ' ' -f 2)
jdk_password=$(cat external_vars.yaml | grep jdk_password | cut -d ' ' -f 2)
tmp_folder=$(pwd)
JENKINS_IMAGE_STREAM_TAG=$(cat external_vars.yaml | grep JENKINS_IMAGE_STREAM_TAG | cut -d ' ' -f 2)

echo "Memory limit:                    $MEMORY_LIMIT"
echo "Iterations:                      $iteration"
echo "Test Project Name:               $test_project_name"
echo "Test Project number:             $test_project_number"
echo "Delete test project before test: $delete_test_project_before_test"
echo "Storage Class Name:              $STORAGE_CLASS_NAME"
echo "Volume Capacity                  $VOLUME_CAPACITY"
echo "Test build number:               $test_build_number"
echo "jdk username:                    $jdk_username"
echo "jdk password:                    $jdk_password"
echo "Temporary folder:                $tmp_folder"

#for sc in $(echo ${STORAGE_CLASS_NAMES} | sed -e s/,/" "/g); do
#  echo "===search-me: sc: ${sc}"
#  ansible-playbook -i "${JUMP_HOST}," jenkins-test.yaml \
#  --extra-vars "MEMORY_LIMIT=${MEMORY_LIMIT} test_project_name=${test_project_name} STORAGE_CLASS_NAME=${sc} iteration=${ITERATIONS} test_build_number=${test_build_number} test_project_number=${test_project_number} pbench_registration=${pbench_registration} pbench_copy_result=${pbench_copy_result} benchmark_timeout=${benchmark_timeout} jdk_username=${jdk_username} jdk_password=${jdk_password}"
#done

chmod +x files/scripts/*.sh

bash files/scripts/create-oc-objects.sh $test_project_name $test_project_number $tmp_folder $delete_test_project_before_test $MEMORY_LIMIT $VOLUME_CAPACITY $STORAGE_CLASS_NAME $JENKINS_IMAGE_STREAM_TAG
echo "Sleep 60 sec.."
sleep 60

bash files/scripts/test-jenkins-m.sh $test_project_name $test_project_number $iteration $tmp_folder $test_build_number 2>&1 | tee -a /tmp/test.log