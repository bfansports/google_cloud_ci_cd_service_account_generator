TERRAGRUNT_VERSION := $(shell cat .terragrunt-version)
OPENTOFU_VERSION := $(shell cat .opentofu-version)

DOCKER_IMAGE := devopsinfra/docker-terragrunt:aws-ot-${OPENTOFU_VERSION}-tg-${TERRAGRUNT_VERSION}
DOCKER_RUN = docker run -it --rm \
    -e AWS_PROFILE=$(AWS_PROFILE) \
    -v ~/.aws/config:/root/.aws/config \
    -v ~/.aws/sso/cache/:/root/.aws/sso/cache/ \
    -v ~/.config/gcloud/application_default_credentials.json:/root/.config/gcloud/application_default_credentials.json \
    -v $(PWD):/app/ \
    -w /app/$*

POSSIBLE_AWS_ENVIRONMENTS := dev-eu qa-eu prod-eu

help:
	@echo "Available commands:"
	@echo "  make init             - Pull Docker image and install tools"
	@echo "  make plan-<env>       - Run Terragrunt plan for an environment"
	@echo "  make apply-<env>      - Run Terragrunt apply for an environment"

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
	@echo "Setting up AWS for environment: $*"
	@if ! aws sts get-caller-identity --profile $* > /dev/null 2>&1; then \
		echo "Error: AWS SSO session expired or not found for $*"; \
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
	$(DOCKER_RUN) $(DOCKER_IMAGE) terragrunt run-all plan


apply-%: setup-aws-% setup-gcloud
	@echo "Terragrunt version: $(TERRAGRUNT_VERSION)"
	@echo "Opentofu version: $(OPENTOFU_VERSION)"
	@echo "Environment: $*"
	$(DOCKER_RUN) $(DOCKER_IMAGE) terragrunt run-all apply --terragrunt-log-level debug --terragrunt-debug

.PHONY: init setup-gcloud setup-aws-% plan-% apply-% help