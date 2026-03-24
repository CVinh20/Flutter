// backend/services/EmailService.js
const nodemailer = require('nodemailer');

class EmailService {
  constructor() {
    // Khởi tạo transporter với cấu hình từ environment variables
    this.transporter = nodemailer.createTransport({
      host: process.env.SMTP_HOST || 'smtp.gmail.com',
      port: parseInt(process.env.SMTP_PORT || '587'),
      secure: process.env.SMTP_SECURE === 'true', // true for 465, false for other ports
      auth: {
        user: process.env.SMTP_USER, // Email của bạn
        pass: process.env.SMTP_PASS, // App password của Gmail hoặc mật khẩu email
      },
    });
  }

  // Gửi email đặt lại mật khẩu
  async sendPasswordResetEmail(email, resetToken) {
    // Tạo reset link - trong production thay localhost bằng domain thật
    const resetLink = `${process.env.FRONTEND_URL || 'http://localhost:3000'}/reset-password?token=${resetToken}`;

    const mailOptions = {
      from: `"${process.env.APP_NAME || 'Gentlemen Grooming'}" <${process.env.SMTP_USER}>`,
      to: email,
      subject: 'Đặt lại mật khẩu tài khoản',
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <style>
            body {
              font-family: 'Segoe UI', Arial, sans-serif;
              line-height: 1.6;
              color: #333;
              background-color: #f4f4f4;
              margin: 0;
              padding: 0;
            }
            .container {
              max-width: 600px;
              margin: 20px auto;
              background: white;
              border-radius: 10px;
              overflow: hidden;
              box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            }
            .header {
              background: linear-gradient(135deg, #0891B2 0%, #06B6D4 100%);
              color: white;
              padding: 30px 20px;
              text-align: center;
            }
            .header h1 {
              margin: 0;
              font-size: 24px;
            }
            .content {
              padding: 30px 40px;
            }
            .button {
              display: inline-block;
              background: linear-gradient(135deg, #0891B2 0%, #06B6D4 100%);
              color: white;
              text-decoration: none;
              padding: 12px 30px;
              border-radius: 5px;
              margin: 20px 0;
              font-weight: bold;
            }
            .button:hover {
              opacity: 0.9;
            }
            .footer {
              background: #f8f8f8;
              padding: 20px;
              text-align: center;
              font-size: 12px;
              color: #666;
            }
            .warning {
              background: #fff3cd;
              border-left: 4px solid #ffc107;
              padding: 12px;
              margin: 20px 0;
              border-radius: 4px;
            }
            .code-box {
              background: #f5f5f5;
              border: 1px dashed #ccc;
              padding: 15px;
              text-align: center;
              font-size: 18px;
              font-weight: bold;
              letter-spacing: 2px;
              margin: 20px 0;
              border-radius: 5px;
            }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>🔐 Đặt Lại Mật Khẩu</h1>
            </div>
            <div class="content">
              <p>Xin chào,</p>
              <p>Chúng tôi nhận được yêu cầu đặt lại mật khẩu cho tài khoản của bạn tại <strong>${process.env.APP_NAME || 'Gentlemen Grooming'}</strong>.</p>
              
              <p>Nhấp vào nút bên dưới để đặt lại mật khẩu:</p>
              
              <div style="text-align: center;">
                <a href="${resetLink}" class="button">Đặt Lại Mật Khẩu</a>
              </div>
              
              <p>Hoặc sao chép và dán link sau vào trình duyệt:</p>
              <div class="code-box">${resetLink}</div>
              
              <div class="warning">
                <strong>⚠️ Lưu ý quan trọng:</strong>
                <ul style="margin: 10px 0; padding-left: 20px;">
                  <li>Link này chỉ có hiệu lực trong <strong>1 giờ</strong></li>
                  <li>Nếu bạn không yêu cầu đặt lại mật khẩu, vui lòng bỏ qua email này</li>
                  <li>Không chia sẻ link này với bất kỳ ai</li>
                </ul>
              </div>
              
              <p>Nếu bạn gặp bất kỳ vấn đề nào, vui lòng liên hệ với chúng tôi.</p>
              
              <p>Trân trọng,<br>
              <strong>Đội ngũ ${process.env.APP_NAME || 'Gentlemen Grooming'}</strong></p>
            </div>
            <div class="footer">
              <p>Email này được gửi tự động, vui lòng không trả lời.</p>
              <p>&copy; ${new Date().getFullYear()} ${process.env.APP_NAME || 'Gentlemen Grooming'}. All rights reserved.</p>
            </div>
          </div>
        </body>
        </html>
      `,
    };

    try {
      const info = await this.transporter.sendMail(mailOptions);
      console.log('✅ Email sent successfully:', info.messageId);
      return { success: true, messageId: info.messageId };
    } catch (error) {
      console.error('❌ Error sending email:', error);
      throw new Error('Failed to send email: ' + error.message);
    }
  }

  // Gửi email chào mừng khi đăng ký
  async sendWelcomeEmail(email, displayName) {
    const mailOptions = {
      from: `"${process.env.APP_NAME || 'Gentlemen Grooming'}" <${process.env.SMTP_USER}>`,
      to: email,
      subject: 'Chào mừng đến với Gentlemen Grooming!',
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <style>
            body {
              font-family: 'Segoe UI', Arial, sans-serif;
              line-height: 1.6;
              color: #333;
              background-color: #f4f4f4;
              margin: 0;
              padding: 0;
            }
            .container {
              max-width: 600px;
              margin: 20px auto;
              background: white;
              border-radius: 10px;
              overflow: hidden;
              box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            }
            .header {
              background: linear-gradient(135deg, #0891B2 0%, #06B6D4 100%);
              color: white;
              padding: 30px 20px;
              text-align: center;
            }
            .content {
              padding: 30px 40px;
            }
            .footer {
              background: #f8f8f8;
              padding: 20px;
              text-align: center;
              font-size: 12px;
              color: #666;
            }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>🎉 Chào Mừng!</h1>
            </div>
            <div class="content">
              <p>Xin chào <strong>${displayName}</strong>,</p>
              <p>Cảm ơn bạn đã đăng ký tài khoản tại <strong>${process.env.APP_NAME || 'Gentlemen Grooming'}</strong>!</p>
              <p>Bạn đã có thể sử dụng đầy đủ các tính năng của ứng dụng.</p>
              <p>Chúc bạn có những trải nghiệm tuyệt vời!</p>
              <p>Trân trọng,<br><strong>Đội ngũ ${process.env.APP_NAME || 'Gentlemen Grooming'}</strong></p>
            </div>
            <div class="footer">
              <p>&copy; ${new Date().getFullYear()} ${process.env.APP_NAME || 'Gentlemen Grooming'}. All rights reserved.</p>
            </div>
          </div>
        </body>
        </html>
      `,
    };

    try {
      const info = await this.transporter.sendMail(mailOptions);
      console.log('✅ Welcome email sent:', info.messageId);
      return { success: true, messageId: info.messageId };
    } catch (error) {
      console.error('❌ Error sending welcome email:', error);
      // Không throw error vì đây không phải lỗi nghiêm trọng
      return { success: false, error: error.message };
    }
  }

  // Test kết nối SMTP
  async testConnection() {
    try {
      await this.transporter.verify();
      console.log('✅ SMTP connection successful');
      return true;
    } catch (error) {
      console.error('❌ SMTP connection failed:', error);
      return false;
    }
  }
}

module.exports = new EmailService();
