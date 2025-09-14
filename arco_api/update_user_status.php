<?php
ob_start();

header("Access-Control-Allow-Origin: http://localhost");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    ob_end_clean();
    http_response_code(200);
    exit();
}

include 'db_connection.php';

$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data['user_id']) || !isset($data['status'])) {
    echo json_encode(['success' => false, 'message' => 'Missing required fields']);
    exit;
}

$user_id = $data['user_id'];
$status = $data['status'];

try {
    // Convert status to isArchived boolean
    $isArchived = ($status === 'archived') ? 1 : 0;

    $stmt = $pdo->prepare("UPDATE users SET isArchived = ? WHERE id = ?");
    $stmt->execute([$isArchived, $user_id]);

    if ($stmt->rowCount() > 0) {
        echo json_encode(['success' => true, 'message' => 'User status updated successfully']);
    } else {
        echo json_encode(['success' => false, 'message' => 'User not found or no changes made']);
    }
} catch (PDOException $e) {
    echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
}

ob_end_flush();
?>