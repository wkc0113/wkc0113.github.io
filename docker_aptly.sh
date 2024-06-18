#!/bin/bash
#
# Provide the Docker environment for ASUS IoT.

export ASUS_DOCKER_ENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
declare -r ASUS_DOCKER_ENV_DEFAULT_WORKDIR="/home/$(id -u -n)/apt-repo"
export ASUS_DOCKER_ENV_BRANCH="aptly"
export ASUS_DOCKER_ENV_SOURCE=${ASUS_DOCKER_ENV_DIR}
export ASUS_DOCKER_ENV_DOCKERFILE="./Dockerfile"
export ASUS_DOCKER_ENV_IMAGE="asus-iot/asus_aptly:latest"
export ASUS_DOCKER_ENV_WORKDIR=${ASUS_DOCKER_ENV_DEFAULT_WORKDIR}

export ASUS_DOCKER_EVN_OPTIONS="--privileged --rm -i --tty --hostname asus-docker-env --volume ${ASUS_DOCKER_ENV_SOURCE}:${ASUS_DOCKER_ENV_WORKDIR} --workdir ${ASUS_DOCKER_ENV_WORKDIR} --volume gpg_key:/home/$(id -u -n)/.gnupg --volume tinker_borad:/home/$(id -u -n)/.aptly"

function asus_docker_env_show_variables() {
  echo "====================================================================="
  echo "ASUS_DOCKER_ENV_DIR:        ${ASUS_DOCKER_ENV_DIR}"
  echo "ASUS_DOCKER_ENV_SOURCE:     ${ASUS_DOCKER_ENV_SOURCE}"
  echo "ASUS_DOCKER_ENV_DOCKERFILE: ${ASUS_DOCKER_ENV_DOCKERFILE}"
  echo "ASUS_DOCKER_ENV_IMAGE:      ${ASUS_DOCKER_ENV_IMAGE}"
  echo "ASUS_DOCKER_ENV_WORKDIR:    ${ASUS_DOCKER_ENV_WORKDIR}"
  echo "ASUS_DOCKER_ENV_OPTIONS:    ${ASUS_DOCKER_EVN_OPTIONS}"
  echo "====================================================================="
}

function asus_docker_env_check_docker() {
  if [[ -x "$(command -v docker)" ]]; then
    echo "Docker is installed and the permission to execute Docker is granted."
    if getent group docker | grep &>/dev/null "\b$(id -un)\b"; then
      echo "The user $(id -un) is in the group docker."
      return 0
    else
      echo "Docker is not managed as a non-root user."
      echo "Please refer to the following URL to manage Docker as a non-root user."
      echo "https://docs.docker.com/install/linux/linux-postinstall/"
    fi
  else
    echo "Docker is not installed or the permission to execute is not granted."
    echo "Please install Docker first and make sure you are able to run it."
  fi
  return 1
}

function asus_docker_env_check_required_packages {
  if dpkg-query -s qemu-user-static 1>/dev/null 2>&1; then
    echo "The package qemu-user-static is installed."
  else
    echo "The package qemu-user-static is not installed yet. Please install it first."
    return 1
  fi
  if dpkg-query -s binfmt-support 1>/dev/null 2>&1; then
    echo "The package binfmt-support is installed."
  else
    echo "The package binfmt-support is not installed yet. Please install it first."
    return 1
  fi
  return 0
}

# Check to see if all the prerequisites are fullfilled.
function asus_docker_env_check_prerequisites() {
  if [[ ! -d ${ASUS_DOCKER_ENV_DIR} ]]; then
    echo "The directory [${ASUS_DOCKER_ENV_DIR}] for the ASUS IoT Docker environment is not found."
    return 1
  fi
  if [[ ! -d ${ASUS_DOCKER_ENV_SOURCE} ]]; then
    echo "The source directory [${ASUS_DOCKER_ENV_SOURCE}] for the ASUS IoT Docker environment is not found."
    return 1
  fi
  if [[ ! -f ${ASUS_DOCKER_ENV_DOCKERFILE} ]]; then
    echo "Dockerfile [${ASUS_DOCKER_ENV_DOCKERFILE}] for the ASUS IoT Docker environment is not found."
    return 1
  fi
  if ! asus_docker_env_check_docker; then
    return 1
  fi
  if ! asus_docker_env_check_required_packages; then
    return 1
  fi
  return 0
}

function asus_docker_env_build_docker_image() {
  docker build --tag ${ASUS_DOCKER_ENV_IMAGE} --file ${ASUS_DOCKER_ENV_DOCKERFILE} ${ASUS_DOCKER_ENV_DIR}
}

function asus_docker_env_run() {
  echo "Entering the ASUS IoT Docker environment......."
  asus_docker_env_show_variables

  if asus_docker_env_check_prerequisites; then
    asus_docker_env_build_docker_image
    if [ $# -eq 0 ]; then
      docker run ${ASUS_DOCKER_EVN_OPTIONS} ${ASUS_DOCKER_ENV_IMAGE} bash -c \
        "groupadd -g $(id -g) $(id -g -n) && \
	useradd -d /home/$(id -u -n) -s /bin/bash -u $(id -u) -g $(id -g) $(id -u -n) && \
	echo '$(id -u -n) ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
	chown -R 1000:1000 /home/$(id -u -n) && \
	sudo -u $(id -u -n) bash"
    else
      docker run ${ASUS_DOCKER_EVN_OPTIONS} ${ASUS_DOCKER_ENV_IMAGE} /bin/bash -c \
        "groupadd --gid $(id -g) $(id -g -n); \
        useradd -m -e \"\" -s /bin/bash --gid $(id -g) --uid $(id -u) $(id -u -n); \
        passwd -d $(id -u -n); \
        echo \"$(id -u -n) ALL=(ALL) NOPASSWD:ALL\" >> /etc/sudoers; \
        sudo -E -u $(id -u -n) --set-home /bin/bash -c \"$*\""
    fi
  fi

  echo "Leaving the ASUS IoT Docker environment......."
}

function asus_docker_env_main() {
  asus_docker_env_run $*
}
asus_docker_env_main

SHORT_OPTS="d:o:l:n:a:c:"
LONG_OPTS="public-key:,private-key:"

PARSED_OPTS=$(getopt --options $SHORT_OPTS --longoptions $LONG_OPTS --name "$0" -- "$@")
if [[ $? -ne 0 ]]; then
  exit 1
fi

eval set -- "$PARSED_OPTS"

while true; do
  case "$1" in
    -d)
      DESCRIPTION="$2"
      echo "DESCRIPTION is $DESCRIPTION"
      shift 2
      ;;
    -o)
      ORIGIN="$2"
      echo "ORIGIN is $ORIGIN"
      shift 2
      ;;
    -l)
      LABEL="$2"
      echo "LABEL is $LABEL"
      shift 2
      ;;
    -n)
      CODENAME="$2"
      echo "CODENAME is $CODENAME"
      shift 2
      ;;
    -a)
      ARCH="$2"
      echo "ARCH is $ARCH"
      shift 2
      ;;
    -c)
      COMPONENT="$2"
      echo "COMPONENT is $COMPONENT"
      shift 2
      ;;
    --public-key)
      public_key="$2"
      shift 2
      ;;
    --private-key)
      private_key="$2"
      shift 2
      ;;
    --)
      shift
      break
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done
