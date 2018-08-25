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