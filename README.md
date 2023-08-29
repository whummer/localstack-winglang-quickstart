[![Build status](https://github.com/whummer/localstack-winglang-quickstart/actions/workflows/test.yml/badge.svg)](https://github.com/whummer/localstack-winglang-quickstart/actions)

# LocalStack Winglang Quickstart

Sample repo for running [Winglang](https://www.winglang.io/) applications on [LocalStack](https://localstack.cloud).

We will take the [Voting App](https://github.com/winglang/voting-app) example provided by Winglang, deploy it against LocalStack, and run an end-to-end invocation - all running entirely on the local machine!

## Prerequisites

* LocalStack
* Node.js v18+, npm
* Python, pip
* Terraform
* [`awslocal`](https://github.com/localstack/awscli-local) CLI
* `make`

## Installing

To initialize the project and install the dependencies:
```
$ make install
```

We also need to apply a small patch in the AWS SDK, to inject the local endpoints (making requests against the LocalStack Gateway under `http://localhost:4566`). Note that we'll look into making this step obsolete in the future, and provide a more seamless integration!
```
$ make patch
```

## Deploying

First, make sure that you have LocalStack running in your local Docker, e.g., using the `localstack` command line interface:
```
$ localstack start
```

To compile the sample app and deploy it to LocalStack:
```
$ make deploy
```

Once the app is deployed, we can then determine the ID of the API Gateway:
```
$ awslocal apigateway get-rest-apis | jq -r '.items[0].id'
5t2vuzar6c
```

Assert that the API Gateway endpoint can be properly invoked:
```
$ curl -X POST http://5t2vuzar6c.execute-api.localhost.localstack.cloud:4566/prod/requestChoices
["Nori","Ravioli"]
```

Next, we create a file `voting-app/website/public/config.json` with the following content (make sure to copy the right API Gateway ID from the output above):
```
{
    "apiUrl": "http://5t2vuzar6c.execute-api.localhost.localstack.cloud:4566/prod"
}
```

Finally, we can build and start up the demo web app, which will become available in the browser under http://localhost:3000
```
$ cd voting-app/website
$ npm install
$ npm run start
```

## Old: Running the "Hello World" Wing app

To compile the app and deploy it to LocalStack:
```
$ make deploy-hello-world
```

Once the app is deployed, we can then determine the URL of the deployed SQS queue, and send a message to it (or simply run `make test`):
```
$ queueUrl=$(awslocal sqs list-queues --query 'QueueUrls[0]' --output text)
$ awslocal sqs send-message --queue-url $queueUrl --message-body 'LocalStack'
```

This will then trigger the execution of the "Hello World" Lambda function - you'll observe some logs are printed in the LocalStack container, similar to this:
```
> START RequestId: 781cd9e6-0798-198a-3b7e-c0c6aee1d017 Version: $LATEST
> END RequestId: 781cd9e6-0798-198a-3b7e-c0c6aee1d017
> REPORT RequestId: 781cd9e6-0798-198a-3b7e-c0c6aee1d017	Init Duration: 726.37 ms	Duration: 894.80 ms	Billed Duration: 895 ms	Memory Size: 1536 MB	Max Memory Used: 165 MB
```

Finally, we can check out the local S3 buckets, and verify that the `hello.txt` file was created properly:
```
$ awslocal s3 ls
2023-01-21 14:26:34 terraform-20230121132624239200000005
2023-01-21 14:26:34 terraform-20230121132624239100000004
$ awslocal s3 cp s3://terraform-20230121132624239200000005/hello.txt /tmp/hello.txt
$ cat /tmp/hello.txt
Hello, LocalStack!
```

## License

This code is available under the Apache License, Version 2.0.
