#!/bin/bash

oc login https://$(minishift ip):8443 -u admin

oc new-project apicurio-studio --display-name="Apicurio Studio" --description="Web-Based Open Source API Design via the OpenAPI specification."

oc create -f https://raw.githubusercontent.com/Apicurio/apicurio-studio/master/distro/openshift/apicurio-standalone-template.yml

oc new-app --template=apicurio-studio-standalone -p UI_ROUTE=apicurio-studio-ui-apicurio-studio.$(minishift ip).nip.io -p API_ROUTE=apicurio-studio-api-apicurio-studio.$(minishift ip).nip.io -p WS_ROUTE=apicurio-studio-ws-apicurio-studio.$(minishift ip).nip.io -p AUTH_ROUTE=keycloak-sso.$(minishift ip).nip.io

#------------------------------------

oc set env dc/apicurio-studio-api APICURIO_KC_AUTH_URL=http://keycloak-sso.$(minishift ip).nip.io/auth APICURIO_MICROCKS_API_URL=http://microcks-microcks.$(minishift ip).nip.io/api APICURIO_MICROCKS_CLIENT_ID=microcks-serviceaccount APICURIO_MICROCKS_CLIENT_SECRET=a0b1a49f-3f3c-4ca4-ae5b-4b75c6ec52a9

oc set env dc/apicurio-studio-ui APICURIO_KC_AUTH_URL=http://keycloak-sso.$(minishift ip).nip.io/auth APICURIO_UI_HUB_API_URL=http://apicurio-studio-api-apicurio-studio.$(minishift ip).nip.io APICURIO_UI_EDITING_URL=ws://apicurio-studio-ws-apicurio-studio.$(minishift ip).nip.io APICURIO_UI_FEATURE_MICROCKS=true

oc delete route apicurio-studio-api apicurio-studio-ui apicurio-studio-ws

oc expose service apicurio-studio-api
oc expose service apicurio-studio-ui
oc expose service apicurio-studio-ws