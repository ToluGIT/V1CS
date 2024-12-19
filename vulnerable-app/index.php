<?php
// Vulnerable SQL injection 
$conn = new mysqli('localhost', 'root', '', 'testdb');
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

$id = $_GET['id']; // Unsafe user input
$sql = "SELECT * FROM users WHERE id = $id"; // SQL injection vulnerability
$result = $conn->query($sql);

while ($row = $result->fetch_assoc()) {
    echo "User: " . $row['username'] . "<br>";
}

$conn->close();
?>
