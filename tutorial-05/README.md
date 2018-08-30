# Connectors (Client endpoints)

So far we have demoed the richness of creating web services, but there was no real integration. We’ve been in the integration space for a long time and we know that connectors are key to productivity allowing developers to work with various systems in a unified way with minimal learning curve.

Ballerina Central is the place where the Ballerina community is sharing those. WSO2 is one of the contributors. Let’s work with Twitter with the help of the WSO2/twitter package. Search for the package:

```
$ ballerina search twitter
```

Pull it so we start getting code completion (pulls also happen automatically on application build):

```
$ ballerina pull wso2/twitter
```

In the code, add:

```ballerina
import wso2/twitter;
```

Now, let’s create a twitter endpoint and initialize it. Twitter requires OAuth credentials that you can get from apps.twitter.com but placing them right into your code is a bad idea  (hint: so no one finds them on github!) so we’d rather read them from a configuration file. 

Import config so we can read from the config file:

```ballerina
import ballerina/config;
```

This code would be right below the import:

```ballerina
endpoint twitter:Client tw {
   clientId: config:getAsString("clientId"),
   clientSecret: config:getAsString("clientSecret"),
   accessToken: config:getAsString("accessToken"),
   accessTokenSecret: config:getAsString("accessTokenSecret"),
   clientConfig:{}   
};
```

Now we have the twitter endpoint in our hands, let’s go ahead and tweet!

Now, we can get our response from Twitter by just calling its tweet method. The check keyword means - I understand that this may return an error. I do not want to handle it hear - pass it further away (to the caller function, or if this is a top-level function - generate a runtime failure).

```ballerina
twitter:Status st = check tw->tweet(payload);
```

Your code will now look like this:

```ballerina

import ballerina/http;

// Pull and use wso2/twitter connector from http://central.ballerina.io
// It has the objects and APIs to make working with Twitter easy
import wso2/twitter;

// this package helps read config files
import ballerina/config;

// twitter package defines this type of endpoint
// that incorporates the twitter API.
// We need to initialize it with OAuth data from apps.twitter.com.
// Instead of providing this confidential data in the code
// we read it from a toml file
endpoint twitter:Client tw {
  clientId: config:getAsString("clientId"),
  clientSecret: config:getAsString("clientSecret"),
  accessToken: config:getAsString("accessToken"),
  accessTokenSecret: config:getAsString("accessTokenSecret"),
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
service<http:Service> hello bind listener {
  @http:ResourceConfig {
      path: "/",
      methods: ["POST"]
  }
  hi (endpoint caller, http:Request request) {
      http:Response res;
      string payload = check request.getTextPayload();

      // Use the twitter connector to do the tweet
      twitter:Status st = check tw->tweet(payload);

      // Change the response back
      res.setPayload("Tweeted: " + st.text);

      _ = caller->respond(res);
  }
}
```

Go ahead and run it and this time pass the config file:

```
$ ballerina run demo.bal --config twitter.toml
```

Demo the empty twitter timeline:

![image alt text](img/image_9.png)

Now go to the terminal window and pass a tweet:

```
$ curl -X POST -d "Ballerina" localhost:9090
Tweeted: Ballerina
```

Let’s go ahead and check out the feed:

![image alt text](img/image_10.png)

Very cool. In just a few lines of code our twitter integration started working!

Now let’s go back to code and make it even more cool by adding transformation logic. This is a very frequent task in integration apps because the format that your backend exposes and returns is often different from what the application or other services need.

We will add transformation logic both on the way to the twitter service and back from the remote service to the caller.

On the way to Twitter, if the string lacks #ballerina hashtag - let’s add it. With the full Turing-complete language and string functions this is as easy as:

```ballerina
if (!payload.contains("@ballerinalang")){payload=payload+" @ballerinalang";}
```

And obviously it makes sense to return not just a string but a meaningful JSON with the id of the tweet, etc. This is easy with Ballerina’s native json type:

```ballerina
      json myJson = {
          text: payload,
          id: st.id,
          agent: "ballerina"
      };

      res.setPayload(untaint myJson);
```

Go ahead and run it:

```
$ ballerina run demo.bal --config twitter.toml
ballerina: initiating service(s) in 'demo.bal'
ballerina: started HTTP/WS endpoint 0.0.0.0:9090
```

Now we got a much nicer JSON:

```
$ curl -d "My new tweet" -X POST localhost:9090
{"text":"My new tweet @ballerinalang","id":978399924428550145,"agent":"ballerina"}
```

![image alt text](img/image_11.png)

Now your code will look like:

```ballerina

import ballerina/http;
import wso2/twitter;
import ballerina/config;

endpoint twitter:Client tw {
  clientId: config:getAsString("clientId"),
  clientSecret: config:getAsString("clientSecret"),
  accessToken: config:getAsString("accessToken"),
  accessTokenSecret: config:getAsString("accessTokenSecret"),
  clientConfig:{}  
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
service<http:Service> hello bind {port:9090} {

  @http:ResourceConfig {
      path: "/",
      methods: ["POST"]
  }
  hi (endpoint caller, http:Request request) {
      http:Response res;
      string payload = check request.getTextPayload();

      // transformation on the way to the twitter service - add hashtag
      if (!payload.contains("@ballerinalang")){payload=payload+" @ballerinalang";}

      twitter:Status st = check tw->tweet(payload);

      // transformation on the way out - generate a JSON and pass it back
      // note that json is a first-class citizen
      // and we can construct it from variables, data, fields
      json myJson = {
          text: payload,
          id: st.id,
          agent: "ballerina"
      };

      // pass back JSON instead of text
      res.setPayload(untaint myJson);

      _ = caller->respond(res);
  }
}
```

