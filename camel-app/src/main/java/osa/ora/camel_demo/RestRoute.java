package osa.ora.camel_demo;


import org.apache.camel.builder.RouteBuilder;
import org.springframework.stereotype.Component;
import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.model.rest.RestBindingMode;


@Component
public class RestRoute extends RouteBuilder {

    @Override
    public void configure() throws Exception {
        // Define REST API endpoint for messages
        rest("/command")
            .get("/{message}")
            .produces("application/json")
            .to("direct:message");

        // Define REST API endpoint for login using mysql
        rest("/user")
            .get("/{id}")
            .to("direct:getUserAccount");

        from("direct:message")
            .process(exchange -> {
                // Fetch the query parameter from the request
                String scenarioParam = exchange.getIn().getHeader("scenario", String.class);

                // Override the scenario variable with query parameter value if present
                int scenario = Integer.parseInt(scenarioParam != null ? scenarioParam : "0");
                exchange.setProperty("scenario", scenario);
            })
            .choice()
                .when(exchange -> exchange.getProperty("scenario", Integer.class) == 1)
                    .log("Scenario is 1: Log")
                    .setBody(simple("{'message':'${header.message} - Log Message'}"))
                    .setHeader("Content-Type", constant("application/json"))
                    .log("Message details: ${body}")
                .when(exchange -> exchange.getProperty("scenario", Integer.class) == 2)
                    .log("Scenario is 2: JMS")
                    .setBody(simple("{'message':'${header.message} - JMS Message'}"))
                    .log("Sending message to JMS: ${body}")
                    //.to("jms:{{jms.destinationType}}:{{jms.destinationName}}?exchangePattern=InOnly")
                    .setHeader("Content-Type", constant("application/json"))
                    .log("Message details: ${body}")
                .when(exchange -> exchange.getProperty("scenario", Integer.class) == 3)
                    .log("Scenario is 3: MQTT")
                    .setBody(simple("{'message':'${header.message} - MQTT Message'}"))
                    .log("Sending message to MQTT: ${body}")
                    //.to("paho-mqtt5:{{mqtt.destinationName}}?brokerUrl={{mqtt.brokerUrl}}&qos=1&username={{mqtt.username}}&password={{mqtt.password}}&clientId={{mqtt.client.id}}")
                    .setHeader("Content-Type", constant("application/json"))
                    .log("Message details: ${body}")
                .when(exchange -> exchange.getProperty("scenario", Integer.class) == 4)
                    .log("Scenario is 4: Kafka")
                    .setBody(simple("{'message':'${header.message} - Kafka Message'}"))
                    .log("Sending message to Kafka: ${body}")
                    //.to("kafka:{{producer.topic}}?brokers={{camel.component.kafka.brokers}}")
                    .setHeader("Content-Type", constant("application/json"))
                    .log("Message details: ${body}")
                .otherwise()
                    .log("Scenario is otherwise");

        // Define the route to retrieve user account details from the database
        from("direct:getUserAccount")
            .setHeader("Content-Type", constant("application/json"))
            .setBody(simple("select * from account where id = ${header.id} LIMIT 1"))
            //.to("jdbc:camel")
            .choice()
               .when(simple("${body.size()} > 0"))
                    .transform().jsonpath("$[0]")
                    .setHeader("CamelHttpResponseCode", constant(200))
                .otherwise()
                    .setHeader("CamelHttpResponseCode", constant(404))
                    .setBody(constant("{ \"error\": \"User account not found\" }"))
            .end()
            .convertBodyTo(String.class) // Convert the response body to a string
            .log("User account details: ${body}");
    }
}
