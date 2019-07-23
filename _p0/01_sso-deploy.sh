#!/bin/bash

oc login https://$(minishift ip):8443 -u admin

oc new-project sso --display-name="Single Sign-On" --description="Single Sign-On"

oc new-app -f https://raw.githubusercontent.com/jboss-dockerfiles/keycloak/master/openshift-examples/keycloak-https.json -p NAMESPACE=keycloak -p KEYCLOAK_USER=admin -p KEYCLOAK_PASSWORD=redhat01