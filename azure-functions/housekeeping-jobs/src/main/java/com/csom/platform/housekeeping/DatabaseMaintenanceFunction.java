package com.csom.platform.housekeeping;

import com.microsoft.azure.functions.ExecutionContext;
import com.microsoft.azure.functions.annotation.FunctionName;
import com.microsoft.azure.functions.annotation.TimerTrigger;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;
import java.time.LocalDateTime;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Azure Function for database maintenance tasks.
 * Runs weekly on Sundays at 3 AM UTC.
 */
public class DatabaseMaintenanceFunction {
    
    private static final Logger logger = Logger.getLogger(DatabaseMaintenanceFunction.class.getName());
    
    @FunctionName("DatabaseMaintenance")
    public void run(
        @TimerTrigger(name = "timerInfo", schedule = "0 0 3 * * 0") String timerInfo,
        final ExecutionContext context) {
        
        context.getLogger().info("Database maintenance function started at: " + LocalDateTime.now());
        
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
        
        try (Connection conn = DriverManager.getConnection(connectionUrl, postgresUser, postgresPassword);
             Statement stmt = conn.createStatement()) {
            
            // Vacuum analyze for performance
            context.getLogger().info("Running VACUUM ANALYZE...");
            stmt.execute("VACUUM ANALYZE");
            
            // Update statistics
            context.getLogger().info("Updating table statistics...");
            stmt.execute("ANALYZE");
            
            context.getLogger().info("Database maintenance completed successfully");
            
        } catch (SQLException e) {
            context.getLogger().severe("Error during database maintenance: " + e.getMessage());
            logger.log(Level.SEVERE, "SQL Error", e);
        }
    }
}

