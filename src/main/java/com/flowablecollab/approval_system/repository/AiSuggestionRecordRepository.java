package com.flowablecollab.approval_system.repository;

import com.flowablecollab.approval_system.entity.AiSuggestionRecord;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AiSuggestionRecordRepository extends JpaRepository<AiSuggestionRecord, Long> {
    List<AiSuggestionRecord> findByTaskIdOrderByCreatedAtDesc(String taskId);

    List<AiSuggestionRecord> findByBusinessKeyInOrderByCreatedAtDesc(List<String> businessKeys);

    List<AiSuggestionRecord> findByTaskId(String taskId);

    List<AiSuggestionRecord> findByProcessInstanceId(String processInstanceId);
}
