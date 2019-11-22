minishift setup-cdk
minishift config set skip-check-openshift-release true
minishift start --cpus=4 --memory=10GB --disk-size=30GB --skip-registration

#------------------------------------------

oc login https://$(minishift ip):8443 -u system:admin

oc policy add-role-to-user registry-viewer admin
oc policy add-role-to-user registry-editor admin

oc adm policy add-role-to-user admin admin -n default
oc adm policy add-role-to-user admin admin -n openshift

oc adm policy remove-scc-from-group anyuid system:authenticated

minishift openshift config set --patch '{"jenkinsPipelineConfig":{"autoProvisionEnabled":false}}'

export REPOSITORY_CREDENTIALS_USERNAME=damianlezcano
export REPOSITORY_CREDENTIALS_PASSWORD=xxxx

# instalación jenkins
#-------------------------------------------------------------------------------------------------

oc login https://$(minishift ip):8443 -u admin

oc new-project jenkins

oc create secret generic repository-credentials --from-literal=username=${REPOSITORY_CREDENTIALS_USERNAME} --from-literal=password=${REPOSITORY_CREDENTIALS_PASSWORD} --type=kubernetes.io/basic-auth -n jenkins
oc label secret repository-credentials credential.sync.jenkins.openshift.io=true -n jenkins

oc new-build jenkins:2 --binary --name custom-jenkins -n jenkins
oc start-build custom-jenkins --from-dir=./jenkins --wait -n jenkins
oc new-app --template=jenkins-persistent --name=jenkins -p JENKINS_IMAGE_STREAM_TAG=custom-jenkins:latest -p NAMESPACE=jenkins -p VOLUME_CAPACITY=2Gi -n jenkins


# creo ambientes DEV TEST PROD
#-------------------------------------------------------------------------------------------------

oc login https://$(minishift ip):8443 -u admin

oc new-project dev --display-name="DEV"

oc create secret generic repository-credentials --from-literal=username=${REPOSITORY_CREDENTIALS_USERNAME} --from-literal=password=${REPOSITORY_CREDENTIALS_PASSWORD} --type=kubernetes.io/basic-auth -n dev
oc label secret repository-credentials credential.sync.jenkins.openshift.io=true -n dev
oc annotate secret repository-credentials 'build.openshift.io/source-secret-match-uri-1=ssh://github.com/*' -n dev
oc adm policy add-role-to-user edit system:serviceaccount:jenkins:jenkins -n dev

oc create -f template-openshift-java-app-deploy.yaml -n dev


#oc new-project test --display-name="TEST"

#oc create secret generic repository-credentials --from-file=ssh-privatekey=$HOME/.ssh/id_rsa --type=kubernetes.io/ssh-auth -n test
#oc label secret repository-credentials credential.sync.jenkins.openshift.io=true -n test
#oc annotate secret repository-credentials 'build.openshift.io/source-secret-match-uri-1=ssh://github.com/*' -n test
#oc adm policy add-role-to-user edit system:serviceaccount:jenkins:jenkins -n test
#oc adm policy add-role-to-user edit system:serviceaccount:dev:jenkins -n test

#oc create -f template-openshift-java-app-deploy.yaml -n dev

#oc new-project prod --display-name="PROD"

#oc create secret generic repository-credentials --from-file=ssh-privatekey=$HOME/.ssh/id_rsa --type=kubernetes.io/ssh-auth -n prod
#oc label secret repository-credentials credential.sync.jenkins.openshift.io=true -n prod
#oc annotate secret repository-credentials 'build.openshift.io/source-secret-match-uri-1=ssh://github.com/*' -n prod
#oc adm policy add-role-to-user edit system:serviceaccount:jenkins:jenkins -n prod
#oc adm policy add-role-to-user edit system:serviceaccount:test:jenkins -n prod

#oc create -f template-openshift-java-app-deploy.yaml -n dev


# instalación SSO
#-------------------------------------------------------------------------------------------------

oc login https://$(minishift ip):8443 -u admin

oc new-project sso --display-name="Single Sign-On" --description="Single Sign-On"

openssl req -new -newkey rsa:4096 -x509 -keyout xpaas.key -out xpaas.crt -days 365 -subj "/CN=xpaas-sso-demo.ca"

keytool -genkeypair -keyalg RSA -keysize 2048 -dname "CN=secure-sso-sso.$(minishift ip).nip.io" -alias jboss -keystore keystore.jks

keytool -certreq -keyalg rsa -alias jboss -keystore keystore.jks -file sso.csr

openssl x509 -req -CA xpaas.crt -CAkey xpaas.key -in sso.csr -out sso.crt -days 365 -CAcreateserial

keytool -import -file xpaas.crt -alias xpaas.ca -keystore keystore.jks

keytool -import -file sso.crt -alias jboss -keystore keystore.jks

keytool -genseckey -alias secret-key -storetype JCEKS -keystore jgroups.jceks

keytool -import -file xpaas.crt -alias xpaas.ca -keystore truststore.jks

oc secret new sso-app-secret keystore.jks jgroups.jceks truststore.jks

oc secrets link default sso-app-secret

oc new-app -f sso72-postgresql-persistent.json -p SSO_ADMIN_USERNAME="admin" -p SSO_ADMIN_PASSWORD="redhat01" -n sso
 
# IMPORTANTE! importar los realms que se adjuntan (microks y apicurio)


# instalación apicurio studio
#-------------------------------------------------------------------------------------------------

oc login https://$(minishift ip):8443 -u admin

oc new-project apicurio-studio --display-name="Apicurio Studio" --description="Web-Based Open Source API Design via the OpenAPI specification."

oc new-app -f apicurio-standalone-template.yml -p UI_ROUTE=apicurio-studio-ui-apicurio-studio.$(minishift ip).nip.io -p API_ROUTE=apicurio-studio-api-apicurio-studio.$(minishift ip).nip.io -p WS_ROUTE=apicurio-studio-ws-apicurio-studio.$(minishift ip).nip.io -p AUTH_ROUTE=sso-sso.$(minishift ip).nip.io -n apicurio-studio

oc set env dc/apicurio-studio-api APICURIO_KC_AUTH_URL=http://sso-sso.$(minishift ip).nip.io/auth APICURIO_MICROCKS_API_URL=http://microcks-microcks.$(minishift ip).nip.io/api APICURIO_MICROCKS_CLIENT_ID=microcks-serviceaccount APICURIO_MICROCKS_CLIENT_SECRET=3f5f150c-272b-455b-8bce-d9d4f325cc10 -n apicurio-studio

oc set env dc/apicurio-studio-ui APICURIO_KC_AUTH_URL=http://sso-sso.$(minishift ip).nip.io/auth APICURIO_UI_HUB_API_URL=http://apicurio-studio-api-apicurio-studio.$(minishift ip).nip.io APICURIO_UI_EDITING_URL=ws://apicurio-studio-ws-apicurio-studio.$(minishift ip).nip.io APICURIO_UI_FEATURE_MICROCKS=true -n apicurio-studio

oc delete route apicurio-studio-api apicurio-studio-ui apicurio-studio-ws -n apicurio-studio

oc expose service apicurio-studio-api -n apicurio-studio
oc expose service apicurio-studio-ui -n apicurio-studio
oc expose service apicurio-studio-ws -n apicurio-studio


# instalación microcks
#-------------------------------------------------------------------------------------------------

oc login https://$(minishift ip):8443 -u admin

oc new-project microcks --display-name="Microcks" --description="A communication and runtime tool for API mocks"

oc create -f https://raw.githubusercontent.com/microcks/microcks/master/install/openshift/openshift-persistent-full-template.yml -n microcks

oc new-app --template=microcks-persistent --param=APP_ROUTE_HOSTNAME="microcks-microcks.$(minishift ip).nip.io" --param=KEYCLOAK_ROUTE_HOSTNAME="sso-sso.$(minishift ip).nip.io" --param=OPENSHIFT_MASTER="https://$(minishift ip).nip.io" --param=OPENSHIFT_OAUTH_CLIENT_NAME=microcks-client -n microcks

# instalación microckslight
#-------------------------------------------------------------------------------------------------

oc login https://$(minishift ip):8443 -u admin

cd microckslight

oc create configmap microckslight-configmap --from-file=./application.properties -n microcks

oc new-build --strategy docker --binary --docker-image fabric8/java-centos-openjdk8-jdk:1.5.1 --name microckslight -n microcks

oc start-build microckslight --from-dir=. -n microcks

oc new-app microckslight -e KEYCLOAK_URL=http://sso-sso.$(minishift ip).nip.io/auth -e JAVA_OPTIONS=-Dext.properties.file=file:///configMap/application.properties -e KEYCLOAL_REALM=microcks -e KEYCLOAL_CLIENT=microcks-app --allow-missing-imagestream-tags -n microcks

oc set volume dc/microckslight --add --name=microckslight-configmap --mount-path /configMap/application.properties --sub-path application.properties --source='{"configMap":{"name":"microckslight-configmap","items":[{"key":"application.properties","path":"application.properties"}]}}' -n microcks

oc patch dc/microckslight --type=json -p '[{"op": "add", "path": "/spec/template/spec/containers/0/volumeMounts/0/subPath", "value":"application.properties"}]' -n microcks

oc expose service microckslight -n microcks




# instalacion 3sclae
#-------------------------------------------------------------------------------------------------

oc login https://$(minishift ip):8443 -u admin

oc new-project 3scale --display-name="3scale API Management" --description="3scale API Management Platform"

oc create -f amp-eval-tech-preview.yml -n 3scale

oc new-app --template=3scale-api-management-eval -p ADMIN_PASSWORD=redhat01 -p WILDCARD_DOMAIN=3scale.$(minishift ip).nip.io -p WILDCARD_POLICY=Subdomain -n 3scale

































# inicio backend y frontend

oc new-app --template java-app-deploy -p APP_NAME=backend-service -p GIT_REPO=https://github.com/damianlezcano/moneda-backend.git -p GIT_BRANCH=master -n dev
oc new-app --template java-app-deploy -p APP_NAME=frontend -p GIT_REPO=https://github.com/damianlezcano/moneda-frontend.git -p GIT_BRANCH=master -e uri=https://microckslight-secure-microcks.$(minishift ip).nip.io/rest/Moneda/1.0.0-SNAPSHOT -n dev



#oc new-app -f template-openshift-java-app-deploy.yaml -p APP_NAME=backend-service -p GIT_REPO=https://github.com/damianlezcano/moneda-backend.git -p GIT_BRANCH=master -n dev
#oc new-app -f template-openshift-java-app-deploy.yaml -p APP_NAME=backend-service -p GIT_REPO=https://github.com/damianlezcano/moneda-backend.git -p GIT_BRANCH=master -n dev

#oc new-app --template deploy-java-app -p APP_NAME=backend-service -p GIT_REPO=ssh://git@github.com/damianlezcano/moneda-backend.git -p GIT_BRANCH=master -n dev
#oc new-app --template ci-pipeline -p APP_NAME=frontend-service-ci -p GIT_REPO=ssh://git@github.com/damianlezcano/moneda-frontend.git -p GIT_BRANCH=master -e uri=http://backend-service-ci-dev.$(minishift ip).nip.io -n dev
#oc new-app --template cd-pipeline -p APP_NAME=backend-service-cd -p GIT_REPO=ssh://git@github.com/damianlezcano/moneda-backend.git -n dev
#oc new-app --template cd-pipeline -p APP_NAME=frontend-service-cd -p GIT_REPO=ssh://git@github.com/damianlezcano/moneda-frontend.git -e uri=http://backend-service-cd-dev.$(minishift ip).nip.io -n dev

#oc new-app --template cd-pipeline -p APP_NAME=backend-service-cd -p GIT_REPO=ssh://git@github.com/damianlezcano/moneda-backend.git -n test
#oc new-app --template cd-pipeline -p APP_NAME=frontend-service-cd -p GIT_REPO=ssh://git@github.com/damianlezcano/moneda-frontend.git -e uri=http://backend-service-cd-dev.$(minishift ip).nip.io -n test

#oc new-app --template cd-pipeline -p APP_NAME=backend-service-cd -p GIT_REPO=ssh://git@github.com/damianlezcano/moneda-backend.git -n prod
#oc new-app --template cd-pipeline -p APP_NAME=frontend-service-cd -p GIT_REPO=ssh://git@github.com/damianlezcano/moneda-frontend.git -e uri=http://backend-service-cd-dev.$(minishift ip).nip.io -n prod

#modificar ruta apicurio a microckslight

#oc project apicurio-studio

#oc set env dc/apicurio-studio-api APICURIO_MICROCKS_API_URL=http://microckslight-microcks.$(minishift ip).nip.io/api