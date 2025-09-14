<?php
header("Access-Control-Allow-Origin: http://localhost");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

include 'db_connection.php';

$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data['name']) || !isset($data['email']) || !isset($data['role']) || !isset($data['status'])) {
    echo json_encode(['success' => false, 'message' => 'Missing required fields']);
    exit;
}

// Prevent creating admin users through this interface
if ($data['role'] === 'admin') {
    echo json_encode(['success' => false, 'message' => 'Cannot create admin users through this interface']);
    exit;
}

try {
    $stmt = $pdo->prepare("INSERT INTO users (username, email, role, status) VALUES (?, ?, ?, ?)");
    $stmt->execute([$data['name'], $data['email'], $data['role'], $data['status']]);

    echo json_encode(['success' => true, 'message' => 'User added successfully']);
} catch (PDOException $e) {
    echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
}
?>