variable "postgres_root_password" {
  description = "Password for the NY Taxi database"
  type        = string
  default     = "root" # You can set defaults or leave them empty to force entry
}

variable "kestra_db_password" {
  description = "Password for the Kestra backend database"
  type        = string
  sensitive   = true # This hides the password in your terminal logs!
}

variable "pgadmin_email" {
  default = "admin@admin.com"
}
