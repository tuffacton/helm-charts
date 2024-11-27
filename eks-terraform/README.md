# EKS Helper

Some helpful terraform for testing SMP on Amazon Elastic Kubernetes Service (EKS). Viable for both commercial and GovCloud flavors.

Give it a review but this should create all assets required including a vpc and OIDC/IRSA roles.

## Tools needed
- AWS CLI
- Terraform (will add OpenTofu soon)
- Kubernetes
  - Kubectl
  - Helm
- OpenSSL

## Steps

### Terraform a new EKS cluster
1. Double-check the terraform files, specifically `variables.tf` to ensure that this cluster will be deployed to a region of your choice.
2. Make any necessary modifications to incorporate an existing VPC of your choosing, or simply the default config which will take care of it for you.
3. Run `terraform init` then `terraform plan` to ensure this execution will run successfully.
4. Run `terraform apply` then confirm with a `yes` when the plan looks good. This can take some time, often 15-20 mins
5. Use the terraform output `eks_kubeconfig_command` that appears at the end of the terraform apply to connect to your cluster (hint: it will look like `"aws eks update-kubeconfig --name smp-eks-1-29-FW31Ae8W --region us-gov-west-1"`). You can always view this again with `terraform output`

### Spin up Harness
1. Create a new namespace for harness `kubectl create ns harness`
2. Next, create a loadbalancer and default backend using our attached "known-good" reference: `kubectl create -f eks-terraform/loadbalancer.yaml -n harness`
3. Retrieve the resulting address from `kubectl get svc -n harness` it will look like an ELB address such as `a03c7375880b84b5099d042fd72b316c-952477994.us-gov-west-1.elb.amazonaws.com` but with a different identifier. 
4. Modify the following values within `src/harness/values.yaml`. See SSL Guidance docs below if you would like to configure SSL certificate at this point.
```
global:
...
  loadbalancerURL: "https://a03c7375880b84b5099d042fd72b316c-952477994.us-gov-west-1.elb.amazonaws.com" # ensure this is set to https://<the ELB address>
...  
  ingress:
    className: "harness"
    enabled: true # ensure this is set to true
    # -- add global.ingress.ingressGatewayServiceUrl in hosts if global.ingress.ingressGatewayServiceUrl is not empty.
    hosts:
      - "a03c7375880b84b5099d042fd72b316c-952477994.us-gov-west-1.elb.amazonaws.com" # ensure this is set to the ELB address you previously retrieved (do not add http or https)
...
  # -- Place the license key, Harness support team will provide these
  license:
    cg: '' # leave blank
    ng: '' # if you have a license, put that string within the quotes here
```
5. After this is completed, we can apply our helm installation. Our recommendation is to utilize the `override-demo.yaml` for the resource definitions at least initially but there are other options for sizing that we can move to if needed to shrink or grow our utilization (https://developer.harness.io/docs/self-managed-enterprise-edition/reference-architecture/). The following will install our latest version of Harness SMP but we can specify a `--version` if we wish as well.
```
# Retrieve helm repos
helm repo add harness https://harness.github.io/helm-charts
helm update

# Install Harness
helm install harness harness/harness -n harness -f src/harness/override-demo.yaml -f src/harness/values.yaml

# If you see the following, then harness should spin up relatively quickly
NAME: harness
LAST DEPLOYED: Mon Nov 18 17:01:01 2024
NAMESPACE: harness
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
/(,
              (((((((((((((
           /(((((((((((((((((
         ((((((((       ((((((((
      *((((((((           ((((((((.
    (((((((((((((       (((((((((((((
  (((((((/ *(((((((* ((((((((. ((((((((        __    __       ___      .______     .__   __.  _______      _______.   _______.
   ((((((       (((((((((((((       ((((((    |  |  |  |     /   \     |   _  \    |  \ |  | |   ____|    /       |  /       |
((((((          ((((((((/          (((((      |  |__|  |    /  ^  \    |  |_)  |   |   \|  | |  |__      |   (----` |   (----`
 ((((((       (((((((((((((      ,((((((      |   __   |   /  /_\  \   |      /    |  . `  | |   __|      \   \      \   \
  (((((((( /(((((((. *(((((((* ((((((((       |  |  |  |  /  _____  \  |  |\  \---.|  |\   | |  |____ .----)   | .----)   |
    (((((((((((((       ((((((((((((/         |__|  |__| /__/     \__\ | _| `.____||__| \__| |_______||_______/  |_______/
      .((((((((           ((((((((
         ((((((((      .(((((((/
            (((((((((((((((((
              ((((((((((((/
```
6. Navigate to your alb address from step 3 in a browser and you should see a live Harness interface(you might need to skip any TLS verification for now, but these can be adjusted later easily!) 
7. You should can make the first Harness admin user by navigating to `https://<YOUR_ELB_ADDRESS>/auth/#/signup` and filling out the resulting form.
8. If you're provided a license later or want to make modifications to your URL/add TLS then we can run a `helm upgrade` on this release with the new values applied.


### SSL/TLS via Self-Signed Certificates
One option to keep things simple for demo or POV purposes is to use a self-signed certificate in place of certificates provided by your Certificate Authority tied to your DNS intended to act as the front-end of your Harness platform. These can done during initial setup or modified later once you're ready to move to production.

Generate a self-signed certificate and private key using `openssl` (this [guide](https://kubernetes.github.io/ingress-nginx/user-guide/tls/) is helpful).
```
# Set the following variables
KEY_FILE="tls.key" 
CERT_FILE="tls.crt"
HOST="aeda914c9b83042d0bce15c8ec33cce2-2065664118.us-east-1.elb.amazonaws.com" # or similar ALB generated from previous loadbalancer.yaml
# generate the certificates
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ${KEY_FILE} -out ${CERT_FILE} \
-subj "/O=LoadBalancer" \
-addext "subjectAltName = DNS:${HOST}"
```

Then create the secret in the cluster
```
CERT_NAME="harness-cert"
kubectl create secret tls ${CERT_NAME} --key ${KEY_FILE} --cert ${CERT_FILE}
```

Then ensure the following values are set in the `values.yaml`:
```
  ingress:
    className: "harness"
...
    tls:
      enabled: true
      secretName: harness-cert # ensure this name matches your harness secret
```

Then run a helm upgrade (modify with intended additions like the `--version` if needed):
```
helm upgrade harness harness/harness -n harness -f src/harness/override-demo.yaml -f src/harness/values.yaml
```

#### Delegates with Self-Signed Certs
You can deploy a delegate with these self-signed certs as well.

Create a PEM from the previous files:
```
cat ${CERT_FILE} ${KEY_FILE} > delegate-cert.pem
```

Then use that pem to create a secret to use with your delegate (you can add more `--from-file` to this command if you have many certificates required)
```
kubectl create secret generic harness-delegate-cert -n harness-delegate-ng --from-file custom-cert1=delegate-cert.pem
```

Use the public helm repo to add the charts for harness delegate:
```
helm repo add harness-delegate https://app.harness.io/storage/harness-download/delegate-helm-chart/
helm repo update
```

You can now generally follow the guidance here to create a delegate token but instead use the self-signed certificate created earlier to onboard the delegate (https://developer.harness.io/docs/platform/get-started/tutorials/install-delegate/#install-the-default-harness-delegate) using the `--set delegateCustomCa.secretName=<SECRET_NAME>` from the previously created secret. For example:
```
helm upgrade -i helm-delegate --namespace harness-delegate-ng --create-namespace \
  harness-delegate/harness-delegate-ng \
  --set delegateName=helm-delegate \
  --set deployMode=KUBERNETES_ONPREM \
  --set accountId=zfGa_nKWSPaMIFvDuPNkaw \
  --set delegateToken=YmRjNDI4YjhlMjEzYjYzOTI1NzdkZTZkMzE5OGY3YWM= \
  --set managerEndpoint=https://aeda914c9b83042d0bce15c8ec33cce2-2065664118.us-east-1.elb.amazonaws.com \
  --set delegateDockerImage=docker.io/harness/delegate:24.09.83900 \
  --set replicas=1 --set upgrader.enabled=true \
  --set delegateCustomCa.secretName=harness-delegate-cert \
  --set upgraderCustomCa.secretName=harness-delegate-cert
```

You should have a healthy delegate in about 2 minutes which you can validate on the Harness UI as well.

### Teardown
You should use a `kubectl delete -f eks-terraform/loadbalancer.yaml` otherwise you might hit this issue which makes cleanup far more difficult: https://stackoverflow.com/a/57074676

Then, you can generally use a `terraform destroy` if you are done with your testing. 
