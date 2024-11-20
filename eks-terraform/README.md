# EKS Helper

Some helpful terraform for testing SMP on EKS, first on GovCloud but will make this variable for commercial as well.

Give it a review but this should create all assets required including a vpc and OIDC/IRSA roles.

## Tools needed
- AWS CLI
- Terraform (will add OpenTofu soon)
- Kubernetes

## Steps

### Terraform a new EKS cluster
1. Check the terraform files to ensure this deployment to ensure that this cluster will be deployed to a region of your choice.
2. Make any necessary modifications to incorporate an existing VPC of your choosing
3. Run `terraform init` then `terraform plan` to ensure this execution will run successfully.
4. Run `terraform apply` then confirm with a `yes` when the plan looks good. This can take some time, often 15-20 mins
5. Use the terraform output `eks_kubeconfig_command` that appears at the end of the terraform apply to connect to your cluster (hint: it will look like `"aws eks update-kubeconfig --name smp-eks-1-29-FW31Ae8W --region us-gov-west-1"`)

### Spin up Harness
1. Create a new namespace for harness `kubectl create ns harness`
2. Next, create a loadbalancer and default backend using our "known-good" reference: `kubectl create -f eks-terraform/loadbalancer.yaml -n harness`
3. Retrieve the resulting address from `kubectl get svc -n harness` it will look like an ALB address such as `a03c7375880b84b5099d042fd72b316c-952477994.us-gov-west-1.elb.amazonaws.com` but with a different identifier.
4. Modify the following values within `src/harness/values.yaml`
```
global:
...
  loadbalancerURL: "https://a03c7375880b84b5099d042fd72b316c-952477994.us-gov-west-1.elb.amazonaws.com" # ensure this is set to https://<the alb address>
...  
  ingress:
    className: "harness"
    enabled: true # ensure this is set to true
    # -- add global.ingress.ingressGatewayServiceUrl in hosts if global.ingress.ingressGatewayServiceUrl is not empty.
    hosts:
      - "a03c7375880b84b5099d042fd72b316c-952477994.us-gov-west-1.elb.amazonaws.com" # ensure this is set to the ALB address you previously retrieved
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

### Teardown
You can generally use a `terraform destroy` if you are done with your testing. HOWEVER, you should use a `kubectl delete -f eks-terraform/loadbalancer.yaml` otherwise you might hit this issue which makes cleanup far more difficult: https://stackoverflow.com/a/57074676