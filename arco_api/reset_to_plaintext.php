<?php
// reset_to_plaintext.php
header('Content-Type: application/json');

$host = 'localhost';
$dbname = 'arcodb';
$username = 'root';
$password = '';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);

    // Reset admin password to plain text
    $stmt = $pdo->prepare("UPDATE users SET password = 'password' WHERE username = 'admin'");
    $stmt->execute();

    echo json_encode([
        'success' => true,
        'message' => 'Admin password reset to plain text: "password"'
    ]);

} catch (PDOException $e) {
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}
?>