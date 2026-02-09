// Main JavaScript - объединение всех модулей
// Scroll Indicator
const initScrollIndicator = () => {
    const scrollIndicator = document.querySelector('.scroll-indicator');
    if (!scrollIndicator) return;
    
    const indicatorBar = document.createElement('div');
    indicatorBar.className = 'indicator-bar';
    scrollIndicator.appendChild(indicatorBar);
    
    const updateScrollIndicator = () => {
        const windowHeight = document.documentElement.scrollHeight - window.innerHeight;
        const scrolled = (window.pageYOffset / windowHeight) * 100;
        indicatorBar.style.width = scrolled + '%';
    };
    
    window.addEventListener('scroll', updateScrollIndicator);
    updateScrollIndicator();
};

// Scroll animations - анимация появления блоков при скролле
const initScrollAnimations = () => {
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -100px 0px'
    };
    
    const mobileObserverOptions = {
        threshold: 0.15,
        rootMargin: '0px 0px -50px 0px'
    };

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('visible');
                observer.unobserve(entry.target);
            }
        });
    }, observerOptions);
    
    // Более агрессивный observer для мобильных
    const isMobile = window.innerWidth <= 767;
    const activeObserver = isMobile ? new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('visible');
                // Добавляем дополнительный класс для более заметной анимации на мобильных
                if (isMobile) {
                    entry.target.classList.add('mobile-animated');
                }
                observer.unobserve(entry.target);
            }
        });
    }, mobileObserverOptions) : observer;

    // Наблюдаем за блоками направлений
    document.querySelectorAll('.direction-block').forEach(block => {
        activeObserver.observe(block);
    });

    // Наблюдаем за элементами преимуществ
    document.querySelectorAll('.benefit-item').forEach(item => {
        activeObserver.observe(item);
    });
    
    // Наблюдаем за элементами списка "Для кого"
    document.querySelectorAll('.audience-list li').forEach(item => {
        activeObserver.observe(item);
    });
    
    // Наблюдаем за заголовками секций
    document.querySelectorAll('.section-title').forEach(title => {
        activeObserver.observe(title);
    });
};

// Parallax effect - плавные эффекты при скролле
const initParallax = () => {
    let ticking = false;
    
    const updateParallax = () => {
        const scrolled = window.pageYOffset;
        const hero = document.querySelector('.hero');
        const logo = document.querySelector('.logo-image');
        const windowHeight = window.innerHeight;
        
        // Параллакс для hero секции - только в пределах первого экрана
        if (hero && scrolled < windowHeight) {
            const parallax = scrolled * 0.15;
            hero.style.transform = `translateY(${parallax}px)`;
        } else if (hero && scrolled >= windowHeight) {
            hero.style.transform = `translateY(${windowHeight * 0.15}px)`;
        }
        
        // Параллакс для логотипа - более мягкий
        if (logo && scrolled < windowHeight) {
            const logoParallax = scrolled * 0.1;
            const scale = Math.max(0.8, 1 - scrolled * 0.0003);
            const opacity = Math.max(0.3, 1 - scrolled * 0.001);
            logo.style.transform = `translateY(${logoParallax}px) scale(${scale})`;
            logo.style.opacity = opacity;
        } else if (logo && scrolled >= windowHeight) {
            const maxParallax = windowHeight * 0.1;
            logo.style.transform = `translateY(${maxParallax}px) scale(0.8)`;
            logo.style.opacity = 0.3;
        }
        
        ticking = false;
    };
    
    const requestTick = () => {
        if (!ticking) {
            requestAnimationFrame(updateParallax);
            ticking = true;
        }
    };
    
    window.addEventListener('scroll', requestTick, { passive: true });
    updateParallax(); // Инициализация
};

// CTA Button interactions - теперь кнопки это ссылки, обработчик не нужен
const initCTAButtons = () => {
    // Кнопки теперь ссылки, дополнительная обработка не требуется
    // Но можно добавить fallback для веб-версии
    const ctaButtons = document.querySelectorAll('.cta-button');
    
    ctaButtons.forEach(button => {
        // Добавляем обработчик для fallback на веб-версию
        button.addEventListener('click', (e) => {
            // Если это ссылка с tg://, добавляем fallback
            if (button.href && button.href.startsWith('tg://')) {
                const telegramId = '6955298371';
                const messageText = 'по предзаказу';
                const webUrl = `https://t.me/user/${telegramId}?text=${encodeURIComponent(messageText)}`;
                
                // Fallback для веб-версии (если десктопное приложение не установлено)
                setTimeout(() => {
                    window.open(webUrl, '_blank');
                }, 1000);
            }
        });
    });
};

// Smooth scroll to top on page load/refresh with beautiful animation
const initSmoothScrollToTop = () => {
    // Отключаем автоматическое восстановление позиции скролла
    if ('scrollRestoration' in history) {
        history.scrollRestoration = 'manual';
    }
    
    // Сразу скроллим наверх без анимации (мгновенно) - но только если страница уже загружена
    if (document.readyState === 'complete') {
        window.scrollTo(0, 0);
        document.documentElement.scrollTop = 0;
        document.body.scrollTop = 0;
    } else {
        // Если страница еще загружается, ждем полной загрузки
        window.addEventListener('load', () => {
            window.scrollTo(0, 0);
            document.documentElement.scrollTop = 0;
            document.body.scrollTop = 0;
        });
    }
    
    // Также при DOMContentLoaded
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => {
            window.scrollTo(0, 0);
            document.documentElement.scrollTop = 0;
        });
    }
};

// Reset button animation - упрощено
const resetButtonAnimation = () => {
    // Анимации кнопок теперь в CSS, без сложной логики
};

// Splash Screen
const initSplashScreen = () => {
    const splashScreen = document.getElementById('splashScreen');
    if (!splashScreen) return;
    
    // Скрываем заставку после загрузки страницы
    const hideSplash = () => {
        splashScreen.classList.add('hidden');
        // Удаляем элемент из DOM после анимации
        setTimeout(() => {
            if (splashScreen.parentNode) {
                splashScreen.remove();
            }
        }, 800);
    };
    
    // Проверяем, загружена ли страница
    if (document.readyState === 'complete') {
        setTimeout(hideSplash, 2500); // Минимум 2.5 секунды показа
    } else {
        window.addEventListener('load', () => {
            setTimeout(hideSplash, 2500);
        });
    }
    
    // Также скрываем при клике на заставку (если пользователь хочет пропустить)
    splashScreen.addEventListener('click', () => {
        hideSplash();
    });
};

// Initialize all modules when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    initSplashScreen();
    initSmoothScrollToTop();
    resetButtonAnimation();
    initScrollIndicator();
    initScrollAnimations();
    initParallax();
    initCTAButtons();
});
