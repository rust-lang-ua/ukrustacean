output "id" {
  value       = digitalocean_droplet.server.id
  description = "ID of the created DigitalOcean droplet"
}

output "name" {
  value       = digitalocean_droplet.server.name
  description = "Name of the created DigitalOcean droplet"
}

output "ip" {
  value       = digitalocean_droplet.server.ipv4_address
  description = "IPv4 address of the created DigitalOcean droplet"
}
