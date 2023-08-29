export AWS_DEFAULT_REGION ?= us-east-1

usage:
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/:.*##\s*/##/g' | awk -F'##' '{ printf "%-20s %s\n", $$1, $$2 }'

install: ## Install dependencies
	test -e node_modules/winglang || npm install
	which tflocal || pip install terraform-local

patch: install ## Patch AWS SDK to inject local endpoints
	echo "Add patch to AWS SDK to inject local endpoints"
	perl -pi -e 's|config = config;$$|config = config; if (process.env.LOCALSTACK_HOSTNAME) config.endpoint = `http://\$${process.env.LOCALSTACK_HOSTNAME}:4566`;|g' node_modules/@winglang/sdk/node_modules/@aws-sdk/smithy-client/dist-cjs/client.js

deploy: patch ## Build and deploy "Voting" sample app
	test -e voting-app/.git || git clone https://github.com/winglang/voting-app
	(cd voting-app/website; npm install; npm run build)
	npm run compile -- voting-app/main.w
	(cd voting-app/target/main.tfaws; tflocal init; tflocal apply -auto-approve)

deploy-hello-world: patch ## Build and deploy "Hello World" app
	test -e wing/.git || git clone https://github.com/winglang/wing
	npm run compile -- wing/examples/tests/valid/hello.w
	cd ./target/cdktf.out/stacks/root; tflocal init; tflocal apply -auto-approve

test: deploy  ## Build and deploy app, run test request
	queueUrl=$$(awslocal sqs list-queues --query 'QueueUrls[0]' --output text); \
		echo "Sending message to queue SQS URL $$queueUrl"; \
		awslocal sqs send-message --queue-url $$queueUrl --message-body 'LocalStack'; \
		echo "Sent message to SQS - hello.txt file should appear in result bucket shortly"

.PHONY: install patch deploy test
