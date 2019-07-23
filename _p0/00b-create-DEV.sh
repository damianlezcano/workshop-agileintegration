oc login https://$(minishift ip):8443 -u admin

oc new-project dev --display-name="DEV"
oc new-project test --display-name="TEST"

#oc new-app -f template.yaml -p APP_NAME=backend -p GIT_REPO=https://github.com/damianlezcano/moneda-backend.git

#oc new-build https://github.com/damianlezcano/openshift-hello-service.git --name=hello-service-ci-pipeline --strategy=pipeline -e APP_NAME=hello-service-ci -n dev

#oc new-app --template ci-pipeline -p APP_NAME=hello-service-ci -p GIT_REPO=https://github.com/damianlezcano/openshift-hello-service.git -p GIT_BRANCH=master -n hello-dev

#oc new-build https://github.com/damianlezcano/moneda-backend.git --strategy pipeline --name backend-pipeline -n dev

#oc new-build https://github.com/damianlezcano/openshift-hello-service.git --strategy pipeline --name hello-service-pipeline -n dev

#oc new-build https://github.com/damianlezcano/moneda-backend.git --name=backend-pipeline --strategy=pipeline -e APP_NAME=backend -n test


oc create -f ./templates/ci-pipeline.yaml -n dev
oc new-app --template ci-pipeline -p APP_NAME=backend-service-ci -p GIT_REPO=ssh://git@github.com/damianlezcano/moneda-backend.git -p GIT_BRANCH=master -n hello-dev

oc new-app --template ci-pipeline -p APP_NAME=frontend-service-ci -p GIT_REPO=ssh://git@github.com/damianlezcano/moneda-frontend.git -p GIT_BRANCH=master -e port=8080 -e uri=http://backend-service-ci-hello-dev.192.168.64.6.nip.io -n hello-dev
