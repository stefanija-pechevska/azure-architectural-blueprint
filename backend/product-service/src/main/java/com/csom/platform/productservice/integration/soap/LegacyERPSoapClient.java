package com.csom.platform.productservice.integration.soap;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.ws.client.core.WebServiceTemplate;
import org.springframework.ws.soap.client.core.SoapActionCallback;

@Component
@RequiredArgsConstructor
@Slf4j
public class LegacyERPSoapClient {

    private final WebServiceTemplate webServiceTemplate;
    private static final String SOAP_ACTION = "http://legacy-erp.example.com/GetInventory";

    public InventoryResponse getInventory(String productId) {
        try {
            GetInventoryRequest request = new GetInventoryRequest();
            request.setProductId(productId);

            GetInventoryResponse response = (GetInventoryResponse) webServiceTemplate
                .marshalSendAndReceive(
                    "https://legacy-erp.example.com/soap",
                    request,
                    new SoapActionCallback(SOAP_ACTION)
                );

            return mapToInventoryResponse(response);
        } catch (Exception e) {
            log.error("Failed to call legacy SOAP service for product: {}", productId, e);
            throw new RuntimeException("Failed to retrieve inventory from ERP", e);
        }
    }

    private InventoryResponse mapToInventoryResponse(GetInventoryResponse response) {
        InventoryResponse inventory = new InventoryResponse();
        inventory.setProductId(response.getProductId());
        inventory.setQuantity(response.getAvailableQuantity());
        inventory.setLastUpdated(response.getLastSyncDate());
        return inventory;
    }
}

