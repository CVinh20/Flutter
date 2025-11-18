import { useScrollAnimation } from '../hooks/useScrollAnimation';
import './About.css';

const About = () => {
  const { ref: sectionRef, isVisible } = useScrollAnimation(0.2);
  
  const skills = [
    { name: 'HTML/CSS', level: 85, icon: '🎨' },
    { name: 'JavaScript', level: 75, icon: '📜' },
    { name: 'React', level: 70, icon: '⚛️' },
    { name: 'TypeScript', level: 60, icon: '📘' },
    { name: 'Node.js', level: 65, icon: '🟢' },
    { name: 'Git/GitHub', level: 80, icon: '📊' },
    { name: 'Java', level: 70, icon: '☕' },
    { name: 'SQL', level: 65, icon: '🗄️' },
  ];



  return (
    <section className="about" id="about" ref={sectionRef as React.RefObject<HTMLElement>}>
      <div className="about-container">
        <div className={`section-header ${isVisible ? 'animate-fadeInUp' : 'animate-on-scroll'}`}>
          <h2 className="section-title">Ỡ Tôi</h2>
          <div className="title-underline"></div>
        </div>

        <div className="about-content">
          <div className={`about-text ${isVisible ? 'animate-fadeInLeft' : 'animate-on-scroll'}`}>
            <h3>Giới thiệu</h3>
            <p>
              Xin chào! Tôi là sinh viên năm cuối ngành Công Nghệ Thông Tin, đam mê lập trình 
              web và xây dựng các ứng dụng có ý nghĩa. Tôi luôn háo hức học hỏi công nghệ mới 
              và không ngừng trau dồi kỹ năng thông qua các dự án cá nhân.
            </p>
            <p>
              Mục tiêu của tôi là trở thành một Full Stack Developer chuyên nghiệp. Tôi tin rằng 
              sự kết hợp giữa kiến thức nền tảng vững chắc và đam mê học hỏi sẽ giúp tôi đóng góp 
              giá trị thực cho team và dự án.
            </p>
            <div className="stats">
              <div className={`stat-item ${isVisible ? 'animate-scaleIn delay-100' : 'animate-on-scroll'}`}>
                <h4>7+</h4>
                <p>Dự Án Cá Nhân</p>
              </div>
              <div className={`stat-item ${isVisible ? 'animate-scaleIn delay-200' : 'animate-on-scroll'}`}>
                <h4>2.9</h4>
                <p>GPA</p>
              </div>
              <div className={`stat-item ${isVisible ? 'animate-scaleIn delay-300' : 'animate-on-scroll'}`}>
                <h4>100+</h4>
                <p>Bài Tập Hoàn Thành</p>
              </div>
            </div>
          </div>

          <div className={`skills-section ${isVisible ? 'animate-fadeInRight' : 'animate-on-scroll'}`}>
            <h3>Kỹ Năng</h3>
            <div className="skills-grid">
              {skills.map((skill, index) => (
                <div key={index} className={`skill-item ${isVisible ? `animate-fadeInUp delay-${Math.min(index * 100, 500)}` : 'animate-on-scroll'}`}>
                  <div className="skill-header">
                    <span className="skill-icon">{skill.icon}</span>
                    <span className="skill-name">{skill.name}</span>
                    <span className="skill-level">{skill.level}%</span>
                  </div>
                  <div className="skill-bar">
                    <div 
                      className="skill-progress" 
                      style={{ width: `${skill.level}%` }}
                    ></div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

       
      </div>
    </section>
  );
};

export default About;
