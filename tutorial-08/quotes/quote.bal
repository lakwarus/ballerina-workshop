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
    name: "quotes"
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
        source: "../resources/lib/mysql-connector-java-8.0.11.jar" }]
}
service<http:Service> quotes bind listener {
    @http:ResourceConfig {
        methods: ["POST"]
    }
    quote (endpoint caller, http:Request request) {

        io:println("Request recived...");
        string category = check request.getPayloadAsString();
        int id;
        if (category=="Docker") {
            id = math:randomInRange(100, 105);        
        }
        if (category=="K8S") {
            id = math:randomInRange(106, 115);        
        }        
        var selectRet = quotesDB->select("SELECT * FROM quotes WHERE ID = " + id , ());
        table dt;
        match selectRet {
            table tableReturned => dt = tableReturned;
            error e => io:println("Select quote from quotes table failed: "
                               + e.message);
        }
        var jsonConversionRet = <json>dt;
        match jsonConversionRet {
            json jsonRes => {
                // to simulate network failures
                // send results only for even id numbers
                if (id%2==0) {
                    http:Response res;
                    json selectedQuote = untaint (jsonRes);
                    res.setJsonPayload(selectedQuote,contentType = "application/json");
                    _ = caller->respond(res);
                    io:println("Request sent...");
                }else{
                    io:println("Result drop to simulate network failures");
                }
            }
            error e => io:println("Error in table to json conversion");
        }            
    }
}
