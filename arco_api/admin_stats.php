<?php
// Start output buffering at the very top
ob_start();

session_start();
require_once 'config.php';
header("Content-Type: application/json");

// Set CORS headers
header('Access-Control-Allow-Origin: http://192.168.1.14');
header('Access-Control-Allow-Credentials: true');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    ob_end_clean();
    exit(0);
}

try {
    // Clean any existing output
    if (ob_get_length()) ob_clean();

    // Get total users
    $stmt = $pdo->query("SELECT COUNT(*) as total_users FROM users WHERE isArchived = 0");
    $totalUsers = $stmt->fetch(PDO::FETCH_ASSOC)['total_users'];

    // Get active users (users who have logged in recently - last 24 hours)
    // First check if last_login column exists
    $columnCheck = $pdo->query("SHOW COLUMNS FROM users LIKE 'last_login'");
    $columnExists = $columnCheck->rowCount() > 0;

    if ($columnExists) {
        $stmt = $pdo->query("SELECT COUNT(*) as active_users FROM users WHERE isArchived = 0 AND last_login >= DATE_SUB(NOW(), INTERVAL 24 HOUR)");
        $activeUsers = $stmt->fetch(PDO::FETCH_ASSOC)['active_users'];
    } else {
        // If last_login column doesn't exist, use alternative query
        $stmt = $pdo->query("SELECT COUNT(*) as active_users FROM users WHERE isArchived = 0");
        $activeUsers = $stmt->fetch(PDO::FETCH_ASSOC)['active_users'];
    }

    // Get total expenses
    $stmt = $pdo->query("SELECT COUNT(*) as total_expenses FROM expenses");
    $totalExpenses = $stmt->fetch(PDO::FETCH_ASSOC)['total_expenses'];

    // Get users by role
    $stmt = $pdo->query("SELECT role, COUNT(*) as count FROM users WHERE isArchived = 0 GROUP BY role");
    $usersByRole = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Get recent registrations (last 7 days) - FIXED: using created_at instead of createdAt
    $stmt = $pdo->query("SELECT COUNT(*) as recent_users FROM users WHERE isArchived = 0 AND created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)");
    $recentUsers = $stmt->fetch(PDO::FETCH_ASSOC)['recent_users'];

    // Get total feedback count
    $stmt = $pdo->query("SELECT COUNT(*) as total_feedback FROM feedback");
    $totalFeedback = $stmt->fetch(PDO::FETCH_ASSOC)['total_feedback'];

    // Get unread feedback count
    $stmt = $pdo->query("SELECT COUNT(*) as unread_feedback FROM feedback WHERE is_read = 0");
    $unreadFeedback = $stmt->fetch(PDO::FETCH_ASSOC)['unread_feedback'];

    // Ensure all values are integers
    $response = [
        'success' => true,
        'stats' => [
            'total_users' => (int)$totalUsers,
            'active_users' => (int)$activeUsers,
            'total_expenses' => (int)$totalExpenses,
            'recent_users' => (int)$recentUsers,
            'users_by_role' => $usersByRole,
            'total_feedback' => (int)$totalFeedback,
            'unread_feedback' => (int)$unreadFeedback
        ]
    ];

    // Clean any output before sending JSON
    if (ob_get_length()) ob_clean();

    echo json_encode($response);

} catch (PDOException $e) {
    // Clean any output before sending error
    if (ob_get_length()) ob_clean();

    error_log("Database error in admin_stats.php: " . $e->getMessage());

    echo json_encode([
        'success' => false,
        'message' => 'Database error: ' . $e->getMessage(),
        'stats' => [
            'total_users' => 0,
            'active_users' => 0,
            'total_expenses' => 0,
            'recent_users' => 0,
            'users_by_role' => [],
            'total_feedback' => 0,
            'unread_feedback' => 0
        ]
    ]);
}

// End output buffering and flush
ob_end_flush();
?>