#!/bin/bash

echo -e "THIS IS A DUMMY SCRIPT TO SUPPORT PROOF"
echo -e "A CHANGI IN https://github.com/openshift/release"
echo -e "THIS SCIRPT SHOULD BE NEVER BE MERGED INTO SVT REPO"
echo -e "AND IT SHOUD DIE AFTER MERGE TO MASTER OF RELEASE BRANCH"
echo -e "Made by and for: skordas"

echo -e "-----------------------------------------------"
echo -e "Let's check if we have connection with cluster:"
echo -e ""
oc get clusterversion
echo -e ""
oc get nodes
echo -e ""
oc get co
echo -e "-----------------------------------------------"
echo -e "IF YOU HAVE CONNECTION WITH OCP YOU ARE GOOD"
