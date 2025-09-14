<?php
// test_login_simple.php
header('Content-Type: application/json');

require_once 'config.php';

// Test data
$testUsername = 'testuser';
$testPassword = 'test123';

error_log("=== SIMPLE LOGIN TEST ===");
error_log("Testing: $testUsername / $testPassword");

try {
    // Check if user exists
    $stmt = $pdo->prepare("SELECT * FROM users WHERE username = :username");
    $stmt->execute(['username' => $testUsername]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        error_log("❌ User not found in database");
        echo json_encode(['success' => false, 'message' => 'User not found']);
        exit;
    }

    error_log("✅ User found in database:");
    error_log("ID: " . $user['id']);
    error_log("Username: '" . $user['username'] . "'");
    error_log("Password in DB: '" . $user['password'] . "'");
    error_log("Password length: " . strlen($user['password']));

    // Check password
    $passwordMatch = ($user['password'] === $testPassword);
    error_log("Password matches: " . ($passwordMatch ? 'YES' : 'NO'));

    if ($passwordMatch) {
        echo json_encode(['success' => true, 'message' => 'Login successful']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Invalid password']);
    }

} catch (Exception $e) {
    error_log("Error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => 'Error: ' . $e->getMessage()]);
}
?>