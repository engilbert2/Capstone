document.addEventListener('DOMContentLoaded', function() {
    // DOM Elements
    const loginForm = document.getElementById('loginForm');
    const verificationForm = document.getElementById('verificationForm');
    const passwordInput = document.getElementById('password');
    const alertBox = document.getElementById('alertBox');
    const verificationAlert = document.getElementById('verificationAlert');
    const loginSection = document.getElementById('login-section');
    const verificationSection = document.getElementById('verification-section');
    const captchaSection = document.getElementById('captcha-section');
    const emailMessage = document.getElementById('emailMessage');
    const resendCodeLink = document.getElementById('resend-code');
    const verifyCaptchaBtn = document.getElementById('verify-captcha-btn');
    const captchaOptions = document.querySelectorAll('.captcha-option');
    const notRobotCheckbox = document.getElementById('not-robot');
    const codeInputs = document.querySelectorAll('.code-input');

    // State variables
    let currentUserId = null;
    let currentUserEmail = null;
    let currentUsername = null;
    let isAdminUser = false;
    let captchaCode = '';
    let selectedOption = null;

    // API Configuration
    const API_BASE_URL = 'http://localhost/arco_api';
    const AUTH_ENDPOINT = `${API_BASE_URL}/auth.php`;

    // Code input auto-focus
    codeInputs.forEach((input, index) => {
        input.addEventListener('input', () => {
            if (input.value && index < codeInputs.length - 1) {
                codeInputs[index + 1].focus();
            }
        });

        input.addEventListener('keydown', (e) => {
            if (e.key === 'Backspace' && !input.value && index > 0) {
                codeInputs[index - 1].focus();
            }
        });
    });

    // CAPTCHA option selection
    captchaOptions.forEach(option => {
        option.addEventListener('click', () => {
            captchaOptions.forEach(opt => opt.classList.remove('selected'));
            option.classList.add('selected');
            selectedOption = option.textContent;
            updateCaptchaButtonState();
        });
    });

    // Robot checkbox
    notRobotCheckbox.addEventListener('change', updateCaptchaButtonState);

    // Handle form submission
    loginForm.addEventListener('submit', function(e) {
        e.preventDefault();

        const username = document.getElementById('username').value;
        const password = document.getElementById('password').value;

        // Show loading state
        const loginBtn = loginForm.querySelector('.login-btn');
        loginBtn.innerHTML = 'Logging in... <i class="fas fa-spinner fa-spin"></i>';
        loginBtn.disabled = true;

        // Call login API
        loginUser(username, password);
    });

    // Handle verification form submission
    verificationForm.addEventListener('submit', function(e) {
        e.preventDefault();

        const code = Array.from(codeInputs).map(input => input.value).join('');

        if (code.length !== 6) {
            showAlert(verificationAlert, 'Please enter a complete 6-digit code', 'error');
            return;
        }

        // Show loading state
        const verifyBtn = verificationForm.querySelector('.login-btn');
        verifyBtn.innerHTML = 'Verifying... <i class="fas fa-spinner fa-spin"></i>';
        verifyBtn.disabled = true;

        // Call verification API
        verifyCode(currentUserId, code);
    });

    // Handle CAPTCHA verification for ADMIN users
    verifyCaptchaBtn.addEventListener('click', function() {
        if (selectedOption === captchaCode && notRobotCheckbox.checked) {
            // CAPTCHA verified successfully for ADMIN users
            showAlert(alertBox, 'CAPTCHA verified successfully! Redirecting to admin dashboard...', 'success');

            // Redirect to admin dashboard
            setTimeout(() => {
                window.location.href = "admin_dashboard.html";
            }, 2000);
        } else {
            showAlert(alertBox, 'CAPTCHA verification failed. Please try again.', 'error');
            generateCaptcha();
        }
    });

    // Handle resend code
    resendCodeLink.addEventListener('click', function(e) {
        e.preventDefault();
        resendVerificationCode(currentUserId, currentUserEmail);
    });

    // Function to update CAPTCHA button state
    function updateCaptchaButtonState() {
        verifyCaptchaBtn.disabled = !(selectedOption && notRobotCheckbox.checked);
    }

    // Function to generate CAPTCHA
    function generateCaptcha() {
        // Generate a random 4-digit code
        captchaCode = Math.floor(1000 + Math.random() * 9000).toString();
        document.getElementById('captcha-display').textContent = captchaCode;

        // Generate options (one correct, two incorrect)
        const options = [captchaCode];
        while (options.length < 3) {
            const randomCode = Math.floor(1000 + Math.random() * 9000).toString();
            if (!options.includes(randomCode)) {
                options.push(randomCode);
            }
        }

        // Shuffle options
        options.sort(() => Math.random() - 0.5);

        // Update DOM
        captchaOptions.forEach((option, index) => {
            option.textContent = options[index];
        });

        // Reset selection
        captchaOptions.forEach(opt => opt.classList.remove('selected'));
        selectedOption = null;
        notRobotCheckbox.checked = false;
        updateCaptchaButtonState();
    }

    // Function to show alert messages
    function showAlert(alertElement, message, type) {
        alertElement.textContent = message;
        alertElement.className = 'alert';
        alertElement.classList.add(type === 'error' ? 'alert-error' : 'alert-success');
        alertElement.style.display = 'block';

        // Hide alert after 5 seconds
        setTimeout(() => {
            alertElement.style.display = 'none';
        }, 5000);
    }

    // Function to login user (ADMIN ONLY)
    function loginUser(username, password) {
        // Test the API endpoint first
        testApiEndpoint()
            .then(() => {
                // If test passes, make the actual login request
                fetch(AUTH_ENDPOINT, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({
                        action: 'login',
                        username: username,
                        password: password
                    })
                })
                .then(response => {
                    if (!response.ok) {
                        throw new Error(`HTTP error! Status: ${response.status}`);
                    }
                    return response.json();
                })
                .then(data => {
                    if (data.success) {
                        if (data.requires_2fa) {
                            // Store user data for verification
                            currentUserId = data.user_id;
                            currentUserEmail = data.user_email;
                            currentUsername = username;
                            isAdminUser = data.is_admin || false;

                            // Show verification section
                            loginSection.style.display = 'none';
                            verificationSection.style.display = 'block';

                            // SHOW PROPER FEEDBACK ABOUT EMAIL STATUS
                            if (data.email_sent) {
                                emailMessage.textContent = `Verification code sent to ${data.user_email}`;
                                showAlert(alertBox, 'Verification code sent to your email', 'success');
                            } else {
                                emailMessage.textContent = `Failed to send email to ${data.user_email}. Please contact support.`;
                                showAlert(alertBox, 'Failed to send verification email. Please try again or contact support.', 'error');
                            }
                        } else {
                            // No 2FA required
                            showAlert(alertBox, 'Login successful! Redirecting...', 'success');
                            setTimeout(() => {
                                window.location.href = "admin_dashboard.html";
                            }, 2000);
                        }
                    } else {
                        showAlert(alertBox, data.message, 'error');

                        // Reset login button
                        const loginBtn = loginForm.querySelector('.login-btn');
                        loginBtn.innerHTML = 'Login';
                        loginBtn.disabled = false;
                    }
                })
                .catch(error => {
                    showAlert(alertBox, `API Error: ${error.message}`, 'error');

                    // Reset login button
                    const loginBtn = loginForm.querySelector('.login-btn');
                    loginBtn.innerHTML = 'Login';
                    loginBtn.disabled = false;
                });
            })
            .catch(error => {
                showAlert(alertBox, `Connection Error: ${error.message}`, 'error');

                // Reset login button
                const loginBtn = loginForm.querySelector('.login-btn');
                loginBtn.innerHTML = 'Login';
                loginBtn.disabled = false;
            });
    }

    // Function to test API endpoint
    function testApiEndpoint() {
        return fetch(AUTH_ENDPOINT, {
            method: 'OPTIONS'
        })
        .then(response => {
            if (response.ok) {
                return Promise.resolve();
            } else {
                return Promise.reject(new Error('API endpoint not responding correctly'));
            }
        })
        .catch(error => {
            return Promise.reject(new Error('Cannot connect to API endpoint'));
        });
    }

    // Function to verify 2FA code (ADMIN ONLY)
    function verifyCode(userId, code) {
        fetch(AUTH_ENDPOINT, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                action: 'verify_token',
                user_id: userId,
                token: code
            })
        })
        .then(response => {
            if (!response.ok) {
                throw new Error(`HTTP error! Status: ${response.status}`);
            }
            return response.json();
        })
        .then(data => {
            if (data.success) {
                // Store user data for the dashboard
                localStorage.setItem('adminUser', JSON.stringify(data.user));
                sessionStorage.setItem('adminUser', JSON.stringify(data.user));

                // For ADMIN users, show CAPTCHA screen
                verificationSection.style.display = 'none';
                captchaSection.style.display = 'block';
                generateCaptcha();

                // Update the CAPTCHA title for admin
                const captchaTitle = document.querySelector('.captcha-title');
                captchaTitle.textContent = 'Admin Security Verification';
            } else {
                showAlert(verificationAlert, data.message, 'error');

                // Reset verification button
                const verifyBtn = verificationForm.querySelector('.login-btn');
                verifyBtn.innerHTML = 'Verify Code';
                verifyBtn.disabled = false;
            }
        })
        .catch(error => {
            showAlert(verificationAlert, `API Error: ${error.message}`, 'error');

            // Reset verification button
            const verifyBtn = verificationForm.querySelector('.login-btn');
            verifyBtn.innerHTML = 'Verify Code';
            verifyBtn.disabled = false;
        });
    }

    // Function to resend verification code
    function resendVerificationCode(userId, email) {
        fetch(AUTH_ENDPOINT, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                action: 'resend_code',
                user_id: userId,
                email: email
            })
        })
        .then(response => {
            if (!response.ok) {
                throw new Error(`HTTP error! Status: ${response.status}`);
            }
            return response.json();
        })
        .then(data => {
            if (data.success) {
                showAlert(verificationAlert, 'New verification code sent to your email', 'success');
            } else {
                showAlert(verificationAlert, data.message, 'error');
            }
        })
        .catch(error => {
            showAlert(verificationAlert, `API Error: ${error.message}`, 'error');
        });
    }

    // Initialize CAPTCHA
    generateCaptcha();
});