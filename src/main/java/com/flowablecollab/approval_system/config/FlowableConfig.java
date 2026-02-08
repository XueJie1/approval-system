package com.flowablecollab.approval_system.config;

import lombok.extern.slf4j.Slf4j;
import org.flowable.engine.ProcessEngine;
import org.flowable.engine.RepositoryService;
import org.flowable.engine.RuntimeService;
import org.flowable.engine.TaskService;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Slf4j
@Configuration
public class FlowableConfig {

    @Bean
    public CommandLineRunner verifyFlowableDeployment(
            ProcessEngine processEngine,
            RepositoryService repositoryService,
            RuntimeService runtimeService,
            TaskService taskService) {
        return args -> {
            log.info("✓ Flowable ProcessEngine initialized: {}", processEngine.getName());
            log.info("✓ RepositoryService available");
            log.info("✓ RuntimeService available");
            log.info("✓ TaskService available");

            long processCount = repositoryService.createProcessDefinitionQuery().count();
            log.info("✓ Deployed process definitions: {}", processCount);
        };
    }
}
