package com.flowablecollab.approval_system.repository.workflow;

import com.flowablecollab.approval_system.entity.workflow.RequestTemplate;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface RequestTemplateRepository extends JpaRepository<RequestTemplate, Long> {

    List<RequestTemplate> findAllByOrderBySortOrderAscIdAsc();

    List<RequestTemplate> findByStatusOrderBySortOrderAscIdAsc(String status);

    Optional<RequestTemplate> findByTemplateKey(String templateKey);

    boolean existsByTemplateKey(String templateKey);
}
