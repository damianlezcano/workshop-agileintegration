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

oc login -u admin

oc whoami -t
docker login -u admin -p Fn3fsi9RFYGROPaQGF7u1Sm8ZeibKj8BRS9UoutmLzI localhost:5000

#pull imagenes redhat
docker pull localhost:5000/openshift/postgresql
#docker pull localhost:5000/openshift/redhat-sso72-openshift:1.2
docker pull localhost:5000/openshift/mongodb:3.2

#push en registry minishift
docker tag localhost:5000/openshift/postgresql localhost:5000/openshift/postgresql:9.5
#docker tag localhost:5000/openshift/redhat-sso72-openshift:1.2 localhost:5000/openshift/redhat-sso72-openshift:1.3
docker tag localhost:5000/openshift/mongodb:3.2 localhost:5000/openshift/mongodb:3.2
docker tag fabric8/java-centos-openjdk8-jdk:1.5.1 localhost:5000/openshift/java-centos-openjdk8-jdk:1.5.1

docker push localhost:5000/openshift/postgresql:9.5
#docker push localhost:5000/openshift/redhat-sso72-openshift:1.3
docker push localhost:5000/openshift/mongodb:3.2
docker push localhost:5000/openshift/java-centos-openjdk8-jdk:1.5.1