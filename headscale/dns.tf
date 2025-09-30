data "cloudflare_zone" "this" {
  filter = {
    account = {
      id = local.cloudflare_account_id
    }
    name = "namnd.com"
  }
}

resource "cloudflare_dns_record" "headscale" {
  zone_id = data.cloudflare_zone.this.zone_id
  name    = "hs"
  ttl     = 1 # Auto
  type    = "A"
  content = oci_core_public_ip.this.ip_address
  proxied = false
}
