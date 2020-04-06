apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: ${name}
  namespace: ${namespace}
spec:
  secretName: ${secretname}
  duration: 10m
  renewBefore: 7m
  issuerRef:
    name: vault-issuer
  commonName: ${dns_names}.${commonname}
  dnsNames:
  - ${dns_names}.${commonname}
