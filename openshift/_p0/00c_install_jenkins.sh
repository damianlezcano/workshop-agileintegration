#! /usr/bin/env bash

oc login https://$(minishift ip):8443 -u admin

oc new-project jenkins

# En OpenShift 3.11 no viene el template persistent
#oc create -f https://raw.githubusercontent.com/openshift/origin/release-3.11/examples/jenkins/jenkins-persistent-template.json

#oc new-build jenkins-ephemeral --binary --name custom-jenkins -n jenkins
#oc start-build custom-jenkins --from-dir=./jenkins/s2i --wait -n jenkins
#oc new-app --template=jenkins-persistent -p JENKINS_IMAGE_STREAM_TAG=custom-jenkins:latest -p VOLUME_CAPACITY=2Gi -p NAMESPACE=jenkins -n jenkins

#oc new-app --template=jenkins-ephemeral --name=jenkins -n jenkins

oc create secret generic repository-credentials --from-file=ssh-privatekey=./id_rsa --type=kubernetes.io/ssh-auth -n dev
oc label secret repository-credentials credential.sync.jenkins.openshift.io=true -n dev
oc annotate secret repository-credentials 'build.openshift.io/source-secret-match-uri-1=ssh://github.com/*' -n dev

oc create secret generic repository-credentials --from-file=ssh-privatekey=$HOME/.ssh/id_rsa --type=kubernetes.io/ssh-auth -n test
oc label secret repository-credentials credential.sync.jenkins.openshift.io=true -n test
oc annotate secret repository-credentials 'build.openshift.io/source-secret-match-uri-1=ssh://github.com/*' -n test

oc create secret generic repository-credentials --from-file=ssh-privatekey=$HOME/.ssh/id_rsa --type=kubernetes.io/ssh-auth -n jenkins
oc label secret repository-credentials credential.sync.jenkins.openshift.io=true -n jenkins


oc new-build jenkins:2 --binary --name custom-jenkins -n jenkins
oc start-build custom-jenkins --from-dir=./jenkins --wait -n jenkins
oc new-app --template=jenkins-persistent --name=jenkins -p JENKINS_IMAGE_STREAM_TAG=custom-jenkins:latest -p NAMESPACE=jenkins -p VOLUME_CAPACITY=2Gi -n jenkins


oc adm policy add-role-to-user edit system:serviceaccount:jenkins:jenkins -n dev
oc adm policy add-role-to-user edit system:serviceaccount:jenkins:jenkins -n test





#oc adm policy add-role-to-user admin system:serviceaccount:jenkins:jenkins -n dev
#oc adm policy add-role-to-user admin system:serviceaccount:jenkins:jenkins -n test

#oc adm policy add-role-to-user view developer -n dev
#oc adm policy add-role-to-user view developer -n test

#oc adm policy add-role-to-user edit developer -n jenkins

#oc policy add-role-to-group system:image-puller system:serviceaccounts:test -n openshift
#oc policy add-role-to-group system:image-puller system:serviceaccounts:test -n dev
