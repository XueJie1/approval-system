package com.flowablecollab.approval_system.repository.form;

import com.flowablecollab.approval_system.entity.form.FormField;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

public interface FormFieldRepository extends JpaRepository<FormField, Long> {
    List<FormField> findByFormVersionId(Long formVersionId);

    @Modifying
    @Transactional
    void deleteByFormVersionId(Long formVersionId);
}
