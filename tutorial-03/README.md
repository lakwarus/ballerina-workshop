# Docker Support

Now we have a microservice which can listen to a HTTP endpoint and process HTTP request. Now lets see how we can bundle our service into Docker image and run as a container.

First lets see how we can create executable binary file of our microservice.

```
$ ballerina build demo.bal
Compiling source
    demo.bal

Generating executable
    demo.balx
```
Ballerina build will create `balx` binary file which can be execute with following command

```bash
$ ballerina run demo.balx 
ballerina: initiating service(s) in 'demo.balx'
ballerina: started HTTP/WS endpoint 0.0.0.0:9090
```

Now common practice is to write a Dockerfile and create the Docker image. Lets create a folder call docker-image and copy demo.balx file into it. Inside the folder create Dockerfile with following content.

```Dockerfile
FROM ballerina/ballerina
  
COPY demo.balx /home/ballerina
EXPOSE  9090
CMD ballerina run demo.balx
```

You can find available Ballerina docker images which include the Ballerina runtime in Ballerina repository at docker hub. https://hub.docker.com/r/ballerina/ballerina/ Here I have not use a specific tag in the first line of the Dockerfile, which use latest available tag. 

We can execute following command within docker-image folder to create Docker image with our written code.

```bash
$ docker build -t my-ballerina-service . // Please notice DOT at the end
Sending build context to Docker daemon  7.168kB
Step 1/4 : from ballerina/ballerina
 ---> a65975411327
Step 2/4 : COPY demo.balx /home/ballerina
 ---> 3b4e481bef57
Step 3/4 : EXPOSE  9090
 ---> d95a1292b232
Step 4/4 : CMD ballerina run demo.balx
 ---> 2698c40bdadd
Successfully built 2698c40bdadd
Successfully tagged my-ballerina-service:latest
```

If you list your local Docker registry, you can find newly created image is at the local registry.

```bash
docker images
REPOSITORY                                     TAG                 IMAGE ID                 CREATED             SIZE
my-ballerina-service                       latest              2698c40bdadd        2 hours ago         127MB
```

Lets create a container and access our hello service;

```bash
$ docker run -it -p 9090:9090 my-ballerina-service
ballerina: initiating service(s) in 'demo.balx'
ballerina: started HTTP/WS endpoint 0.0.0.0:909
```

I used -p 9090:9090 to map container Ballerina service listen port to localhost 9090, because from Windows and Mac you can’t access container IP address directly. Now we can access our service by using following `curl` command.

```bash
$ curl -X POST -d " Ballerina, running as a container" http://localhost:9090
Hello Ballerina, running as a container!
```
You can use ctrl+c command  (in the terminal which we execute docker run)  to exit and terminate container.

As you experienced, to run our service inside a container required lot of manual steps to carried out.  This was interrupted the developer’s flow. Let's look at how Ballerina helps to avoid all of these manual steps.

Ballerina support builder (compiler) extensions and Docker will ship as one of default extension along with Kubernetes. We can use annotation in our code to generate proper Docker image while we compiling the code.

First we need to import the Docker package. Docker package shiped under ballerinax org.

```ballerina
import ballerinax/docker;
```

You can use `@docker:Config` on top of our service code. When we set a name in that, it will create proper Docker image and also generate Dockerfile. We can use `@docker:Expose` annotation on top of our listener endpoint, which allow expose our service outside traffic.

Here is the code with two annotations.

```ballerina
import ballerina/http;
import ballerinax/docker;

@docker:Expose {}
endpoint http:Listener listener {
   port: 9090
};

@http:ServiceConfig {
   basePath: "/"
}

@docker:Config {
   name: "hello-service"
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

Let's build the source.

```bash
$ballerina build demo.bal 
Compiling source
    demo.bal

Generating executable
    demo.balx
	@docker 		 - complete 3/3 

	Run the following command to start a Docker container:
	docker run -d -p 9090:9090 hello-service:latest
```

As you see, it will create balx, Dockerfile, Docker image and print the docker command to run our service as a container.

```bash
$ docker run -d -p 9090:9090 hello-service:latest
76890b960843a9d37a2c154287b98d7303dc29eb648f5c55c83cffbb198af697
```

Curl command to access

```bash
$ curl -X POST -d " Ballerina, running as a container" http://localhost:9090
Hello  Ballerina, running as a container!
```

Woohoo!, no manual steps, did you like it?

Lets clean thing up. We have to use docker kill (or stop) command to stop the container, because we used `-d` option in teh docker run command, then it's running in the background.  

```bash
$ docker kill 76890b960843a9d37a2c154287b98d7303dc29eb648f5c55c83cffbb198af697
76890b960843a9d37a2c154287b98d7303dc29eb648f5c55c83cffbb198af697
```

