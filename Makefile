include version.env

BASE = cloudresty
NAME = $$(awk -F'/' '{print $$(NF-0)}' <<< $$PWD)
DOCKER_REPO = ${BASE}/${NAME}
DOCKER_TAG = ${DOCKYDEB_VERSION}

.PHONY: build shell clean

help: ## Show list of make targets and their description.
	@grep -E '^[%a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## Build docker image.
	@docker buildx build \
		--platform linux/amd64 \
		--pull \
		--force-rm -t ${DOCKER_REPO}:${DOCKER_TAG} \
		--file Dockerfile .

shell: ## Run docker image locally and open a shell.
	@docker run \
		--platform linux/amd64 \
		--rm \
		--name ${NAME} \
		--hostname ${NAME} \
		-it ${DOCKER_REPO}:${DOCKER_TAG} zsh

clean: ## Remove all local docker images for this repo.
	@if [[ $$(docker images --format '{{.Repository}}:{{.Tag}}' | grep ${DOCKER_REPO}) ]]; then docker rmi $$(docker images --format '{{.Repository}}:{{.Tag}}' | grep ${DOCKER_REPO}); else echo "INFO: No images found for '${DOCKER_REPO}'"; fi