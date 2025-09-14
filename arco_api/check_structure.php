<?php
// check_structure.php
echo "<h2>Checking Folder Structure</h2>";

$paths_to_check = [
    'D:\xampp\htdocs\\',
    'D:\xampp\htdocs\arco_api\\',
    'D:\xampp\htdocs\arco_api\PHPMailer\\'
];

foreach ($paths_to_check as $path) {
    if (is_dir($path)) {
        echo "<p style='color: green;'>✅ Folder exists: $path</p>";

        // List files in this directory
        $files = scandir($path);
        echo "<ul>";
        foreach ($files as $file) {
            if ($file != '.' && $file != '..') {
                $full_path = $path . $file;
                $type = is_dir($full_path) ? '📁 Directory' : '📄 File';
                echo "<li>$type: $file</li>";
            }
        }
        echo "</ul>";
    } else {
        echo "<p style='color: red;'>❌ Folder missing: $path</p>";
    }
}
?>
