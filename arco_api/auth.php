<?php
session_start();
require_once 'config.php';
header("Content-Type: application/json");

// Set CORS headers
header('Access-Control-Allow-Origin: http://192.168.1.14');
header('Access-Control-Allow-Credentials: true');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// Allow only POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['success' => false, 'message' => 'Invalid request method']);
    exit;
}

// Read request JSON
$input = file_get_contents("php://input");
$data = json_decode($input, true);

if ($data === null) {
    echo json_encode(['success' => false, 'message' => 'Invalid JSON input']);
    exit;
}

$action = $data['action'] ?? '';

switch ($action) {
    // ----------------------------
    // GENERATE CAPTCHA
    // ----------------------------
    case 'generate_captcha':
        // Generate simple numeric captcha
        $captcha = strval(rand(1000, 9999));
        $_SESSION['captcha'] = $captcha;

        echo json_encode([
            'success' => true,
            'captcha' => $captcha
        ]);
        break;

    // ----------------------------
    // VERIFY CAPTCHA
    // ----------------------------
    case 'verify_captcha':
        $captcha = $data['captcha'] ?? '';
        $storedCaptcha = $_SESSION['captcha'] ?? '';

        if (empty($captcha)) {
            echo json_encode(['success' => false, 'message' => 'CAPTCHA required']);
        } elseif ($captcha === $storedCaptcha) {
            // Clear the CAPTCHA after successful verification
            unset($_SESSION['captcha']);
            echo json_encode(['success' => true, 'message' => 'CAPTCHA verified']);
        } else {
            echo json_encode(['success' => false, 'message' => 'Invalid CAPTCHA']);
        }
        break;

    // ----------------------------
    // LOGIN (ADMIN USERS ONLY)
    // ----------------------------
    case 'login':
        $username = $data['username'] ?? '';
        $password = $data['password'] ?? '';
        $captcha = $data['captcha'] ?? '';
        $storedCaptcha = $_SESSION['captcha'] ?? '';

        try {
            $stmt = $pdo->prepare("SELECT * FROM users WHERE username = :username AND isArchived = 0");
            $stmt->execute(['username' => $username]);
            $user = $stmt->fetch(PDO::FETCH_ASSOC);

            if (!$user || $user['password'] !== $password) {
                // Increment failed attempts
                $_SESSION['login_attempts'][$username] = ($_SESSION['login_attempts'][$username] ?? 0) + 1;

                echo json_encode(['success' => false, 'message' => 'Invalid username or password']);
                exit();
            }

            // CHECK IF USER IS ADMIN - BLOCK NON-ADMIN USERS
            if ($user['role'] !== 'admin') {
                echo json_encode([
                    'success' => false,
                    'message' => 'Access denied. Admin privileges required to access this website.'
                ]);
                exit();
            }

            // CAPTCHA verification for ADMIN users
            // First verify CAPTCHA if provided
            if (!empty($captcha) && $captcha !== $storedCaptcha) {
                echo json_encode(['success' => false, 'message' => 'Invalid CAPTCHA']);
                exit();
            }

            // Clear CAPTCHA after verification
            if (!empty($captcha)) {
                unset($_SESSION['captcha']);
            }

            // Check if CAPTCHA is required for admin users (first failed attempt)
            $failedAttempts = $_SESSION['login_attempts'][$username] ?? 0;

            if ($failedAttempts >= 1 && empty($captcha)) {
                // CAPTCHA required
                echo json_encode([
                    'success' => false,
                    'message' => 'CAPTCHA required',
                    'requires_captcha' => true
                ]);
                exit();
            }

            // Generate 6-digit token
            $token = str_pad(rand(0, 999999), 6, '0', STR_PAD_LEFT);

            $stmt = $pdo->prepare("
                INSERT INTO verification_tokens (user_id, token, expires_at, created_at)
                VALUES (?, ?, DATE_ADD(NOW(), INTERVAL 15 MINUTE), NOW())
                ON DUPLICATE KEY UPDATE
                    token = VALUES(token),
                    expires_at = VALUES(expires_at),
                    created_at = NOW()
            ");
            $stmt->execute([$user['id'], $token]);

            // Send email - ADD PROPER ERROR HANDLING
            require_once 'email_service.php';
            $emailSent = sendVerificationEmail($user['email'], $token);

            // Log the result
            error_log("Email sending result for {$user['email']}: " . ($emailSent ? 'Success' : 'Failed'));

            // Reset failed attempts
            unset($_SESSION['login_attempts'][$username]);

            echo json_encode([
                'success' => true,
                'requires_2fa' => true,
                'user_id' => $user['id'],
                'user_email' => $user['email'],
                'is_admin' => true, // Always true since we block non-admin users
                'message' => $emailSent ? 'Verification code sent' : 'Login successful but failed to send email',
                'email_sent' => $emailSent,
                'user' => [
                    'id' => $user['id'],
                    'username' => $user['username'],
                    'email' => $user['email'],
                    'firstName' => $user['first_name'],
                    'lastName' => $user['last_name'],
                    'role' => $user['role']
                ]
            ]);
        } catch (Exception $e) {
            // Increment failed attempts
            $_SESSION['login_attempts'][$username] = ($_SESSION['login_attempts'][$username] ?? 0) + 1;

            echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
        }
        break;

    // ----------------------------
    // VERIFY TOKEN (2FA) - ADMIN ONLY
    // ----------------------------
    case 'verify_token':
        $userId = $data['user_id'] ?? 0;
        $token = $data['token'] ?? '';

        if (!$userId || !$token) {
            echo json_encode(['success' => false, 'message' => 'User ID and token required']);
            exit;
        }

        $stmt = $pdo->prepare("
            SELECT * FROM verification_tokens
            WHERE user_id = ? AND token = ? AND expires_at > NOW()
        ");
        $stmt->execute([$userId, $token]);
        $found = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($found) {
            // Verify that the user is still an admin
            $stmtUser = $pdo->prepare("SELECT id, username, email, first_name, last_name, role FROM users WHERE id = ? AND role = 'admin'");
            $stmtUser->execute([$userId]);
            $user = $stmtUser->fetch(PDO::FETCH_ASSOC);

            if (!$user) {
                echo json_encode(['success' => false, 'message' => 'Access denied. Admin privileges required.']);
                exit();
            }

            $pdo->prepare("DELETE FROM verification_tokens WHERE user_id = ?")->execute([$userId]);

            // Set session data
            $_SESSION['user'] = $user;
            $_SESSION['logged_in'] = true;

            // Return user data for client-side storage
            echo json_encode([
                'success' => true,
                'message' => 'Verification successful',
                'user' => $user
            ]);
        } else {
            echo json_encode(['success' => false, 'message' => 'Invalid or expired token']);
        }
        break;

    // ----------------------------
    // RESEND VERIFICATION CODE - ADMIN ONLY
    // ----------------------------
    case 'resend_code':
        $userId = $data['user_id'] ?? '';
        $email = $data['email'] ?? '';

        if (empty($userId) || empty($email)) {
            echo json_encode(['success' => false, 'message' => 'User ID and email required']);
            exit;
        }

        try {
            // Verify that the user is an admin before resending code
            $stmt = $pdo->prepare("SELECT id FROM users WHERE id = ? AND role = 'admin'");
            $stmt->execute([$userId]);
            $adminUser = $stmt->fetch(PDO::FETCH_ASSOC);

            if (!$adminUser) {
                echo json_encode(['success' => false, 'message' => 'Access denied. Admin privileges required.']);
                exit();
            }

            $token = str_pad(rand(0, 999999), 6, '0', STR_PAD_LEFT);

            $stmt = $pdo->prepare("
                INSERT INTO verification_tokens (user_id, token, expires_at, created_at)
                VALUES (?, ?, DATE_ADD(NOW(), INTERVAL 15 MINUTE), NOW())
                ON DUPLICATE KEY UPDATE
                    token = VALUES(token),
                    expires_at = VALUES(expires_at),
                    created_at = NOW()
            ");
            $stmt->execute([$userId, $token]);

            require_once 'email_service.php';
            $emailSent = sendVerificationEmail($email, $token);

            // Log the result
            error_log("Resend email result for {$email}: " . ($emailSent ? 'Success' : 'Failed'));

            echo json_encode([
                'success' => true,
                'message' => $emailSent ? 'Verification code resent' : 'Failed to resend verification code',
                'email_sent' => $emailSent
            ]);
        } catch (Exception $e) {
            echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
        }
        break;

    default:
        echo json_encode(['success' => false, 'message' => 'Invalid action']);
}
?>