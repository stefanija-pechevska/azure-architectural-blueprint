package com.csom.platform.orderservice.repository;

import com.csom.platform.orderservice.entity.Order;
import com.csom.platform.orderservice.entity.OrderStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface OrderRepository extends JpaRepository<Order, UUID> {
    Optional<Order> findByIdAndCustomerId(UUID id, UUID customerId);
    List<Order> findByCustomerId(UUID customerId);
    List<Order> findByCustomerIdAndStatus(UUID customerId, OrderStatus status);
}

