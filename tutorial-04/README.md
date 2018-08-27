# Kubernetes support

In the last tutorial we were able to run our service inside a Docker container. In this tutorial we will see how we can run our service on a Kubernetes cluster.

Kubernetes POD is the simplest way to run our service on a Kubernetes cluster. But to support essential features like number of replicas,  liveness probe, rolling updates etc, we should create [Kubernetes Deployment] (https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) kind.  

Let's get a sample template and add our service information. You can find sample YAML file [here](./k8s/hello-service-deployment.yaml). We can used previously created docker image, hello-service:latest. 

```YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-service-deployment
  labels:
    app: hello-service
spec:
  replicas: 3
  selector:
    matchLabels:
      app: hello-service
  template:
    metadata:
      labels:
        app: hello-service
    spec:
      containers:
      - name: hello-service
        image: hello-service:latest
        imagePullPolicy: "IfNotPresent"
        ports:
        - containerPort: 9090
```

Now we can deploy our service using following command

```bash
$ kubectl apply -f hello-service-deployment.yaml 
deployment.apps "hello-service-deployment" created
```

Lets list Kubernetes Deployment and PODs by using kubectl

```bash
$ kubectl get deployment
NAME                       DESIRED   CURRENT   UP-TO-DATE     AVAILABLE  	 AGE
hello-service-deployment   3         3         		3                  3         	 3m

$ kubectl get pods
NAME                                        READY     STATUS    RESTARTS   AGE
hello-service-deployment-688c6846f9-8kgkq   1/1       Running   0          10s
hello-service-deployment-688c6846f9-lcr5x   1/1       Running   0          10s
hello-service-deployment-688c6846f9-s6sn9   1/1       Running   0          10s
```

Since we have define to have 3 replicas in hello-service-deployment YAML, Kubernetes will created 3 Kubernetes PODs. 

You can’t directly access Kubernetes PODs. We need to expose our hello-service via a [Kubernetes Service](https://kubernetes.io/docs/concepts/services-networking/service/). Kubernetes service has different types.  `ClusterIP` type services can only access within the Kubernetes cluster. Since we need to access this service from outside of the Kubernetes cluster, at least we should create `NodeType` Service. Here is a sample Service(./k8s/hello-service.yaml)


```YAML
apiVersion: "v1"
kind: "Service"
metadata:
  labels:
    app: "hello-service"
  name: "hello-service"
spec:
  ports:
  - port: 9090
    protocol: "TCP"
    targetPort: 9090
  selector:
    app: "hello-service"
  type: "NodePort"
```

Lets deploy the Service and retrive details by using `kubectl`


```bash
$ kubectl apply -f hello-service.yaml 
service "hello-service" created
```

```bash
$ kubectl get service
NAME            TYPE        CLUSTER-IP         EXTERNAL-IP   	PORT(S)          	AGE
hello-service   NodePort    10.103.207.46   <none>        9090:30008/TCP   33m
kubernetes      ClusterIP   10.96.0.1       <none>        443/TCP          33d
```

Since we use `NodePort` type Service, you can see Kubernetes open a port (30008) in Kubernetes cluster. If you are use Docker-for-Mac(Windows) Kubernetes setup, you can access the service via `http://localhost:30008`

```bash
$ curl -X POST -d " Ballerina, running on k8s cluster" http://localhost:30008/
Hello  Ballerina, running on k8s cluster!
```
Lets clean things up before we going to next section.

```bash
$ kubectl delete -f hello-service.ymal
service "hello-service" deleted
$ kubectl delete -f hello-service-deployment.yaml
deployment.apps "hello-service-deployment" deleted
```

As you experienced, to run our service inside a Kubernetes cluster is required lot of manual steps to carried out.  This was interrupted the developer’s flow. Let's look at how Ballerina helps to avoid all of these manual steps.

Lets see how Ballerina Kubernetes builder (compiler) extensions helps to deploy out code on a Kubernetes cluster.

With the manual steps we created a Kubernetes Deployment and a Service to access our hello service. First we need to import `ballerinax/kubernetes`. Then `@kubernetes:Deployment` can use to create Deployment YAML.  This annotation is allowed to define on top of our `hello` service.  I have set `replicas: 3` to create 3 pods.

```ballerina
@kubernetes:Deployment {
   name: "hello-service-deployment",
   image: "hello-service-k8s",
   replicas: 3
}
```
You might be notice that I have used `image` property because Kubernetes builder extension does not depends on any other builder extension. (e.g Docker). It can create necessary Docker image while generating Kubernetes YAMLs

Now lets annotate our service endpoint to generate relevant Kubernetes Service with `@kubernetes:Service`. I used `nodePort` type to allow access from outside of the cluster.

```ballerina
@kubernetes:Service {
   serviceType: "NodePort"
}
``` 

[Here](./demo.bal) is the full code

```ballerina
import ballerina/http;
import ballerinax/kubernetes;

@kubernetes:Service {
   serviceType: "NodePort"
}
endpoint http:Listener listener {
   port: 9090
};

@http:ServiceConfig {
   basePath: "/"
}

@kubernetes:Deployment {
   name: "hello-service-deployment",
   image: "hello-service-k8s"
}
service<http:Service> hello bind listener{
   @http:ResourceConfig {
       path: "/",
       methods: ["POST"]
   }
   hi (endpoint caller, http:Request request) {
       http:Response res;
       string payload = check request.getPayloadAsString();
       res.setPayload("Hello "+untaint payload +"!\n");
       _ = caller->respond(res);
   }
}
```

Let's build the demo.bal

```bash
$ ballerina build demo.bal 
Compiling source
    demo.bal

Generating executable
    demo.balx
	@kubernetes:Service 			- complete 1/1
	@kubernetes:Deployment 		- complete 1/1
	@kubernetes:Docker 			- complete 3/3 

	Run the following command to deploy the Kubernetes artifacts: 
	kubectl apply -f /Users/lakmal/Documents/ballerina-workshop/tutorial-04/kubernetes/
```

Let's follow the instruction printed out by the compiler.

```bash
$ kubectl apply -f /Users/lakmal/Documents/ballerina-workshop/tutorial-04/kubernetes/
deployment.extensions "hello-service-deployment" created
service "listener-svc" created
```
```bash
$ kubectl get pods
NAME                                       READY     STATUS    RESTARTS   AGE
hello-service-deployment-74fbb6784-g5tvn   1/1       Running   0          7s
hello-service-deployment-74fbb6784-hdr27   1/1       Running   0          7s
hello-service-deployment-74fbb6784-lsqn5   1/1       Running   0          7s

$ kubectl get service
NAME           TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
kubernetes     ClusterIP   10.96.0.1       	<none>        443/TCP          33d
listener-svc   NodePort    10.107.109.32   <none>        9090:30621/TCP   33s
```

If we curled

```bash
$ curl -X POST -d " Ballerina, running on k8s cluster by using k8s annotation" http://localhost:30621/
Hello  Ballerina, running on k8s cluster by using k8s annotation!
```

Yeah! Isn’t that easy?

