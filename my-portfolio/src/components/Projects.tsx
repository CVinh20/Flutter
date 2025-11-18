import { useState } from 'react';
import './Projects.css';
import { useScrollAnimation } from '../hooks/useScrollAnimation';

const Projects = () => {
  const { ref: sectionRef, isVisible } = useScrollAnimation(0.1);
  const [filter, setFilter] = useState('all');

  const projects = [
    {
      id: 1,
      title: "GENTLEMEN'S GROOMING",
      category: 'mobile',
      description: 'Đồ án chuyên ngành - Hệ thống quản lý đặt lịch và dịch vụ cắt tóc nam',
      technologies: ['Flutter', 'Dart', 'JavaScript', 'Firebase'],
      image: '📚',
      link: '#',
      github: '#'
    },
    {
      id: 2,
      title: 'KBV Fashion',
      category: 'web',
      description: 'Web thương mại điện tử thời trang với giao diện người dùng thân thiện',
      technologies: ['ASP.NET', 'HTML', 'SQL SERVER', 'JavaScript'],
      image: '✅',
      link: '#',
      github: '#'
    },
    {
      id: 3,
      title: 'Portfolio Website',
      category: 'web',
      description: 'Website giới thiệu bản thân với thiết kế hiện đại và responsive',
      technologies: ['React', 'TypeScript', 'CSS3'],
      image: '🎨',
      link: '#',
      github: '#'
    },
 

  ];

  const categories = [
    { id: 'all', label: 'Tất Cả' },
    { id: 'web', label: 'Web App' },
    { id: 'mobile', label: 'Mobile App' }
  ];

  const filteredProjects = filter === 'all' 
    ? projects 
    : projects.filter(project => project.category === filter);

  return (
    <section className="projects" id="projects" ref={sectionRef as React.RefObject<HTMLElement>}>
      <div className="projects-container">
        <div className={`section-header ${isVisible ? 'animate-fadeInUp' : 'animate-on-scroll'}`}>
          <h2 className="section-title">Dự Án Của Tôi</h2>
          <div className="title-underline"></div>
          <p className="section-subtitle">
            Một số dự án nổi bật mà tôi đã thực hiện
          </p>
        </div>

        <div className={`filter-buttons ${isVisible ? 'animate-fadeInUp delay-100' : 'animate-on-scroll'}`}>
          {categories.map(cat => (
            <button
              key={cat.id}
              className={`filter-btn ${filter === cat.id ? 'active' : ''}`}
              onClick={() => setFilter(cat.id)}
            >
              {cat.label}
            </button>
          ))}
        </div>

        <div className="projects-grid">
          {filteredProjects.map((project, index) => (
            <div key={project.id} className={`project-card ${isVisible ? `animate-fadeInUp delay-${Math.min(index * 100, 400)}` : 'animate-on-scroll'}`}>
              <div className="project-image">
                <div className="image-placeholder">
                  <span className="project-emoji">{project.image}</span>
                </div>
                <div className="project-overlay">
                  <a href={project.link} className="project-link" target="_blank" rel="noopener noreferrer">
                    <span>🔗</span>
                  </a>
                  <a href={project.github} className="project-link" target="_blank" rel="noopener noreferrer">
                    <span>💻</span>
                  </a>
                </div>
              </div>
              <div className="project-content">
                <h3 className="project-title">{project.title}</h3>
                <p className="project-description">{project.description}</p>
                <div className="project-technologies">
                  {project.technologies.map((tech, index) => (
                    <span key={index} className="tech-tag">{tech}</span>
                  ))}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};

export default Projects;
