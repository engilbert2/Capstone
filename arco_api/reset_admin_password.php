<?php
// reset_admin_password.php
header('Content-Type: application/json');

$host = 'localhost';
$dbname = 'arcodb';
$username = 'root';
$password = '';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);

    // Reset admin password to "password" (hashed)
    $hashedPassword = password_hash('password', PASSWORD_DEFAULT);

    $stmt = $pdo->prepare("UPDATE users SET password = ? WHERE username = 'admin'");
    $stmt->execute([$hashedPassword]);

    echo json_encode([
        'success' => true,
        'message' => 'Admin password reset to "password"',
        'hashed_password' => $hashedPassword
    ]);

} catch (PDOException $e) {
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}
?>