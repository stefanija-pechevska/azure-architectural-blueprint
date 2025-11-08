package com.csom.platform.orderservice.messaging;

import com.csom.platform.orderservice.entity.Order;
import com.azure.messaging.servicebus.ServiceBusMessage;
import com.azure.messaging.servicebus.ServiceBusSenderClient;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
@Slf4j
public class OrderEventPublisher {

    private final ServiceBusSenderClient serviceBusSenderClient;

    public void publishOrderCreated(Order order) {
        try {
            String messageBody = String.format(
                "{\"eventType\":\"ORDER_CREATED\",\"orderId\":\"%s\",\"customerId\":\"%s\",\"totalAmount\":%f}",
                order.getId(), order.getCustomerId(), order.getTotalAmount()
            );
            ServiceBusMessage message = new ServiceBusMessage(messageBody);
            message.setMessageId(order.getId().toString());
            serviceBusSenderClient.sendMessage(message);
            log.info("Published ORDER_CREATED event for order: {}", order.getId());
        } catch (Exception e) {
            log.error("Failed to publish ORDER_CREATED event", e);
        }
    }

    public void publishOrderStatusUpdated(Order order) {
        try {
            String messageBody = String.format(
                "{\"eventType\":\"ORDER_STATUS_UPDATED\",\"orderId\":\"%s\",\"status\":\"%s\"}",
                order.getId(), order.getStatus()
            );
            ServiceBusMessage message = new ServiceBusMessage(messageBody);
            message.setMessageId(order.getId().toString());
            serviceBusSenderClient.sendMessage(message);
            log.info("Published ORDER_STATUS_UPDATED event for order: {}", order.getId());
        } catch (Exception e) {
            log.error("Failed to publish ORDER_STATUS_UPDATED event", e);
        }
    }

    public void publishOrderDeleted(Order order) {
        try {
            String messageBody = String.format(
                "{\"eventType\":\"ORDER_DELETED\",\"orderId\":\"%s\",\"customerId\":\"%s\"}",
                order.getId(), order.getCustomerId()
            );
            ServiceBusMessage message = new ServiceBusMessage(messageBody);
            message.setMessageId(order.getId().toString());
            serviceBusSenderClient.sendMessage(message);
            log.info("Published ORDER_DELETED event for order: {}", order.getId());
        } catch (Exception e) {
            log.error("Failed to publish ORDER_DELETED event", e);
        }
    }
}

