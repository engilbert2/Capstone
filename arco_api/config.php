<?php
// config.php - Improved version

// Check for early output before sending headers
if (headers_sent($filename, $linenum)) {
    die(json_encode([
        'success' => false,
        'message' => "Headers already sent - check for spaces or output in $filename on line $linenum"
    ]));
}

// Set CORS headers - Fixed duplicate Access-Control-Allow-Origin
$allowedOrigins = [
    'http://192.168.1.14',
    'http://192.168.1.14:80',
    'http://localhost',
    'http://localhost:3000'
];

$requestOrigin = $_SERVER['HTTP_ORIGIN'] ?? '';
if (in_array($requestOrigin, $allowedOrigins)) {
    header("Access-Control-Allow-Origin: $requestOrigin");
} else {
    header('Access-Control-Allow-Origin: http://192.168.1.14');
}

header('Access-Control-Allow-Credentials: true');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS, DELETE, PUT, PATCH');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, Accept, X-CSRF-Token');
header('Access-Control-Max-Age: 3600');
header('Access-Control-Expose-Headers: Authorization');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Only parse JSON for POST/PUT/PATCH requests
$data = [];
$requestMethod = $_SERVER['REQUEST_METHOD'];

if (in_array($requestMethod, ['POST', 'PUT', 'PATCH'])) {
    $contentType = $_SERVER['CONTENT_TYPE'] ?? '';

    // Handle both content-type headers with and without charset
    if (stripos($contentType, 'application/json') !== false ||
        stripos($contentType, 'text/json') !== false) {

        $json = file_get_contents('php://input');
        $data = json_decode($json, true);

        if (json_last_error() !== JSON_ERROR_NONE) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'Invalid JSON input: ' . json_last_error_msg(),
                'error_code' => 'INVALID_JSON'
            ]);
            exit();
        }
    }
}

// Database configuration
$host = 'localhost';
$dbname = 'arcodb';
$username = 'root';
$password = '';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
        PDO::ATTR_PERSISTENT => false,
        PDO::MYSQL_ATTR_INIT_COMMAND => "SET time_zone = '+00:00'"
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database connection failed',
        'error_code' => 'DB_CONNECTION_ERROR',
        'debug_info' => (ENVIRONMENT === 'development') ? $e->getMessage() : null
    ]);
    exit();
}

// Define environment
define('ENVIRONMENT', getenv('APP_ENV') ?: 'production');

// Global error handling
set_error_handler(function($errno, $errstr, $errfile, $errline) {
    if (!(error_reporting() & $errno)) {
        return false;
    }

    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => ENVIRONMENT === 'development' ?
            "Error: $errstr in $errfile on line $errline" :
            'Internal server error',
        'error_code' => 'PHP_ERROR'
    ]);
    exit();
}, E_ALL);

// Exception handler
set_exception_handler(function($exception) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => ENVIRONMENT === 'development' ?
            'Uncaught Exception: ' . $exception->getMessage() :
            'Internal server error',
        'error_code' => 'UNCAUGHT_EXCEPTION',
        'debug_info' => ENVIRONMENT === 'development' ? [
            'file' => $exception->getFile(),
            'line' => $exception->getLine(),
            'trace' => $exception->getTrace()
        ] : null
    ]);
    exit();
});

// Shutdown function for fatal errors
register_shutdown_function(function() {
    $error = error_get_last();
    if ($error && in_array($error['type'], [E_ERROR, E_PARSE, E_CORE_ERROR, E_COMPILE_ERROR])) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => ENVIRONMENT === 'development' ?
                "Fatal error: {$error['message']} in {$error['file']} on line {$error['line']}" :
                'Internal server error',
            'error_code' => 'FATAL_ERROR'
        ]);
    }
});

// Utility functions
function getAuthorizationHeader() {
    $headers = null;
    if (isset($_SERVER['Authorization'])) {
        $headers = trim($_SERVER['Authorization']);
    } else if (isset($_SERVER['HTTP_AUTHORIZATION'])) {
        $headers = trim($_SERVER['HTTP_AUTHORIZATION']);
    } elseif (function_exists('apache_request_headers')) {
        $requestHeaders = apache_request_headers();
        $requestHeaders = array_combine(array_map('ucwords', array_keys($requestHeaders)), array_values($requestHeaders));
        if (isset($requestHeaders['Authorization'])) {
            $headers = trim($requestHeaders['Authorization']);
        }
    }
    return $headers;
}

function getBearerToken() {
    $headers = getAuthorizationHeader();
    if (!empty($headers) && preg_match('/Bearer\s(\S+)/', $headers, $matches)) {
        return $matches[1];
    }
    return null;
}

// Security headers in production
if (ENVIRONMENT === 'production') {
    header('X-Content-Type-Options: nosniff');
    header('X-Frame-Options: DENY');
    header('X-XSS-Protection: 1; mode=block');
}

// Timezone setting
date_default_timezone_set('UTC');

// Response helper function
function sendResponse($data, $statusCode = 200) {
    http_response_code($statusCode);
    echo json_encode($data);
    exit();
}
?>