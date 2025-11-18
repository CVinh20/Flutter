import { useEffect, useRef, useState } from 'react';
import './Technologies.css';

const Technologies = () => {
  const [isVisible, setIsVisible] = useState(false);
  const sectionRef = useRef<HTMLElement>(null);

  useEffect(() => {
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setIsVisible(true);
        }
      },
      { threshold: 0.2 }
    );

    if (sectionRef.current) {
      observer.observe(sectionRef.current);
    }

    return () => {
      if (sectionRef.current) {
        observer.unobserve(sectionRef.current);
      }
    };
  }, []);

  return (
    <section className="technologies" id="technologies" ref={sectionRef}>
      <div className="technologies-container">
        <div className={`section-header ${isVisible ? 'fade-in' : ''}`}>
          <h2 className="section-title">Công Nghệ & Kỹ Năng</h2>
          <div className="title-underline"></div>
          <p className="section-subtitle">
            Các công nghệ và công cụ tôi sử dụng trong phát triển
          </p>
        </div>

        <div className={`learning-section ${isVisible ? 'slide-up' : ''}`}>
          <h3>🎯 Đang Học & Phát Triển</h3>
          <div className="learning-items">
            {['Next.js', 'GraphQL', 'Docker', 'PostgreSQL', 'AWS', 'Testing (Jest)'].map((tech, index) => (
              <span 
                key={tech}
                className={`learning-tag ${isVisible ? 'pop-in' : ''}`}
                style={{ animationDelay: `${index * 0.1}s` }}
              >
                {tech}
              </span>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
};

export default Technologies;
