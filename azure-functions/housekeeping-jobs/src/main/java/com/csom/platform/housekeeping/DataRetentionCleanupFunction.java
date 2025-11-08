package com.csom.platform.housekeeping;

import com.microsoft.azure.functions.ExecutionContext;
import com.microsoft.azure.functions.annotation.FunctionName;
import com.microsoft.azure.functions.annotation.TimerTrigger;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.time.LocalDateTime;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Azure Function to clean up old data based on retention policies.
 * Runs daily at 2 AM UTC.
 */
public class DataRetentionCleanupFunction {
    
    private static final Logger logger = Logger.getLogger(DataRetentionCleanupFunction.class.getName());
    
    @FunctionName("DataRetentionCleanup")
    public void run(
        @TimerTrigger(name = "timerInfo", schedule = "0 0 2 * * *") String timerInfo,
        final ExecutionContext context) {
        
        context.getLogger().info("Data retention cleanup function started at: " + LocalDateTime.now());
        
        String postgresHost = System.getenv("POSTGRES_HOST");
        String postgresUser = System.getenv("POSTGRES_USER");
        String postgresPassword = System.getenv("POSTGRES_PASSWORD");
        
        if (postgresHost == null || postgresUser == null || postgresPassword == null) {
            context.getLogger().severe("PostgreSQL connection details not configured");
            return;
        }
        
        String connectionUrl = String.format(
            "jdbc:postgresql://%s:5432/ordersdb?sslmode=require",
            postgresHost
        );
        
        try (Connection conn = DriverManager.getConnection(connectionUrl, postgresUser, postgresPassword)) {
            // Clean up old notifications (older than 90 days)
            cleanupOldNotifications(conn, context);
            
            // Anonymize old customer data (older than 7 years for inactive customers)
            anonymizeOldCustomerData(conn, context);
            
            // Archive old audit logs (older than 10 years)
            archiveOldAuditLogs(conn, context);
            
            context.getLogger().info("Data retention cleanup completed successfully");
            
        } catch (SQLException e) {
            context.getLogger().severe("Error during data retention cleanup: " + e.getMessage());
            logger.log(Level.SEVERE, "SQL Error", e);
        }
    }
    
    private void cleanupOldNotifications(Connection conn, ExecutionContext context) throws SQLException {
        String sql = "DELETE FROM notifications.notifications " +
                     "WHERE created_at < NOW() - INTERVAL '90 days' " +
                     "AND read = true";
        
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            int deleted = stmt.executeUpdate();
            context.getLogger().info("Deleted " + deleted + " old notifications");
        }
    }
    
    private void anonymizeOldCustomerData(Connection conn, ExecutionContext context) throws SQLException {
        String sql = "UPDATE customers.customers " +
                     "SET email = 'anonymized-' || id || '@anonymized.local', " +
                     "    name = 'Anonymized User', " +
                     "    phone = NULL " +
                     "WHERE deleted = false " +
                     "AND last_login < NOW() - INTERVAL '7 years'";
        
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            int anonymized = stmt.executeUpdate();
            context.getLogger().info("Anonymized " + anonymized + " old customer records");
        }
    }
    
    private void archiveOldAuditLogs(Connection conn, ExecutionContext context) throws SQLException {
        // Archive old audit logs to Blob Storage before deletion
        // This is handled by the AuditLogArchivalFunction which runs separately
        // Here we only delete logs that are older than 7 years (after archival)
        String sql = "DELETE FROM audit.audit_logs " +
                     "WHERE created_at < NOW() - INTERVAL '7 years' " +
                     "AND archived = true";
        
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            int deleted = stmt.executeUpdate();
            context.getLogger().info("Deleted " + deleted + " archived audit logs older than 7 years");
        }
    }
}

