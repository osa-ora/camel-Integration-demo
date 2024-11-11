package osa.ora.camel_demo;

import org.apache.camel.builder.RouteBuilder;
import org.springframework.stereotype.Component;

@Component  // Make this class a Spring Bean
public class JMSToLogRoute extends RouteBuilder {

    @Override
    public void configure() throws Exception {
        // Use Spring Boot's application properties for dynamic JMS configuration
        from("activemq:topic:transfers")
            .log("Recieved JMS message by the listener: ${body}");
    }
}

