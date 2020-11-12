output "Root_Certificate_Authority" {
  value = vault_pki_secret_backend_root_cert.pki.issuing_ca
}

