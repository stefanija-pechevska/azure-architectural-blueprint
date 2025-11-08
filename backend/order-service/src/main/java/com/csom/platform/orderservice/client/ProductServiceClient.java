package com.csom.platform.orderservice.client;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;

import java.util.List;

@FeignClient(name = "product-service", url = "${product.service.url:http://product-service}")
public interface ProductServiceClient {

    @PostMapping("/api/v1/products/validate")
    ValidationResponse validateProducts(@RequestBody ValidationRequest request);

    class ValidationRequest {
        private List<ProductItem> items;

        // Getters and setters
        public List<ProductItem> getItems() { return items; }
        public void setItems(List<ProductItem> items) { this.items = items; }
    }

    class ProductItem {
        private String productId;
        private Integer quantity;

        // Getters and setters
        public String getProductId() { return productId; }
        public void setProductId(String productId) { this.productId = productId; }
        public Integer getQuantity() { return quantity; }
        public void setQuantity(Integer quantity) { this.quantity = quantity; }
    }

    class ValidationResponse {
        private Boolean valid;
        private String message;

        // Getters and setters
        public Boolean getValid() { return valid; }
        public void setValid(Boolean valid) { this.valid = valid; }
        public String getMessage() { return message; }
        public void setMessage(String message) { this.message = message; }
    }
}

