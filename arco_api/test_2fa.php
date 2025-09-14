<?php
// test_2fa.php - FIXED VERSION
echo "<h2>Testing 2FA API</h2>";

// First, let's get a valid user ID from the database
try {
    require_once __DIR__ . '/config.php';

    // Get a real user from the database
    $stmt = $pdo->query("SELECT id, username, email FROM users WHERE isArchived = 0 LIMIT 1");
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($user) {
        echo "<p>Testing with user: <strong>{$user['username']}</strong> (ID: {$user['id']})</p>";
        echo "<p>Email: {$user['email']}</p>";

        $userId = $user['id'];
        $email = $user['email'];
    } else {
        echo "<p style='color: red;'>❌ No users found in database</p>";
        // Use fallback values
        $userId = 1;
        $email = 'engilbertreyes2@gmail.com';
    }
} catch (Exception $e) {
    echo "<p style='color: red;'>❌ Database error: " . $e->getMessage() . "</p>";
    // Use fallback values
    $userId = 1;
    $email = 'engilbertreyes2@gmail.com';
}

// Test the 2FA API endpoint
$url = 'http://localhost/arco_api/2fa.php';
$data = [
    'action' => 'generate_token',
    'user_id' => $userId, // Use numeric ID from database
    'email' => $email
];

echo "<p>Request data: <pre>" . json_encode($data, JSON_PRETTY_PRINT) . "</pre></p>";

$options = [
    'http' => [
        'header'  => "Content-type: application/json\r\n",
        'method'  => 'POST',
        'content' => json_encode($data),
    ],
];

$context = stream_context_create($options);

try {
    $result = file_get_contents($url, false, $context);

    if ($result === FALSE) {
        echo "<p style='color: red;'>❌ No response from API</p>";

        // Check if the file exists and is accessible
        $apiFile = 'D:\xampp\htdocs\arco_api\2fa.php';
        if (!file_exists($apiFile)) {
            echo "<p style='color: red;'>❌ 2fa.php file not found</p>";
        } else {
            echo "<p style='color: green;'>✅ 2fa.php file exists</p>";

            // Check file content
            $content = file_get_contents($apiFile);
            if (strpos($content, 'generate_token') !== false) {
                echo "<p style='color: green;'>✅ 2fa.php contains generate_token code</p>";
            } else {
                echo "<p style='color: red;'>❌ 2fa.php does not contain generate_token code</p>";
            }
        }
    } else {
        echo "<p>Response: <pre>" . json_encode(json_decode($result), JSON_PRETTY_PRINT) . "</pre></p>";

        // Check if it's valid JSON
        if (json_last_error() === JSON_ERROR_NONE) {
            echo "<p style='color: green;'>✅ Valid JSON response</p>";
        } else {
            echo "<p style='color: red;'>❌ Invalid JSON response: " . json_last_error_msg() . "</p>";
            echo "<p>Raw response: <pre>" . htmlspecialchars($result) . "</pre></p>";
        }
    }
} catch (Exception $e) {
    echo "<p style='color: red;'>❌ Error: " . $e->getMessage() . "</p>";
}

// Test direct file access
echo "<h3>Testing Direct File Access:</h3>";
$apiFile = 'D:\xampp\htdocs\arco_api\2fa.php';
if (file_exists($apiFile)) {
    // Check file size
    $fileSize = filesize($apiFile);
    echo "<p>File size: $fileSize bytes</p>";

    // Check first few lines
    $content = file_get_contents($apiFile);
    $lines = explode("\n", $content);
    echo "<p>First 5 lines:</p>";
    echo "<pre>";
    for ($i = 0; $i < min(5, count($lines)); $i++) {
        echo htmlspecialchars($lines[$i]) . "\n";
    }
    echo "</pre>";
} else {
    echo "<p style='color: red;'>❌ 2fa.php not found</p>";
}
?>