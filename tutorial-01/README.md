# Hello World 

In the terminal pane of VS Code (or in the terminal window), inside the Demo folder, open the empty demo.bal that you created:

$ code demo.bal

This is the code that you need to type (or grab from 1_demo_hello.bal) and explanations for each line:

```ballerina
// The simplest hello world REST API
// To run it:
// ballerina run demo.bal
// To invoke:
// curl localhost:9090/hello/hi
// Ballerina has packages that can be imported
// This one adds services, endpoints, objects, and
// annotations for HTTP

import ballerina/http;

// Services, endpoint, resources are built into the language
// This one is HTTP (other options include WebSockets, Protobuf, gRPC, etc)
// We bind it to port 9090
service<http:Service> hello bind {port:9090} {

  // The service exposes one resource (hi)
  // It gets the endpoint that called it - so we can pass response back
  // and the request struct to extract payload, etc.
  hi (endpoint caller, http:Request request) {

      // Create the Response object
      http:Response res;
      // Put the data into it
      res.setPayload("Hello World!\n");
      // Send it back. -> means remote call (. means local)
      // _ means ignore the value that the call returns
      _ = caller->respond(res);
  }
}
```

In VS Code’s Terminal pane run:

```
$ ballerina run demo.bal
ballerina: initiating service(s) in 'demo.bal'
ballerina: started HTTP/WS endpoint 0.0.0.0:9090
```

Now you can invoke the service in the Terminal window:

```
$ curl localhost:9090/hello/hi
Hello World!
```

Side-by-side split view of the terminal pane makes it easier to do the demo:

![image alt text](../img/image_8.png)

You now have a Hello World REST service running and listening on port 9090.

Go back to VS Code terminal pane and kill the service by pressing Ctrl-C.
