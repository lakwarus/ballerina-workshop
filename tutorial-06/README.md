# Data integration

In this tutorial we will see how we can write a service which can connect to a database and retrive some records. 

I already pushed a mysql Docker image (lakwarus/mysql-with-quotes) with pre created database call “quotes”  and it has few quotes about Docker and Kubernetes. You can find [SQL file](./mysql/quotes.sql) and [Dockerfile](./mysql/Dockerfile) I used to create akwarus/mysql-with-quotes Docker image.
First we deploy this database into into Kubernetes cluster. You can find the [YAML file](./mysql/mysql.yaml) to deploy the database. 

```bash
$ kubectl apply -f mysql/mysql.ymal 
namespace "mysql" configured
service "mysql" created
deployment.extensions "mysql" created
```

It will create mysql deployment and a service on Kubernetes cluster. Now we can access this mysql database by using url call `mysql` and it will listen to port 3306. Also I have set mysql root password as “root”.

OK, we have all prerequisites to write our quotes service. Let's start writing it.

In this service we need to open a connection to mysql database. In Ballerina we can create this connection by using mysql client endpoint. 

```ballaerina
endpoint mysql:Client quotesDB {
    host: "localhost",
    port: 30140,
    name: "quotes",
    username: config:getAsString("username"),
    password: config:getAsString("password"),
    poolOptions: { maximumPoolSize: 5 },
    dbOptions: { useSSL: false }
};
```

As you notice, I have used config API to retrieve username and password, rather defining its inline.

Let's create the service now. I am going to name my service as `quotes` and add a resource call “quote”, which listen to POST request. In my database I have table called quotes and it has field call category and current values are “Docker”, “K8S”.  I am expecting category name from the request, extract value from POST request, and retrieve the all record belong to that given category name.  Then all the retrieval records converted to a JSON and pass it as response to the POST request.  Here is the sample code.   

```ballerina
import ballerina/http;
import ballerina/mysql;
import ballerina/io;
import ballerina/config;


endpoint mysql:Client quotesDB {
    host: "mysql",
    port: 3306,
    name: "quotes",
    username: config:getAsString("username"),
    password: config:getAsString("password"),
    poolOptions: { maximumPoolSize: 5 },
    dbOptions: { useSSL: false }
};

endpoint http:Listener listener {
    port: 8080
};

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
```

One thing to notice that, I had to untaint value coming from the POST request before passing it as SQL query. It because Ballerina does not allow to pass untrusted values 

Now let add Kubernetes annotation to run our quotes service on the Kubernetes cluster. [Here](./quote.bal) is the full code. 

 ```ballerina
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
    serviceType: "NodePort"
}
endpoint http:Listener listener {
    port: 8080
};

@kubernetes:ConfigMap {
    ballerinaConf: "./mysql.toml"
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
```

