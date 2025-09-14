<?php
require_once 'config.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method == 'GET') {
    // Get admin statistics
    if (isset($_GET['action']) && $_GET['action'] == 'stats') {
        $stmt = $pdo->query("SELECT COUNT(*) as totalUsers FROM users");
        $totalUsers = $stmt->fetch(PDO::FETCH_ASSOC)['totalUsers'];

        $stmt = $pdo->query("SELECT role, COUNT(*) as count FROM users GROUP BY role");
        $usersByRole = $stmt->fetchAll(PDO::FETCH_KEY_PAIR);

        $stmt = $pdo->query("SELECT COUNT(*) as totalExpenses FROM expenses");
        $totalExpenses = $stmt->fetch(PDO::FETCH_ASSOC)['totalExpenses'];

        echo json_encode([
            'totalUsers' => $totalUsers,
            'totalExpenses' => $totalExpenses,
            'usersByRole' => $usersByRole
        ]);
    }

    // Get users with filtering
    if (isset($_GET['action']) && $_GET['action'] == 'users') {
        $search = isset($_GET['search']) ? "%{$_GET['search']}%" : "%";
        $role = isset($_GET['role']) && $_GET['role'] != 'all' ? $_GET['role'] : "%";

        $stmt = $pdo->prepare("SELECT * FROM users
                              WHERE (username LIKE :search OR firstName LIKE :search OR lastName LIKE :search OR email LIKE :search)
                              AND role LIKE :role");
        $stmt->execute(['search' => $search, 'role' => $role]);
        $users = $stmt->fetchAll(PDO::FETCH_ASSOC);

        echo json_encode($users);
    }
}
?>
