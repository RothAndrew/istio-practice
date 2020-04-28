# istio-practice

Repo to collect the things I do to practice with Istio.

This guide is written with the assumption that the reader already understands and uses Docker and Kubernetes.

The guide has been developed using Linux and MacOS. Not so sure about Windows. Your mileage may vary.

This guide uses a kubernetes cluster in AWS EKS. For a version that uses your local dev machine, go [here](../README.md)

## Prerequisites

You need the following tools installed. Links have been provided to documentation on how to install them.

- [docker](https://www.docker.com/get-started)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [istioctl](https://istio.io/docs/ops/diagnostic-tools/istioctl/)
- [helm 3+](https://helm.sh/docs/intro/quickstart/)
- [arkade](https://github.com/alexellis/arkade)
- [terraform](https://learn.hashicorp.com/terraform/getting-started/install.html)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)

## Clone this repository

```sh
git clone https://github.com/RothAndrew/istio-practice.git
cd istio-practice
```

## Create a Kubernetes cluster using Terraform

Note: This requires real money and access to an AWS account where you can provision resources. It will create a VPC, subnets, the cluster, EC2 resources, and IAM resources. See [main.tf](./main.tf) for full details.

Make sure your AWS CLI is configured to point at the right profile. `aws sts get-caller-identity` without specifying a profile should point to where you want to deploy to.

```sh
cd eks
terraform init
terraform apply
```

Your kube context should automatically be switched. Run `kubectl get nodes` to make sure.

## Install Istio using Istio Operator

1. Install the operator

   ```sh
   istioctl operator init
   ```

1. Install the Istio `demo` configuration profile

   ```sh
   kubectl create ns istio-system
   kubectl apply -f - <<EOF
   apiVersion: install.istio.io/v1alpha1
   kind: IstioOperator
   metadata:
     namespace: istio-system
     name: example-istiocontrolplane
   spec:
     profile: demo
   EOF
   ```

## Set up Inlets to get a public IP for the Ingress Gateway

Note: This costs actual money (around \$5 per month per LoadBalancer if you keep it running)

1. Set up a DigitalOcean account and create an access token
1. Save the token in a text file
1. Install [Inlets](https://github.com/inlets/inlets-operator) using `arkade`

   ```sh
   TOKEN_FILE="PathToYourTokenFileHere"
   arkade install inlets-operator \
     --helm3 \
     --provider digitalocean \
     --region lon1 \
     --token-file "$TOKEN_FILE"
   ```

1. Wait for the operator to automatically create a DigitalOcean droplet. You'll know when it is ready when the `istio-ingressgateway` service in namespace `istio-system` transitions from `Pending` to `Active` and shows a public IP address.

## BookInfo Demo App

1. Deploy the app

   ```sh
   kubectl create ns bookinfo
   kubectl label ns bookinfo "istio-injection=enabled"
   kubectl -n bookinfo apply -f "https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/platform/kube/bookinfo.yaml"
   ```

1. Create a Gateway and VirtualService

   ```sh
   kubectl -n bookinfo apply -f "https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/networking/bookinfo-gateway.yaml"
   ```

1. Ensure the app is reachable from the internet by going to `http://<YourPublicIPAddress>/productpage`. Use the public IP address associated with the `istio-ingressgateway` service.
1. Refresh the page a few times. Notice that the stars ratings change from black to red and disappear. This is because there are 3 versions of the "reviews" service. Later we will use destination rules to fix that.

## Mutual TLS

To force mTLS cluster-wide for all services managed in the istio mesh, run

```sh
kubectl apply -n istio-system -f - <<EOF
apiVersion: "security.istio.io/v1beta1"
kind: "PeerAuthentication"
metadata:
  name: "default"
spec:
  mtls:
    mode: STRICT
EOF
```

## HTTPS (Optional, requires inlets-pro license)

This section is WIP...

Next, let's configure Istio to accept HTTPS traffic, and to redirect HTTP traffic to HTTPS.

1. Update istio's configuration to turn on SDS and HTTPS

    ```sh
    kubectl apply -f - <<EOF
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    metadata:
      namespace: istio-system
      name: example-istiocontrolplane
    spec:
      profile: demo
      values:
        gateways:
          istio-ingressgateway:
            sds:
              enabled: true
        global:
          k8sIngress:
            enabled: true
            enableHttps: true
            gatewayName: ingressgateway
    EOF
    ```

1. Install `cert-manager`

    ```sh
    arkade install cert-manager
    ```

1. TBD

## Cleanup

1. Delete the kind cluster

   ```sh
   kind delete cluster
   ```

1. Delete the DigitalOcean droplet
