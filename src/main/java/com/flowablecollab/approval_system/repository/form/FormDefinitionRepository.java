package com.flowablecollab.approval_system.repository.form;

import com.flowablecollab.approval_system.entity.form.FormDefinition;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface FormDefinitionRepository extends JpaRepository<FormDefinition, Long> {
    Optional<FormDefinition> findByFormKey(String formKey);

    List<FormDefinition> findAllByOrderByFormNameAscIdAsc();
}
