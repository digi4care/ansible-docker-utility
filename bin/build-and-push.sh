#!/bin/bash

VERSION="1.2.0"
TITLE="Docker Image Builder"
AUTHOR="Chris Engelhard"
EMAIL="chris@chrisengelhard.nl"
WEBSITE="https://www.chrisengelhard.nl"
COMPANY="Digi4Care"
_DATE="2025-05-08"

# Default values
IMAGE_NAME="ansible-docker-utility"
TAG="latest"
REGISTRY=""  # e.g., your-private-registry.example.com/digi4care
PUSH=false
SYSTEM_PRUNE=false
BUILDER_PRUNE=false
START=false
BUILD=false
BUILD_OPTS=""

# Terminal output
show_header() {
  local title="$1"
  local version="$2"
  local image_name="$3"
  local tag="$4"
  local author="$5"
  local email="$6"
  local website="$7"
  local company="$8"
  # Parameters 1-8: title, version, image_name, tag, author, email, website, company
  # Parameter 9: script_name
  # Parameter 10: show_help
  local script_name="${9:-$0}"
  local show_help="${10:-false}"

  printf -- "--------------------------------------------------------------------------------\n"
  printf -- "--- %s --- Version: %s\n" "$title" "$version"
  printf -- "--------------------------------------------------------------------------------\n"
  printf -- "--- Image: %s:%s\n" "$image_name" "$tag"
  printf -- "--------------------------------------------------------------------------------\n"
  printf -- "--- Author: %s <%s>\n" "$author" "$email"
  printf -- "--- Website: %s\n" "$website"
  printf -- "--- Copyright: © %s %s\n" "$(date +'%Y')" "$company"
  printf -- "--------------------------------------------------------------------------------\n"
  if [ "$show_help" = "true" ]; then
    printf -- "\n"
    printf -- "--- Usage: %s [options]\n" "$script_name"
    printf -- "--- Options:\n"
    printf -- "\n"
    printf -- "--- -s, --start             Start the Docker container (default: %s:%s)\n" "$IMAGE_NAME" "$TAG"
    printf -- "--- -b, --build             Build the Docker image (default: %s:%s)\n" "$IMAGE_NAME" "$TAG"
    printf -- "--- -n, --name              Image name (default: %s)\n" "$IMAGE_NAME"
    printf -- "--- -t, --tag               Image tag (default: %s)\n" "$TAG"
    printf -- "--- -r, --registry          Registry URL (e.g., registry.example.com/username)\n"
    printf -- "--- -p, --push              Push to registry after build\n"
    printf -- "--- -pr, --prune            Run both system and builder prune before building\n"
    printf -- "--- -sp, --system-prune     Run docker system prune before building\n"
    printf -- "--- -bp, --builder-prune    Run docker builder prune before building\n"
    printf -- "--- -h, --help              Show this help message\n"
  else
    printf -- "--- For help, run: %s --help\n" "$script_name"
  fi
  printf -- "--------------------------------------------------------------------------------\n"
  printf -- "\n"
}

show_after_build() {
  echo "Image build complete!"
  echo -e "\nWriting to docker-compose.yml..."
  cat > docker-compose.yml << EOF
services:
  ansible:
    image: $IMAGE_NAME:$TAG
    container_name: $IMAGE_NAME
    environment:
      - TZ=\${TZ:-Europe/Amsterdam}
    volumes:
      - .:/ansible
    working_dir: /ansible
    # Keep the container running
    command: tail -f /dev/null
EOF

  echo -e "\nTo run your playbooks, use commands like:"
  printf "docker exec %s ansible-playbook playbooks/testing/test-playbook.yml\n" "$IMAGE_NAME"
  echo -e "\nExample crontab entry on the host to run daily at 3 AM:"
  printf "0 3 * * * docker exec %s ansible-playbook /ansible/playbooks/testing/test-playbook.yml\n" "$IMAGE_NAME"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -n|--name)
      IMAGE_NAME="$2"
      shift # past argument
      shift # past value
      ;;
    -t|--tag)
      TAG="$2"
      shift # past argument
      shift # past value
      ;;
    -r|--registry)
      REGISTRY="$2"
      shift # past argument
      shift # past value
      ;;
    -p|--push)
      PUSH=true
      shift # past argument
      ;;
    -sp|--system-prune)
      SYSTEM_PRUNE=true
      shift # past argument
      ;;
    -bp|--builder-prune)
      BUILDER_PRUNE=true
      shift # past argument
      ;;
    -b|--build)
      BUILD=true
      shift # past argument
      ;;
    -pr|--prune)
      SYSTEM_PRUNE=true
      BUILDER_PRUNE=true
      shift # past argument
      ;;
    -s|--start)
      START=true
      shift # past argument
      ;;
      -h|--help)
      show_header "$TITLE" "$VERSION" "$IMAGE_NAME" "$TAG" "$AUTHOR" "$EMAIL" "$WEBSITE" "$COMPANY" "$0" true
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      show_header "$TITLE" "$VERSION" "$IMAGE_NAME" "$TAG" "$AUTHOR" "$EMAIL" "$WEBSITE" "$COMPANY" "$0" true
      exit 1
      ;;
  esac
done

# Show header
show_header "$TITLE" "$VERSION" "$IMAGE_NAME" "$TAG" "$AUTHOR" "$EMAIL" "$WEBSITE" "$COMPANY" "$0" false

# Clean up Docker objects based on flags
if [ "$SYSTEM_PRUNE" = true ] || [ "$BUILDER_PRUNE" = true ]; then
  if [ "$SYSTEM_PRUNE" = true ]; then
    echo "Running docker system prune..."
    docker system prune -f
  fi

  if [ "$BUILDER_PRUNE" = true ]; then
    echo "Running docker builder prune..."
    docker builder prune -f
  fi

  # Only use --no-cache if either prune option is true
  if [ "$BUILD" = true ]; then
    BUILD_OPTS="--no-cache"
  fi
fi

# Start the container, build first if image doesn't exist
if [ "$START" = true ]; then
  # Check if image exists
  if ! docker image inspect "$IMAGE_NAME:$TAG" > /dev/null 2>&1; then
    echo "Image $IMAGE_NAME:$TAG not found. Building it first..."
    if ! docker build $BUILD_OPTS -t "$IMAGE_NAME:$TAG" -f build/Dockerfile .; then
      echo "Error: Failed to build the image"
      exit 1
    fi
  fi

  # Check if container is already running
  if docker ps -a --format '{{.Names}}' | grep -q "^${IMAGE_NAME}$"; then
    echo "Container $IMAGE_NAME already exists. Removing it first..."
    docker rm -f "$IMAGE_NAME"
  fi

  echo "Starting Docker container: $IMAGE_NAME:$TAG"
  if docker run -d --name "$IMAGE_NAME" -v "$PWD":/ansible -w /ansible "$IMAGE_NAME:$TAG" tail -f /dev/null; then
    echo "Container started successfully"
    show_after_build
  else
    echo "Error: Failed to start container"
    exit 1
  fi
  exit 0
fi

# Build the image
if [ "$BUILD" = true ]; then
  echo "Building Docker image: $IMAGE_NAME:$TAG"
  if ! docker build $BUILD_OPTS -t "$IMAGE_NAME:$TAG" -f build/Dockerfile .; then
    echo "Error: Failed to build the image"
    exit 1
  fi
  show_after_build
  exit 0
fi

# Tag for registry if registry is provided
if [ -n "$REGISTRY" ]; then
  FULL_IMAGE_NAME="$REGISTRY/$IMAGE_NAME:$TAG"
  echo "Tagging image as: $FULL_IMAGE_NAME"
  if ! docker tag "$IMAGE_NAME:$TAG" "$FULL_IMAGE_NAME"; then
    echo "Error: Failed to tag the image"
    exit 1
  fi

  # Push to registry if requested
  if [ "$PUSH" = true ]; then
    echo "Pushing image to registry..."
    if ! docker push "$FULL_IMAGE_NAME"; then
      echo "Error: Failed to push the image to the registry"
      exit 1
    fi
  fi
  exit 0
fi
