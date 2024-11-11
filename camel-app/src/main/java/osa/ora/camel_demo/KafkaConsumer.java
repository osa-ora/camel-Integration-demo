package osa.ora.camel_demo;

import org.apache.camel.builder.RouteBuilder;
import org.springframework.stereotype.Component;

@Component
public class KafkaConsumer extends RouteBuilder {
    @Override
    public void configure() throws Exception {
        log.info("Starting Kafka Consumer");

        from("kafka:{{consumer.topic}}")
            .log("${body}");
    }
}
