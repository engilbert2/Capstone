<?php
// Import PHPMailer classes
use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

// Load PHPMailer files
require 'PHPMailer/Exception.php';
require 'PHPMailer/PHPMailer.php';
require 'PHPMailer/SMTP.php';

// Create a new PHPMailer instance
$mail = new PHPMailer(true);

try {
    // Server settings
    $mail->isSMTP();                                      // Use SMTP
    $mail->Host       = 'smtp.gmail.com';                 // Set mail server (Gmail example)
    $mail->SMTPAuth   = true;                             // Enable SMTP authentication
    $mail->Username   = 'engilbertreyes2@gmail.com';           // Your Gmail address
    $mail->Password   = 'djdlqsmzrssspwrn';              // Gmail App Password (not your login password!)
    $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;   // Encryption (TLS)
    $mail->Port       = 587;                              // TCP port

    // Recipients
    $mail->setFrom('engilbertreyes2@gmail.com', 'Engilbert');
    $mail->addAddress('engilbertreyes4@gmail.com', 'Elio Reyes'); // Change to test email

    // Content
    $mail->isHTML(true);                                  // Set email format to HTML
    $mail->Subject = 'PHPMailer Test Email';
    $mail->Body    = '<h3>This is a test email sent using <b>PHPMailer</b>!</h3>';
    $mail->AltBody = 'This is a plain-text version of the email content.';

    // Send email
    $mail->send();
    echo "✅ Test email sent successfully!";
} catch (Exception $e) {
    echo "❌ Email could not be sent. Error: {$mail->ErrorInfo}";
}
