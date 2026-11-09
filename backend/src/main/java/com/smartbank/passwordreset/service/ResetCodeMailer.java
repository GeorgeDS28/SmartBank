/*ResetCodeMailer.java
 */

package com.smartbank.passwordreset.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.mail.MailException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ResponseStatusException;

/**
 * Delivers a reset code over SMTP. Spring Boot only creates a
 * {@link JavaMailSender} when spring.mail.host is set, so an unconfigured
 * server reports a failure instead of pretending the code was sent.
 */
@Component
public class ResetCodeMailer {

    private static final Logger log =
            LoggerFactory.getLogger(ResetCodeMailer.class);

    private final ObjectProvider<JavaMailSender> mailSenderProvider;
    private final String fromAddress;

    public ResetCodeMailer(
            ObjectProvider<JavaMailSender> mailSenderProvider,
            @Value("${app.password-reset.from:}") String fromAddress) {

        this.mailSenderProvider = mailSenderProvider;
        this.fromAddress = fromAddress;
    }

    public void send(String recipient, String code, int validMinutes) {

        JavaMailSender mailSender = mailSenderProvider.getIfAvailable();

        if (mailSender == null || fromAddress.isBlank()) {
            log.error("Reset code requested but email delivery is not configured");
            throw new ResponseStatusException(
                    HttpStatus.SERVICE_UNAVAILABLE,
                    "Email delivery is not configured on this server");
        }

        SimpleMailMessage message = new SimpleMailMessage();

        message.setFrom(fromAddress);
        message.setTo(recipient);
        message.setSubject("SmartBank password reset code");
        message.setText("""
                Your SmartBank password reset code is %s.

                It can be used once and expires in %d minutes. If you did not
                ask to reset your password, you do not need to do anything.
                """.formatted(code, validMinutes));

        try {
            mailSender.send(message);
        } catch (MailException error) {
            // Neither the code nor the address reaches the log.
            log.error("Reset code delivery failed: {}", error.getMessage());
            throw new ResponseStatusException(
                    HttpStatus.SERVICE_UNAVAILABLE,
                    "The reset code could not be sent. Try again later.");
        }

        log.info("Password reset code emailed");
    }
}
