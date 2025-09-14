<?php
use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

require 'vendor/autoload.php'; // If using PHPMailer

function sendVerificationEmail($toEmail, $token) {
    $subject = "Your Verification Code";
    $message = "Your verification code is: $token\nThis code will expire in 15 minutes.";

    // Using PHP's mail() function (simplest)
    $headers = "From: no-reply@arko.com\r\n";
    $headers .= "Reply-To: no-reply@arko.com\r\n";
    $headers .= "Content-Type: text/plain; charset=UTF-8\r\n";

    return mail($toEmail, $subject, $message, $headers);

    // OR using PHPMailer (more reliable):
    /*
    $mail = new PHPMailer(true);
    try {
        $mail->isSMTP();
        $mail->Host = 'smtp.gmail.com';
        $mail->SMTPAuth = true;
        $mail->Username = 'your_email@gmail.com';
        $mail->Password = 'your_app_password';
        $mail->SMTPSecure = 'tls';
        $mail->Port = 587;

        $mail->setFrom('no-reply@arko.com', 'Arko App');
        $mail->addAddress($toEmail);
        $mail->Subject = $subject;
        $mail->Body = $message;

        return $mail->send();
    } catch (Exception $e) {
        error_log("Mailer Error: " . $mail->ErrorInfo);
        return false;
    }
    */
}
?>