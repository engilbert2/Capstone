<?php
// mobile_auth.php - Dedicated endpoint for Flutter mobile app
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Database configuration
$host = 'localhost';
$dbname = 'arcodb';
$username = 'root';
$password = '';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
    ]);

    // Set timezone to avoid expiration issues
    date_default_timezone_set('UTC');
    $pdo->exec("SET time_zone = '+00:00'");

} catch (PDOException $e) {
    echo json_encode(['success' => false, 'message' => 'Database connection failed']);
    exit();
}

// Read request JSON
$input = file_get_contents("php://input");
$data = json_decode($input, true);

if ($data === null) {
    echo json_encode(['success' => false, 'message' => 'Invalid JSON input']);
    exit();
}

$action = $data['action'] ?? '';

switch ($action) {
    // ----------------------------
    // CHECK USERNAME AVAILABILITY - MOBILE
    // ----------------------------
    case 'check_username':
        $username = $data['username'] ?? '';

        if (empty($username)) {
            echo json_encode(['success' => false, 'message' => 'Username required']);
            exit();
        }

        try {
            $stmt = $pdo->prepare("SELECT id FROM users WHERE username = ? OR email = ?");
            $stmt->execute([$username, $username]);
            $existingUser = $stmt->fetch();

            if ($existingUser) {
                echo json_encode([
                    'success' => true,
                    'available' => false,
                    'message' => 'Username already taken'
                ]);
            } else {
                echo json_encode([
                    'success' => true,
                    'available' => true,
                    'message' => 'Username available'
                ]);
            }
        } catch (Exception $e) {
            echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
        }
        break;

    // ----------------------------
    // SIGN UP USER - MOBILE
    // ----------------------------
    case 'sign_up':
        $username = $data['username'] ?? '';
        $firstName = $data['first_name'] ?? '';
        $lastName = $data['last_name'] ?? '';
        $password = $data['password'] ?? '';
        $email = $data['email'] ?? '';
        $securityQuestion = $data['security_question'] ?? '';
        $securityAnswer = $data['security_answer'] ?? '';

        if (empty($username) || empty($firstName) || empty($lastName) || empty($password)) {
            echo json_encode(['success' => false, 'message' => 'All required fields must be filled']);
            exit();
        }

        try {
            // Check if username already exists
            $stmt = $pdo->prepare("SELECT id FROM users WHERE username = ? OR email = ?");
            $stmt->execute([$username, $email]);
            $existingUser = $stmt->fetch();

            if ($existingUser) {
                echo json_encode(['success' => false, 'message' => 'Username or email already exists']);
                exit();
            }

            // Insert new user - USING CORRECT COLUMN NAME created_at
            $stmt = $pdo->prepare("
                INSERT INTO users (username, first_name, last_name, password, email, security_question, security_answer, role, isArchived, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, 'user', 0, NOW())
            ");
            $stmt->execute([$username, $firstName, $lastName, $password, $email, $securityQuestion, $securityAnswer]);

            $userId = $pdo->lastInsertId();

            echo json_encode([
                'success' => true,
                'message' => 'User created successfully',
                'user' => [
                    'id' => $userId,
                    'username' => $username,
                    'first_name' => $firstName,
                    'last_name' => $lastName,
                    'email' => $email,
                    'role' => 'user'
                ]
            ]);

        } catch (Exception $e) {
            echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
        }
        break;

    // ----------------------------
    // RESET PASSWORD - MOBILE
    // ----------------------------
    case 'reset_password':
        $username = $data['username'] ?? '';
        $securityQuestion = $data['security_question'] ?? '';
        $securityAnswer = $data['security_answer'] ?? '';
        $newPassword = $data['new_password'] ?? '';

        if (empty($username) || empty($securityQuestion) || empty($securityAnswer) || empty($newPassword)) {
            echo json_encode(['success' => false, 'message' => 'All fields are required']);
            exit();
        }

        try {
            $stmt = $pdo->prepare("
                SELECT id FROM users
                WHERE username = ? AND security_question = ? AND security_answer = ?
            ");
            $stmt->execute([$username, $securityQuestion, $securityAnswer]);
            $user = $stmt->fetch();

            if (!$user) {
                echo json_encode(['success' => false, 'message' => 'Invalid security question or answer']);
                exit();
            }

            $updateStmt = $pdo->prepare("UPDATE users SET password = ? WHERE id = ?");
            $updateStmt->execute([$newPassword, $user['id']]);

            echo json_encode(['success' => true, 'message' => 'Password reset successfully']);

        } catch (Exception $e) {
            echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
        }
        break;

    // ----------------------------
    // LOGIN (MOBILE APP) - FIXED - BLOCK ADMIN ACCOUNTS
    // ----------------------------
    case 'login':
        $username = $data['username'] ?? '';
        $password = $data['password'] ?? '';

        if (empty($username) || empty($password)) {
            echo json_encode(['success' => false, 'message' => 'Username and password required']);
            exit();
        }

        try {
            // Check if user exists and is not archived
            $stmt = $pdo->prepare("SELECT * FROM users WHERE (username = ? OR email = ?) AND isArchived = 0");
            $stmt->execute([$username, $username]);
            $user = $stmt->fetch();

            if (!$user) {
                echo json_encode(['success' => false, 'message' => 'Invalid username or password']);
                exit();
            }

            // ✅ BLOCK ADMIN ACCOUNTS FROM LOGGING INTO MOBILE APP
            if ($user['role'] === 'admin') {
                echo json_encode([
                    'success' => false,
                    'message' => 'Admin accounts cannot login through the mobile app. Please use the web admin portal.'
                ]);
                exit();
            }

            // Verify password
            if ($user['password'] !== $password) {
                echo json_encode(['success' => false, 'message' => 'Invalid username or password']);
                exit();
            }

            // Generate 6-digit token for 2FA
            $token = str_pad(rand(0, 999999), 6, '0', STR_PAD_LEFT);

            // Insert into verification_tokens - USING CORRECT COLUMN NAME created_at
            $stmt = $pdo->prepare("
                INSERT INTO verification_tokens (user_id, token, expires_at, created_at)
                VALUES (?, ?, DATE_ADD(NOW(), INTERVAL 15 MINUTE), NOW())
                ON DUPLICATE KEY UPDATE
                    token = VALUES(token),
                    expires_at = VALUES(expires_at),
                    created_at = NOW()
            ");
            $stmt->execute([$user['id'], $token]); // Use numeric user ID, not username

            // Send email
            require_once 'email_service.php';
            $emailSent = sendVerificationEmail($user['email'], $token);

            echo json_encode([
                'success' => true,
                'requires_2fa' => true,
                'user_id' => $user['id'], // Return numeric ID
                'user_email' => $user['email'],
                'message' => $emailSent ? 'Verification code sent to your email' : 'Login successful but failed to send email',
                'email_sent' => $emailSent,
                'user' => [
                    'id' => $user['id'],
                    'username' => $user['username'],
                    'email' => $user['email'],
                    'first_name' => $user['first_name'],
                    'last_name' => $user['last_name'],
                    'role' => $user['role']
                ]
            ]);

        } catch (Exception $e) {
            echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
        }
        break;

    // ----------------------------
    // VERIFY TOKEN (2FA) - MOBILE - FIXED - BLOCK ADMIN ACCOUNTS
    // ----------------------------
    case 'verify_token':
        $userId = $data['user_id'] ?? 0;
        $token = $data['token'] ?? '';

        if (!$userId || !$token) {
            echo json_encode(['success' => false, 'message' => 'User ID and token required']);
            exit();
        }

        try {
            $stmt = $pdo->prepare("
                SELECT * FROM verification_tokens
                WHERE user_id = ? AND token = ? AND expires_at > NOW()
            ");
            $stmt->execute([$userId, $token]);
            $found = $stmt->fetch();

            if ($found) {
                // Get user data and CHECK IF USER IS ADMIN
                $stmtUser = $pdo->prepare("SELECT id, username, email, first_name, last_name, role FROM users WHERE id = ? AND isArchived = 0");
                $stmtUser->execute([$userId]);
                $user = $stmtUser->fetch();

                if (!$user) {
                    echo json_encode(['success' => false, 'message' => 'User not found or account archived']);
                    exit();
                }

                // ✅ BLOCK ADMIN ACCOUNTS FROM VERIFYING TOKENS IN MOBILE APP
                if ($user['role'] === 'admin') {
                    echo json_encode([
                        'success' => false,
                        'message' => 'Admin accounts cannot login through the mobile app. Please use the web admin portal.'
                    ]);
                    exit();
                }

                // Delete used token
                $pdo->prepare("DELETE FROM verification_tokens WHERE user_id = ?")->execute([$userId]);

                echo json_encode([
                    'success' => true,
                    'message' => 'Verification successful',
                    'user' => $user
                ]);
            } else {
                echo json_encode(['success' => false, 'message' => 'Invalid or expired token']);
            }
        } catch (Exception $e) {
            echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
        }
        break;

    // ----------------------------
    // RESEND VERIFICATION CODE - MOBILE - IMPROVED
    // ----------------------------
    case 'resend_code':
        $userId = $data['user_id'] ?? '';
        $email = $data['email'] ?? '';

        if (empty($userId) || empty($email)) {
            echo json_encode(['success' => false, 'message' => 'User ID and email required']);
            exit();
        }

        try {
            // Verify user exists and email matches
            $stmt = $pdo->prepare("SELECT id, email FROM users WHERE id = ? AND email = ?");
            $stmt->execute([$userId, $email]);
            $user = $stmt->fetch();

            if (!$user) {
                echo json_encode(['success' => false, 'message' => 'User not found or email mismatch']);
                exit();
            }

            $token = str_pad(rand(0, 999999), 6, '0', STR_PAD_LEFT);

            // Insert or update token with correct column names
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