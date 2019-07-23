#! /usr/bin/env bash

oc login https://ocp01-noprod-api.pro.edenor -u admin -p redhat01

oc rollout pause dc/jenkins -n jenkins

oc set env dc/jenkins SRC_REGISTRY_URL=${SRC_REGISTRY_URL} -n jenkins
oc set env dc/jenkins DST_REGISTRY_URL=${DST_REGISTRY_URL} -n jenkins
oc set env dc/jenkins DST_CLUSTER_URL=${DST_CLUSTER_URL} -n jenkins
oc set env dc/jenkins DST_CLUSTER_TOKEN=${DST_CLUSTER_TOKEN} -n jenkins
oc set env dc/jenkins PIPELINE_LIBRARY_REPOSITORY=${PIPELINE_LIBRARY_REPOSITORY} -n jenkins
oc set env dc/jenkins PIPELINE_LIBRARY_REPOSITORY_CREDENTIALS=${PIPELINE_LIBRARY_REPOSITORY_CREDENTIALS} -n jenkins
oc set env dc/jenkins SRC_REGISTRY_CREDENTIALS=${SRC_REGISTRY_CREDENTIALS} -n jenkins
oc set env dc/jenkins DST_REGISTRY_CREDENTIALS=${DST_REGISTRY_CREDENTIALS} -n jenkins

oc create secret generic src-registry-credentials --from-literal=username=unused --from-literal=password=${SRC_REGISTRY_TOKEN} --type=kubernetes.io/basic-auth -n jenkins
oc label secret src-registry-credentials credential.sync.jenkins.openshift.io=true -n jenkins

oc create secret generic dst-registry-credentials --from-literal=username=unused --from-literal=password=${DST_REGISTRY_TOKEN} --type=kubernetes.io/basic-auth -n jenkins
oc label secret dst-registry-credentials credential.sync.jenkins.openshift.io=true -n jenkins

oc create secret generic pipeline-library-repository-credentials --from-literal=username=${PIPELINE_LIBRARY_REPOSITORY_CREDENTIALS_USERNAME} --from-literal=password=${PIPELINE_LIBRARY_REPOSITORY_CREDENTIALS_PASSWORD} --type=kubernetes.io/basic-auth -n jenkins
oc label secret pipeline-library-repository-credentials credential.sync.jenkins.openshift.io=true -n jenkins
oc annotate secret pipeline-library-repository-credentials 'build.openshift.io/source-secret-match-uri-1=https://github.com/*' -n jenkins

oc rollout resume dc/jenkins -n jenkins



# Grants view access to developer in uat project
oc adm policy add-role-to-user edit developer -n esb-test
oc adm policy add-role-to-user view developer -n esb-uat
oc adm policy add-role-to-user view developer -n esb-prod-management
oc adm policy add-role-to-user edit developer -n jenkins

# Grants edit access to jenkins service account
oc policy add-role-to-user edit system:serviceaccount:jenkins:jenkins -n esb-dev
oc policy add-role-to-user edit system:serviceaccount:jenkins:jenkins -n esb-test
oc policy add-role-to-user edit system:serviceaccount:jenkins:jenkins -n esb-uat
oc policy add-role-to-user edit system:serviceaccount:jenkins:jenkins -n esb-prod-management

# Allows prod service account the ability to pull images from dev
oc policy add-role-to-group system:image-puller system:serviceaccounts:esb-test -n esb-dev
oc policy add-role-to-group system:image-puller system:serviceaccounts:esb-uat -n esb-dev
oc policy add-role-to-group system:image-puller system:serviceaccounts:esb-prod-management -n esb-dev