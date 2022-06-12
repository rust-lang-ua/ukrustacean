provider "digitalocean" {
  token = var.digitalocean_token
}

resource "digitalocean_droplet" "server" {
  name   = "ukrustacean.rust-lang-ua.org"
  region = "ams3"
  size   = "s-1vcpu-1gb"
  image  = "ubuntu-22-04-x64"

  user_data = templatefile("${path.module}/provision.sh", {
    telegram_bot_token = var.telegram_bot_token
  })

  graceful_shutdown = true
}
