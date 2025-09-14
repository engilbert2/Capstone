<?php
// check_tables.php
echo "<h2>Checking Database Tables</h2>";

try {
    require_once 'arco_api/config.php';

    // Check if verification_tokens table exists
    $stmt = $pdo->query("SHOW TABLES LIKE 'verification_tokens'");
    $tableExists = $stmt->rowCount() > 0;

    if ($tableExists) {
        echo "<p style='color: green;'>✅ verification_tokens table exists</p>";

        // Check table structure
        $stmt = $pdo->query("DESCRIBE verification_tokens");
        $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);

        echo "<p>Table columns:</p>";
        echo "<ul>";
        foreach ($columns as $column) {
            echo "<li>{$column['Field']} ({$column['Type']})</li>";
        }
        echo "</ul>";
    } else {
        echo "<p style='color: red;'>❌ verification_tokens table does not exist</p>";
        echo "<p>Run this SQL in phpMyAdmin:</p>";
        echo "<pre>CREATE TABLE verification_tokens (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    token VARCHAR(6) NOT NULL,
    expires_at DATETIME NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_user (user_id)
);</pre>";
    }

    // Check if users table has is2FAEnabled column
    $stmt = $pdo->query("SHOW COLUMNS FROM users LIKE 'is2FAEnabled'");
    $columnExists = $stmt->rowCount() > 0;

    if ($columnExists) {
        echo "<p style='color: green;'>✅ users table has is2FAEnabled column</p>";
    } else {
        echo "<p style='color: red;'>❌ users table missing is2FAEnabled column</p>";
        echo "<p>Run this SQL in phpMyAdmin:</p>";
        echo "<pre>ALTER TABLE users ADD COLUMN is2FAEnabled TINYINT(1) DEFAULT 0;</pre>";
    }

} catch (Exception $e) {
    echo "<p style='color: red;'>❌ Database error: " . $e->getMessage() . "</p>";
}
?>