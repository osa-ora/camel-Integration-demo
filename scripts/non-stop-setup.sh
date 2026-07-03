#!/bin/sh
if [ "$#" -ne 1 ];  then
  echo "Usage: $0  project_name" >&1
  exit 1
fi

# Create project
oc new-project $1
# Provision MySQL DB
oc new-app mysql-persistent -p DATABASE_SERVICE_NAME=mysql -p MYSQL_USER=test -p MYSQL_PASSWORD=test123 -p MYSQL_DATABASE=accountdb

# for deploymenbt
#oc wait --for=condition=available deployment/mysql --timeout=180s
oc rollout status dc/mysql --timeout=180s

COMMAND="create table accountdb.account ( id INT AUTO_INCREMENT NOT NULL PRIMARY KEY, firstname VARCHAR( 255 ) NOT NULL, lastname VARCHAR( 255 ) NOT NULL,status INT NOT NULL);insert into accountdb.account (id, firstname, lastname, status) values (1,'Osama','Oransa',1);insert into accountdb.account (id, firstname, lastname, status) values (2,'Osa','Ora',1);"

# Get POD name
POD_NAME=$(oc get pods -l=name=mysql -o custom-columns=POD:.metadata.name --no-headers)
echo "MySQL Pod name $POD_NAME"

# Install the DB schema and add some data
# Display Schema and data installing sql statements
echo "Will install: $COMMAND"
oc exec $POD_NAME -- mysql -u root accountdb -e "create table accountdb.account ( id INT AUTO_INCREMENT NOT NULL PRIMARY KEY, firstname VARCHAR( 255 ) NOT NULL, lastname VARCHAR( 255 ) NOT NULL,status INT NOT NULL);insert into accountdb.account (id, firstname, lastname, status) values (1,'Osama','Oransa',1);insert into accountdb.account (id, firstname, lastname, status) values (2,'Osa','Ora',1);"  

# Download database properties
curl https://raw.githubusercontent.com/osa-ora/camel-Integration-demo/refs/heads/main/scripts/datasource.properties >datasource.properties

# Create DB secret
oc create secret generic my-datasource --from-file=datasource.properties

echo "Setup the Kafka node pool ..." 
# Provision Kafka using object details
oc apply -f https://raw.githubusercontent.com/osa-ora/camel-Integration-demo/refs/heads/main/scripts/nodepool.yaml
echo "Setup the Kafka Cluster ..." 
oc apply -f https://raw.githubusercontent.com/osa-ora/camel-Integration-demo/refs/heads/main/scripts/kafaka-cluster.yaml

# Download kafka properties
curl https://raw.githubusercontent.com/osa-ora/camel-Integration-demo/refs/heads/main/scripts/kafka.properties >kafka-config.properties

# Create secret
oc create secret generic my-kafka-props --from-file=kafka-config.properties

# Deploy SpringBoot Application
echo "Will deploye SoringBoot Camel App: camel-app"
oc new-app --name=camel-app java~https://github.com/osa-ora/camel-Integration-demo --context-dir=camel-app
oc expose svc/camel-app
oc set env deployment/camel-app --from secret/my-datasource
oc set env deployment/camel-app --from secret/my-kafka-props
oc wait --for=condition=available deployment/mysql --timeout=180s

# Group all resourcs
oc label deploymentconfig/mysql app.kubernetes.io/part-of=camel-demo
oc label deployment/camel-app app.kubernetes.io/part-of=camel-demo
oc label deployment/my-kafka-cluster app.kubernetes.io/part-of=camel-demo

# Run some curl commands for testing
curl $(oc get route camel-app -o jsonpath='{.spec.host}')/command/TestKafkaMessage?scenario=4
curl $(oc get route camel-app -o jsonpath='{.spec.host}')/user/1
echo "Congratulations, we are done!"
