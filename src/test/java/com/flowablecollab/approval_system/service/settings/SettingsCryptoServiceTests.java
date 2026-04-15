package com.flowablecollab.approval_system.service.settings;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class SettingsCryptoServiceTests {

    @Test
    void encryptAndDecrypt_roundTripsSecretValue() {
        SettingsCryptoService cryptoService = new SettingsCryptoService("unit-test-crypto-key");

        String plain = "sk-test-super-secret";
        String encrypted = cryptoService.encrypt(plain);

        assertThat(encrypted).startsWith("v1:");
        assertThat(encrypted).doesNotContain(plain);
        assertThat(cryptoService.decrypt(encrypted)).isEqualTo(plain);
    }

    @Test
    void encrypt_generatesDifferentCipherTextsForSamePlainValue() {
        SettingsCryptoService cryptoService = new SettingsCryptoService("unit-test-crypto-key");

        String encryptedA = cryptoService.encrypt("same-secret");
        String encryptedB = cryptoService.encrypt("same-secret");

        assertThat(encryptedA).isNotEqualTo(encryptedB);
    }
}
