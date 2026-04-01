package com.flowablecollab.approval_system.config;

import com.flowablecollab.approval_system.service.workflow.manage.WorkflowCatalogBootstrapService;
import org.flowable.engine.ProcessEngine;
import org.flowable.engine.RepositoryService;
import org.flowable.engine.RuntimeService;
import org.flowable.engine.TaskService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class FlowableConfig {

    private static final Logger log = LoggerFactory.getLogger(FlowableConfig.class);

    @Bean
    public CommandLineRunner verifyFlowableDeployment(
            ProcessEngine processEngine,
            RepositoryService repositoryService,
            RuntimeService runtimeService,
            TaskService taskService,
            WorkflowCatalogBootstrapService workflowCatalogBootstrapService) {
        return args -> {
            log.info("✓ Flowable ProcessEngine initialized: {}", processEngine.getName());
            log.info("✓ RepositoryService available");
            log.info("✓ RuntimeService available");
            log.info("✓ TaskService available");

            long processCount = repositoryService.createProcessDefinitionQuery().count();
            log.info("✓ Deployed process definitions: {}", processCount);

            workflowCatalogBootstrapService.bootstrapCatalog();
        };
    }
}
