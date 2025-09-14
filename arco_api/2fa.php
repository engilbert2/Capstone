<?php
// 2fa.php - Mandatory 2FA version
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

// Enable debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Include required files
require_once __DIR__ . '/config.php';

// Check if email_service exists before including
if (!file_exists(__DIR__ . '/email_service.php')) {
    error_log("ERROR: email_service.php not found");
    echo json_encode(['success' => false, 'message' => 'Email service not configured']);
    exit;
}

require_once __DIR__ . '/email_service.php';

// Get input data
$input = file_get_contents('php://input');
$data = json_decode($input, true);

if ($data === null) {
    error_log("ERROR: Invalid JSON input");
    echo json_encode(['success' => false, 'message' => 'Invalid JSON input']);
    exit;
}

$action = $data['action'] ?? '';

error_log("Action: $action");

// ========================================
// GENERATE TOKEN
// ========================================
if ($action === 'generate_token') {
    $userId = $data['user_id'] ?? '';
    $email = $data['email'] ?? '';

    error_log("Generate token for user: $userId, email: $email");

    if (empty($userId) || empty($email)) {
        echo json_encode(['success' => false, 'message' => 'Missing parameters']);
        exit;
    }

    // Generate 6-digit token
    $token = str_pad(rand(0, 999999), 6, '0', STR_PAD_LEFT);

    try {
        // Insert token with proper TIMESTAMP expiry - UPDATED TO USE created_at INSTEAD OF createdAt
        $stmt = $pdo->prepare("
            INSERT INTO verification_tokens (user_id, token, expires_at, created_at)
            VALUES (?, ?, DATE_ADD(NOW(), INTERVAL 15 MINUTE), NOW())
            ON DUPLICATE KEY UPDATE
                token = VALUES(token),
                expires_at = VALUES(expires_at),
                created_at = NOW()
        ");
        $success = $stmt->execute([$userId, $token]);

        if ($success) {
            $emailSent = sendVerificationEmail($email, $token);

            echo json_encode([
                'success' => true,
                'token' => $token,
                'email_sent' => $emailSent,
                'message' => $emailSent ? "Verification code sent to $email" : 'Failed to send email'
            ]);
        } else {
            echo json_encode(['success' => false, 'message' => 'Failed to generate token']);
        }
    } catch (PDOException $e) {
        error_log("Database error: " . $e->getMessage());
        echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
    }

// ========================================
// VERIFY TOKEN
// ========================================
} elseif ($action === 'verify_token') {
    $userId = $data['user_id'] ?? '';
    $token = $data['token'] ?? '';

    if (empty($userId) || empty($token)) {
        echo json_encode(['success' => false, 'message' => 'Missing parameters']);
        exit;
    }

    try {
        $stmt = $pdo->prepare("
            SELECT * FROM verification_tokens
            WHERE user_id = ? AND token = ? AND expires_at > NOW()
        ");
        $stmt->execute([$userId, $token]);
        $tokenData = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($tokenData) {
            $deleteStmt = $pdo->prepare("DELETE FROM verification_tokens WHERE user_id = ?");
            $deleteStmt->execute([$userId]);

            echo json_encode(['success' => true, 'message' => 'Token verified']);
        } else {
            echo json_encode(['success' => false, 'message' => 'Invalid or expired token']);
        }
    } catch (PDOException $e) {
        error_log("Database error: " . $e->getMessage());
        echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
    }

// ========================================
// STATUS (ALWAYS RETURNS ENABLED)
// ========================================
} elseif ($action === 'status') {
    $userId = $data['user_id'] ?? '';

    if (empty($userId)) {
        echo json_encode(['success' => false, 'message' => 'Missing user ID']);
        exit;
    }

    // 2FA is always enabled for all users
    echo json_encode(['enabled' => true]);

// ========================================
// TOGGLE 2FA (DISABLED - MANDATORY 2FA)
// ========================================
} elseif ($action === 'toggle') {
    // 2FA is mandatory - cannot be disabled
    echo json_encode(['success' => false, 'message' => 'Two-factor authentication is required for all users and cannot be disabled']);

} else {
    echo json_encode(['success' => false, 'message' => 'Invalid action']);
}
?>