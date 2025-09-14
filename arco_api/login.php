<?php
include 'db.php';

// Read request (from Flutter)
$username = $_POST['username'] ?? '';
$password = $_POST['password'] ?? '';

if (empty($username) || empty($password)) {
    echo json_encode([
        "success" => false,
        "message" => "Missing username or password"
    ]);
    exit;
}

// Check user in database
$sql = "SELECT * FROM users WHERE username = ? LIMIT 1";
$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $username);
$stmt->execute();
$result = $stmt->get_result();

if ($row = $result->fetch_assoc()) {
    // Simple password check (you can use password_hash for better security)
    if ($row['password'] === $password) {
        echo json_encode([
            "success" => true,
            "message" => "Login successful",
            "user" => [
                "id" => $row['id'],
                "username" => $row['username'],
                "email" => $row['email'], // ← ADD THIS LINE
                "role" => $row['role'] ?? "user"
            ]
        ]);
    } else {
        echo json_encode([
            "success" => false,
            "message" => "Invalid password"
        ]);
    }
} else {
    echo json_encode([
        "success" => false,
        "message" => "User not found"
    ]);
}
?>