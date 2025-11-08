package com.csom.platform.orderservice.dto;

import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Data
public class OrderResponse {
    private UUID id;
    private UUID customerId;
    private String status;
    private Double totalAmount;
    private LocalDateTime createdAt;
    private List<OrderItemResponse> items;

    @Data
    public static class OrderItemResponse {
        private UUID productId;
        private Integer quantity;
        private Double price;
    }
}

