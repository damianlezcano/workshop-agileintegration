oc login https://$(minishift ip):8443 -u admin

oc new-app --template ci-pipeline -p APP_NAME=backend-service-ci -p GIT_REPO=ssh://git@github.com/damianlezcano/moneda-backend.git -p GIT_BRANCH=master -n rh-dev
oc new-app --template cd-pipeline -p APP_NAME=backend-service-cd -p GIT_REPO=ssh://git@github.com/damianlezcano/moneda-backend.git -n rh-dev

oc new-app --template ci-pipeline -p APP_NAME=frontend-service-ci -p GIT_REPO=ssh://git@github.com/damianlezcano/moneda-frontend.git -p GIT_BRANCH=master -e uri=http://microcks-microcks.$(minishift ip).nip.io/rest/Moneda/1.0 -n rh-dev
oc new-app --template cd-pipeline -p APP_NAME=frontend-service-cd -p GIT_REPO=ssh://git@github.com/damianlezcano/moneda-frontend.git -e uri=http://backend-service-cd-rh-dev.$(minishift ip).nip.io -n rh-dev