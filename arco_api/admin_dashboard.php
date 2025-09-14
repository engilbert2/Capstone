[file name]: admin_dashboard.php
[file content begin]
<?php
session_start();
require_once 'config.php';

// Check if user is logged in and is admin
if (!isset($_SESSION['user']) || $_SESSION['user']['role'] !== 'admin') {
    header('Location: index.html');
    exit();
}

// Get user data from session
$user = $_SESSION['user'];
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Dashboard - Arko</title>
    <!-- Same CSS as above -->
</head>
<body>
<div class="dashboard">
    <div class="welcome">
        <h1>Admin Dashboard</h1>
        <p>Welcome, <?php echo htmlspecialchars($user['firstName'] . ' ' . $user['lastName']); ?>!</p>
        <!-- Rest of the HTML from admin_dashboard.html -->
    </div>
</div>
<!-- Same JavaScript as above -->
</body>
</html>
<?php } ?>
[file content end]