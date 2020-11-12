apiVersion: cert-manager.io/v1alpha3
kind: Certificate
metadata:
  name: ${name}
  namespace: ${namespace}
spec:
  secretName: ${secretname}
  duration: 2h
  renewBefore: 10m
  issuerRef:
    name: vault-issuer
  commonName: ${dns_names}.${commonname}
  dnsNames:
  - ${dns_names}.${commonname}
