package com.traxia.identity.application;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.MailException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class RegistrationEmailSender {

    private final JavaMailSender mailSender;
    private final String emailFrom;
    private final String verificationUrl;

    public RegistrationEmailSender(
            JavaMailSender mailSender,
            @Value("${traxia.registration.email-from}") String emailFrom,
            @Value("${traxia.registration.verification-url}") String verificationUrl) {
        this.mailSender = mailSender;
        this.emailFrom = emailFrom;
        this.verificationUrl = verificationUrl;
    }

    public void sendVerification(String email, String displayName, String token) {
        String url = verificationUrl + "?token="
                + URLEncoder.encode(token, StandardCharsets.UTF_8);
        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(emailFrom);
        message.setTo(email);
        message.setSubject("Verifica tu correo de TRAXIA (prueba local)");
        message.setText("""
                Hola, %s.

                Para verificar este correo de prueba, abre:
                %s

                El enlace vence en 30 minutos. Si no solicitaste esta cuenta, ignora este mensaje.
                Este correo fue generado por el entorno local de desarrollo de TRAXIA.
                """.formatted(displayName, url));
        try {
            mailSender.send(message);
        } catch (MailException exception) {
            throw new RegistrationEmailDeliveryException(exception);
        }
    }

    public static final class RegistrationEmailDeliveryException extends RuntimeException {
        public RegistrationEmailDeliveryException(Throwable cause) {
            super(cause);
        }
    }
}
