# YET ANOTHER DAMN DOCKER COMPOSE MEDIA SERVER

This project sets up a media server using Docker Compose with the following services:

- Jellyfin
- Radarr
- Sonarr
- Prowlarr
- qBittorrent
- FlareSolverr
- Nginx Proxy Manager
- Pi-hole

## Prerequisites

- Docker
- Docker Compose

## Setup Instructions

1. **Clone the repository:**

   ```sh
   git clone https://github.com/fuegoblanco/yaddcms
   cd yaddcms
    ```


2. **Run the setup script**

```sh
./setup.sh
```

The script will prompt you for the following information:

- PUID (default: 1001)
- PGID (default: 1001)
- Timezone (default: Etc/UTC)
- Configuration directory (default: ./casa.config)
- Data directory (default: ./data)
- Torrents directory (default: ./data/torrents)
- Pi-hole web password

The script will create the necessary directories and generate the .env and docker-compose.yml files.

### 3. Pi-hole & Nginx Proxy Manager

#### **Pi-hole**

- **Purpose**: A network-wide ad blocker.
- **Access**:
  - Default URL: `http://<your-server-ip>:8800/admin`
  - Log in with the password you provided during setup.

- **Configuration**:
  1. Set your router's DNS to the Pi-hole server's IP address for network-wide ad blocking.
  2. Alternatively, configure individual devices to use the Pi-hole DNS.

#### **Nginx Proxy Manager**

- **Purpose**: Manage reverse proxies for the media server services.
- **Access**:
  - Default URL: `http://<your-server-ip>:81`
  - Default credentials:
    - Email: `admin@example.com`
    - Password: `changeme`

- **Configuration**:
  1. Log in and update the default credentials.
  2. Set up a reverse proxy for each service:
     - Go to "Hosts" > "Add Proxy Host."
     - Enter the domain/subdomain (e.g., `jellyfin.mydomain.com`).
     - Specify the internal IP and port of the service (e.g., Jellyfin: `8096`).
     - Enable SSL (optional, requires Let's Encrypt or another certificate authority).
  3. Test the proxy by accessing the domain or subdomain you configured.

---

## Starting and Stopping Services

### Start All Services

```sh
docker compose up -d
```

### Stop All Services

```sh
docker compose down
```

### Rebuild Containers

If you make changes to the `docker-compose.yml` file or want to pull updated images:

```sh
docker compose up -d --build
```

---

## Accessing Services

| Service               | Default Port  | URL                           |
|-----------------------|---------------|-------------------------------|
| Jellyfin              | `8096`        | `http://<your-server-ip>:8096`|
| Radarr                | `7878`        | `http://<your-server-ip>:7878`|
| Sonarr                | `8989`        | `http://<your-server-ip>:8989`|
| Prowlarr              | `9696`        | `http://<your-server-ip>:9696`|
| qBittorrent           | `8080`        | `http://<your-server-ip>:8080`|
| FlareSolverr          | `8191`        | `http://<your-server-ip>:8191`|
| Nginx Proxy Manager   | `81`          | `http://<your-server-ip>:81`  |
| Pi-hole               | `8800`        | `http://<your-server-ip>:8800/admin`|

---

## Post-Setup Tips

### Pi-hole

- Add custom blocklists in `Group Management > Adlists`.
- Monitor queries and blocked requests in the admin interface.

### Nginx Proxy Manager

- Use Let's Encrypt for free SSL certificates.
- Configure Access Lists to secure sensitive services.

---

## Troubleshooting

### Common Issues

- **Port Conflicts**: Ensure ports in `docker-compose.yml` are not used by other applications.
- **Permission Errors**: Verify directory permissions for Docker.

### Useful Commands

- View running containers:

  ```sh
  docker ps
  ```

- Check logs for a specific service:

  ```sh
  docker logs <container_name>
  ```

- Prune unused Docker resources:

  ```sh
  docker system prune -a
  ```

---
