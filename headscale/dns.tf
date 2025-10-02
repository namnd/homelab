data "cloudflare_zone" "this" {
  filter = {
    account = {
      id = local.cloudflare_account_id
    }
    name = local.domain
  }
}

resource "cloudflare_dns_record" "headscale" {
  zone_id = data.cloudflare_zone.this.zone_id
  name    = local.subdomain
  ttl     = 1 # Auto
  type    = "A"
  content = aws_instance.this.public_ip
  proxied = false
}
