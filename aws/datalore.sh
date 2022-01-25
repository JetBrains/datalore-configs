#!/usr/bin/env bash
set -e

DATALORE_VERSION="${DATALORE_VERSION:-v0.3.0}"
ENVIRONMENT_VERSION="${ENVIRONMENT_VERSION:-build-3}"
DATALORE_CONFIGS_BRANCH="${DATALORE_CONFIGS_BRANCH:-on-premises-0.3.0}"

ENVIRONMENT_CONFIGS=(\
  https://raw.githubusercontent.com/JetBrains/datalore-configs/${DATALORE_CONFIGS_BRANCH}/aws/configs/envs/environment_minimal.yml \
  https://raw.githubusercontent.com/JetBrains/datalore-configs/${DATALORE_CONFIGS_BRANCH}/aws/configs/envs/requirements_default.txt \
  https://raw.githubusercontent.com/JetBrains/datalore-configs/${DATALORE_CONFIGS_BRANCH}/aws/configs/envs/requirements_minimal.txt \
)
PLANS_CONFIG_URL="https://raw.githubusercontent.com/JetBrains/datalore-configs/${DATALORE_CONFIGS_BRANCH}/aws/configs/plans_config.yaml"
LOGBACK_CONFIG_URL="https://raw.githubusercontent.com/JetBrains/datalore-configs/${DATALORE_CONFIGS_BRANCH}/aws/configs/logback.xml"
DATALORE_IMAGE="${DATALORE_IMAGE:-jetbrains/datalore-server}:${DATALORE_VERSION}"
HUB_IMAGE="${HUB_IMAGE:-jetbrains/hub:2020.1.12693}"
PUBLIC_ENV_STORAGE="${PUBLIC_ENV_STORAGE:-https://datalore-public-environments.s3-eu-west-1.amazonaws.com}"
AGENTS_IMAGES_REGISTRY=${AGENTS_IMAGES_REGISTRY:-jetbrains/datalore-agent}
AGENT_DOCKER_IMAGES_TAG="on-prem"

LOG_PREFIX="\033[1;95m[datalore.sh]\033[0m "
info() {
  printf "$LOG_PREFIX\033[1;32m${1}\033[0m\n"
}

error() {
  printf >&2 "$LOG_PREFIX\033[1;91m${1}\033[0m\n"
}

fatal() {
  error "$1"
  exit 1
}

DATALORE_CONFIGS_DIR="/home/ubuntu/datalore"

RUN_HUB_COMMAND_ARGS="\
    --rm \
    -p 8082:8080 \
    --name hub \
    --volume hub-data:/opt/hub/data \
    --volume hub-conf:/opt/hub/conf \
    --volume hub-logs:/opt/hub/logs \
    --volume hub-backups:/opt/hub/backups \
    ${HUB_IMAGE} \
"

HUB_AUTHORIZARION_HEADER="Authorization: Basic YWRtaW46Y2hhbmdlbWU="

hub_post() {
  curl -s -X "POST" -H "$HUB_AUTHORIZARION_HEADER" -H "Content-Type: application/json;charset=UTF-8" "${REST_API_URL}$1" -d "$2"
}

pull_images() {
  sudo docker pull "${HUB_IMAGE}"
  sudo docker pull "${DATALORE_IMAGE}"
}

copy_to_s3() {
  input_name=$1
  output_name=$2
  tmp_file="/tmp/${input_name}"

  info "Copying ${input_name}"
  wget "${PUBLIC_ENV_STORAGE}/${input_name}" -O "${tmp_file}"
  aws s3 cp "${tmp_file}" "s3://${S3_ENVIRONMENTS_ADDRESS}/${output_name}"
  rm "${tmp_file}"
}

upload_envs() {
  if ! [[ -v S3_ENVIRONMENTS_ADDRESS ]]; then
    fatal "--s3-environments-address is missing"
  fi
  if ! [[ -v LOCAL_S3_ARCHIVE ]]; then
    fatal "--local-s3-archive is missing"
  fi
  info "Uploading environment to s3"

  aws s3 cp "${LOCAL_S3_ARCHIVE}" "s3://${S3_ENVIRONMENTS_ADDRESS}/environment.tar"

  info "S3 environments have been uploaded"
}

download_envs() {
  if ! [[ -v S3_ENVIRONMENTS_ADDRESS ]]; then
    fatal "--s3-environments-address is missing"
  fi
  info "Copying s3 environments"

  copy_to_s3 "environment-${ENVIRONMENT_VERSION}-cpu.tar" "environment.tar"

  info "S3 environments have been copied"
}

download_agent_images() {
  if ! [[ -v DOCKER_REGISTRY_ADDRESS ]]; then
    fatal "--docker-registry-address is missing"
  fi

  info "Copying docker images"

  sudo docker pull "${AGENTS_IMAGES_REGISTRY}:computation-agent-${DATALORE_VERSION}"
  sudo docker pull "${AGENTS_IMAGES_REGISTRY}:computation-agent-gpu-${DATALORE_VERSION}"

  sudo docker tag "${AGENTS_IMAGES_REGISTRY}:computation-agent-${DATALORE_VERSION}" "${DOCKER_REGISTRY_ADDRESS}/computation-agent:${AGENT_DOCKER_IMAGES_TAG}"
  sudo docker tag "${AGENTS_IMAGES_REGISTRY}:computation-agent-gpu-${DATALORE_VERSION}" "${DOCKER_REGISTRY_ADDRESS}/computation-agent-gpu:${AGENT_DOCKER_IMAGES_TAG}"

  sudo docker push "${DOCKER_REGISTRY_ADDRESS}/computation-agent:${AGENT_DOCKER_IMAGES_TAG}"
  sudo docker push "${DOCKER_REGISTRY_ADDRESS}/computation-agent-gpu:${AGENT_DOCKER_IMAGES_TAG}"

  info "Docker images have been copied"
}

init_hub() {
  info "Initializing hub"

  sudo docker run $RUN_HUB_COMMAND_ARGS configure \
    --base-url="${HUB_BASE_URL}" \
    --disable.configurationWizard=true \
    -J-Djetbrains.hub.installation.type=DOCKER \
    -J-Ddisable.configuration.wizard.on.clean.install=true \
    -J-Djetbrains.jetpass.admin.login=admin \
    -J-Djetbrains.jetpass.admin.name=admin \
    -J-Djetbrains.jetpass.admin.password=changeme \
    -J-Djetbrains.hub.block-not-verified-accounts.disabled=false \
    -J-Djetbrains.hub.jabber.settings.hide=true \
    -J-Djetbrains.hub.user.vcsusernames.hide=true \
    -J-Djetbrains.hub.user.sshpublickeys.hide=true

  info "Hub has been initialized"
}

start_hub() {
  info "Starting hub"
  sudo docker run -d $RUN_HUB_COMMAND_ARGS
}

prepare_datalore_configs() {
  info "Preparing datalore storage dir"
  sudo mkdir /home/storage
  sudo chown 5000:5000 /home/storage

  info "Preparing datalore configs"
  mkdir -p $DATALORE_CONFIGS_DIR

  HUB_SERVICE_SECRET=$(LC_ALL=C tr -dc '[:alnum:]' </dev/urandom | head -c20)
  info "Creating datalore service in hub"
  hub_post "/services" "{\
        \"name\": \"datalore\", \
        \"homeUrl\": \"${DATALORE_BASE_URL}\", \
        \"id\": \"datalore\", \
        \"secret\": \"${HUB_SERVICE_SECRET}\", \
        \"iconUrl\": \"data:image/png;base64,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\", \
        \"baseUrls\": [\"${DATALORE_BASE_URL}\"], \
        \"redirectUris\": [\"/api/hub/openid/login\"], \
        \"trusted\": true \
    }" >/dev/null

  info "Datalore service in hub has been created"

  info "Creating hub token"

  HUB_TOKEN=$(hub_post "/users/me/permanenttokens?fields=token" "{\
        \"scope\": [\
          {\
            \"id\":\"0-0-0-0-0\",\
            \"key\":\"0-0-0-0-0\",\
            \"label\":\"Hub\",\
            \"data\": {\
              \"id\":\"0-0-0-0-0\",\
              \"name\":\"Hub\",\
              \"applicationName\":\"Hub\"\
            }\
          },\
          {\
            \"id\":\"datalore\",\
            \"key\":\"datalore\",\
            \"label\":\"datalore\",\
            \"data\":{\
              \"id\":\"datalore\",\
              \"name\":\"datalore\"\
            }\
          }\
        ],\
        \"name\":\"datalore_token\"\
      }" | jq --raw-output '.token')

  info "Hub token has been created"

  ADMIN_API_AUTH_TOKEN=$(LC_ALL=C tr -dc '[:alnum:]' </dev/urandom | head -c20)
  echo >${DATALORE_CONFIGS_DIR}/datalore.env "
FRONTEND_URL=${DATALORE_BASE_URL}
DATALORE_INTERNAL_HOST=${INTERNAL_IP_ADDRESS}
MAX_HEAP_SIZE=2048m

DB_HOST=${DB_HOST}
DB_PORT=5432

DB_USER=postgres
DB_PASSWORD=${DB_PASSWORD}

HUB_PUBLIC_BASE_URL=${HUB_BASE_URL}/hub/
HUB_INTERNAL_BASE_URL=${HUB_BASE_URL}/hub/
HUB_DATALORE_SERVICE_ID=datalore
HUB_DATALORE_SERVICE_SECRET=${HUB_SERVICE_SECRET}
HUB_PERM_TOKEN=${HUB_TOKEN}
HUB_FORCE_EMAIL_VERIFICATION=false

PASSWORD_SECRET=CHANGEME
ENABLE_PLANS=false

MAIL_ENABLED=false

AGENT_IMAGE_VERSION=${AGENT_DOCKER_IMAGES_TAG}
AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY}
AWS_SECRET_ACCESS_KEY=${AWS_ACCESS_SECRET}

DEFAULT_BASE_ENV_NAME=default
DEFAULT_PACKAGE_MANAGER=pip
ADMIN_API_AUTH_TOKEN=${ADMIN_API_AUTH_TOKEN}
"

  echo >${DATALORE_CONFIGS_DIR}/agents_config.yaml "
aws:
  instanceManager:
    securityGroupIds: ${SECURITY_GROUP_ID}
    subnetId: ${AGENT_SUBNET_ID}
    agentIamProfile: ${AGENT_IAM_PROFILE}
    instanceName: datalore-comp-agent
    instanceGroup: datalore-agents
    regionName: ${AWS_REGION}
    dockerRegistryAddress: ${DOCKER_REGISTRY_ADDRESS}
    s3EnvironmentsAddress: ${S3_ENVIRONMENTS_ADDRESS}
    cpuAmi: ami-0f6e35663abb90cb2
    gpuAmi: ami-06b6462a7439045e2
    availabilityZoneId: ${AVAILABILITY_ZONE_ID}
    keyPairName: ${KEYPAIR_NAME}
    anacondaSource: /mnt/local/anaconda3
    associatePublicIpAddress: true
  instances:
    - id: basic
      awsTag: t2.medium
      creditSpecification: standard
      label: \"Basic machine\"
      description: \"Use for simple data analysis and machine learning tasks.\"
      features:
        - \"4 GB RAM\"
        - \"AWS name: t2.medium\"
      ram: 4
      isGpu: false
      spot: true
      minAllowed: 1
      maxAllowed: 2
      numCPUs: 2
      cpuMemoryText: \"4 GB\"
      numGPUs: 0
      gpuMemoryText: \"\"
      isEphemeralStorage: true
      environmentArchive: environment.tar
      default: true

    - id: large
      awsTag: r5.large
      label: \"Large machine\"
      description: \"Enjoy a more powerful machine designed for tasks with huge datasets.\"
      features:
        - \"2 vCPU cores\"
        - \"16 GB RAM\"
        - \"AWS name: r5.large\"
      ram: 16
      isGpu: false
      spot: true
      minAllowed: 0
      maxAllowed: 1
      numCPUs: 2
      cpuMemoryText: \"16 GB\"
      numGPUs: 0
      gpuMemoryText: \"\"
      isEphemeralStorage: true
      environmentArchive: environment.tar
"

  wget -q "${PLANS_CONFIG_URL}" -P "${DATALORE_CONFIGS_DIR}"
  wget -q "${LOGBACK_CONFIG_URL}" -P "${DATALORE_CONFIGS_DIR}"

  mkdir -p "${DATALORE_CONFIGS_DIR}/envs"
  for config in "${ENVIRONMENT_CONFIGS[@]}"; do
    wget -P "${DATALORE_CONFIGS_DIR}/envs" "$config"
  done

  info "ADMIN_API_AUTH_TOKEN=${ADMIN_API_AUTH_TOKEN}"
  info "Default datalore configs have been created in ${DATALORE_CONFIGS_DIR}"
}

start_datalore() {
  info "Starting datalore"

  sudo docker run -d --rm --name datalore \
    -v ${DATALORE_CONFIGS_DIR}/agents_config.yaml:/etc/datalore/agents-config/agents_config.yaml \
    -v ${DATALORE_CONFIGS_DIR}/logback.xml:/etc/datalore/logback-config/logback.xml \
    -v ${DATALORE_CONFIGS_DIR}/plans_config.yaml:/etc/datalore/plans-config/plans_config.yaml \
    -v ${DATALORE_CONFIGS_DIR}/envs:/etc/datalore/environment_info \
    -v /home/storage:/home/storage \
    --env-file ${DATALORE_CONFIGS_DIR}/datalore.env \
    -p 5050:5050 \
    -p 5060:5060 \
    -p 8080:8080 \
    "${DATALORE_IMAGE}"
}

stop_datalore() {
  info "Stopping datalore"
  sudo docker stop datalore 2>/dev/null || true
}

init_postgres() {
  info "Creating database"

  PGPASSWORD="${DB_PASSWORD}" \
    psql \
    --host="${DB_HOST}" \
    --port=5432 \
    --username=postgres \
    --dbname=template1 \
    -c "CREATE DATABASE \"datalore\"" || error "Database already exists"

  info "Database has been created"
}

clean() {
  read -p "Do you really want to destroy ALL datalore/hub data (y/N)?" choice
  case "$choice" in
  y | Y)
    stop
    sudo docker volume rm hub-logs hub-data hub-conf hub-backups
    sudo docker rmi -f $(sudo docker images -q)
    sudo rm -rf /home/storage
    sudo rm -rf "${DATALORE_CONFIGS_DIR}"
    ;;
  n | N)
    exit 1
    ;;
  *)
    exit 1
    ;;
  esac
}

init() {
  if ! [[ -v PUBLIC_IP_ADDRESS ]]; then
    fatal "--public-ip-address is missing"
  fi
  if ! [[ -v INTERNAL_IP_ADDRESS ]]; then
    fatal "--internal-ip-address is missing"
  fi
  if ! [[ -v DB_HOST ]]; then
    fatal "--db-host is missing"
  fi
  if ! [[ -v DB_PASSWORD ]]; then
    fatal "--db-password is missing"
  fi
  if ! [[ -v AWS_ACCESS_KEY ]]; then
    fatal "--aws-access-key is missing"
  fi
  if ! [[ -v AWS_ACCESS_SECRET ]]; then
    fatal "--aws-access-secret is missing"
  fi
  if ! [[ -v KEYPAIR_NAME ]]; then
    fatal "--keypair-name is missing"
  fi
  if ! [[ -v S3_ENVIRONMENTS_ADDRESS ]]; then
    fatal "--s3-environments-address is missing"
  fi
  if ! [[ -v DOCKER_REGISTRY_ADDRESS ]]; then
    fatal "--docker-registry-address is missing"
  fi
  if ! [[ -v AGENT_IAM_PROFILE ]]; then
    fatal "--agent-iam-profile is missing"
  fi
  if ! [[ -v AGENT_SUBNET_ID ]]; then
    fatal "--agent-subnet-id is missing"
  fi
  if ! [[ -v SECURITY_GROUP_ID ]]; then
    fatal "--security-group-id is missing"
  fi
  if ! [[ -v AWS_REGION ]]; then
    fatal "--aws-region is missing"
  fi
  if ! [[ -v AVAILABILITY_ZONE_ID ]]; then
    fatal "--availability-zone-id is missing"
  fi

  DATALORE_BASE_URL="http://${PUBLIC_IP_ADDRESS}:8080"
  HUB_BASE_URL="http://${PUBLIC_IP_ADDRESS}:8082"
  REST_API_URL="${HUB_BASE_URL}/hub/api/rest"

  pull_images
  init_postgres
  init_hub
  start_hub
  wait_for_hub
  download_envs
  download_agent_images
  prepare_datalore_configs

  info "Your hub admin user/password is admin/changeme. Don't forget to change it."
  info "Your default configs is in ${DATALORE_CONFIGS_DIR}. Modify it if you want and execute 'datalore.sh start-datalore' to start datalore."
}

wait_for_hub() {
  MAX_ITERATIONS=50
  WAITS_SECONDS=6
  HTTP_ENDPOINT="http://127.0.0.1:8082/hub/api/rest/users/guest"

  ITERATIONS=0
  while true; do
    ((ITERATIONS++)) || true
    info "Waiting hub to start. Iteration $ITERATIONS/$MAX_ITERATIONS"
    sleep $WAITS_SECONDS

    HTTP_CODE=$(curl -s -o /tmp/result.txt -w '%{http_code}' "$HTTP_ENDPOINT")

    if [ "$HTTP_CODE" -eq 200 ]; then
      info "Hub is up"
      break
    fi

    if [ "$ITERATIONS" -ge "$MAX_ITERATIONS" ]; then
      fatal "Loop timeout"
    fi
  done
}

start() {
  start_hub
  wait_for_hub
  start_datalore
}

stop() {
  stop_datalore

  info "Stopping hub"
  sudo docker stop hub 2>/dev/null || true
}

print_help() {
  printf "Usage: datalore.sh [--ip-address value|--db-host value|--db-password value] [init|start|stop|help]\n
\n
Available commands:
\t init\t Initialize hub and datalore. Must be executed before any other commands. Required arguments:
\t\t --public-ip-address value\t Public address of machine where you are executing this script.
\t\t --internal-ip-address value\t Internal address of machine where you are executing this script.
\t\t --db-host value\t Your database host.
\t\t --db-password value\t Password for postgres user of your database.
\t\t --aws-sccess-key value\t AWS access key from your aws account.
\t\t --aws-sccess-secret value\t AWS access secret from your aws account.
\t\t --keypair-name value\t Name of AWS keypair.
\t\t --s3-environments-address value\t Address of s3 where you store environments.
\t\t --docker-registry-address value\t Address of registry where you keep agent images.
\t\t --agent-iam-profile value\t Name of IAM profile for agents.
\t\t --agent-subnet-id value\t Id of subnet where agent will be started.
\t\t --security-group-id value\t Id of security group for agents.
\t\t --availability-zone-id value\t AWS availability zone id.
\t\t --aws-region value\t AWS region.
\t\t --admin-token\t API token for admin API. NB: use it only for initiating first admin! (More in README#Setting up admin user)
\t start-hub\t Start hub.
\t start-datalore\t Start datalore.
\t start\t Start datalore and hub.
\t stop\t Stop datalore and hub.
\t pull-images\t Pull datalore and hub docker images.
\t help\t Print this message.
"
}

while test $# -gt 0; do
  opt=$1
  shift
  case "$opt" in
  init)
    init
    exit
    ;;
  start)
    start
    exit
    ;;
  start-hub)
    start_hub
    exit
    ;;
  start-datalore)
    start_datalore
    exit
    ;;
  stop-datalore)
    stop_datalore
    exit
    ;;
  stop)
    stop
    exit
    ;;
  help)
    print_help
    exit
    ;;
  pull-images)
    pull_images
    exit
    ;;
  download-agent-images)
    download_agent_images
    exit
    ;;
  upload-envs)
    upload_envs
    exit
    ;;
  clean)
    clean
    exit
    ;;
  --public-ip-address)
    PUBLIC_IP_ADDRESS=$1
    shift
    ;;
  --internal-ip-address)
    INTERNAL_IP_ADDRESS=$1
    shift
    ;;
  --aws-access-key)
    AWS_ACCESS_KEY=$1
    shift
    ;;
  --aws-access-secret)
    AWS_ACCESS_SECRET=$1
    shift
    ;;
  --security-group-id)
    SECURITY_GROUP_ID=$1
    shift
    ;;
  --agent-subnet-id)
    AGENT_SUBNET_ID=$1
    shift
    ;;
  --agent-iam-profile)
    AGENT_IAM_PROFILE=$1
    shift
    ;;
  --docker-registry-address)
    DOCKER_REGISTRY_ADDRESS=$1
    shift
    ;;
  --local-s3-archive)
    LOCAL_S3_ARCHIVE=$1
    shift
    ;;
  --s3-environments-address)
    S3_ENVIRONMENTS_ADDRESS=$1
    shift
    ;;
  --keypair-name)
    KEYPAIR_NAME=$1
    shift
    ;;
  --db-host)
    DB_HOST=$1
    shift
    ;;
  --availability-zone-id)
    AVAILABILITY_ZONE_ID=$1
    shift
    ;;
  --aws-region)
    AWS_REGION=$1
    shift
    ;;
  --db-password)
    DB_PASSWORD=$1
    shift
    ;;
  *)
    fatal "Unexpected option: $opt"
    ;;
  esac
done

print_help
