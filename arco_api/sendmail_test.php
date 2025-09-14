<?php
echo "<h2>Testing Sendmail Configuration</h2>";

// Test email using sendmail
$to = "your_email@gmail.com"; // Change to your actual email
$subject = "Sendmail Test from XAMPP";
$message = "This is a test email using sendmail configuration";
$headers = "From: engilbertreyes2@gmail.com\r\n";
$headers .= "Reply-To: engilbertreyes2@gmail.com\r\n";
$headers .= "Content-Type: text/plain; charset=UTF-8\r\n";

if (mail($to, $subject, $message, $headers)) {
    echo "<p style='color: green;'>✓ Email sent successfully using sendmail!</p>";
} else {
    echo "<p style='color: red;'>✗ Email failed to send</p>";
    $error = error_get_last();
    echo "<pre>Error: " . print_r($error, true) . "</pre>";
}

// Show sendmail path
echo "<h3>Sendmail Path:</h3>";
echo "sendmail_path: " . ini_get('sendmail_path') . "<br>";

// Check if sendmail.exe exists
$sendmailPath = "C:\\xampp\\sendmail\\sendmail.exe";
if (file_exists($sendmailPath)) {
    echo "<p style='color: green;'>✓ sendmail.exe found</p>";
} else {
    echo "<p style='color: red;'>✗ sendmail.exe NOT found at: $sendmailPath</p>";
}
?>