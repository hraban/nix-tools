#!/usr/bin/env bash
set -euo pipefail
${DEBUGSH+set -x}

# Love this hack.
# https://discourse.nixos.org/t/build-x86-64-linux-on-aarch64-darwin/35937/2?u=hraban

if ! docker version &> /dev/null; then
	>&2 echo "Is Docker installed and running? 'docker version' failed"
	exit 1
fi

: "${ARCH=linux/arm64}"
: "${DIR=$(git rev-parse --show-toplevel)}"
: "${NIX_IN_DOCKER_NAME=nix-docker}"

init-container() {
	docker create ${ARCH:+--platform $ARCH} --privileged --name "$NIX_IN_DOCKER_NAME" -it -w /work -v "$DIR:/work" -v /var/run/docker.sock:/var/run/docker.sock nixos/nix && \
	docker start "$NIX_IN_DOCKER_NAME" > /dev/null && \
	docker exec "$NIX_IN_DOCKER_NAME" bash -c "git config --global --add safe.directory /work" && \
	docker exec "$NIX_IN_DOCKER_NAME" bash -c "echo 'sandbox = true' >> /etc/nix/nix.conf" && \
	docker exec "$NIX_IN_DOCKER_NAME" bash -c "echo 'filter-syscalls = false' >> /etc/nix/nix.conf" && \
	docker exec "$NIX_IN_DOCKER_NAME" bash -c "echo 'max-jobs = auto' >> /etc/nix/nix.conf" && \
	docker exec "$NIX_IN_DOCKER_NAME" bash -c "echo 'experimental-features = nix-command flakes' >> /etc/nix/nix.conf" && \
	docker exec "$NIX_IN_DOCKER_NAME" bash -c "nix-env -iA nixpkgs.docker nixpkgs.nixos-rebuild"
}

if ! docker container inspect "$NIX_IN_DOCKER_NAME" > /dev/null 2>&1; then
	>&2 echo "Initializing build container $NIX_IN_DOCKER_NAME"
	if ! init-container; then
		>&2 echo "Failed to create build container"
		docker rm -f "$NIX_IN_DOCKER_NAME" || true
		exit 1
	fi
fi

docker start "$NIX_IN_DOCKER_NAME" > /dev/null
exec docker exec -i "$NIX_IN_DOCKER_NAME" "$@"
