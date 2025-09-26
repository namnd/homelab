resource "tls_private_key" "root_ca_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "root_ca" {
  private_key_pem    = tls_private_key.root_ca_key.private_key_pem
  is_ca_certificate  = true
  set_subject_key_id = true

  subject {
    country             = "AU"
    province            = "Queensland"
    locality            = "Brisbane"
    organization        = "namnd"
    organizational_unit = "homelab"
    common_name         = "VPN root CA"
  }

  validity_period_hours = 8760 # 1 year

  allowed_uses = [
    "cert_signing",
    "crl_signing",
    "digital_signature",
  ]
}

resource "aws_rolesanywhere_trust_anchor" "this" {
  name    = "namnd-homelab"
  enabled = true

  source {
    source_data {
      x509_certificate_data = tls_self_signed_cert.root_ca.cert_pem
    }
    source_type = "CERTIFICATE_BUNDLE"
  }
}

data "aws_iam_policy_document" "assume_role_anywhere" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["rolesanywhere.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:SetSourceIdentity",
      "sts:TagSession",
    ]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_rolesanywhere_trust_anchor.this.arn]
    }
  }
}

resource "aws_iam_role" "vpn" {
  name = "namnd-homelab-vpn"

  assume_role_policy = data.aws_iam_policy_document.assume_role_anywhere.json
}

resource "aws_rolesanywhere_profile" "vpn" {
  enabled = true

  name      = "namnd-homelab"
  role_arns = [aws_iam_role.vpn.arn]
}

resource "kubernetes_namespace" "vpn" {
  metadata {
    name = "vpn"
  }
}

resource "kubernetes_secret" "root_ca" {
  metadata {
    name      = "namnd-homelab-iamra-ca"
    namespace = kubernetes_namespace.vpn.id
  }

  data = {
    "tls.key" = tls_private_key.root_ca_key.private_key_pem
    "tls.crt" = tls_self_signed_cert.root_ca.cert_pem
  }
}

resource "kubernetes_manifest" "root_ca_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Issuer"
    metadata = {
      name      = "namnd-homelab-ca-issuer"
      namespace = kubernetes_namespace.vpn.id
    }

    spec = {
      ca = {
        secretName = kubernetes_secret.root_ca.metadata[0].name
      }
    }
  }
}

resource "kubernetes_manifest" "root_ca_cert" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "namnd-homelab-ca-cert"
      namespace = kubernetes_namespace.vpn.id
    }

    spec = {
      commonName = "VPN root CA"
      duration   = "2160h"
      issuerRef = {
        group = "cert-manager.io"
        kind  = "Issuer"
        name  = "namnd-homelab-ca-issuer"
      }
      secretName = "namnd-homelab-iamra-cert"
      privateKey = {
        algorithm = "RSA"
        size      = 2048
      }
    }
  }
}

resource "tailscale_tailnet_key" "this" {
  reusable      = true
  ephemeral     = true
  preauthorized = false
  description   = "namnd-homelab auth key"
}

resource "helm_release" "vpn" {
  name       = "vpn"
  repository = "https://namnd.github.io/helm-charts"
  chart      = "vpn"
  version    = "0.3.0"

  create_namespace = false
  namespace        = kubernetes_namespace.vpn.id

  set = [
    {
      name  = "tailscaleAuthKey"
      value = tailscale_tailnet_key.this.key
    },
    {
      name  = "iamra.trustAnchorArn"
      value = aws_rolesanywhere_trust_anchor.this.arn
    },
    {
      name  = "iamra.profileArn"
      value = aws_rolesanywhere_profile.vpn.arn
    },
    {
      name  = "iamra.roleArn"
      value = aws_iam_role.vpn.arn
    },
    {
      name  = "iamra.certSecretName"
      value = "namnd-homelab-iamra-cert"
    },
  ]
}
