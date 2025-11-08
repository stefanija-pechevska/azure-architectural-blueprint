package com.csom.platform.housekeeping;

import com.azure.core.util.BinaryData;
import com.azure.storage.blob.BlobClient;
import com.azure.storage.blob.BlobContainerClient;
import com.azure.storage.blob.BlobServiceClient;
import com.azure.storage.blob.BlobServiceClientBuilder;
import com.microsoft.azure.functions.ExecutionContext;
import com.microsoft.azure.functions.annotation.FunctionName;
import com.microsoft.azure.functions.annotation.TimerTrigger;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Azure Function to archive old audit logs to Azure Blob Storage.
 * Runs daily at 3 AM UTC to archive logs older than 1 year.
 */
public class AuditLogArchivalFunction {
    
    private static final Logger logger = Logger.getLogger(AuditLogArchivalFunction.class.getName());
    private static final ObjectMapper objectMapper = new ObjectMapper();
    private static final DateTimeFormatter dateFormatter = DateTimeFormatter.ofPattern("yyyy/MM/dd");
    
    @FunctionName("AuditLogArchival")
    public void run(
        @TimerTrigger(name = "timerInfo", schedule = "0 0 3 * * *") String timerInfo,
        final ExecutionContext context) {
        
        context.getLogger().info("Audit log archival function started at: " + LocalDateTime.now());
        
        String blobStorageConnectionString = System.getenv("BLOB_STORAGE_CONNECTION_STRING");
        String postgresHost = System.getenv("POSTGRES_HOST");
        String postgresUser = System.getenv("POSTGRES_USER");
        String postgresPassword = System.getenv("POSTGRES_PASSWORD");
        
        if (blobStorageConnectionString == null) {
            context.getLogger().severe("Blob Storage connection string not configured");
            return;
        }
        
        if (postgresHost == null || postgresUser == null || postgresPassword == null) {
            context.getLogger().severe("PostgreSQL connection details not configured");
            return;
        }
        
        String connectionUrl = String.format(
            "jdbc:postgresql://%s:5432/ordersdb?sslmode=require",
            postgresHost
        );
        
        try {
            // Initialize Blob Storage client
            BlobServiceClient blobServiceClient = new BlobServiceClientBuilder()
                .connectionString(blobStorageConnectionString)
                .buildClient();
            
            BlobContainerClient containerClient = blobServiceClient
                .getBlobContainerClient("audit-logs");
            
            // Ensure container exists
            if (!containerClient.exists()) {
                containerClient.create();
                context.getLogger().info("Created audit-logs container");
            }
            
            // Archive audit logs
            try (Connection conn = DriverManager.getConnection(connectionUrl, postgresUser, postgresPassword)) {
                archiveAuditLogs(conn, containerClient, context);
            }
            
            context.getLogger().info("Audit log archival completed successfully");
            
        } catch (Exception e) {
            context.getLogger().severe("Error during audit log archival: " + e.getMessage());
            logger.log(Level.SEVERE, "Archival Error", e);
        }
    }
    
    private void archiveAuditLogs(Connection conn, BlobContainerClient containerClient, ExecutionContext context) 
            throws SQLException {
        
        // Query logs older than 1 year that haven't been archived
        String selectSql = "SELECT id, user_id, action, resource_type, resource_id, " +
                          "ip_address, user_agent, created_at, metadata " +
                          "FROM audit.audit_logs " +
                          "WHERE created_at < NOW() - INTERVAL '1 year' " +
                          "AND archived = false " +
                          "ORDER BY created_at " +
                          "LIMIT 1000"; // Process in batches
        
        String updateSql = "UPDATE audit.audit_logs " +
                          "SET archived = true, archived_at = NOW() " +
                          "WHERE id = ?";
        
        int archivedCount = 0;
        
        try (PreparedStatement selectStmt = conn.prepareStatement(selectSql);
             PreparedStatement updateStmt = conn.prepareStatement(updateSql);
             ResultSet rs = selectStmt.executeQuery()) {
            
            ArrayNode logsArray = objectMapper.createArrayNode();
            String currentDate = null;
            
            while (rs.next()) {
                String logDate = rs.getTimestamp("created_at").toLocalDateTime()
                    .format(dateFormatter);
                
                // Group logs by date and archive in batches
                if (currentDate != null && !currentDate.equals(logDate)) {
                    // Archive the current batch
                    archiveBatch(containerClient, currentDate, logsArray, context);
                    logsArray = objectMapper.createArrayNode();
                }
                
                currentDate = logDate;
                
                // Create log entry
                ObjectNode logEntry = objectMapper.createObjectNode();
                logEntry.put("id", rs.getLong("id"));
                logEntry.put("user_id", rs.getString("user_id"));
                logEntry.put("action", rs.getString("action"));
                logEntry.put("resource_type", rs.getString("resource_type"));
                logEntry.put("resource_id", rs.getString("resource_id"));
                logEntry.put("ip_address", rs.getString("ip_address"));
                logEntry.put("user_agent", rs.getString("user_agent"));
                logEntry.put("created_at", rs.getTimestamp("created_at").toString());
                if (rs.getString("metadata") != null) {
                    logEntry.put("metadata", rs.getString("metadata"));
                }
                
                logsArray.add(logEntry);
                
                // Mark as archived
                updateStmt.setLong(1, rs.getLong("id"));
                updateStmt.executeUpdate();
                archivedCount++;
            }
            
            // Archive the last batch
            if (currentDate != null && logsArray.size() > 0) {
                archiveBatch(containerClient, currentDate, logsArray, context);
            }
            
            context.getLogger().info("Archived " + archivedCount + " audit logs to Blob Storage");
            
        } catch (Exception e) {
            context.getLogger().severe("Error archiving audit logs: " + e.getMessage());
            logger.log(Level.SEVERE, "Archive Error", e);
            throw new SQLException("Failed to archive audit logs", e);
        }
    }
    
    private void archiveBatch(BlobContainerClient containerClient, String date, ArrayNode logsArray, ExecutionContext context) {
        try {
            // Create blob path: audit-logs/yyyy/MM/dd/audit-logs-yyyyMMdd-HHmmss.json
            String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd-HHmmss"));
            String blobName = String.format("%s/audit-logs-%s.json", date, timestamp);
            
            // Convert logs array to JSON
            String jsonContent = objectMapper.writerWithDefaultPrettyPrinter()
                .writeValueAsString(logsArray);
            
            // Upload to Blob Storage
            BlobClient blobClient = containerClient.getBlobClient(blobName);
            blobClient.upload(BinaryData.fromString(jsonContent), true);
            
            context.getLogger().info("Archived batch to: " + blobName + " (" + logsArray.size() + " logs)");
            
        } catch (Exception e) {
            context.getLogger().severe("Error uploading batch to Blob Storage: " + e.getMessage());
            logger.log(Level.SEVERE, "Upload Error", e);
        }
    }
}

