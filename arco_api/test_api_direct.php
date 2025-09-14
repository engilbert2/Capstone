<?php
// Test the users.php endpoint directly
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, "http://localhost/arco_api/users.php");
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, "action=get_users");
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
$response = curl_exec($ch);
curl_close($ch);

echo "Raw response: " . htmlspecialchars($response);
?>