<?php
$host = 'localhost';
$dbname = 'arcodb';
$username = 'root';
$password = '';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
    // Don't output error directly, return JSON instead
    header('Content-Type: application/json');
    echo json_encode(["success" => false, "message" => "Database connection failed"]);
    exit();
}
?>