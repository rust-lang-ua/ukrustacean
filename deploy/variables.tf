variable "digitalocean_token" {
  type        = string
  sensitive   = true
  description = "DigitalOcean API token"
}

variable "telegram_bot_token" {
  type        = string
  sensitive   = true
  description = "Telegram Bot token"
}
