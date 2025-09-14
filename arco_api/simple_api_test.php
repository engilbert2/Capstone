<?php
// simple_email_service.php
function sendVerificationEmail($toEmail, $token) {
    $subject = 'Your Verification Code';
    $message = "Your verification code is: $token\nThis code will expire in 15 minutes.";
    $headers = 'From: no-reply@yourdomain.com' . "\r\n" .
               'Reply-To: no-reply@yourdomain.com' . "\r\n" .
               'X-Mailer: PHP/' . phpversion();

    return mail($toEmail, $subject, $message, $headers);
}
?>