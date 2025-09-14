<?php
header('Content-Type: text/plain');

// load PHPMailer classes
require __DIR__ . '/PHPMailer/Exception.php';
require __DIR__ . '/PHPMailer/PHPMailer.php';
require __DIR__ . '/PHPMailer/SMTP.php';

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

try {
    $mail = new PHPMailer(true);

    // SMTP config
    $mail->isSMTP();
    $mail->Host = 'smtp.gmail.com'; // or your mail server
    $mail->SMTPAuth = true;
    $mail->Username = 'engilbertreyes2@gmail.com';
    $mail->Password = 'djdlqsmzrssspwrn';
    $mail->SMTPSecure = 'tls';
    $mail->Port = 587;

    // sender/recipient
    $mail->setFrom('engilbertreyes2@gmail.com', 'Arco API');
    $mail->addAddress('admin@arko.com');

    // message
    $mail->Subject = 'Test Email';
    $mail->Body    = 'Hello, this is a test email from test_email.php';

    $mail->send();
    echo "✅ Email sent successfully!";
} catch (Exception $e) {
    echo "❌ Email failed: {$mail->ErrorInfo}";
}
