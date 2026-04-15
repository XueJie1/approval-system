package com.flowablecollab.approval_system.repository.settings;

import com.flowablecollab.approval_system.entity.settings.SystemSetting;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface SystemSettingRepository extends JpaRepository<SystemSetting, Long> {

    Optional<SystemSetting> findBySettingKey(String settingKey);

    List<SystemSetting> findBySettingKeyIn(Collection<String> settingKeys);

    void deleteBySettingKey(String settingKey);
}
