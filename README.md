# Cloud Native Orchestration

*Capstone project for Udacity's Cloud DevOps Nanodegree*

We will prepare an image recognition service. This service constitues a react frontend, a golang gRPC API serving and a [Tensorflow ModelServer](https://www.tensorflow.org/tfx/guide/serving). (TensorFlow Serving is a flexible, high-performance serving system for machine learning models, designed for production environments.)

---

## Application Architecture

A user submits an image url to the frontend service. The service makes a POST request and displays the result. The result is acquired when, the api sends a proto request and receives a proto response. 

A result looks like this:

![Alt Text](./screenshots/response.jpg)


## Pipeline


## Deployment Strategy

We will be using a rolling update strategy for all microservices to ensure that we always have available instances. The following snippet show's how this is done in kubernetes:
```
spec:
  replicas: 2
  strategy:
    **type: RollingUpdate**
    rollingUpdate:
      maxUnavailable: 50%
      maxSurge: 1
```

## Infrastructure Architecture



## GitOps

We will be using GitOps methodology to manage deployments into our cluster. See [here](https://eksctl.io/gitops-quickstart/setup-gitops/)