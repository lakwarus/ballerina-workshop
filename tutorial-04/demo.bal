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
    image: "hello-service-k8s",
    replicas: 3
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