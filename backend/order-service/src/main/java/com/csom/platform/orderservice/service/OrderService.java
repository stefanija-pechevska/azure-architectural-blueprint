package com.csom.platform.orderservice.service;

import com.csom.platform.orderservice.dto.OrderCreateRequest;
import com.csom.platform.orderservice.dto.OrderResponse;
import com.csom.platform.orderservice.entity.Order;
import com.csom.platform.orderservice.entity.OrderStatus;
import com.csom.platform.orderservice.repository.OrderRepository;
import com.csom.platform.orderservice.client.PaymentServiceClient;
import com.csom.platform.orderservice.client.ProductServiceClient;
import com.csom.platform.orderservice.messaging.OrderEventPublisher;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class OrderService {

    private final OrderRepository orderRepository;
    private final PaymentServiceClient paymentServiceClient;
    private final ProductServiceClient productServiceClient;
    private final OrderEventPublisher eventPublisher;

    @Transactional
    public OrderResponse createOrder(OrderCreateRequest request, String userId) {
        log.info("Creating order for user: {}", userId);

        // Validate products and inventory
        productServiceClient.validateProducts(request.getItems());

        // Create order
        Order order = new Order();
        order.setCustomerId(UUID.fromString(userId));
        order.setStatus(OrderStatus.PENDING);
        order.setTotalAmount(calculateTotal(request));
        // Set order items...

        order = orderRepository.save(order);

        // Process payment
        paymentServiceClient.processPayment(order.getId(), order.getTotalAmount());

        // Publish event
        eventPublisher.publishOrderCreated(order);

        return mapToResponse(order);
    }

    public OrderResponse getOrder(UUID id, String userId) {
        Order order = orderRepository.findByIdAndCustomerId(id, UUID.fromString(userId))
            .orElseThrow(() -> new RuntimeException("Order not found"));
        return mapToResponse(order);
    }

    public List<OrderResponse> getOrders(String userId, String status, Integer page, Integer size) {
        List<Order> orders;
        if (status != null) {
            orders = orderRepository.findByCustomerIdAndStatus(
                UUID.fromString(userId), OrderStatus.valueOf(status.toUpperCase()));
        } else {
            orders = orderRepository.findByCustomerId(UUID.fromString(userId));
        }
        return orders.stream().map(this::mapToResponse).collect(Collectors.toList());
    }

    @Transactional
    public OrderResponse updateOrderStatus(UUID id, String status, String userId) {
        Order order = orderRepository.findByIdAndCustomerId(id, UUID.fromString(userId))
            .orElseThrow(() -> new RuntimeException("Order not found"));
        order.setStatus(OrderStatus.valueOf(status.toUpperCase()));
        order = orderRepository.save(order);
        eventPublisher.publishOrderStatusUpdated(order);
        return mapToResponse(order);
    }

    @Transactional
    public void deleteOrder(UUID id, String userId) {
        Order order = orderRepository.findByIdAndCustomerId(id, UUID.fromString(userId))
            .orElseThrow(() -> new RuntimeException("Order not found"));
        // Soft delete for GDPR compliance
        order.setDeleted(true);
        orderRepository.save(order);
        eventPublisher.publishOrderDeleted(order);
    }

    private Double calculateTotal(OrderCreateRequest request) {
        // Calculate total from items
        return request.getItems().stream()
            .mapToDouble(item -> item.getPrice() * item.getQuantity())
            .sum();
    }

    private OrderResponse mapToResponse(Order order) {
        OrderResponse response = new OrderResponse();
        response.setId(order.getId());
        response.setCustomerId(order.getCustomerId());
        response.setStatus(order.getStatus().toString());
        response.setTotalAmount(order.getTotalAmount());
        response.setCreatedAt(order.getCreatedAt());
        // Map items...
        return response;
    }
}

