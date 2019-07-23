#!/bin/bash

oc login https://prod-ocp-api.bue299.comafi.com.ar --token=vESXQ742ygSZsW95kxhNlFpHRrL6UcF_cn43D_MEs8o

#oc new-project prod-comafi-3scale --display-name="3scale API Management" --description="3scale API Management Platform"

oc project prod-comafi-3scale

oc create -f amp.yml -n prod-comafi-3scale

oc new-app --template=3scale-api-management -p ADMIN_PASSWORD=redhat01 -p WILDCARD_DOMAIN=prod-comafi-3scale.apps.bue299.comafi.com.ar -p WILDCARD_POLICY=Subdomain -n prod-comafi-3scale

#configuracion SMTP
oc patch configmap smtp -p '{"data":{"address":"relayapp.bue299.comafi.com.ar:25"}}'

oc rollout latest dc/system-app
oc rollout latest dc/system-sidekiq

# crear ruta desde la UI: 
# https://backend-noprod-admin.prod-comafi-3scale.apps.bue299.comafi.com.ar -> servicio: backend-listener
# https://backend-sandbox-admin.prod-comafi-3scale.apps.bue299.comafi.com.ar -> servicio: backend-listener

#--------------------------------------------------

#oc secret new-basicauth apicast-configuration-url-secret --password=https://c903ebd69db06c50332b2adbd05300f82f36829231da66e0abb5d45c0adc8826@noprod-admin.prod-comafi-3scale.apps.bue299.comafi.com.ar
#oc new-app --file apicast.yml
#oc env dc/apicast --overwrite BACKEND_ENDPOINT_OVERRIDE=https://backend-noprod-admin.prod-comafi-3scale.apps.bue299.comafi.com.ar
#oc new-app -f apicast.yml -p APICAST_NAME=apicast-staging -e BACKEND_ENDPOINT_OVERRIDE=https://backend-3scale.3scale.apps.openshift.ase.local -p DEPLOYMENT_ENVIRONMENT=staging -p CONFIGURATION_LOADER=lazy -n prod-comafi-noprod

oc new-project prod-comafi-noprod  --display-name="App - NoProd" --description="Namespace donde se configura el apicast para los ambientes no productivos"

oc create secret generic apicast-configuration-url-secret --from-literal=password=https://c903ebd69db06c50332b2adbd05300f82f36829231da66e0abb5d45c0adc8826@noprod-admin.prod-comafi-3scale.apps.bue299.comafi.com.ar --type=kubernetes.io/basic-auth -n prod-comafi-noprod
oc new-app -f apicast.yml --param BACKEND_ENDPOINT_OVERRIDE=https://backend-noprod-admin.prod-comafi-3scale.apps.bue299.comafi.com.ar -p DEPLOYMENT_ENVIRONMENT=staging -p CONFIGURATION_LOADER=lazy -n prod-comafi-noprod

#--------------------------------------------------

oc new-project prod-comafi-sandbox  --display-name="App - SandBox" --description="Ambiente para testing de metricas/politicas 3scale"

oc create secret generic apicast-configuration-url-secret --from-literal=password=https://bb254da6b6a1096341c0f2b73a83eda3ca0bbbcd01273c40e1d8c9e0592102c4@sandbox-admin.prod-comafi-3scale.apps.bue299.comafi.com.ar --type=kubernetes.io/basic-auth -n prod-comafi-sandbox
oc new-app -f apicast.yml --param BACKEND_ENDPOINT_OVERRIDE=https://backend-sandbox-admin.prod-comafi-3scale.apps.bue299.comafi.com.ar -p DEPLOYMENT_ENVIRONMENT=staging -p CONFIGURATION_LOADER=lazy -n prod-comafi-sandbox
