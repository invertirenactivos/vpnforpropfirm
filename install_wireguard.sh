#!/bin/bash

# Script de instalación de Docker y WireGuard Easy

# Solicitar IP pública y contraseña
read -p "Introduce la IP pública de tu servidor: " SERVER_IP
read -sp "Introduce una contraseña para WireGuard Easy: " WG_PASSWORD
echo

# Verificar si el script se ejecuta como root
if [ "$(id -u)" -ne 0 ]; then
    echo "Este script debe ejecutarse como root o con privilegios sudo"
    exit 1
fi

# Actualizar sistema
echo "Actualizando los repositorios del sistema..."
apt update -y && apt upgrade -y

# Instalar dependencias necesarias
echo "Instalando dependencias necesarias..."
apt install -y curl gnupg lsb-release

# Instalar Docker
echo "Instalando Docker..."
curl -fsSL https://get.docker.com | bash
systemctl start docker
systemctl enable docker

# Verificar la instalación de Docker
if ! command -v docker &> /dev/null; then
    echo "Docker no se instaló correctamente. Abortando."
    exit 1
fi

echo "Docker instalado correctamente."

# Instalar Docker Compose
echo "Instalando Docker Compose..."
curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Verificar la instalación de Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose no se instaló correctamente. Abortando."
    exit 1
fi

echo "Docker Compose instalado correctamente."

# Crear un directorio para WireGuard Easy
mkdir -p /opt/wireguard-easy

# Descargar archivo Docker Compose para WireGuard Easy
cat > /opt/wireguard-easy/docker-compose.yml <<EOF
version: '3'

services:
  wireguard:
    image: linuxserver/wireguard
    container_name: wireguard
    environment:
      - PUID=1000
      - PGID=1000
      - SERVERURL=$SERVER_IP # Usamos la IP pública proporcionada
      - SERVERPORT=51820
      - PEERS=5 # Cantidad de clientes WireGuard a crear
      - PEERDNS=8.8.8.8
      - INTERNAL_SUBNET=10.13.13.0
      - PASSWORD=$WG_PASSWORD # La contraseña proporcionada
    volumes:
      - ./config:/config
    ports:
      - 51820:51820/udp
    sysctls:
      - net.ipv4.conf.all.src_valid_mark=1
    restart: unless-stopped
EOF

# Iniciar el contenedor de WireGuard Easy
echo "Iniciando WireGuard Easy..."
cd /opt/wireguard-easy
docker-compose up -d

# Verificar que el contenedor esté corriendo
if [ "$(docker ps -q -f name=wireguard)" ]; then
    echo "WireGuard Easy está corriendo correctamente en el servidor."
else
    echo "Hubo un problema al iniciar WireGuard Easy. Abortando."
    exit 1
fi

# Mostrar información de acceso
echo ""
echo "WireGuard Easy ha sido instalado y está en ejecución."
echo "Puedes acceder a la interfaz web a través de la IP del servidor en el puerto 51820."
echo "La contraseña para la interfaz web es: $WG_PASSWORD"
echo "El servidor WireGuard está listo para ser configurado."

exit 0
