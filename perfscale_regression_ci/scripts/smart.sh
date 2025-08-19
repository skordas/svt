#!/bin/bash

echo -e "This is a smart scritp to support a proof"
echo -e "A change in https://github.com/openshift/release"
echo -e "This script should be never merged into SVT repository"
echo -e "And it should die after merge of release branch"
echo -e "Made by and for: skordas"

echo -e "-----------------------------------------------"
echo -e "Let's check if we have connection with cluster:"
echo -e ""
oc get clusterversion
echo -e ""
oc get nodes -o wide
echo -e ""
oc get co
echo -e "-----------------------------------------------"
echo -e "If you this script got all info - it means we can run it every other scipt in way we want."
