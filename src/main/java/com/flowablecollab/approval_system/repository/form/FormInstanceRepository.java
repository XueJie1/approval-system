package com.flowablecollab.approval_system.repository.form;

import com.flowablecollab.approval_system.entity.form.FormInstance;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface FormInstanceRepository extends JpaRepository<FormInstance, Long> {
    Optional<FormInstance> findByBusinessKey(String businessKey);
}
