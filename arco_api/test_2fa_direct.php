<?php
// test_2fa.php
header('Content-Type: application/json');

// Simulate a 2FA verification request
$testData = [
    'action' => 'verify',
    'user_id' => 1,
    'verification_code' => '123456'
];

echo json_encode([
    'success' => true,
    'test_data' => $testData,
    'message' => 'Use this structure for your 2FA request'
]);
?>