# istio-practice

Repo to collect the things I do to practice with Istio

## Prerequisites

- [docker](https://www.docker.com/get-started)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [kind](https://github.com/kubernetes-sigs/kind)
- [istioctl](https://istio.io/docs/ops/diagnostic-tools/istioctl/)
- [helm 3+](https://helm.sh/docs/intro/quickstart/)
- [arkade](https://github.com/alexellis/arkade)

## Create a Kubernetes cluster using kind

```sh
kind create cluster --config kind-config.yaml
```

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
1. Install Inlets using `arkade`

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

## Mutual TLS

WIP
