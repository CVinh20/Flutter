import { useState, useEffect } from 'react';
import './Hero.css';

const Hero = () => {
  const [displayText, setDisplayText] = useState('');
  const fullText = 'Sinh Viên Công Nghệ Thông Tin';
  const [index, setIndex] = useState(0);

  useEffect(() => {
    if (index < fullText.length) {
      const timeout = setTimeout(() => {
        setDisplayText(prev => prev + fullText[index]);
        setIndex(index + 1);
      }, 100);
      return () => clearTimeout(timeout);
    }
  }, [index]);

  return (
    <section className="hero">
      <div className="hero-content">
        <div className="hero-text">
          <h1 className="hero-title">
            Xin chào, tôi là <span className="highlight">Nguyễn Anh Khôi</span>
          </h1>
          <h2 className="hero-subtitle">
            <span className="typing-text">{displayText}</span>
            <span className="cursor">|</span>
          </h2>
          <p className="hero-description">
            Sinh viên năm cuối ngành Công Nghệ Thông Tin, đam mê lập trình web và 
            luôn học hỏi các công nghệ mới. Tìm kiếm cơ hội thực tập và phát triển kỹ năng.
          </p>
          <div className="hero-buttons">
            <a href="#projects" className="btn btn-primary">Xem Dự Án</a>
            <a href="#contact" className="btn btn-secondary">Liên Hệ</a>
          </div>
        </div>
        <div className="hero-image">
          <div className="image-container">
            <div className="circle-decoration"></div>
            <div className="profile-placeholder">
              <img 
                src="/Profile.jpg" 
                alt="Profile" 
                style={{
                  width: '100%', 
                  height: '100%', 
                  objectFit: 'cover', 
                  borderRadius: '50%'
                }} 
              />
            </div>
          </div>
        </div>
      </div>
      <div className="scroll-indicator">
        <div className="mouse"></div>
        <span>Scroll Down</span>
      </div>
    </section>
  );
};

export default Hero;
