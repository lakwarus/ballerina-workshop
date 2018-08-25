## Annotations

Now, let’s tidy things up:

Lets create a proper HTTP listener.

```ballerina
endpoint http:Listener listener {
   port : 9090
};
```

Obviously, the service now needs to be bound to that listener and not just inline anonymous declaration:

```ballerina
service<http:Service> hello bind listener {
```

We want the service to just be there at the root path / - so let’s add ServiceConfig to overwrite the default base path (which is the service name). Add the following annotation right before the service:

```ballerina
@http:ServiceConfig {
   basePath: "/"
}
```

Make the resource available at the root as well and change methods to POST - we will pass some parameters!  

```ballerina
   @http:ResourceConfig {
       methods: ["POST"],
       path: "/"
   }
```

In the hello function, get the payload as string (filter out possible errors):

```ballerina
       string payload = check req.getTextPayload();
```

Then add the name into the output string:

```ballerina
      response.setPayload("Hello " + untaint payload + "!\n");
```

Your final code should be (see comments for the new lines that you add at this stage):

```ballerina
// Add annotations for @ServiceConfig & @ResourceConfig
// to provide custom path and limit to POST
// Get payload from the POST request
// To run it:
// ballerina run demo.bal
// To invoke:
// curl -X POST -d "Demo" localhost:9090

import ballerina/http;

endpoint http:Listener listener {
   port : 9090
};

// Add this annotation to the service to change the base path
@http:ServiceConfig {
  basePath: "/"
}

service<http:Service> hello bind listener {

  // Add this annotation to the resource to change its path
  // and to limit the calls to POST only
  @http:ResourceConfig {
      path: "/",
      methods: ["POST"]
  }

  hi (endpoint caller, http:Request request) {

      // extract the payload from the request
      // getTextPayload actually returns a union of string | error
      // we will show how to handle the error later in the demo
      // for now, just use check that "removes" the error
      // (in reality, if there is error it will pass it up the caller stack)
      string payload = check request.getTextPayload();
      
      http:Response res;

      // use it in the response
      res.setPayload("Hello "+untaint payload+"!\n");

      _ = caller->respond(res);
  }
}
```

Run it again and invoke this time as POST:

```
$ curl -X POST -d "Ballerina" localhost:9090
Hello Ballerina!
```

Summarize:

* Annotations are native and built-in - this is not some artificial add-on things but integral part of the language that lets you meaningfully tweak behavior and provide parameters,
* Full language helps you intuitively handle any required transformation (like handling the empty string in our case),
* Code completion and strong types help you easily locate the methods you need (such as getTextPayload) and use them,
* The whole power of HTTP, REST, WebSockets, gRPC, etc. is at your power.
* The edit / run / test iterations work great and keep us productive.
