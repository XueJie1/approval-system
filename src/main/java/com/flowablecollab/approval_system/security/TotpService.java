package com.flowablecollab.approval_system.security;

import org.apache.commons.codec.binary.Base32;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.net.URLEncoder;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.time.Instant;

@Service
public class TotpService {

    private static final int TIME_STEP_SECONDS = 30;
    private static final int DIGITS = 6;
    private static final int RECOVERY_CODE_COUNT = 10;
    private static final int RECOVERY_CODE_LENGTH = 8;

    private final SecureRandom secureRandom = new SecureRandom();
    private final Base32 base32 = new Base32();

    @Value("${security.totp.issuer:ApprovalSystem}")
    private String issuer;

    public String generateSecret() {
        byte[] randomBytes = new byte[20];
        secureRandom.nextBytes(randomBytes);
        return base32.encodeToString(randomBytes).replace("=", "");
    }

    public String generateRecoveryCodes() {
        StringBuilder codes = new StringBuilder();
        for (int i = 0; i < RECOVERY_CODE_COUNT; i++) {
            if (i > 0) codes.append(",");
            codes.append(generateRecoveryCode());
        }
        return codes.toString();
    }

    public boolean validateRecoveryCode(String storedCodes, String code) {
        if (storedCodes == null || storedCodes.isBlank() || code == null || code.isBlank()) {
            return false;
        }
        String[] codes = storedCodes.split(",");
        for (int i = 0; i < codes.length; i++) {
            if (codes[i].equals(code)) {
                // Remove used code
                StringBuilder remaining = new StringBuilder();
                for (int j = 0; j < codes.length; j++) {
                    if (j != i) {
                        if (remaining.length() > 0) remaining.append(",");
                        remaining.append(codes[j]);
                    }
                }
                return true;
            }
        }
        return false;
    }

    private String generateRecoveryCode() {
        StringBuilder code = new StringBuilder();
        for (int i = 0; i < RECOVERY_CODE_LENGTH; i++) {
            if (i > 0 && i % 2 == 0) code.append("-");
            if (i > 0 && i % 2 == 0) code.append("-");
            code.append(secureRandom.nextInt(10));
        }
        return code.toString();
    }

    public boolean verifyCode(String secret, String code) {
        if (secret == null || secret.isBlank() || code == null || !code.matches("\\d{6}")) {
            return false;
        }
        long timeWindow = Instant.now().getEpochSecond() / TIME_STEP_SECONDS;
        byte[] key = decodeSecret(secret);
        for (int i = -1; i <= 1; i++) {
            if (generateTotpCode(key, timeWindow + i).equals(code)) {
                return true;
            }
        }
        return false;
    }

    public String buildOtpAuthUri(String username, String secret) {
        String label = urlEncode(issuer + ":" + username);
        String issuerEncoded = urlEncode(issuer);
        return "otpauth://totp/" + label + "?secret=" + secret + "&issuer=" + issuerEncoded + "&digits=6&period=30";
    }

    private String generateTotpCode(byte[] key, long counter) {
        try {
            byte[] data = ByteBuffer.allocate(8).putLong(counter).array();
            Mac mac = Mac.getInstance("HmacSHA1");
            mac.init(new SecretKeySpec(key, "HmacSHA1"));
            byte[] hash = mac.doFinal(data);

            int offset = hash[hash.length - 1] & 0x0F;
            int binary = ((hash[offset] & 0x7F) << 24)
                    | ((hash[offset + 1] & 0xFF) << 16)
                    | ((hash[offset + 2] & 0xFF) << 8)
                    | (hash[offset + 3] & 0xFF);
            int otp = binary % (int) Math.pow(10, DIGITS);
            return String.format("%0" + DIGITS + "d", otp);
        } catch (Exception ex) {
            throw new IllegalStateException("Cannot generate TOTP code", ex);
        }
    }

    private byte[] decodeSecret(String secret) {
        return base32.decode(secret);
    }

    private String urlEncode(String text) {
        return URLEncoder.encode(text, StandardCharsets.UTF_8);
    }
}
