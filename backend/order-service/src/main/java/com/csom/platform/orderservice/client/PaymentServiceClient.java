package com.csom.platform.orderservice.client;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;

import java.util.UUID;

@FeignClient(name = "payment-service", url = "${payment.service.url:http://payment-service}")
public interface PaymentServiceClient {

    @PostMapping("/api/v1/payments")
    PaymentResponse processPayment(@RequestBody PaymentRequest request);

    class PaymentRequest {
        private UUID orderId;
        private Double amount;

        // Getters and setters
        public UUID getOrderId() { return orderId; }
        public void setOrderId(UUID orderId) { this.orderId = orderId; }
        public Double getAmount() { return amount; }
        public void setAmount(Double amount) { this.amount = amount; }
    }

    class PaymentResponse {
        private UUID paymentId;
        private String status;

        // Getters and setters
        public UUID getPaymentId() { return paymentId; }
        public void setPaymentId(UUID paymentId) { this.paymentId = paymentId; }
        public String getStatus() { return status; }
        public void setStatus(String status) { this.status = status; }
    }
}

