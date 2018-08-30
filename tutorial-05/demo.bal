import ballerina/http;
import ballerinax/kubernetes;
import wso2/twitter;
import ballerina/config;

endpoint twitter:Client tw {
    accessToken: config:getAsString("accessToken"),
    accessTokenSecret: config:getAsString("accessTokenSecret"),
    clientId: config:getAsString("clientId"),
    clientSecret: config:getAsString("clientSecret"),
    clientConfig: {}
};

@kubernetes:Service {
    serviceType: "NodePort",
    name: "hello-service"
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
    replicas: 1
}
service<http:Service> hello bind listener{
    @http:ResourceConfig {
        path: "/",
        methods: ["POST"]
    }
    hi (endpoint caller, http:Request request) {
        http:Response res;
        string payload = check request.getPayloadAsString();

        twitter:Status st = check tw->tweet(payload);
        res.setPayload("Twitted :"+ st.text +"!\n");
        _ = caller->respond(res);
    }
}