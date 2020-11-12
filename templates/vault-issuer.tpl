apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: vault-issuer
  namespace: ${namespace}
spec:
  vault:
    path: pki_int/sign/fruits-catalog
    namespace: test
    server: http://${vault_address}
    auth:
      kubernetes:
        role: ${vault_k8s_role}
        mountPath: /v1/test/auth/${vault_k8s_backend_path}
        secretRef:
          name: ${secret_name} 
          key: token
