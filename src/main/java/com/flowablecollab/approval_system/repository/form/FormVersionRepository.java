package com.flowablecollab.approval_system.repository.form;

import com.flowablecollab.approval_system.entity.form.FormVersion;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface FormVersionRepository extends JpaRepository<FormVersion, Long> {
    Optional<FormVersion> findTopByFormIdOrderByVersionDesc(Long formId);
}
