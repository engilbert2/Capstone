// API Configuration
const API_BASE_URL = 'http://localhost/arco_api';

// DOM Elements
const menuItems = document.querySelectorAll('.menu-item');
const pageSections = document.querySelectorAll('.page-section');
const logoutBtn = document.getElementById('logout-btn');

// Current user data
let currentUser = null;

// Global variables to store feedback data and current filters
let allFeedback = [];
let currentFilters = {
    rating: 'all',
    date: 'all',
    status: 'all'
};

// Initialize dashboard
document.addEventListener('DOMContentLoaded', function() {
    // Load user data from session if available
    loadUserData();

    // Set up menu item click handlers
    menuItems.forEach(item => {
        if (item.id !== 'logout-btn') {
            item.addEventListener('click', () => {
                const page = item.getAttribute('data-page');
                switchPage(page);
            });
        }
    });

    // Set up logout button
    logoutBtn.addEventListener('click', handleLogout);

    // Load initial page (dashboard by default)
    switchPage('dashboard');

    // Password form submission
    document.getElementById('password-form').addEventListener('submit', handlePasswordChange);

    // Close modal when clicking on X
    document.querySelector('.close').addEventListener('click', closePasswordModal);

    // Close modal when clicking outside
    document.getElementById('password-modal').addEventListener('click', function(e) {
        if (e.target === this) {
            closePasswordModal();
        }
    });

    // Set up archived feedback toggle button
    const showArchivedBtn = document.getElementById('show-archived-btn');
    const showActiveBtn = document.getElementById('show-active-btn');

    if (showArchivedBtn) {
        showArchivedBtn.addEventListener('click', showArchivedFeedback);
    }

    if (showActiveBtn) {
        showActiveBtn.addEventListener('click', switchToActiveFeedback);
    }

    // Set up filter buttons
    document.getElementById('apply-filters-btn').addEventListener('click', applyFilters);
    document.getElementById('clear-filters-btn').addEventListener('click', clearFilters);
});

// Load user data from session
function loadUserData() {
    // Try to get user data from localStorage or session
    const userData = localStorage.getItem('adminUser') || sessionStorage.getItem('adminUser');

    if (userData) {
        try {
            currentUser = JSON.parse(userData);

            // FIX: Use the correct property names (with underscores)
            document.getElementById('admin-name').textContent =
                `${currentUser.first_name} ${currentUser.last_name}`;

            // Update avatar with initials
            const avatar = document.querySelector('.user-avatar');
            if (currentUser.first_name && currentUser.last_name) {
                avatar.textContent =
                    currentUser.first_name.charAt(0) + currentUser.last_name.charAt(0);
            }
        } catch (e) {
            console.error('Error parsing user data:', e);
        }
    }
}

// Switch between pages
function switchPage(page) {
    // Update menu items
    menuItems.forEach(item => {
        if (item.getAttribute('data-page') === page) {
            item.classList.add('active');
        } else {
            item.classList.remove('active');
        }
    });

    // Show/hide page sections
    pageSections.forEach(section => {
        if (section.id === `${page}-section`) {
            section.style.display = 'block';
            section.classList.add('active');
        } else {
            section.style.display = 'none';
            section.classList.remove('active');
        }
    });

    // Load page-specific content
    switch (page) {
        case 'users':
            loadUsers();
            // Automatically filter to show only regular users
            setTimeout(() => filterUsers('user'), 100);
            break;
        case 'dashboard':
            loadDashboardStats();
            loadFeedbackPreview();
            break;
        case 'feedback':
            loadFeedback();
            // Reset to active feedback view
            const archivedContainer = document.getElementById('archived-feedback-container');
            if (archivedContainer) {
                archivedContainer.style.display = 'none';
            }
            document.getElementById('feedback-table-container').style.display = 'block';
            const showActiveBtn = document.getElementById('show-active-btn');
            const showArchivedBtn = document.getElementById('show-archived-btn');
            if (showActiveBtn && showArchivedBtn) {
                showActiveBtn.style.display = 'none';
                showArchivedBtn.style.display = 'inline-block';
            }
            break;
    }
}

// Function to reset filter buttons
function resetFilterButtons() {
    document.getElementById('filter-admin-btn').classList.remove('active');
    document.getElementById('filter-user-btn').classList.remove('active');
    document.getElementById('filter-archived-btn').classList.remove('active');
}

// Function to load users from the database
function loadUsers() {
    // Show loading, hide error and table
    document.getElementById('users-loading').style.display = 'block';
    document.getElementById('users-error').style.display = 'none';
    document.getElementById('users-table-container').style.display = 'none';

    // Reset filter button states
    resetFilterButtons();

    // Make API request to get users with JSON payload
    fetch(`${API_BASE_URL}/users.php`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            action: 'get_users'
        })
    })
    .then(handleApiResponse)
    .then(data => {
        console.log('Users data received:', data); // Debug log
        if (data.success && data.users) {
            // Populate the users table
            populateUsersTable(data.users);

            // Hide loading, show table
            document.getElementById('users-loading').style.display = 'none';
            document.getElementById('users-table-container').style.display = 'block';
        } else {
            throw new Error(data.message || 'Failed to load users');
        }
    })
    .catch(error => {
        console.error('Error loading users:', error); // Debug log
        // Show error message
        document.getElementById('users-loading').style.display = 'none';
        document.getElementById('users-error').style.display = 'block';
        document.getElementById('users-error').textContent = `Error: ${error.message}`;
    });
}

// Function to filter users by role
function filterUsers(filterType) {
    const tableBody = document.getElementById('users-table-body');
    const allRows = tableBody.querySelectorAll('tr');

    // Get all users from localStorage for reference
    const allUsers = JSON.parse(localStorage.getItem('allUsers') || '[]');

    allRows.forEach(row => {
        // Get the user ID from the row (we'll need to add a data attribute)
        const userId = row.getAttribute('data-user-id');
        const user = allUsers.find(u => u.id == userId);

        if (user) {
            if (filterType === 'admin') {
                row.style.display = user.role === 'admin' ? '' : 'none';
            } else if (filterType === 'user') {
                row.style.display = user.role === 'user' ? '' : 'none';
            } else if (filterType === 'archived') {
                row.style.display = user.isArchived ? '' : 'none';
            } else {
                row.style.display = ''; // Show all
            }
        }
    });

    // Update button states
    resetFilterButtons();

    if (filterType === 'admin') {
        document.getElementById('filter-admin-btn').classList.add('active');
    } else if (filterType === 'user') {
        document.getElementById('filter-user-btn').classList.add('active');
    } else if (filterType === 'archived') {
        document.getElementById('filter-archived-btn').classList.add('active');
    }
}

// Function to populate the users table with data
function populateUsersTable(users) {
    const tableBody = document.getElementById('users-table-body');
    tableBody.innerHTML = ''; // Clear existing rows

    // Cache all users for filtering
    localStorage.setItem('allUsers', JSON.stringify(users));

    // Check if users is defined and is an array
    if (!users || !Array.isArray(users) || users.length === 0) {
        tableBody.innerHTML = `
            <tr>
                <td colspan="5" style="text-align: center; padding: 20px;">
                    No users found in the database.
                </td>
            </tr>
        `;
        return;
    }

    // Helper function to create user rows
    const createUserRow = (user) => {
        const row = document.createElement('tr');
        row.setAttribute('data-user-id', user.id); // Add user ID to row

        // Add admin class if user is admin
        if (user.role === 'admin') {
            row.className = 'admin-user';
        }

        // Determine status
        const statusClass = user.isArchived ? 'inactive' : 'active';
        const statusText = user.isArchived ? 'Inactive' : 'Active';

        // Generate action buttons based on user status and permissions
        let actionButtons = '';

        if (user.isArchived) {
            actionButtons = `<button class="action-btn btn-edit" onclick="restoreUser(${user.id})">Restore</button>`;
        } else {
            // For admin users, only show edit button (no promote/demote/archive)
            if (user.role === 'admin') {
                actionButtons = `<button class="action-btn btn-edit" onclick="editUser(${user.id})">Edit</button>`;
            } else {
                // For regular users, show edit and archive buttons
                actionButtons = `
                    <button class="action-btn btn-edit" onclick="editUser(${user.id})">Edit</button>
                    <button class="action-btn btn-delete" onclick="archiveUser(${user.id})">Archive</button>
                `;
            }
        }

        row.innerHTML = `
            <td>${user.first_name} ${user.last_name}</td>
            <td>${user.email}</td>
            <td>
                ${user.role === 'admin'
                    ? '<span class="admin-badge">ADMIN</span>'
                    : '<span class="user-badge">USER</span>'}
            </td>
            <td><span class="status ${statusClass}">${statusText}</span></td>
            <td>${actionButtons}</td>
        `;

        return row;
    };

    // Add all users
    users.forEach(user => {
        tableBody.appendChild(createUserRow(user));
    });
}

// Function to archive a user
function archiveUser(userId) {
    if (confirm('Are you sure you want to archive this user?')) {
        fetch(`${API_BASE_URL}/users.php`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                action: 'archive_user',
                user_id: userId
            })
        })
        .then(handleApiResponse)
        .then(data => {
            if (data.success) {
                alert('User archived successfully!');
                loadUsers(); // Reload the users list
            } else {
                alert('Error: ' + data.message);
            }
        })
        .catch(error => {
            console.error('Error archiving user:', error);
            alert('Error archiving user: ' + error.message);
        });
    }
}

// Function to restore a user
function restoreUser(userId) {
    fetch(`${API_BASE_URL}/users.php`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            action: 'restore_user',
            user_id: userId
        })
    })
    .then(handleApiResponse)
    .then(data => {
        if (data.success) {
            alert('User restored successfully!');
            loadUsers(); // Reload the users list
            } else {
            alert('Error: ' + data.message);
        }
    })
    .catch(error => {
        console.error('Error restoring user:', error);
        alert('Error restoring user: ' + error.message);
    });
}

// Function to edit a user - OPEN PASSWORD MODAL
function editUser(userId) {
    // Store the user ID for later use
    document.getElementById('edit-user-id').value = userId;

    // Show the modal
    document.getElementById('password-modal').style.display = 'flex';
}

// Function to close password modal
function closePasswordModal() {
    document.getElementById('password-modal').style.display = 'none';
    document.getElementById('password-form').reset();
}

// Function to handle password form submission
function handlePasswordChange(e) {
    e.preventDefault();

    const userId = document.getElementById('edit-user-id').value;
    const newPassword = document.getElementById('new-password').value;
    const confirmPassword = document.getElementById('confirm-password').value;

    // Validate passwords match
    if (newPassword !== confirmPassword) {
        alert('Passwords do not match!');
        return;
    }

    // Validate password length
    if (newPassword.length < 8) {
        alert('Password must be at least 8 characters long!');
        return;
    }

    // Make API request to change password
    fetch(`${API_BASE_URL}/update_password.php`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            action: 'update_password',
            user_id: userId,
            new_password: newPassword
        })
    })
    .then(handleApiResponse)
    .then(data => {
        if (data.success) {
            alert('Password updated successfully!');
            closePasswordModal();
        } else {
            alert('Error: ' + data.message);
        }
    })
    .catch(error => {
        console.error('Error updating password:', error);
        alert('Error updating password: ' + error.message);
    });
}

// Function to load dashboard statistics
async function loadDashboardStats() {
    const statsContainer = document.getElementById('stats-container');
    statsContainer.innerHTML = `
        <div class="loading">
            <i class="fas fa-spinner fa-spin" style="font-size: 24px; margin-bottom: 10px;"></i>
            <p>Loading statistics...</p>
        </div>
    `;

    try {
        // Fetch main stats from API
        const response = await fetch(`${API_BASE_URL}/admin_stats.php`);

        if (!response.ok) {
            throw new Error(`Server returned ${response.status}: ${response.statusText}`);
        }

        const contentType = response.headers.get('content-type');
        if (!contentType || !contentType.includes('application/json')) {
            const text = await response.text();
            throw new Error(`Server returned non-JSON response: ${text.substring(0, 100)}`);
        }

        const data = await response.json();

        if (data.success) {
            // Now fetch feedback stats
            try {
                const feedbackResponse = await fetch(`${API_BASE_URL}/feedback.php`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({
                        action: 'get_feedback_stats'
                    })
                });

                if (feedbackResponse.ok) {
                    const feedbackContentType = feedbackResponse.headers.get('content-type');
                    if (feedbackContentType && feedbackContentType.includes('application/json')) {
                        const feedbackData = await feedbackResponse.json();

                        // Merge feedback stats with main stats
                        if (feedbackData.success) {
                            data.stats.total_feedback = feedbackData.total || 0;
                            data.stats.unread_feedback = feedbackData.unread || 0;
                        }
                    }
                }
            } catch (feedbackError) {
                console.error('Error loading feedback stats:', feedbackError);
                // Set default values if feedback stats fail
                data.stats.total_feedback = 0;
                data.stats.unread_feedback = 0;
            }

            // Display all stats including feedback
            displayDashboardStats(data.stats);
        } else {
            throw new Error(data.message || 'Failed to load statistics');
        }
    } catch (error) {
        statsContainer.innerHTML = `
            <div class="error">
                Error loading statistics: ${error.message}
            </div>
        `;
    }
}

// Function to display dashboard statistics
function displayDashboardStats(stats) {
    const statsContainer = document.getElementById('stats-container');

    // Create HTML for all stats including feedback
    let statsHTML = '';

    // Add user stats if available
    if (stats.users_by_role && stats.users_by_role.length > 0) {
        stats.users_by_role.forEach(role => {
            // Change "User Users" to "Regular Users"
            const roleName = role.role === 'user' ? 'Regular Users' : role.role + ' Users';
            const roleClass = role.role === 'user' ? 'regular-users' : role.role + '-users';

            statsHTML += `
                <div class="stat-card ${roleClass}">
                    <h4>${roleName}</h4>
                    <div class="stat-value">${role.count}</div>
                    <div class="stat-label">${role.role === 'user' ? 'Regular' : role.role} Role</div>
                </div>
            `;
        });
    }

    // Add total users if available
    if (stats.total_users !== undefined) {
        statsHTML += `
            <div class="stat-card total-users">
                <h4>Total Users</h4>
                <div class="stat-value">${stats.total_users}</div>
                <div class="stat-label">Registered Users</div>
            </div>
        `;
    }

    // Add active users if available
    if (stats.active_users !== undefined) {
        statsHTML += `
            <div class="stat-card active-users">
                <h4>Active Users</h4>
                <div class="stat-value">${stats.active_users}</div>
                <div class="stat-label">Currently Active</div>
            </div>
        `;
    }

    // Add feedback stats (use the values from the merged stats object)
    statsHTML += `
        <div class="stat-card feedback">
            <h4>Total Feedback</h4>
            <div class="stat-value">${stats.total_feedback || 0}</div>
            <div class="stat-label">All Feedback</div>
        </div>
        <div class="stat-card unread-feedback">
            <h4>Unread Feedback</h4>
            <div class="stat-value">${stats.unread_feedback || 0}</div>
            <div class="stat-label">Requires Attention</div>
        </div>
    `;

    statsContainer.innerHTML = statsHTML;
}

// Function to load feedback
function loadFeedback() {
    // Show loading, hide error and table
    document.getElementById('feedback-loading').style.display = 'block';
    document.getElementById('feedback-error').style.display = 'none';
    document.getElementById('feedback-table-container').style.display = 'none';
    document.getElementById('no-feedback-message').style.display = 'none';
    document.getElementById('feedback-stats').style.display = 'none';
    document.getElementById('feedback-filters').style.display = 'none';
    document.getElementById('feedback-pagination').style.display = 'none';

    // Make API request to get feedback
    fetch(`${API_BASE_URL}/feedback.php`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            action: 'get_feedback'
        })
    })
    .then(handleApiResponse)
    .then(data => {
        console.log('Feedback data received:', data);
        if (data.success) {
            // Store feedback globally for filtering
            allFeedback = data.feedback || [];

            // Check if feedback array exists and has items
            if (allFeedback.length > 0) {
                // Populate the feedback table with all data initially
                populateFeedbackTable(allFeedback);

                // UPDATE THE STATS CARDS WITH REAL NUMBERS
                updateFeedbackStats(allFeedback);

                // Hide loading, show table and stats
                document.getElementById('feedback-loading').style.display = 'none';
                document.getElementById('feedback-table-container').style.display = 'block';
                document.getElementById('feedback-stats').style.display = 'block';
                document.getElementById('feedback-filters').style.display = 'flex';
                document.getElementById('feedback-pagination').style.display = 'flex';
            } else {
                // No feedback available - set all stats to zero
                updateFeedbackStats([]);

                document.getElementById('feedback-loading').style.display = 'none';
                document.getElementById('no-feedback-message').style.display = 'block';
                document.getElementById('feedback-stats').style.display = 'block';
            }
        } else {
            throw new Error(data.message || 'Failed to load feedback');
        }
    })
    .catch(error => {
        console.error('Error loading feedback:', error);
        // Show error message
        document.getElementById('feedback-loading').style.display = 'none';
        document.getElementById('feedback-error').style.display = 'block';
        document.getElementById('feedback-error').textContent = `Error: ${error.message}`;
    });
}

// NEW FUNCTION: Update feedback statistics cards
function updateFeedbackStats(feedback) {
    // Calculate statistics
    const totalFeedback = feedback.length;

    // Count archived feedback
    const archivedFeedback = feedback.filter(item => item.is_archived).length;

    // Count this month's feedback
    const currentMonth = new Date().getMonth();
    const currentYear = new Date().getFullYear();
    const monthlyFeedback = feedback.filter(item => {
        const feedbackDate = new Date(item.created_at);
        return feedbackDate.getMonth() === currentMonth &&
               feedbackDate.getFullYear() === currentYear;
    }).length;

    // Update the DOM elements
    document.getElementById('total-feedback').textContent = totalFeedback;
    document.getElementById('archived-feedback').textContent = archivedFeedback;
    document.getElementById('monthly-feedback').textContent = monthlyFeedback;
}

// Function to populate the feedback table with data
function populateFeedbackTable(feedback) {
    const tableBody = document.getElementById('feedback-table-body');
    tableBody.innerHTML = ''; // Clear existing rows

    // Check if we're viewing archived feedback
    const archivedContainer = document.getElementById('archived-feedback-container');
    const isViewingArchived = archivedContainer && archivedContainer.style.display === 'block';

    // Check if feedback is defined and is an array
    if (!feedback || !Array.isArray(feedback) || feedback.length === 0) {
        tableBody.innerHTML = `
            <tr>
                <td colspan="6" style="text-align: center; padding: 20px;">
                    No feedback found.
                </td>
            </tr>
        `;
        return;
    }

    // Add each feedback as a row in the table
    feedback.forEach(item => {
        // Skip items that don't match the current view (archived vs active)
        if (isViewingArchived && !item.is_archived) return;
        if (!isViewingArchived && item.is_archived) return;

        const row = document.createElement('tr');
        row.setAttribute('data-feedback-id', item.id); // Add feedback ID to row

        // Format date
        const date = new Date(item.created_at);
        const formattedDate = date.toLocaleDateString();

        // Get user info or use anonymous
        const userName = item.first_name && item.last_name
            ? `${item.first_name} ${item.last_name}`
            : 'Anonymous';

        // Create star rating display
        let starsHtml = '';
        if (item.rating) {
            for (let i = 1; i <= 5; i++) {
                starsHtml += `<i class="fas fa-star ${i <= item.rating ? 'active' : 'inactive'}"></i>`;
            }
        } else {
            starsHtml = 'No rating';
        }

        // Determine status
        const statusClass = item.is_read ? 'read' : 'unread';
        const statusText = item.is_read ? 'Read' : 'Unread';

        row.innerHTML = `
            <td>${userName}</td>
            <td>${starsHtml}</td>
            <td>${item.message || 'No message provided'}</td>
            <td>${formattedDate}</td>
            <td><span class="status ${statusClass}">${statusText}</span></td>
            <td>
                <button class="action-btn btn-view" onclick="viewFeedback(${item.id})">
                    View
                </button>
                ${!item.is_archived ?
                    `<button class="action-btn btn-archive" onclick="archiveFeedback(${item.id})">
                        Archive
                    </button>` :
                    `<button class="action-btn btn-edit" onclick="restoreFeedback(${item.id})">
                        Restore
                    </button>`
                }
            </td>
        `;

        tableBody.appendChild(row);
    });
}

// Function to view feedback details and mark as read
function viewFeedback(feedbackId) {
    // First mark the feedback as read
    fetch(`${API_BASE_URL}/feedback.php`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            action: 'mark_as_read',
            feedback_id: feedbackId
        })
    })
    .then(handleApiResponse)
    .then(data => {
        if (data.success) {
            // Update the UI to show the feedback as read
            const statusElement = document.querySelector(`tr[data-feedback-id="${feedbackId}"] .status`);
            if (statusElement) {
                statusElement.textContent = 'Read';
                statusElement.className = 'status read';
            }

            // Update dashboard stats
            loadDashboardStats();

            // Show feedback details
            showFeedbackDetails(feedbackId);
        } else {
            alert('Error: ' + data.message);
        }
    })
    .catch(error => {
        console.error('Error marking feedback as read:', error);
        alert('Error marking feedback as read: ' + error.message);
    });
}

// Function to show feedback details
function showFeedbackDetails(feedbackId) {
    // Fetch and display detailed feedback information
    fetch(`${API_BASE_URL}/feedback.php`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            action: 'get_feedback_by_id',
            feedback_id: feedbackId
        })
    })
    .then(handleApiResponse)
    .then(data => {
        if (data.success && data.feedback) {
            // Create and show a modal with the feedback details
            const feedback = data.feedback;
            const modal = createFeedbackModal(feedback);
            document.body.appendChild(modal);
            modal.style.display = 'flex';
        } else {
            alert('Error loading feedback details: ' + data.message);
        }
    })
    .catch(error => {
        console.error('Error loading feedback details:', error);
        alert('Error loading feedback details: ' + error.message);
    });
}

// Helper function to create a feedback modal
function createFeedbackModal(feedback) {
    const modal = document.createElement('div');
    modal.className = 'modal';
    modal.id = 'feedback-modal';

    // Format date
    const date = new Date(feedback.created_at);
    const formattedDate = date.toLocaleDateString();

    // Get user info or use anonymous
    const userName = feedback.first_name && feedback.last_name
        ? `${feedback.first_name} ${feedback.last_name}`
        : 'Anonymous';

    // Create star rating display
    let starsHtml = '';
    if (feedback.rating) {
        for (let i = 1; i <= 5; i++) {
            starsHtml += `<i class="fas fa-star ${i <= feedback.rating ? 'active' : 'inactive'}"></i>`;
        }
    } else {
        starsHtml = 'No rating';
    }

    modal.innerHTML = `
        <div class="modal-content">
            <span class="close">&times;</span>
            <h2>Feedback Details</h2>
            <div class="feedback-details">
                <div class="detail-row">
                    <label>User:</label>
                    <span>${userName}</span>
                </div>
                <div class="detail-row">
                    <label>Email:</label>
                    <span>${feedback.email || 'Not provided'}</span>
                </div>
                <div class="detail-row">
                    <label>Rating:</label>
                    <span>${starsHtml}</span>
                </div>
                <div class 'detail-row'>
                    <label>Date:</label>
                    <span>${formattedDate}</span>
                </div>
                <div class="detail-row full-width">
                    <label>Message:</label>
                    <div class="feedback-message">${feedback.message || 'No message provided'}</div>
                </div>
            </div>
        </div>
    `;

    // Add event listener to close the modal
    modal.querySelector('.close').addEventListener('click', () => {
        modal.style.display = 'none';
        document.body.removeChild(modal);
    });

    // Close modal when clicking outside
    modal.addEventListener('click', (e) => {
        if (e.target === modal) {
            modal.style.display = 'none';
            document.body.removeChild(modal);
        }
    });

    return modal;
}

// Function to archive feedback
function archiveFeedback(feedbackId) {
    if (confirm('Are you sure you want to archive this feedback?')) {
        fetch(`${API_BASE_URL}/feedback.php`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                action: 'archive_feedback',
                feedback_id: feedbackId
            })
        })
    .then(handleApiResponse)
    .then(data => {
        if (data.success) {
            alert('Feedback archived successfully!');
            // Reload all feedback data
            loadFeedback();
        } else {
            alert('Error: ' + data.message);
        }
    })
    .catch(error => {
        console.error('Error archiving feedback:', error);
        alert('Error archiving feedback: ' + error.message);
    });
    }
}

// Function to show archived feedback
function showArchivedFeedback() {
    // Show loading state
    document.getElementById('feedback-loading').style.display = 'block';

    // Safely hide the active feedback table if it exists
    const feedbackTableContainer = document.getElementById('feedback-table-container');
    if (feedbackTableContainer) {
        feedbackTableContainer.style.display = 'none';
    }

    // Safely check if the archived container exists before trying to access it
    const archivedContainer = document.getElementById('archived-feedback-container');
    if (archivedContainer) {
        archivedContainer.style.display = 'none';
    }

    // Make API request to get archived feedback specifically
    fetch(`${API_BASE_URL}/feedback.php`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            action: 'get_archived_feedback'
        })
    })
    .then(handleApiResponse)
    .then(data => {
        document.getElementById('feedback-loading').style.display = 'none';

        if (data.success && data.feedback && data.feedback.length > 0) {
            // Show archived container if it exists
            if (archivedContainer) {
                archivedContainer.style.display = 'block';
                populateArchivedFeedbackTable(data.feedback);
            }

            // Toggle buttons safely
            const showArchivedBtn = document.getElementById('show-archived-btn');
            const showActiveBtn = document.getElementById('show-active-btn');

            if (showArchivedBtn) showArchivedBtn.style.display = 'none';
            if (showActiveBtn) showActiveBtn.style.display = 'inline-block';
        } else {
            // No archived feedback
            if (archivedContainer) {
                archivedContainer.style.display = 'block';
                document.getElementById('archived-feedback-table-body').innerHTML = `
                    <tr>
                        <td colspan="6" style="text-align: center; padding: 20px;">
                            No archived feedback found.
                        </td>
                    </tr>
                `;
            }

            // Toggle buttons safely
            const showArchivedBtn = document.getElementById('show-archived-btn');
            const showActiveBtn = document.getElementById('show-active-btn');

            if (showArchivedBtn) showArchivedBtn.style.display = 'none';
            if (showActiveBtn) showActiveBtn.style.display = 'inline-block';
        }
    })
    .catch(error => {
        console.error('Error loading archived feedback:', error);
        document.getElementById('feedback-loading').style.display = 'none';
        alert('Error loading archived feedback: ' + error.message);
    });
}

// Function to load archived feedback
function loadArchivedFeedback() {
    const tableBody = document.getElementById('archived-feedback-table-body');
    tableBody.innerHTML = '<tr><td colspan="6" style="text-align: center; padding: 20px;">Loading archived feedback...</td></tr>';

    fetch(`${API_BASE_URL}/feedback.php`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            action: 'get_archived_feedback'
        })
    })
    .then(handleApiResponse)
    .then(data => {
        if (data.success && data.feedback && data.feedback.length > 0) {
            populateArchivedFeedbackTable(data.feedback);
        } else {
            tableBody.innerHTML = `
                <tr>
                    <td colspan="6" style="text-align: center; padding: 20px;">
                        No archived feedback found.
                    </td>
                </tr>
            `;
        }
    })
    .catch(error => {
        console.error('Error loading archived feedback:', error);
        tableBody.innerHTML = `
            <tr>
                <td colspan="6" style="text-align: center; padding: 20px; color: red;">
                    Error loading archived feedback: ${error.message}
                </td>
            </tr>
        `;
    });
}

// Function to populate the archived feedback table
function populateArchivedFeedbackTable(feedback) {
    const tableBody = document.getElementById('archived-feedback-table-body');
    tableBody.innerHTML = '';

    if (!feedback || feedback.length === 0) {
        tableBody.innerHTML = `
            <tr>
                <td colspan="6" style="text-align: center; padding: 20px;">
                    No archived feedback found.
                </td>
            </tr>
        `;
        return;
    }

    feedback.forEach(item => {
        const row = document.createElement('tr');

        // Format dates
        const createdDate = new Date(item.created_at);
        const formattedCreatedDate = createdDate.toLocaleDateString();

        const archivedDate = item.archived_at ? new Date(item.archived_at) : new Date();
        const formattedArchivedDate = archivedDate.toLocaleDateString();

        // Get user info or use anonymous
        const userName = item.first_name && item.last_name
            ? `${item.first_name} ${item.last_name}`
            : 'Anonymous';

        // Create star rating display
        let starsHtml = '';
        if (item.rating) {
            for (let i = 1; i <= 5; i++) {
                starsHtml += `<i class="fas fa-star ${i <= item.rating ? 'active' : 'inactive'}"></i>`;
            }
        } else {
            starsHtml = 'No rating';
        }

        row.innerHTML = `
            <td>${userName}</td>
            <td>${starsHtml}</td>
            <td>${item.message || 'No message provided'}</td>
            <td>${formattedCreatedDate}</td>
            <td>${formattedArchivedDate}</td>
            <td>
                <button class="action-btn btn-view" onclick="viewFeedback(${item.id})">
                    View
                </button>
                <button class="action-btn btn-edit" onclick="restoreFeedback(${item.id})">
                    Restore
                </button>
            </td>
        `;

        tableBody.appendChild(row);
    });
}

// Function to restore archived feedback
function restoreFeedback(feedbackId) {
    if (confirm('Are you sure you want to restore this feedback?')) {
        fetch(`${API_BASE_URL}/feedback.php`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                action: 'restore_feedback',
                feedback_id: feedbackId
            })
        })
        .then(handleApiResponse)
        .then(data => {
            if (data.success) {
            alert('Feedback restored successfully!');
            // Reload all feedback data
            loadFeedback();
        } else {
            alert('Error: ' + data.message);
        }
    })
    .catch(error => {
        console.error('Error restoring feedback:', error);
        alert('Error restoring feedback: ' + error.message);
    });
    }
}

// Function to switch back to active feedback
function switchToActiveFeedback() {
    const archivedContainer = document.getElementById('archived-feedback-container');
    if (archivedContainer) {
        archivedContainer.style.display = 'none';
    }
    document.getElementById('feedback-table-container').style.display = 'block';

    const showArchivedBtn = document.getElementById('show-archived-btn');
    const showActiveBtn = document.getElementById('show-active-btn');

    if (showArchivedBtn) showArchivedBtn.style.display = 'inline-block';
    if (showActiveBtn) showActiveBtn.style.display = 'none';

    // Reload active feedback
    loadFeedback();
}

// Function to handle logout with custom modal
function handleLogout() {
    // Show custom modal
    const modal = document.getElementById('logout-modal');
    modal.style.display = 'flex';

    // Set up event listeners for modal buttons
    document.getElementById('logout-cancel').onclick = function() {
        modal.style.display = 'none';
    };

    document.getElementById('logout-confirm').onclick = function() {
        // Clear user data
        localStorage.removeItem('adminUser');
        sessionStorage.removeItem('adminUser');
        localStorage.removeItem('allUsers'); // Clear cached users

        // Redirect to login page
        window.location.href = 'index.html';
    };
}

// Close modal if user clicks outside the modal content
document.getElementById('logout-modal').addEventListener('click', function(e) {
    if (e.target === this) {
        this.style.display = 'none';
    }
});

// Function to load feedback preview in card format
function loadFeedbackPreview() {
    const previewContainer = document.getElementById('recent-feedback');
    if (!previewContainer) return;

    previewContainer.innerHTML = `
        <div class="loading">
            <i class="fas fa-spinner fa-spin" style="font-size: 20px; margin-bottom: 10px;"></i>
            <p>Loading recent feedback...</p>
        </div>
    `;

    fetch(`${API_BASE_URL}/feedback.php`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            action: 'get_recent_feedback',
            limit: 5
        })
    })
    .then(handleApiResponse)
    .then(data => {
        if (data.success && data.feedback && data.feedback.length > 0) {
            previewContainer.innerHTML = '';

            // Create feedback preview items
            data.feedback.forEach(item => {
                const previewItem = createFeedbackPreviewItem(item);
                previewContainer.appendChild(previewItem);
            });
        } else {
            previewContainer.innerHTML = `
                <div class="no-feedback-preview">
                    <i class="fas fa-comment-slash"></i>
                    <p>No recent feedback</p>
                </div>
            `;
        }
    })
    .catch(error => {
        console.error('Error loading feedback preview:', error);
        previewContainer.innerHTML = `
            <div class="error">
                Error loading recent feedback: ${error.message}
            </div>
        `;
    });
}

// Function to create a feedback preview item
function createFeedbackPreviewItem(feedback) {
    const item = document.createElement('div');
    item.className = `feedback-preview-item ${feedback.is_read ? '' : 'unread'}`;

    // Format date
    const date = new Date(feedback.created_at);
    const formattedDate = date.toLocaleDateString();

    // Get user info
    const userName = feedback.first_name && feedback.last_name
        ? `${feedback.first_name} ${feedback.last_name}`
        : 'Anonymous';

    // Get user initials for avatar
    const userInitials = getUserInitials(feedback.first_name, feedback.last_name);

    // Create star rating display
    let starsHtml = '';
    if (feedback.rating) {
        for (let i = 1; i <= 5; i++) {
            starsHtml += `<i class="fas fa-star ${i <= feedback.rating ? 'active' : 'inactive'}"></i>`;
        }
    }

    item.innerHTML = `
        <div class="feedback-user">
            <div class="feedback-avatar">${userInitials}</div>
            <div class="feedback-name">${userName}</div>
            ${!feedback.is_read ? '<span class="unread-badge">New</span>' : ''}
        </div>
        <div class="feedback-rating">${starsHtml}</div>
        <div class="feedback-comment">${feedback.message || 'No message provided'}</div>
        <div class="feedback-meta">
            <span>${formattedDate}</span>
            <span>${feedback.is_read ? 'Read' : 'Unread'}</span>
        </div>
    `;

    return item;
}

// Helper function to get user initials
function getUserInitials(firstName, lastName) {
    if (firstName && lastName) {
        return firstName.charAt(0) + lastName.charAt(0);
    } else if (firstName) {
        return firstName.charAt(0);
    } else if (lastName) {
        return lastName.charAt(0);
    }
    return 'A'; // Anonymous
}

// Function to mark feedback as read
function markAsRead(feedbackId) {
    fetch(`${API_BASE_URL}/feedback.php`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            action: 'mark_as_read',
            feedback_id: feedbackId
        })
    })
    .then(handleApiResponse)
    .then(data => {
        if (data.success) {
            // Reload the feedback preview to update the status
            loadFeedbackPreview();
            // Also update the dashboard stats to reflect the change in unread count
            loadDashboardStats();
        } else {
            alert('Error: ' + data.message);
        }
    })
    .catch(error => {
        console.error('Error marking feedback as read:', error);
        alert('Error marking feedback as read: ' + error.message);
    });
}

// Function to apply filters to feedback
function applyFilters() {
    const ratingFilter = document.getElementById('rating-filter').value;
    const dateFilter = document.getElementById('date-filter').value;
    const statusFilter = document.getElementById('status-filter').value;

    // Update current filters
    currentFilters = {
        rating: ratingFilter,
        date: dateFilter,
        status: statusFilter
    };

    // Apply filters to the feedback data
    filterFeedback();
}

// Function to filter feedback based on current filters
function filterFeedback() {
    if (allFeedback.length === 0) return;

    const filteredFeedback = allFeedback.filter(item => {
        // Rating filter
        if (currentFilters.rating !== 'all') {
            if (parseInt(item.rating) !== parseInt(currentFilters.rating)) {
                return false;
            }
        }

        // Date filter
        if (currentFilters.date !== 'all') {
            const feedbackDate = new Date(item.created_at);
            const today = new Date();

            switch(currentFilters.date) {
                case 'today':
                    if (!isSameDay(feedbackDate, today)) return false;
                    break;
                case 'week':
                    if (!isThisWeek(feedbackDate)) return false;
                    break;
                case 'month':
                    if (!isThisMonth(feedbackDate)) return false;
                    break;
            }
        }

        // Status filter
        if (currentFilters.status !== 'all') {
            switch(currentFilters.status) {
                case 'read':
                    if (!item.is_read) return false;
                    break;
                case 'unread':
                    if (item.is_read) return false;
                    break;
                case 'archived':
                    if (!item.is_archived) return false;
                    break;
            }
        }

        return true;
    });

    // Update the table with filtered data
    populateFeedbackTable(filteredFeedback);
}

// Helper function to check if two dates are the same day
function isSameDay(date1, date2) {
    return date1.getFullYear() === date2.getFullYear() &&
           date1.getMonth() === date2.getMonth() &&
           date1.getDate() === date2.getDate();
}

// Helper function to check if a date is in the current week
function isThisWeek(date) {
    const today = new Date();
    const startOfWeek = new Date(today);
    startOfWeek.setDate(today.getDate() - today.getDay()); // Sunday
    const endOfWeek = new Date(today);
    endOfWeek.setDate(today.getDate() + (6 - today.getDay())); // Saturday

    return date >= startOfWeek && date <= endOfWeek;
}

// Helper function to check if a date is in the current month
function isThisMonth(date) {
    const today = new Date();
    return date.getFullYear() === today.getFullYear() &&
           date.getMonth() === today.getMonth();
}

// Function to clear filters
function clearFilters() {
    document.getElementById('rating-filter').value = 'all';
    document.getElementById('date-filter').value = 'all';
    document.getElementById('status-filter').value = 'all';

    // Reset current filters
    currentFilters = {
        rating: 'all',
        date: 'all',
        status: 'all'
    };

    // Show all feedback
    populateFeedbackTable(allFeedback);
}

// Function to change page (pagination)
function changePage(direction) {
    // Implement pagination logic here
    console.log('Changing page:', direction);
    alert('Pagination functionality will be implemented here');
}

// API response handler function
async function handleApiResponse(response) {
    if (!response.ok) {
        throw new Error(`Server returned ${response.status}: ${response.statusText}`);
    }

    const contentType = response.headers.get('content-type');
    if (!contentType || !contentType.includes('application/json')) {
        const text = await response.text();
        throw new Error(`Server returned non-JSON response: ${text.substring(0, 100)}`);
    }

    return response.json();
}

// Modal CSS styles
const modalStyles = `
.modal {
    display: none;
    position: fixed;
    z-index: 1000;
    left: 0;
    top: 0;
    width: 100%;
    height: 100%;
    background-color: rgba(0, 0, 0, 0.5);
    justify-content: center;
    align-items: center;
}
.modal-content {
    background-color: #fff;
    padding: 20px;
    border-radius: 8px;
    width: 80%;
    max-width: 600px;
    max-height: 80vh;
    overflow-y: auto;
    position: relative;
}
.modal .close {
    position: absolute;
    top: 10px;
    right: 15px;
    font-size: 24px;
    cursor: pointer;
}
.feedback-details {
    margin-top: 20px;
}
.detail-row {
    display: flex;
    margin-bottom: 10px;
    align-items: flex-start;
}
.detail-row label {
    font-weight: bold;
    min-width: 80px;
    margin-right: 10px;
}
.detail-row full-width {
    flex-direction: column;
}
.feedback-message {
    margin-top: 5px;
    padding: 10px;
    background-color: #f5f5f5;
    border-radius: 4px;
    white-space: pre-wrap;
}
`;

// Add the modal styles to the document
const styleSheet = document.createElement('style');
styleSheet.textContent = modalStyles;
document.head.appendChild(styleSheet);