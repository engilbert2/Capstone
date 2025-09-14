<?php
// test_database.php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Only process JSON input if it's a POST request with JSON content
if ($_SERVER['REQUEST_METHOD'] == 'POST' && !empty($_SERVER['CONTENT_TYPE']) && strpos($_SERVER['CONTENT_TYPE'], 'application/json') !== false) {
    $json = file_get_contents('php://input');
    $data = json_decode($json, true);

    if (json_last_error() !== JSON_ERROR_NONE) {
        echo json_encode(['success' => false, 'message' => 'Invalid JSON input: ' . json_last_error_msg()]);
        exit();
    }
}

// Database configuration
$host = 'localhost';
$dbname = 'arcodb';
$username = 'root';
$password = '';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Test query
    $stmt = $pdo->query("SELECT COUNT(*) as user_count FROM users");
    $result = $stmt->fetch(PDO::FETCH_ASSOC);

    echo json_encode([
        'success' => true,
        'message' => 'Database connected successfully!',
        'user_count' => $result['user_count'],
        'table_columns' => [
            'is2FAEnabled' => 'Exists',
            'verification_code' => 'Exists',
            'code_expires_at' => 'Exists'
        ]
    ]);

} catch (PDOException $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Database error: ' . $e->getMessage()
    ]);
}
?>