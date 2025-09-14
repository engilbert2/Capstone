<?php
// Add output buffering at the very top
ob_start();

session_start();
require_once 'config.php';
header("Content-Type: application/json");

// Set CORS headers
$allowedOrigins = ['http://localhost', 'http://192.168.1.14'];
$origin = $_SERVER['HTTP_ORIGIN'] ?? '';
if (in_array($origin, $allowedOrigins)) {
    header("Access-Control-Allow-Origin: $origin");
}
header('Access-Control-Allow-Credentials: true');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    ob_end_clean();
    exit(0);
}

// Clean any existing output
if (ob_get_length()) ob_clean();

// Get JSON input
$input = file_get_contents("php://input");
$data = json_decode($input, true);

// Check if action is provided
if (!$data || !isset($data['action'])) {
    echo json_encode(['success' => false, 'message' => 'No action specified']);
    ob_end_flush();
    exit;
}

$action = $data['action'];

try {
    switch ($action) {
        case 'get_users':
            // Get all users with their details
            $stmt = $pdo->query("SELECT id, username, email, first_name, last_name, role, isArchived, created_at FROM users ORDER BY created_at DESC");
            $users = $stmt->fetchAll(PDO::FETCH_ASSOC);

            echo json_encode([
                'success' => true,
                'users' => $users
            ]);
            break;

        case 'archive_user':
            if (!isset($data['user_id'])) {
                echo json_encode(['success' => false, 'message' => 'User ID required']);
                ob_end_flush();
                exit;
            }

            $stmt = $pdo->prepare("UPDATE users SET isArchived = 1 WHERE id = ?");
            $stmt->execute([$data['user_id']]);

            echo json_encode(['success' => true, 'message' => 'User archived successfully']);
            break;

        case 'restore_user':
            if (!isset($data['user_id'])) {
                echo json_encode(['success' => false, 'message' => 'User ID required']);
                ob_end_flush();
                exit;
            }

            $stmt = $pdo->prepare("UPDATE users SET isArchived = 0 WHERE id = ?");
            $stmt->execute([$data['user_id']]);

            echo json_encode(['success' => true, 'message' => 'User restored successfully']);
            break;

        default:
            echo json_encode(['success' => false, 'message' => 'Invalid action']);
            break;
    }

} catch (PDOException $e) {
    error_log("Database error in users.php: " . $e->getMessage());
    echo json_encode([
        'success' => false,
        'message' => 'Database error: ' . $e->getMessage()
    ]);
}

ob_end_flush();
?>