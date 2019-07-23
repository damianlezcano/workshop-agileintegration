#!/bin/bash

oc login https://$(minishift ip):8443 -u admin

oc new-project microcks --display-name="Microcks" --description="A communication and runtime tool for API mocks"

oc create -f https://raw.githubusercontent.com/microcks/microcks/master/install/openshift/openshift-persistent-full-template.yml 

oc new-app --template=microcks-persistent --param=APP_ROUTE_HOSTNAME="microcks-microcks.$(minishift ip).nip.io" --param=KEYCLOAK_ROUTE_HOSTNAME="keycloak-sso.$(minishift ip).nip.io" --param=OPENSHIFT_MASTER="https://$(minishift ip).nip.io" --param=OPENSHIFT_OAUTH_CLIENT_NAME=microcks-client

#instalamos microckslight

cd microckslight

oc create configmap microckslight-configmap --from-file=./application.properties

oc new-build --strategy docker --binary --docker-image fabric8/java-centos-openjdk8-jdk:1.5.1 --name microckslight
# creo una carpeta build con el dockerFile y el jar
oc start-build microckslight --from-dir=.

oc new-app microckslight -e KEYCLOAK_URL=http://keycloak-sso.$(minishift ip).nip.io/auth -e JAVA_OPTIONS=-Dext.properties.file=file:///configMap/application.properties -e KEYCLOAL_REALM=microcks -e KEYCLOAL_CLIENT=microcks-app

oc set volume dc/microckslight --add --name=microckslight-configmap --mount-path /configMap/application.properties --sub-path application.properties --source='{"configMap":{"name":"microckslight-configmap","items":[{"key":"application.properties","path":"application.properties"}]}}'
oc patch dc/microckslight --type=json -p '[{"op": "add", "path": "/spec/template/spec/containers/0/volumeMounts/0/subPath", "value":"application.properties"}]'

oc expose service microckslight

#modificar ruta apicurio a microckslight

oc project apicurio-studio

oc set env dc/apicurio-studio-api APICURIO_MICROCKS_API_URL=http://microckslight-microcks.$(minishift ip).nip.io/api