import { useState } from 'react';
import './Contact.css';
import { useScrollAnimation } from '../hooks/useScrollAnimation';

const Contact = () => {
  const { ref: sectionRef, isVisible } = useScrollAnimation(0.1);
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    message: ''
  });

  const [status, setStatus] = useState('');

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    });
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setStatus('Cảm ơn bạn! Tin nhắn đã được gửi đi.');
    setFormData({ name: '', email: '', message: '' });
    setTimeout(() => setStatus(''), 3000);
  };

  const socialLinks = [
    { name: 'GitHub', icon: '💻', url: 'https://github.com/NguyenAnnhKhoi', color: '#333' },
    { name: 'Facebook', icon: '👤', url: 'https://www.facebook.com/anhkhoi.nguyen.3979/', color: '#1877f2' },
    { name: 'Email', icon: '📧', url: 'lionjoki08@gmail.com', color: '#ea4335' }
  ];

  const contactInfo = [
    { icon: '🎓', label: 'Trường', value: 'Đại Học Công Nghệ TP.HCM-HUTECH' },
    { icon: '📧', label: 'Email', value: 'lionjoki08@gmail.com' },
    { icon: '📱', label: 'Điện thoại', value: '0344091018' }
  ];

  return (
    <section className="contact" id="contact" ref={sectionRef as React.RefObject<HTMLElement>}>
      <div className="contact-container">
        <div className={`section-header ${isVisible ? 'animate-fadeInUp' : 'animate-on-scroll'}`}>
          <h2 className="section-title">Liên Hệ</h2>
          <div className="title-underline"></div>
          <p className="section-subtitle">
            Hãy kết nối với tôi! Tôi đang tìm kiếm cơ hội thực tập và học hỏi
          </p>
        </div>

        <div className="contact-content">
          <div className={`contact-info-section ${isVisible ? 'animate-fadeInLeft' : 'animate-on-scroll'}`}>
            <h3>Thông Tin Liên Hệ</h3>
            <div className="contact-info-list">
              {contactInfo.map((info, index) => (
                <div key={index} className={`contact-info-item ${isVisible ? `animate-fadeInUp delay-${index * 100}` : 'animate-on-scroll'}`}>
                  <span className="info-icon">{info.icon}</span>
                  <div className="info-text">
                    <p className="info-label">{info.label}</p>
                    <p className="info-value">{info.value}</p>
                  </div>
                </div>
              ))}
            </div>

            <div className="social-section">
              <h4>Theo dõi tôi trên</h4>
              <div className="social-links">
                {socialLinks.map((social, index) => (
                  <a
                    key={index}
                    href={social.url}
                    className="social-link"
                    target="_blank"
                    rel="noopener noreferrer"
                    style={{ '--hover-color': social.color } as React.CSSProperties}
                  >
                    <span className="social-icon">{social.icon}</span>
                    <span className="social-name">{social.name}</span>
                  </a>
                ))}
              </div>
            </div>

            <div className="availability">
              <div className="availability-indicator">
                <span className="status-dot"></span>
                <span className="status-text">Đang tìm cơ hội thực tập</span>
              </div>
            </div>
          </div>

          <div className={`contact-form-section ${isVisible ? 'animate-fadeInRight' : 'animate-on-scroll'}`}>
            <h3>Gửi Tin Nhắn</h3>
            <form className="contact-form" onSubmit={handleSubmit}>
              <div className="form-group">
                <label htmlFor="name">Tên của bạn</label>
                <input
                  type="text"
                  id="name"
                  name="name"
                  value={formData.name}
                  onChange={handleChange}
                  required
                  placeholder="Nhập tên của bạn"
                />
              </div>

              <div className="form-group">
                <label htmlFor="email">Email</label>
                <input
                  type="email"
                  id="email"
                  name="email"
                  value={formData.email}
                  onChange={handleChange}
                  required
                  placeholder="your.email@example.com"
                />
              </div>

              <div className="form-group">
                <label htmlFor="message">Tin nhắn</label>
                <textarea
                  id="message"
                  name="message"
                  value={formData.message}
                  onChange={handleChange}
                  required
                  rows={6}
                  placeholder="Nội dung tin nhắn của bạn..."
                />
              </div>

              <button type="submit" className="submit-btn">
                <span>Gửi Tin Nhắn</span>
                <span className="btn-icon">✉️</span>
              </button>

              {status && <p className="form-status">{status}</p>}
            </form>
          </div>
        </div>
      </div>

      <footer className="footer">
        <p>© 2025 Nguyễn Anh Khôi. Made with ❤️ in Vietnam</p>
      </footer>
    </section>
  );
};

export default Contact;
