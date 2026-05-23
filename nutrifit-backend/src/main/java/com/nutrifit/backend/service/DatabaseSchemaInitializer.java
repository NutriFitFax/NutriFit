package com.nutrifit.backend.service;

import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Component
public class DatabaseSchemaInitializer {
    private static final Logger LOGGER = LoggerFactory.getLogger(DatabaseSchemaInitializer.class);

    private final ObjectProvider<StorageRepository> repositoryProvider;
    private final boolean autoInit;

    public DatabaseSchemaInitializer(
            ObjectProvider<StorageRepository> repositoryProvider,
            @Value("${NUTRIFIT_DB_AUTO_INIT:true}") boolean autoInit
    ) {
        this.repositoryProvider = repositoryProvider;
        this.autoInit = autoInit;
    }

    @EventListener(ApplicationReadyEvent.class)
    public void initializeSchema() {
        StorageRepository repository = repositoryProvider.getIfAvailable();
        if (autoInit && repository != null) {
            try {
                repository.initializeSchema();
            } catch (Exception ex) {
                LOGGER.warn("Database schema initialization failed; storage endpoints will report DB errors", ex);
            }
        }
    }
}
