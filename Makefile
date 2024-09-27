# Read the .terragrunt-version in current directory
TERRAGRUNT_VERSION := $(shell cat .terragrunt-version)
# Read the .opentofu-version in current directory
OPENTOFU_VERSION := $(shell cat .opentofu-version)
# Docker image from https://github.com/devops-infra/docker-terragrunt
DOCKER_IMAGE := devopsinfra/docker-terragrunt:aws-ot-${OPENTOFU_VERSION}-tg-${TERRAGRUNT_VERSION}

POSSIBLE_AWS_ENVIRONMENTS := dev-eu qa-eu prod-eu
aws-environment-guard-%:
	@echo $(POSSIBLE_AWS_ENVIRONMENTS) | grep -wq $* || (echo "Invalid AWS environment: $*" && exit 1)

init: setup-gcloud
	@echo "Pulling terragrunt docker image"
	@docker pull $(DOCKER_IMAGE)

dev: init
# https://tofuutils.github.io/tenv/
	tenv opentofu install
	tenv terragrunt install

setup-aws-%: aws-environment-guard-%
	@echo "Checking if AWS SSO session is still valid"
	@if ! aws sts get-caller-identity --profile $* > /dev/null 2>&1; then \
		echo "AWS SSO session expired or not found, running aws sso login"; \
		aws sso login --profile $*; \
	else \
		echo "AWS SSO session is still valid"; \
	fi

setup-gcloud:
	@token=$$(gcloud auth application-default print-access-token); \
	if curl -s -H "Authorization: Bearer $$token" https://www.googleapis.com/oauth2/v1/userinfo | jq -e '.email == "dev-google@bfansports.com"' > /dev/null; then \
		echo "Already logged in as dev-google@bfansports.com"; \
	else \
		echo "Running gcloud auth application-default login"; \
		echo "Please connect with dev-google@bfansports.com"; \
		gcloud auth application-default login; \
		token=$$(gcloud auth application-default print-access-token); \
		if curl -s -H "Authorization: Bearer $$token" https://www.googleapis.com/oauth2/v1/userinfo | jq -e '.email == "dev-google@bfansports.com"' > /dev/null; then \
			echo "gcloud auth application-default login successful"; \
		else \
			echo "Failed to log in as dev-google@bfansports.com"; \
			exit 1; \
		fi; \
	fi

plan-%: setup-aws-% setup-gcloud
	@echo "Terragrunt version: $(TERRAGRUNT_VERSION)"
	@echo "Opentofu version: $(OPENTOFU_VERSION)"
	@echo "Environment: $*"
	docker run -it --rm \
		-v ~/.aws/config:/root/.aws/config -v ~/.aws/sso/cache/:/root/.aws/sso/cache/ \
		-v ~/.config/gcloud/application_default_credentials.json:/root/.config/gcloud/application_default_credentials.json \
		-v $(PWD):/app/ -w /app/$* \
		$(DOCKER_IMAGE) \
		terragrunt run-all plan

apply-%: setup-aws-% setup-gcloud
	@echo "Terragrunt version: $(TERRAGRUNT_VERSION)"
	@echo "Opentofu version: $(OPENTOFU_VERSION)"
	@echo "Environment: $*"
	docker run -it --rm \
		-v ~/.aws/config:/root/.aws/config -v ~/.aws/sso/cache/:/root/.aws/sso/cache/ \
		-v ~/.config/gcloud/application_default_credentials.json:/root/.config/gcloud/application_default_credentials.json \
		-v $(PWD):/app/ -w /app/$* \
		$(DOCKER_IMAGE) \
		terragrunt run-all apply