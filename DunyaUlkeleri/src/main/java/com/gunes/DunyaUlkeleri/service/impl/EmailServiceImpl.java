package com.gunes.DunyaUlkeleri.service.impl;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import jakarta.mail.internet.MimeMessage;
import com.gunes.DunyaUlkeleri.service.EmailService;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j; // 🚨 YENİ: Profesyonel loglama için eklendi

@Service
@RequiredArgsConstructor
@Transactional
@Slf4j // 🚨 YENİ: System.out.println yerine log.info kullanmak için eklendi
public class EmailServiceImpl implements EmailService {

    private final JavaMailSender mailSender;

    @Value("${spring.mail.username}")
    private String senderEmail;

    // --- 1. KAYIT DOĞRULAMA MAİLİ ---
    @Override
    @Async
    public void sendVerificationCode(String toEmail, String code) {
        sendEmailTemplate(
            toEmail, 
            "Dünya Ülkeleri - Doğrulama Kodu", 
            "Hesap Doğrulama", 
            "Aramıza katılmak için doğrulama kodunuz:", 
            code, 
            "#ffbf00" // Uygulamanın sarı/amber teması
        );
    }

    // --- 2. ŞİFRE SIFIRLAMA MAİLİ ---
    @Override
    @Async
    public void sendPasswordResetEmail(String toEmail, String resetCode) {
        sendEmailTemplate(
            toEmail, 
            "Dünya Ülkeleri - Şifre Sıfırlama Kodu", 
            "Şifre Sıfırlama İsteği", 
            "Şifrenizi sıfırlamak için kullanacağınız kod:", 
            resetCode, 
            "#e74c3c" // Uyarı için kırmızı tema
        );
    }

    // =====================================================================================
    // ========================= YARDIMCI VE YAPISAL METODLAR ==============================
    // =====================================================================================

    // Tüm maillerin ortak olarak gönderildiği çekirdek metod
    private void sendEmailTemplate(String toEmail, String subject, String headerTitle, String bodyText, String code, String colorCode) {
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
            
            helper.setFrom(senderEmail); 
            helper.setTo(toEmail);
            helper.setSubject(subject);
            
            // HTML içeriğini oluşturucu metoddan alıyoruz
            String htmlContent = buildHtmlTemplate(headerTitle, bodyText, code, colorCode);
            helper.setText(htmlContent, true);
            
            mailSender.send(message);
            log.info("HTML E-posta BAŞARIYLA gönderildi: {}", toEmail); // Konsolda yeşil/beyaz temiz log
        } catch (Exception e) {
            log.error("E-POSTA GÖNDERİLEMEDİ! Hata Detayı: {}", e.getMessage()); // Konsolda kırmızı hata logu
        }
    }

    // Maillerin tüm e-posta istemcilerinde (Gmail, Apple Mail, Outlook) kusursuz görünmesi için 
    // modern ve "Table" (Tablo) tabanlı Responsive HTML üreten metod
    private String buildHtmlTemplate(String headerTitle, String bodyText, String code, String colorCode) {
        return "<!DOCTYPE html>"
             + "<html>"
             + "<head><meta charset='UTF-8'></head>"
             + "<body style='margin: 0; padding: 0; background-color: #f4f7f6; font-family: Helvetica, Arial, sans-serif;'>"
             + "  <table width='100%' cellpadding='0' cellspacing='0' style='background-color: #f4f7f6; padding: 40px 20px;'>"
             + "    <tr>"
             + "      <td align='center'>"
             + "        <table width='600' cellpadding='0' cellspacing='0' style='background-color: #ffffff; border-radius: 12px; box-shadow: 0 4px 15px rgba(0,0,0,0.1); overflow: hidden;'>"
             // ÜST BİLGİ (HEADER) BÖLÜMÜ
             + "          <tr>"
             + "            <td style='background-color: " + colorCode + "; padding: 35px 20px; text-align: center;'>"
             + "              <h1 style='color: #ffffff; margin: 0; font-size: 28px; letter-spacing: 2px;'>DÜNYA ÜLKELERİ</h1>"
             + "              <p style='color: #ffffff; margin: 10px 0 0 0; font-size: 16px; opacity: 0.9;'>" + headerTitle + "</p>"
             + "            </td>"
             + "          </tr>"
             // İÇERİK VE KOD BÖLÜMÜ
             + "          <tr>"
             + "            <td style='padding: 40px 30px; text-align: center;'>"
             + "              <h3 style='color: #333333; font-weight: normal; margin-top: 0; font-size: 18px;'>" + bodyText + "</h3>"
             + "              <div style='margin: 30px auto; padding: 25px 40px; background-color: #fcfcfc; border: 3px dashed " + colorCode + "; display: inline-block; border-radius: 12px;'>"
             + "                <h1 style='font-size: 48px; letter-spacing: 12px; color: #111111; margin: 0;'>" + code + "</h1>"
             + "              </div>"
             + "              <p style='font-size: 14px; color: #777777; margin-top: 30px; line-height: 1.5;'>"
             + "                Güvenliğiniz için bu doğrulama kodunu hiç kimseyle paylaşmayın.<br>Eğer bu işlemi siz başlatmadıysanız, lütfen bu e-postayı dikkate almayın."
             + "              </p>"
             + "            </td>"
             + "          </tr>"
             // ALT BİLGİ (FOOTER) BÖLÜMÜ
             + "          <tr>"
             + "            <td style='background-color: #f9f9f9; padding: 20px; text-align: center; border-top: 1px solid #eeeeee;'>"
             + "              <p style='margin: 0; color: #aaaaaa; font-size: 12px;'>© 2024 Dünya Ülkeleri. Tüm hakları saklıdır.</p>"
             + "            </td>"
             + "          </tr>"
             + "        </table>"
             + "      </td>"
             + "    </tr>"
             + "  </table>"
             + "</body>"
             + "</html>";
    }
}