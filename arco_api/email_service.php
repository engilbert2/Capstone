<?php
// email_service.php - Fixed version
use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

// Load PHPMailer files
require_once 'PHPMailer/Exception.php';
require_once 'PHPMailer/PHPMailer.php';
require_once 'PHPMailer/SMTP.php';

function sendVerificationEmail($toEmail, $token) {
    $mail = new PHPMailer(true);

    try {
        // Server settings
        $mail->SMTPDebug = 2; // Enable verbose debug output
        $mail->isSMTP();
        $mail->Host       = 'smtp.gmail.com';
        $mail->SMTPAuth   = true;
        $mail->Username   = 'engilbertreyes2@gmail.com';
        $mail->Password   = 'djdlqsmzrssspwrn';
        $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
        $mail->Port       = 587;

        // Recipients
        $mail->setFrom('engilbertreyes2@gmail.com', 'Arco App');
        $mail->addAddress($toEmail);

        // Enable this if you want to see where it fails
        $mail->addReplyTo('engilbertreyes2@gmail.com', 'Support');

        // Content
        $mail->isHTML(false);
        $mail->Subject = 'Your Verification Code';
        $mail->Body    = "Your verification code is: $token\nThis code will expire in 15 minutes.";
        $mail->AltBody = "Your verification code is: $token\nThis code will expire in 15 minutes.";

        // Debug output to error log
        $mail->Debugoutput = function($str, $level) {
            error_log("PHPMailer DEBUG: $str");
        };

        $result = $mail->send();

        error_log("✅ Email send attempt to: $toEmail - Result: " . ($result ? 'SUCCESS' : 'FAILED'));

        return $result;

    } catch (Exception $e) {
        $errorMsg = "PHPMailer Error: " . $e->getMessage();
        error_log($errorMsg);

        // Fallback to basic mail() function if PHPMailer fails
        return sendVerificationEmailFallback($toEmail, $token);
    }
}

// Fallback function using PHP's mail()
function sendVerificationEmailFallback($toEmail, $token) {
    $subject = 'Your Verification Code';
    $message = "Your verification code is: $token\nThis code will expire in 15 minutes.";

    $headers = "From: engilbertreyes2@gmail.com\r\n";
    $headers .= "Reply-To: engilbertreyes2@gmail.com\r\n";
    $headers .= "Content-Type: text/plain; charset=UTF-8\r\n";

    error_log("🔄 Using fallback mail() function for: $toEmail");

    $result = mail($toEmail, $subject, $message, $headers);
    error_log("Fallback mail() result: " . ($result ? 'SUCCESS' : 'FAILED'));

    return $result;
}

// Test function to verify email service works
function testEmailService() {
    $testEmail = 'engilbertreyes2@gmail.com'; // Send to yourself for testing
    $testToken = 'TEST123';

    error_log("🧪 Testing email service...");
    $result = sendVerificationEmail($testEmail, $testToken);

    return $result;
}
?>