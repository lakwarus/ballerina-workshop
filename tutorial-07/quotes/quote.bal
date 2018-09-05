import ballerina/http;
import ballerina/mysql;
import ballerina/io;
import ballerina/math;
import ballerina/config;
import ballerinax/kubernetes;

endpoint mysql:Client quotesDB {
    host: "mysql",
    port: 3306,
    name: "quotes",
    username: config:getAsString("username"),
    password: config:getAsString("password"),
    poolOptions: { maximumPoolSize: 5 },
    dbOptions: { useSSL: false }
};

@kubernetes:Service{
    name: "quotes",
    serviceType: "ClusterIP"
}
endpoint http:Listener listener {
    port: 8080
};

@kubernetes:ConfigMap {
    ballerinaConf: "./quotes/mysql.toml"
}
@kubernetes:Deployment {
    name: "quotes",
    image: "lakwarus/quotes",
    copyFiles: [{ target: "/ballerina/runtime/bre/lib",
        source: "./quotes/resources/lib/mysql-connector-java-8.0.11.jar" }]
}
service<http:Service> quotes bind listener {
    @http:ResourceConfig {
        methods: ["POST"]
    }
    quote (endpoint caller, http:Request request) {
        string category = check request.getPayloadAsString();
       
        var selectRet = quotesDB->select("SELECT * FROM quotes WHERE category = '" + untaint category + "'" , ());
        table dt;
        match selectRet {
            table tableReturned => dt = tableReturned;
            error e => io:println("Select quote from quotes table failed: "
                               + e.message);
        }
        var jsonConversionRet = <json>dt;
        match jsonConversionRet {
            json jsonRes => {
                http:Response res;
                json selectedQuote = untaint (jsonRes);
                res.setJsonPayload(selectedQuote, contentType = "application/json");
                _ = caller->respond(res);
            }
            error e => io:println("Error in table to json conversion");
        }            
    }
}