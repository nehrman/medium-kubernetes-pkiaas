output "mongodb_admin_password" {
    value = "${random_string.mongodb-adm-password.result}"
}
