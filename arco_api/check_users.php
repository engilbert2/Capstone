<?php
// check_users.php
header('Content-Type: application/json');

require_once 'config.php';

try {
    $stmt = $pdo->query("SELECT id, username, password, LENGTH(password) as pass_length, email FROM users");
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode(['success' => true, 'users' => $users]);

} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => 'Error: ' . $e->getMessage()]);
}
?>