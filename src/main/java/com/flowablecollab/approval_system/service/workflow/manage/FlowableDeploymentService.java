package com.flowablecollab.approval_system.service.workflow.manage;

import com.flowablecollab.approval_system.exception.WorkflowValidationException;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.flowable.engine.RepositoryService;
import org.flowable.engine.repository.Deployment;
import org.flowable.engine.repository.ProcessDefinition;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
@RequiredArgsConstructor
public class FlowableDeploymentService {

    private final RepositoryService repositoryService;
    private final WorkflowDefinitionVersionService workflowDefinitionVersionService;

    public FlowableDeploymentResult deploy(String processKey, String bpmnXml) {
        WorkflowDefinitionVersionService.ParsedMainProcess parsed = workflowDefinitionVersionService.parseMainProcess(bpmnXml);
        if (!processKey.equals(parsed.processId())) {
            throw new WorkflowValidationException(
                    WorkflowValidationException.BPMN_KEY_MISMATCH,
                    "processKey does not match BPMN process id",
                    Map.of("processKey", processKey, "processId", parsed.processId()));
        }

        String resourceName = processKey + ".bpmn20.xml";
        Deployment deployment = repositoryService.createDeployment()
                .name("workflow-definition-" + processKey)
                .key(processKey)
                .addString(resourceName, bpmnXml)
                .deploy();

        ProcessDefinition processDefinition = repositoryService.createProcessDefinitionQuery()
                .deploymentId(deployment.getId())
                .processDefinitionKey(processKey)
                .latestVersion()
                .singleResult();
        if (processDefinition == null) {
            throw new IllegalStateException("flowable deployment succeeded but process definition was not found");
        }

        FlowableDeploymentResult result = new FlowableDeploymentResult();
        result.setDeploymentId(deployment.getId());
        result.setProcessDefinitionId(processDefinition.getId());
        result.setProcessDefinitionKey(processDefinition.getKey());
        result.setVersion(processDefinition.getVersion());
        return result;
    }

    @Data
    public static class FlowableDeploymentResult {
        private String deploymentId;
        private String processDefinitionId;
        private String processDefinitionKey;
        private Integer version;
    }
}
