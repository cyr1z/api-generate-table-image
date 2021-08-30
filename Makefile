# import config.
# You can change the default config with `make cnf="config_special.env" build`
cnf ?= .env
include $(cnf)
export $(shell sed 's/=.*//' $(cnf))

# import deploy config
# You can change the default deploy config with
#`make cnf="deploy_special.env" release`
#dpl ?= deploy.env
#include $(dpl)
#export $(shell sed 's/=.*//' $(dpl))

# get host name and ip
#INSTANCE_NAME := $(shell hostname)
#INSTANCE_IP := $(shell hostname -I | cut -f 1 -d " ")
# 	docker run -i -t --rm --env INSTANCE_NAME=$(INSTANCE_NAME) --env INSTANCE_IP=$(INSTANCE_IP) --env-file=./.env -p=$(PORT):$(PORT) --name="$(APP_NAME)" $(APP_NAME)

# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

# default: build

# DOCKER TASKS
# Build the container
build: ## Build the container
	docker build -t $(APP_NAME):$(VERSION) -t $(APP_NAME):latest .

logs: ## view logs
	docker logs $(APP_NAME)
pip-freeze: #freezing dependencies
	pip freeze > requirements.txt

build-nc: pip-freeze ## Build the container without caching
	docker build --no-cache -t $(APP_NAME):$(VERSION) -t $(APP_NAME):latest .

run: ## Run container on port configured in `.env`
	docker run -i -t --rm  --env-file=./.env --name="$(APP_NAME)" $(APP_NAME)

dc-run: ## Run container on port configured in `.env` docker-compose
	docker-compose --env-file .env up

up: ##  Run container on port configured in `.env` with -d (background mode)
	docker run -d -t --rm  --env-file=./.env  --name="$(APP_NAME)" $(APP_NAME)

dc-up: ##  Run container on port configured in `.env` with -d (background mode)
	docker-compose --env-file .env up -d --build

dev-run: ## build and run container on port configured in `.env` (interactive mode)
	docker-compose --env-file .env up --build

stop: ## Stop a running container
	docker stop $(APP_NAME) || true

rm: ## Stop and remove a running container
	docker rm $(APP_NAME) || true

dc-stop: ## Stop and remove a running container
	docker-compose --env-file .env stop

clean: ## Cleaning up old container images and cache files
	rm -rf `find . -name __pycache__`
	rm -f `find . -type f -name '*.py[co]' `
	docker-compose down -v
	docker rmi $(docker images -f "dangling=true" -q)

flake: ## Run flake8 linters
	flake8 -v src/app

pylint: ## Run Pylint linter
	pylint src/app

test: ## Run tests
	docker exec $(APP_NAME) python -i -m pytest -q /tests/unit/ -p no:warnings

test-last-failed: ## Run last failed tests only
	docker exec $(APP_NAME) python -m pytest -q /tests/unit/ --lf

test-dev: ## Run tests with covarege
	python -m pytest -v --cov=src --cov-report term-missing ./tests/unit/ --cov ./src/app

kill: ## Kill a running container
	docker kill $(APP_NAME)

release: build-nc publish ## Make a release by building and publishing the `{version}` and `latest` tagged containers to registry.

# Docker publish
publish: repo-login publish-latest publish-version ## Publish the `{version}` and `latest` tagged containers to registry.

publish-latest: tag-latest ## Publish the `latest` taged container to ECR
	@echo 'publish latest to $(DOCKER_REPO)'
	docker push $(DOCKER_REPO)/$(APP_NAME):latest

publish-version: tag-version ## Publish the `{version}` tagged container to ECR
	@echo 'publish $(VERSION) to $(DOCKER_REPO)'
	docker push $(DOCKER_REPO)/$(APP_NAME):$(VERSION)

## Docker tagging
tag: tag-latest tag-version ## Generate container tags for the `{version}` ans `latest` tags

tag-latest: ## Generate container `{version}` tag
	@echo 'create tag latest'
	docker tag $(APP_NAME) $(DOCKER_REPO)/$(APP_NAME):latest

tag-version: ## Generate container `latest` tag
	@echo 'create tag $(VERSION)'
	docker tag $(APP_NAME) $(DOCKER_REPO)/$(APP_NAME):$(VERSION)
#
#aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 779282180335.dkr.ecr.us-east-1.amazonaws.com
#docker build -t i4r-aiohttp-api .
#docker tag i4r-aiohttp-api:latest 779282180335.dkr.ecr.us-east-1.amazonaws.com/i4r-aiohttp-api:latest
#docker push 779282180335.dkr.ecr.us-east-1.amazonaws.com/i4r-aiohttp-api:latest
#
#docker tag  i4r-aiohttp-api:latest 779282180335.dkr.ecr.us-east-1.amazonaws.com/i4r-aiohttp-api:latest
#docker push 779282180335.dkr.ecr.us-east-1.amazonaws.com/i4r-aiohttp-api:latest

shell: ## run bash in container
	docker exec -i -t $(APP_NAME) bash
	#docker-compose exec $(APP_NAME) bash

bash: shell ## run bash in container

sh: ## run sh in container
	docker exec -i -t $(APP_NAME) sh

analyse-types:
	 docker run $(DOCKER_RUN_PARAMS) $(IMAGE_NAME) bash -c '\
	 cd /app/src && \
	 \
	 MYPYPATH="$$PYTHONPATH" mypy --ignore-missing-imports --no-strict-optional --follow-imports=skip \
	  config.py server.py endpoints logs \
 '

analyse-codestyle:
	 docker run $(DOCKER_RUN_PARAMS) $(IMAGE_NAME) bash -c '\
	 cd /app/src && \
	 pylint -j 4 --max-line-length=130 --disable=\
	 missing-function-docstring,missing-class-docstring,missing-module-docstring,\
	 too-few-public-methods,invalid-name,import-outside-toplevel,no-member,no-self-use,logging-format-interpolation,\
	 broad-except,too-many-instance-attributes ./*; \
	 '

## HELPERS
## generate script to login to aws docker repo
#CMD_REPOLOGIN := "eval $$\( aws ecr"
#ifdef AWS_CLI_PROFILE
#CMD_REPOLOGIN += " --profile $(AWS_CLI_PROFILE)"
#endif
#ifdef AWS_CLI_REGION
#CMD_REPOLOGIN += " --region $(AWS_CLI_REGION)"
#endif
#CMD_REPOLOGIN += " get-login --no-include-email \)"


# login to AWS-ECR
repo-login: ## Auto login to AWS-ECR using aws-cli
	 docker login --username i4radmin --password 3YvxgHHeUQ4Lqs9M docker-hub.tasks.life

pull: repo-login ## pull latest docker image
	docker pull $(DOCKER_REPO)/$(APP_NAME)

version: ## Output the current version
	@echo $(VERSION)

send-link:
	./infra/tg.sh 'https://$(DOCKER_REPO)/v2/$(APP_NAME)/manifests/$(VERSION)/'
	./infra/tg.sh 'docker pull $(DOCKER_REPO)/$(APP_NAME)'
