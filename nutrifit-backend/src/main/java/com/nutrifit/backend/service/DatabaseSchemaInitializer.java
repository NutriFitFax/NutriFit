package com.nutrifit.backend.service;

import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

@Component
public class DatabaseSchemaInitializer {
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
            repository.initializeSchema();
        }
    }
}
