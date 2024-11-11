#!/bin/sh
if [ "$#" -ne 1 ];  then
  echo "Usage: $0  project_name" >&1
  exit 1
fi

echo "Please Login to OCP using oc login ..... "  
echo "Make sure Openshift AMQ Broker Operator is installed"
echo "Make sure Openshift AMQ Streams Operator is installed"
echo "Make sure oc command is available"

# Create project
oc new-project $1
# Provision MySQL DB
oc new-app mysql-persistent -p DATABASE_SERVICE_NAME=mysql -p MYSQL_USER=test -p MYSQL_PASSWORD=test123 -p MYSQL_DATABASE=accountdb

COMMAND="create table accountdb.account ( id INT AUTO_INCREMENT NOT NULL PRIMARY KEY, firstname VARCHAR( 255 ) NOT NULL, lastname VARCHAR( 255 ) NOT NULL,status INT NOT NULL);insert into accountdb.account (id, firstname, lastname, status) values (1,'Osama','Oransa',1);insert into accountdb.account (id, firstname, lastname, status) values (2,'Osa','Ora',1);"
# Display Schema and data installing sql statements
echo "Will install: $COMMAND"
echo "Press [Enter] key to setup the DB once MySQL pod started successfully ..." 
read

# Get POD name
POD_NAME=$(oc get pods -l=name=mysql -o custom-columns=POD:.metadata.name --no-headers)
echo "MySQL Pod name $POD_NAME"

# Install the DB schema and add some data
oc exec $POD_NAME -- mysql -u root accountdb -e "create table accountdb.account ( id INT AUTO_INCREMENT NOT NULL PRIMARY KEY, firstname VARCHAR( 255 ) NOT NULL, lastname VARCHAR( 255 ) NOT NULL,status INT NOT NULL);insert into accountdb.account (id, firstname, lastname, status) values (1,'Osama','Oransa',1);insert into accountdb.account (id, firstname, lastname, status) values (2,'Osa','Ora',1);"  

# Download database properties
# TODO fix the URL
curl https://raw.githubusercontent.com/osa-ora/camel-Integration-demo/scripts/datasource.properties >datasource.properties

# Create DB secret
oc create secret generic my-datasource --from-file=datasource.properties


# Provision Kafka using object details
oc apply -f https://raw.githubusercontent.com/osa-ora/camel-Integration-demo/scripts/kafka-sample/kafka-topic.yaml

# Download kafka properties
curl https://raw.githubusercontent.com/osa-ora/camel-Integration-demo/scripts/kafka.properties >kafka-config.properties

# Create secret
oc create secret generic my-kafka-props --from-file=kafka-config.properties

# Provision AMQ using object details
oc apply -f https://raw.githubusercontent.com/osa-ora/camel-Integration-demo/scripts/amq-broker.yaml

# Download jms properties
curl https://raw.githubusercontent.com/osa-ora/camel-Integration-demo/scripts/amq-config.properties >amq-config.properties

# Create configMap
#oc create configmap my-amq-config --from-file=amq-config.properties
# Create secret
oc create secret generic my-amq-config --from-file=amq-config.properties

# Deploy SpringBoot Application
oc new-app --name=camel-app java~https://github.com/osa-ora/camel-Integration-demo --context-dir=camel-app -n $1
oc expose svc/camel-demo -n $1
oc set env deployment/camel-app --from secret/my-datasource
oc set env deployment/camel-app --from secret/my-kafka-props
oc set env deployment/camel-app --from secret/my-amq-config

echo "Press [Enter] key to do some testing once the camel app deployed successfully ..." 
read

# Group all resourcs
oc label deploymentconfig/mysql app.kubernetes.io/part-of=camel-demo
oc label deployment/camel-app app.kubernetes.io/part-of=camel-demo
oc label deployment/my-kafka-cluster app.kubernetes.io/part-of=camel-demo
oc label deployment/my-amq app.kubernetes.io/part-of=camel-demo

# Run some curl commands for testing
curl $(oc get route camel-app -o jsonpath='{.spec.host}')/command/test?scenario=1
curl $(oc get route camel-app -o jsonpath='{.spec.host}')/command/TestJMSMessage?scenario=2
curl $(oc get route camel-app -o jsonpath='{.spec.host}')/command/TestMQTTMessage?scenario=3
curl $(oc get route camel-app -o jsonpath='{.spec.host}')/command/TestKafkaMessage?scenario=4
curl $(oc get route camel-app -o jsonpath='{.spec.host}')/command/test?scenario=5

curl $(oc get route camel-app -o jsonpath='{.spec.host}')/user/1
curl $(oc get route camel-app -o jsonpath='{.spec.host}')/user/2
curl $(oc get route camel-app -o jsonpath='{.spec.host}')/user/10


echo "Congratulations, we are done!"
