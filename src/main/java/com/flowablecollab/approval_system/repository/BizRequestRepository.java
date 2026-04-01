package com.flowablecollab.approval_system.repository;

import com.flowablecollab.approval_system.entity.BizRequest;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface BizRequestRepository extends JpaRepository<BizRequest, Long> {
    Optional<BizRequest> findByBusinessKey(String businessKey);

    Optional<BizRequest> findByProcessInstanceId(String processInstanceId);

    List<BizRequest> findByApplicantDeptIdIn(List<Long> deptIds);

    List<BizRequest> findByApplicantId(Long applicantId);

    List<BizRequest> findByApplicantDeptIdInOrApplicantPostIdIn(List<Long> deptIds, List<Long> postIds);

    long countByWorkflowDefinitionVersionId(Long workflowDefinitionVersionId);

    long countByWorkflowDefinitionVersionIdAndFinishTimeIsNull(Long workflowDefinitionVersionId);

    List<BizRequest> findTop10ByWorkflowDefinitionVersionIdOrderBySubmitTimeDescIdDesc(Long workflowDefinitionVersionId);
}
