package com.gunes.DunyaUlkeleri.config;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import javax.sql.DataSource;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.stereotype.Component;

@Component
public class PostgresCustomAvatarMigration implements InitializingBean {

    private static final Logger log = LoggerFactory.getLogger(PostgresCustomAvatarMigration.class);

    private final DataSource dataSource;

    public PostgresCustomAvatarMigration(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    @Override
    public void afterPropertiesSet() {
        try (Connection connection = dataSource.getConnection()) {
            if (!isPostgres(connection)) {
                return;
            }

            String udtName = findCustomAvatarUdtName(connection);
            if (udtName == null || !"oid".equalsIgnoreCase(udtName)) {
                return;
            }

            log.warn("Detected `users.custom_avatar` as OID; migrating to `bytea` using `lo_get(...)`.");
            boolean originalAutoCommit = connection.getAutoCommit();
            connection.setAutoCommit(false);
            try {
                try (Statement statement = connection.createStatement()) {
                    statement.execute(
                            "ALTER TABLE users " +
                            "ALTER COLUMN custom_avatar TYPE bytea " +
                            "USING CASE " +
                            "WHEN custom_avatar IS NULL THEN NULL " +
                            "ELSE lo_get(custom_avatar) " +
                            "END"
                    );
                }
                connection.commit();
                log.warn("Migration complete: `users.custom_avatar` is now `bytea`.");
            } catch (SQLException e) {
                try {
                    connection.rollback();
                } catch (SQLException ignored) {
                    // no-op
                }
                throw e;
            } finally {
                try {
                    connection.setAutoCommit(originalAutoCommit);
                } catch (SQLException ignored) {
                    // no-op
                }
            }
        } catch (SQLException e) {
            throw new IllegalStateException("Failed to migrate users.custom_avatar from oid to bytea", e);
        }
    }

    private static boolean isPostgres(Connection connection) throws SQLException {
        String productName = connection.getMetaData().getDatabaseProductName();
        return productName != null && productName.toLowerCase().contains("postgres");
    }

    private static String findCustomAvatarUdtName(Connection connection) throws SQLException {
        String sql = "SELECT udt_name " +
                "FROM information_schema.columns " +
                "WHERE table_schema = 'public' " +
                "  AND table_name = 'users' " +
                "  AND column_name = 'custom_avatar'";

        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                return rs.getString(1);
            }
        }
    }
}
