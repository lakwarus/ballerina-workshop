
In the early 2000s, I was fascinated with Linux. I tried to install Linux everywhere: laptops, notebooks, MAC minis, PS2, LiveCD, PDAs, and POS terminals! But by the late 2000s, Linux became boring — it was now the default operating system to run servers. People moved on to virtual machines, where the OS didn’t matter.

Then, in the early 2010s, I started looking into running our workload on containers. I spent a lot of time experimenting with LXC and OpenStack and exploring new Linux kernel features like cgroups and namespace. In the mid-2010s, Docker announced its first public release. Its layered file system, built-in registry, and simplified CLI exploded the industry. Everyone started talking about Docker. No one wanted to understand how it works, but instead, they just started working with it. 

With the emergence of microservices running the workload on a single container also became boring. Applications now needed to be deployed to multiple containers. Container orchestration, load balancing, auto-healing, monitoring, and management became interesting areas of research. Docker Swarm, DC/OS, and Kubernetes are a few projects in this space. I was lucky enough to be exposed to Kubernetes in its early stages and started to love it. I was fascinated by its flexible architecture and how it managed networking and routing and soon became a strong advocate. Now that we are in 2020 I think Kubernetes has won the battle and in my point of view is the next-gen Linux to run distributed workloads.

## But through all the eras, developers have been neglected

Deployment options like Linux, virtual machines, containers, and Kubernetes are not a part of the developer’s programming experience. Developers love their coding and should ideally focus on solving business problems. We have tried to fill the gap between development and deployment by introducing DevOps, but, in practice, these two worlds live separately.

So how can we make Kubernetes boring and enhance the developer experience? After some out-of-the-box thinking into how we can distinctively connect these two worlds, Ballerina Kubernetes annotations were born. [Ballerina](https://ballerina.io/?utm_source=devto&utm_medium=article&utm_campaign=kubernetes_ballerina_devto_article_feb20) is an open source programming language for cloud-era application developers. It is intended to be the core of a language-centric middleware platform. It has all the general-purpose functionality expected of a modern programming language, but it also has several unusual aspects that make it particularly suitable for its intended purpose.

Note: I will only talk about how to run Ballerina applications on Kubernetes. If you are interested in the other capabilities of Ballerina please visit [http://ballerina.io](https://ballerina.io/?utm_source=devto&utm_medium=article&utm_campaign=kubernetes_ballerina_devto_article_feb20)

## Ballerina Kubernetes Annotation

Developers would prefer to stay within their IDE instead of writing Docker files, generating Docker images, and writing Kubernetes YAML files. But running their application on Kubernetes and testing production behavior is important. Unfortunately, running an application in a Kubernetes cluster currently requires a steep learning curve for developers. 

The Ballerina Kubernetes annotation model was created to address this issue. A simple hello world sample can be used to understand the concepts, but these annotations can be used in complex examples as well. Let’s take the service below, which is written in Ballerina as an example:

```ballerina
import ballerina/http;
import ballerina/log;
 
service hello on new http:Listener(8080) {
   resource function hi(http:Caller caller, http:Request request) {
       var result = caller->respond("Hello World!\n");
       if result is error {
           log:printError("Error occurred while sending response");
       }
   }
}
```

The sample program has a `hello` HTTP service and within the service, there is a `hi` resource function. The hello service is listening to port 8080 and when we invoke the hi resource it returns the “Hello World” HTTP response. When the source code is compiled it will generate a JAR. This will enable users to run the program with the java -jar command.

```bash
$> ballerina build hello.bal 
Compiling source
	hello.bal
Generating executables
	hello.jar
$> java -jar hello.jar 
[ballerina/http] started HTTP/WS listener 0.0.0.0:8080
$> curl http://localhost:8080/hello/hi
Hello World!
```
To annotate the above source code with Ballerina Kubernetes annotations, the ballerina/kubernetes module needs to be imported. Then the following annotations need to be added.

```ballerina
import ballerina/http;
import ballerina/log;
import ballerina/kubernetes;
 
@kubernetes:Service {
   name: "hello-world",
   serviceType: "NodePort"
}
@kubernetes:Deployment {
   name: "hello-world"
}
service hello on new http:Listener(8080) {
   resource function hi(http:Caller caller, http:Request request) {
       var result = caller->respond("Hello World!\n");
       if result is error {
           log:printError("Error occurred while sending response");
       }
   }
}
```

The two annotations added above with a few properties are `@kubernetes:Deployment` and `@kubernetes:Service`. As shown below, once the code is compiled the Ballerina compiler will generate the Dockerfile, Docker image, and all necessary artifacts required to deploy the application.

```bash
$> ballerina build hello.bal 
Compiling source
	hello.bal

Generating executables
	hello.jar

Generating artifacts...

	@kubernetes:Service			- complete 1/1
	@kubernetes:Deployment		- complete 1/1
	@kubernetes:Docker			- complete 2/2 
	@kubernetes:Helm			- complete 1/1

	Run the following command to deploy the Kubernetes artifacts: 
	kubectl apply -f /Users/lakmal/hello/kubernetes

	Run the following command to install the application using Helm: 
	helm install --name hello-world /Users/lakmal/hello/kubernetes/hello-world

$> docker images |grep hello
hello    latest        278a34c943fd        10 minutes ago      109MB
```
The `kubectl` command can be used to deploy your application into a Kubernetes cluster. 
```bash
$> kubectl apply -f /Users/lakmal/Documents/work/demo/DevWeekTX/kubernetes
service/hello-world created
deployment.apps/hello-world created

$> kubectl get all
NAME                               READY   STATUS    RESTARTS   AGE
pod/hello-world-6ff4b986f7-68b47   1/1     Running   0          15s

NAME                  TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
service/hello-world   NodePort    10.103.148.96   <none>        8080:31686/TCP   15s
service/kubernetes    ClusterIP   10.96.0.1       <none>        443/TCP          21d

NAME                          READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/hello-world   1/1     1            1           15s

NAME                                     DESIRED   CURRENT   READY   AGE
replicaset.apps/hello-world-6ff4b986f7   1         1         1       15s
```

Since the `serviceType` has been set to NodePort in the @kubernetes:Service annotation, it creates a NordPort type Kubernetes service. The application can be accessed via NodePort as shown below.
```bash
$> curl http://localhost:31686/hello/hi
Hello World!
```
As you can see, using Ballerina annotations doesn’t interrupt the developer’s flow. The developer has to just code the annotations and the compiler takes care of the rest. Ballerina Kubernetes annotation reads the source code, populates the correct values and generates validated Kubernetes artifacts all while following best practices. The default values can be overridden by setting them as annotation properties. The IDE can even suggest what to put and where to put it in your source code. For example, see the following IDE suggestions under the @kubernetes:Deployment annotation:


Ballerina annotations can generate artifacts for all major Kubernetes `kinds` such as
- @kubernetes:Deployment{}
- @kubernetes:Service{}
- @kubernetes:Ingress{}
- @kubernetes:HPA{}
- @kubernetes:Secret{}
- @kubernetes:ConfigMap{}
- @kubernetes:PersistentVolumeClaim{}
- @kubernetes:ResourceQuota{}
- @kubernetes:Job{}

It also support Istio and OpenShift artifact generation as well:
- @istio:Gateway{}
- @istio:VirtualService{}
- @openshift:Route{}

More information on this can be found at https://github.com/ballerinax/kubernetes. To quickly learn about the language features in Ballerina, check out these [Ballerina by Examples](https://ballerina.io/learn/by-example/?utm_source=devto&utm_medium=article&utm_campaign=kubernetes_ballerina_devto_article_feb20).
