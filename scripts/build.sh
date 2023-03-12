#!/bin/bash -e

echo 'This script is used to build and push multi-arch images to a container registry.'
echo ''
echo 'The script is intended to be used in a CI/CD pipeline.'
echo ''
echo 'The following variables can be set:'
echo ''
echo '| variable       | value                                             | default value                 | required                    |'
echo '|----------------|---------------------------------------------------|-------------------------------|-----------------------------|'
echo '| EXECUTOR       | podman or docker                                  | podman or docker if available | optional                    |'
echo '| REGISTRY       | docker.io, quay.io, ...                           | docker.io                     | optional                    |'
echo '| REPOSITORY     | e.g. example-project                              | not set                       | required                    |'
echo '| IMAGE_NAME     | e.g. example                                      | not set                       | required                    |'
echo '| IMAGE_TAG      | e.g. v1.0.0                                       | latest commit sha             | optional                    |'
echo '| GIT_SHA        | e.g. 1234567890abcdef                             | latest commit sha             | required, if git is missing |'
echo '| CONTEXT        | e.g. ./example                                    | .                             | optional                    |'
echo '| CONTAINERFILE  | e.g. ./example/Dockerfile                         | Dockerfile or Containerfile   | optional                    |'
echo '| DEBUG          | if set, the script will be executed in debug mode | not set                       | optional                    |'
echo ''
echo 'All arguments after the first one will be passed to the build command as build-args.'
echo 'They should be in the format: ARG=VALUE'
echo ''
echo 'example: ./build.sh ARG1=VALUE1 ARG2=VALUE2'
echo ''
echo '> starting build'

# Validate if required variables are set
if [[ -z "${EXECUTOR}" ]]; then
	echo "> EXECUTOR not set"
	if EXECUTOR=$(which docker) ; then
		echo ">> using docker as EXECUTOR"
	elif EXECUTOR=$(which podman) ; then
		echo ">> using podman as EXECUTOR"
	else
		echo ">> no executor found on the system"
		exit 1
	fi
fi

# set debug mode if DEBUG is set
if [[ -n "${DEBUG}" ]]; then
	set -x
	if [[ "${EXECUTOR}" == "podman" ]]; then
		EXTRA_FLAGS=(--log-level=debug)
	elif [[ "${EXECUTOR}" == "docker" ]]; then
		EXTRA_FLAGS=(--debug)
	fi
fi

# set git sha if not set
if [[ -z "${GIT_SHA}" ]]; then
	GIT_SHA=$(git rev-parse HEAD)
fi

# validate if required variables are set
if [[ -z "${REGISTRY}" ]]; then
	echo "> REGISTRY not set"
	echo ">> using docker.io"
	REGISTRY='docker.io'
fi
if [[ -z "${REPOSITORY}" ]]; then
	echo "> REPOSITORY not set"
	exit 1
fi
if [[ -z "${IMAGE_NAME}" ]]; then
	echo "> IMAGE_NAME not set"
	exit 1
fi
# combine variables to easier refer to the image
IMAGE="${REGISTRY}"/"${REPOSITORY}"/"${IMAGE_NAME}"

if [[ -z "${CONTEXT}" ]]; then
	echo "> CONTEXT not set"
	echo ">> using '.'"
	CONTEXT='.'
fi

if [[ -z "${CONTAINERFILE}" ]]; then
	echo "> CONTAINERFILE not set"
	if [[ -f "${CONTEXT}"/Dockerfile ]]; then
		echo ">> using '${CONTEXT}/Dockerfile'"
		CONTAINERFILE="${CONTEXT}"/Dockerfile
	elif [[ -f "${CONTEXT}"/Containerfile ]]; then
		echo ">> using '${CONTEXT}/Containerfile'"
		CONTAINERFILE='Containerfile'
	else
		echo ">> no Containerfile found in '${CONTEXT}'"
		exit 1
	fi
fi

BUILD_ARGS=()
for ARG in "${@}"; do
	# add args to list
	BUILD_ARGS+=("--build-arg=${ARG}")
done

for ARCH in amd64 arm64; do
	"${EXECUTOR}" build \
		--tag="${IMAGE}":"${GIT_SHA}"-"${ARCH}" \
		--platform="linux/${ARCH}" \
		--file "${CONTAINERFILE}" \
		"${BUILD_ARGS[@]}" \
		--pull \
		--rm \
		"${EXTRA_FLAGS[@]}" \
		"${CONTEXT}"
done
