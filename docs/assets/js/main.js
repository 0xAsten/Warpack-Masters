document.addEventListener('DOMContentLoaded', function() {
  // Mobile navigation toggle
  const menuToggle = document.createElement('button');
  menuToggle.className = 'menu-toggle';
  menuToggle.innerHTML = '<span></span><span></span><span></span>';
  menuToggle.setAttribute('aria-label', 'Toggle Navigation');
  
  const siteNav = document.querySelector('.site-nav');
  if (siteNav) {
    siteNav.parentNode.insertBefore(menuToggle, siteNav);
    
    menuToggle.addEventListener('click', function() {
      siteNav.classList.toggle('active');
      menuToggle.classList.toggle('active');
    });
  }
  
  // Add copy button to code blocks
  document.querySelectorAll('pre code').forEach(function(codeBlock) {
    const container = codeBlock.parentNode;
    const copyButton = document.createElement('button');
    copyButton.className = 'copy-button';
    copyButton.textContent = 'Copy';
    
    container.style.position = 'relative';
    container.appendChild(copyButton);
    
    copyButton.addEventListener('click', function() {
      const code = codeBlock.textContent;
      navigator.clipboard.writeText(code).then(function() {
        copyButton.textContent = 'Copied!';
        setTimeout(function() {
          copyButton.textContent = 'Copy';
        }, 2000);
      });
    });
  });
  
  // Smooth scrolling for anchor links
  document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function(e) {
      const targetId = this.getAttribute('href');
      if (targetId !== '#') {
        const targetElement = document.querySelector(targetId);
        if (targetElement) {
          e.preventDefault();
          targetElement.scrollIntoView({
            behavior: 'smooth',
            block: 'start'
          });
        }
      }
    });
  });
});