# vault-k8s-pki
This is a demo project to have HashiCorp Vault issue PKI certificates for Kubernetes applications

Learn more about this project including many more here: [The Best Kept Secrets of HashiCorp Vault](https://secretsofvault.com/).

## Helpful commands

Manually scale the agent injector deployment down:
```
kubectl scale deployment vault-agent-injector --replicas=0
```

Manually scale the agent injector deployment back up:
```
kubectl scale deployment vault-agent-injector --replicas=1
```

To ***update/upgrade*** the exsisting Helm Chart deployment
```
helm upgrade --install vault hashicorp/vault \
    --set "injector.enabled=true" \
    --set "global.externalVaultAddr=http://$EXTERNAL_VAULT_ADDR:8200"
```

Verify network connectivity to Vault cluster if it is running locally from minikube:
```
dig +short host.docker.internal | xargs -I{} curl -s http://{}:8200/v1/sys/seal-status
```