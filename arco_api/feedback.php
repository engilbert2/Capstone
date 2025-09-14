<?php
// feedback.php - UPDATED VERSION WITH ARCHIVE FUNCTIONALITY
ob_start();

session_start();
require_once 'config.php';
header("Content-Type: application/json");

// Set CORS headers
$allowedOrigins = ['http://localhost', 'http://192.168.1.14', 'http://192.168.1.14'];
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
        case 'submit':
            // Handle feedback submission from Flutter app
            if (!isset($data['user_id']) || !isset($data['message'])) {
                echo json_encode(['success' => false, 'message' => 'User ID and message are required']);
                ob_end_flush();
                exit;
            }

            $userId = filter_var($data['user_id'], FILTER_VALIDATE_INT);
            $message = trim($data['message']);
            $name = isset($data['name']) ? trim($data['name']) : 'Anonymous';
            $rating = isset($data['rating']) && $data['rating'] > 0 ? (int)$data['rating'] : null;

            // Validate inputs
            if ($userId === false || $userId <= 0) {
                echo json_encode(['success' => false, 'message' => 'Invalid user ID']);
                ob_end_flush();
                exit;
            }

            if (empty($message)) {
                echo json_encode(['success' => false, 'message' => 'Message cannot be empty']);
                ob_end_flush();
                exit;
            }

            if (empty($name)) {
                $name = 'Anonymous';
            }

            // Debug output to check what's being received
            error_log("Feedback received - User: $userId, Rating: " . ($rating ?? 'NULL') . ", Message: $message");

            // Insert feedback into database
            $stmt = $pdo->prepare("INSERT INTO feedback (user_id, message, rating, name, created_at) VALUES (?, ?, ?, ?, NOW())");
            $success = $stmt->execute([$userId, $message, $rating, $name]);

            if ($success) {
                echo json_encode([
                    'success' => true,
                    'message' => 'Feedback submitted successfully',
                    'feedback_id' => $pdo->lastInsertId() // Return the ID of the inserted feedback
                ]);
            } else {
                echo json_encode([
                    'success' => false,
                    'message' => 'Failed to submit feedback'
                ]);
            }
            break;

        // ... rest of your existing cases remain unchanged
        case 'get_feedback':
            // Get all feedback with user information
            $stmt = $pdo->query("
                SELECT f.id, f.user_id, f.message, f.rating, f.name, f.is_read, f.is_archived, f.created_at, f.archived_at,
                       u.first_name, u.last_name, u.email
                FROM feedback f
                LEFT JOIN users u ON f.user_id = u.id
                ORDER BY f.created_at DESC
            ");
            $feedback = $stmt->fetchAll(PDO::FETCH_ASSOC);

            echo json_encode([
                'success' => true,
                'feedback' => $feedback
            ]);
            break;

        case 'get_recent_feedback':
            // Get recent feedback with user information
            $limit = isset($data['limit']) ? intval($data['limit']) : 5;

            $stmt = $pdo->prepare("
                SELECT f.id, f.user_id, f.message, f.rating, f.name, f.is_read, f.is_archived, f.created_at, f.archived_at,
                       u.first_name, u.last_name
                FROM feedback f
                LEFT JOIN users u ON f.user_id = u.id
                WHERE f.is_archived = 0
                ORDER BY f.created_at DESC
                LIMIT :limit
            ");
            $stmt->bindParam(':limit', $limit, PDO::PARAM_INT);
            $stmt->execute();

            $feedback = $stmt->fetchAll(PDO::FETCH_ASSOC);

            echo json_encode([
                'success' => true,
                'feedback' => $feedback
            ]);
            break;

        case 'get_feedback_by_id':
            if (!isset($data['feedback_id'])) {
                echo json_encode(['success' => false, 'message' => 'Feedback ID required']);
                ob_end_flush();
                exit;
            }

            $stmt = $pdo->prepare("
                SELECT f.id, f.user_id, f.message, f.rating, f.name, f.is_read, f.is_archived, f.created_at, f.archived_at,
                       u.first_name, u.last_name, u.email
                FROM feedback f
                LEFT JOIN users u ON f.user_id = u.id
                WHERE f.id = ?
            ");
            $stmt->execute([$data['feedback_id']]);
            $feedback = $stmt->fetch(PDO::FETCH_ASSOC);

            if ($feedback) {
                echo json_encode([
                    'success' => true,
                    'feedback' => $feedback
                ]);
            } else {
                echo json_encode([
                    'success' => false,
                    'message' => 'Feedback not found'
                ]);
            }
            break;

        case 'delete_feedback':
            if (!isset($data['feedback_id'])) {
                echo json_encode(['success' => false, 'message' => 'Feedback ID required']);
                ob_end_flush();
                exit;
            }

            $stmt = $pdo->prepare("DELETE FROM feedback WHERE id = ?");
            $success = $stmt->execute([$data['feedback_id']]);

            if ($success) {
                echo json_encode(['success' => true, 'message' => 'Feedback deleted successfully']);
            } else {
                echo json_encode(['success' => false, 'message' => 'Failed to delete feedback']);
            }
            break;

        case 'mark_as_read':
            // Mark feedback as read
            if (!isset($data['feedback_id'])) {
                echo json_encode(['success' => false, 'message' => 'Feedback ID required']);
                ob_end_flush();
                exit;
            }

            $stmt = $pdo->prepare("UPDATE feedback SET is_read = 1 WHERE id = ?");
            $success = $stmt->execute([$data['feedback_id']]);

            if ($success) {
                echo json_encode(['success' => true, 'message' => 'Feedback marked as read']);
            } else {
                echo json_encode(['success' => false, 'message' => 'Failed to mark feedback as read']);
            }
            break;

        case 'archive_feedback':
            if (!isset($data['feedback_id'])) {
                echo json_encode(['success' => false, 'message' => 'Feedback ID required']);
                ob_end_flush();
                exit;
            }

            $stmt = $pdo->prepare("UPDATE feedback SET is_archived = 1, archived_at = NOW() WHERE id = ?");
            $success = $stmt->execute([$data['feedback_id']]);

            echo json_encode([
                'success' => $success,
                'message' => $success ? 'Feedback archived successfully' : 'Failed to archive feedback'
            ]);
            break;

        case 'restore_feedback':
            if (!isset($data['feedback_id'])) {
                echo json_encode(['success' => false, 'message' => 'Feedback ID required']);
                ob_end_flush();
                exit;
            }

            $stmt = $pdo->prepare("UPDATE feedback SET is_archived = 0, archived_at = NULL WHERE id = ?");
            $success = $stmt->execute([$data['feedback_id']]);

            echo json_encode([
                'success' => $success,
                'message' => $success ? 'Feedback restored successfully' : 'Failed to restore feedback'
            ]);
            break;

        case 'get_archived_feedback':
            $stmt = $pdo->query("
                SELECT f.id, f.user_id, f.message, f.rating, f.name, f.is_read, f.is_archived, f.created_at, f.archived_at,
                       u.first_name, u.last_name
                FROM feedback f
                LEFT JOIN users u ON f.user_id = u.id
                WHERE f.is_archived = 1
                ORDER BY f.archived_at DESC
            ");
            $feedback = $stmt->fetchAll(PDO::FETCH_ASSOC);

            echo json_encode([
                'success' => true,
                'feedback' => $feedback
            ]);
            break;

        case 'get_feedback_stats':
            // Get total feedback count
            $stmt = $pdo->query("SELECT COUNT(*) as total FROM feedback");
            $total = $stmt->fetch(PDO::FETCH_ASSOC)['total'];

            // Get unread feedback count
            $stmt = $pdo->query("SELECT COUNT(*) as unread FROM feedback WHERE is_read = 0");
            $unread = $stmt->fetch(PDO::FETCH_ASSOC)['unread'];

            // Get archived feedback count
            $stmt = $pdo->query("SELECT COUNT(*) as archived FROM feedback WHERE is_archived = 1");
            $archived = $stmt->fetch(PDO::FETCH_ASSOC)['archived'];

            echo json_encode([
                'success' => true,
                'total' => (int)$total,
                'unread' => (int)$unread,
                'archived' => (int)$archived
            ]);
            break;

        default:
            echo json_encode(['success' => false, 'message' => 'Unknown action: ' . $action]);
            break;
    }

} catch (PDOException $e) {
    error_log("Database error in feedback.php: " . $e->getMessage());
    echo json_encode([
        'success' => false,
        'message' => 'Database error: ' . $e->getMessage()
    ]);
} catch (Exception $e) {
    error_log("General error in feedback.php: " . $e->getMessage());
    echo json_encode([
        'success' => false,
        'message' => 'Server error: ' . $e->getMessage()
    ]);
}

ob_end_flush();
?>