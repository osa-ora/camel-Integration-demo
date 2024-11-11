## Basic Demo for Red Hat Build of Apache Camel

This basic demo demonstrate how to use Red Hat Build of Apache Camel to connect to DB and send/recieve messages from Kafka

<img width="432" alt="Screenshot 2024-11-11 at 1 13 50 PM" src="https://github.com/user-attachments/assets/ba8bdbfc-94db-4fff-81c9-f9d93a944344">

Note: You'll need the following to execute the scenarios:
- Access to an OpenShift cluster.
- OpenShift command line installed (i.e. oc)
- Red Hat AMQ Streams (Kafka) Operator installed.

To install the demo:
 ```
  curl https://raw.githubusercontent.com/osa-ora/camel-Integration-demo/refs/heads/main/scripts/setup-script.sh > setup-script.sh
  chmod +x setup-script.sh
  ./setup-script.sh camel-demo
 ```

You can test the application manually by accessing the application route in the following end points:

 ```
  # Run some curl commands for testing
  curl $(oc get route camel-app -o jsonpath='{.spec.host}')/command/test?scenario=1
  curl $(oc get route camel-app -o jsonpath='{.spec.host}')/command/TestKafkaMessage?scenario=4
  curl $(oc get route camel-app -o jsonpath='{.spec.host}')/command/test?scenario=5
  
  curl $(oc get route camel-app -o jsonpath='{.spec.host}')/user/1
  curl $(oc get route camel-app -o jsonpath='{.spec.host}')/user/2
  curl $(oc get route camel-app -o jsonpath='{.spec.host}')/user/10
 ```


