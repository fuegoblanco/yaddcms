#!/bin/bash


cat << "EOF"
                           /$$       /$$                                  
                          | $$      | $$                                  
 /$$   /$$  /$$$$$$   /$$$$$$$  /$$$$$$$  /$$$$$$$ /$$$$$$/$$$$   /$$$$$$$
| $$  | $$ |____  $$ /$$__  $$ /$$__  $$ /$$_____/| $$_  $$_  $$ /$$_____/
| $$  | $$  /$$$$$$$| $$  | $$| $$  | $$| $$      | $$ \ $$ \ $$|  $$$$$$ 
| $$  | $$ /$$__  $$| $$  | $$| $$  | $$| $$      | $$ | $$ | $$ \____  $$
|  $$$$$$$|  $$$$$$$|  $$$$$$$|  $$$$$$$|  $$$$$$$| $$ | $$ | $$ /$$$$$$$/
 \____  $$ \_______/ \_______/ \_______/ \_______/|__/ |__/ |__/|_______/ 
 /$$  | $$                                                                
|  $$$$$$/                                                                
 \______/                                                                 
    YET    ANOTHER     DAMN     DOCKER    COMPOSE     MEDIA      SERVER
    
    FEAT: JELLYFIN,RADARR,SONARR,PROWLARR,QBITTORRENT,FLARESOLVERR,NGNIX PROXY MANAGER,PIHOLE
    
    
EOF
# Setup logging
LOG_FILE="setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Colors for output
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
RESET=$(tput sgr0)

# Function to prompt for input with validation
prompt_input() {
  local prompt_message=$1
  local default_value=$2
  local var_name=$3
  local validation_regex=$4

  while true; do
    read -p "$prompt_message [$default_value]: " input_value
    input_value=${input_value:-$default_value}
    if [[ -z "$validation_regex" || "$input_value" =~ $validation_regex ]]; then
      eval "$var_name='$input_value'"
      break
    else
      echo "${RED}Invalid input. Please try again.${RESET}"
    fi
  done
}

# Prompt for environment variables
CURRENT_DIR=$(pwd)

prompt_input "Enter PUID" "1001" PUID "^[0-9]+$"
prompt_input "Enter PGID" "1001" PGID "^[0-9]+$"
prompt_input "Enter Timezone (e.g., Etc/UTC or your local timezone)" "Etc/UTC" TZ
prompt_input "Enter configuration directory (default: ${CURRENT_DIR}/yaddcms.config)" "${CURRENT_DIR}/yaddcms.config" CONFIG_DIR
prompt_input "Enter data directory (default: ${CURRENT_DIR}/data)" "${CURRENT_DIR}/data" DATA_DIR
prompt_input "Enter torrents directory (default: ${CURRENT_DIR}/data/torrents)" "${CURRENT_DIR}/data/torrents" TORRENTS_DIR
prompt_input "Enter Pi-hole web password" "" WEBPASSWORD

# Confirm directories
echo "${YELLOW}The following directories will be created:${RESET}"
echo "  - ${CONFIG_DIR}"
echo "  - ${DATA_DIR}"
echo "  - ${TORRENTS_DIR}"
read -p "Proceed? (y/n): " proceed
if [[ "$proceed" != "y" ]]; then
  echo "${RED}Aborting setup.${RESET}"
  exit 1
fi

# Create directories with error handling
create_directory() {
  local dir_path=$1
  if ! mkdir -p "$dir_path"; then
    echo "${RED}Error: Could not create directory $dir_path. Check permissions.${RESET}" >&2
    exit 1
  fi
}

echo "Creating directories..."
create_directory "$CONFIG_DIR"
create_directory "$DATA_DIR"
create_directory "$TORRENTS_DIR"
for service in radarr sonarr qbittorrent jellyfin proxymanager flarsolver pihole prowlarr; do
  create_directory "${CONFIG_DIR}/${service}"
done
echo "${GREEN}Directories created successfully.${RESET}"

# Create the .env file
if [[ -f ".env" ]]; then
  read -p ".env file already exists. Overwrite? (y/n): " overwrite
  if [[ "$overwrite" != "y" ]]; then
    echo "${RED}Aborting to avoid overwriting .env.${RESET}"
    exit 1
  fi
fi

echo "Creating .env file..."
cat <<EOF >.env
PUID=$PUID
PGID=$PGID
TZ=$TZ
CONFIG_DIR=$CONFIG_DIR
DATA_DIR=$DATA_DIR
TORRENTS_DIR=$TORRENTS_DIR
WEBPASSWORD=$WEBPASSWORD
EOF
echo "${GREEN}.env file created.${RESET}"

# Create the docker-compose.yml file
if [[ -f "docker-compose.yml" ]]; then
  read -p "docker-compose.yml file already exists. Overwrite? (y/n): " overwrite
  if [[ "$overwrite" != "y" ]]; then
    echo "${RED}Aborting to avoid overwriting docker-compose.yml.${RESET}"
    exit 1
  fi
fi

echo "Creating docker-compose.yml..."
cat <<EOF >docker-compose.yml
version: "3.9"

services:
  radarr:
    image: lscr.io/linuxserver/radarr:latest
    container_name: radarr
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TZ}
    volumes:
      - \${CONFIG_DIR}/radarr:/config
      - \${DATA_DIR}:/data
    ports:
      - "7878:7878"
    restart: unless-stopped

  sonarr:
    image: lscr.io/linuxserver/sonarr:latest
    container_name: sonarr
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TZ}
    volumes:
      - \${CONFIG_DIR}/sonarr:/config
      - \${DATA_DIR}:/data
    ports:
      - "8989:8989"
    restart: unless-stopped

  qbittorrent:
    image: lscr.io/linuxserver/qbittorrent:latest
    container_name: qbittorrent
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TZ}
      - WEBUI_PORT=8080
    volumes:
      - \${CONFIG_DIR}/qbittorrent:/config
      - \${TORRENTS_DIR}:/data/torrents
    ports:
      - "8080:8080"
    restart: unless-stopped

  jellyfin:
    image: jellyfin/jellyfin:latest
    container_name: jellyfin
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TZ}
    volumes:
      - \${CONFIG_DIR}/jellyfin:/config
      - \${DATA_DIR}:/data
    ports:
      - "8096:8096"
      - "8920:8920"
    restart: unless-stopped

  nginx-proxy-manager:
    image: jc21/nginx-proxy-manager:latest
    container_name: nginx-proxy-manager
    environment:
      - DB_SQLITE_FILE=/data/database.sqlite
    volumes:
      - \${CONFIG_DIR}/proxymanager:/data
    ports:
      - "80:80"
      - "81:81"
      - "443:443"
    restart: unless-stopped

  flarsolver:
    image: ghcr.io/flaresolverr/flaresolverr:latest
    container_name: flarsolver
    environment:
      - LOG_LEVEL=info
    volumes:
      - \${CONFIG_DIR}/flarsolver:/config
    ports:
      - "8191:8191"
    restart: unless-stopped

  pihole:
    image: pihole/pihole:latest
    container_name: pihole
    environment:
      - TZ=\${TZ}
      - WEBPASSWORD=\${WEBPASSWORD}
    volumes:
      - \${CONFIG_DIR}/pihole:/etc/pihole
      - \${CONFIG_DIR}/dnsmasq:/etc/dnsmasq.d
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "8800:80"
    restart: unless-stopped

  prowlarr:
    image: lscr.io/linuxserver/prowlarr:latest
    container_name: prowlarr
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TZ}
    volumes:
      - \${CONFIG_DIR}/prowlarr:/config
    ports:
      - "9696:9696"
    restart: unless-stopped
EOF
echo "${GREEN}docker-compose.yml created.${RESET}"

# Validate docker-compose.yml
echo "Validating docker-compose.yml..."
if docker compose config; then
  echo "${GREEN}docker-compose.yml is valid.${RESET}"
else
  echo "${RED}docker-compose.yml contains errors. Please fix them before starting the stack.${RESET}"
  exit 1
fi

# Ask to start Docker containers
read -p "Do you want to start the Docker containers now? (y/n): " start_now
if [[ "$start_now" == "y" ]]; then
  docker compose up -d
  echo "${GREEN}Docker containers started.${RESET}"
else
  echo "${YELLOW}You can start the containers later using: docker compose up -d${RESET}"
fi

echo "${GREEN}Setup complete!${RESET}"