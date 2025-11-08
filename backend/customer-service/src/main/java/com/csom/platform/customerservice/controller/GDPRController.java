package com.csom.platform.customerservice.controller;

import com.csom.platform.customerservice.dto.GDPRDataExport;
import com.csom.platform.customerservice.service.GDPRService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/customers")
@RequiredArgsConstructor
public class GDPRController {

    private final GDPRService gdprService;

    @PostMapping("/{id}/gdpr/export")
    public ResponseEntity<GDPRDataExport> exportCustomerData(
            @PathVariable UUID id,
            @AuthenticationPrincipal Jwt jwt) {
        String userId = jwt.getClaimAsString("sub");
        GDPRDataExport export = gdprService.exportCustomerData(id, userId);
        return ResponseEntity.ok(export);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteCustomerData(
            @PathVariable UUID id,
            @AuthenticationPrincipal Jwt jwt) {
        String userId = jwt.getClaimAsString("sub");
        gdprService.deleteCustomerData(id, userId);
        return ResponseEntity.status(HttpStatus.NO_CONTENT).build();
    }

    @GetMapping("/{id}/gdpr/audit")
    public ResponseEntity<?> getGDPRAuditTrail(
            @PathVariable UUID id,
            @AuthenticationPrincipal Jwt jwt) {
        String userId = jwt.getClaimAsString("sub");
        // Only admins can view audit trails
        return ResponseEntity.ok(gdprService.getAuditTrail(id, userId));
    }
}

