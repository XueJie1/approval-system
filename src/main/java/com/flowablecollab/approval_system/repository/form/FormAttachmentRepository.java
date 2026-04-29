package com.flowablecollab.approval_system.repository.form;

import com.flowablecollab.approval_system.entity.form.FormAttachment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface FormAttachmentRepository extends JpaRepository<FormAttachment, Long> {

    List<FormAttachment> findByFormInstanceIdOrderByCreatedAtAsc(Long formInstanceId);

    List<FormAttachment> findByFormInstanceIdAndFieldKey(Long formInstanceId, String fieldKey);

    List<FormAttachment> findByIdIn(List<Long> ids);
}
