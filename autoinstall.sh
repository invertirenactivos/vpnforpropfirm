#!/bin/bash

# Actualizar e instalar dependencias básicas
echo "Actualizando el sistema y instalando dependencias necesarias..."
apt-get update && apt-get upgrade -y || { echo "Error al actualizar el sistema"; exit 1; }
apt-get install -y curl gnupg2 lsb-release sudo ufw git jq || { echo "Error al instalar dependencias"; exit 1; }

# Obtener la IP pública desde ipinfo.io
echo "Obteniendo la IP pública..."
WG_HOST=$(curl -s https://ipinfo.io/ip) || { echo "Error al obtener la IP pública"; exit 1; }

# Configurar UFW para permitir puertos específicos (UDP y TCP)
echo "Configurando las reglas de firewall con UFW..."
sudo ufw allow 51820/udp
sudo ufw allow 51820/tcp
sudo ufw allow 53/udp
sudo ufw allow 53/tcp
sudo ufw allow 51821/udp
sudo ufw allow 51821/tcp
sudo ufw allow 22/udp
sudo ufw allow 22/tcp

# Habilitar el firewall
echo "Habilitando UFW..."
sudo ufw enable

# Instalar Docker
echo "Instalando Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh || { echo "Error al instalar Docker"; exit 1; }
rm get-docker.sh

# Agregar el usuario actual al grupo de Docker
echo "Añadiendo el usuario al grupo de Docker..."
usermod -aG docker $USER

# Verificar que Docker se haya instalado correctamente
echo "Verificando la instalación de Docker..."
docker --version || { echo "Docker no se instaló correctamente"; exit 1; }

# Instalar Docker Compose
echo "Instalando Docker Compose..."
LATEST_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)
curl -L "https://github.com/docker/compose/releases/download/$LATEST_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose || { echo "Error al instalar Docker Compose"; exit 1; }

# Verificar que Docker Compose se haya instalado correctamente
echo "Verificando la instalación de Docker Compose..."
docker-compose --version || { echo "Docker Compose no se instaló correctamente"; exit 1; }

# Descargar y configurar WireGuard Easy Docker
echo "Clonando el repositorio WireGuard Easy Docker..."
git clone https://github.com/invertirenactivos/wg-easy.git
cd wg-easy

# Configuración del archivo .env con la IP obtenida dinámicamente
echo "Configurando archivo .env para WireGuard Easy Docker..."
cat > .env <<EOF
WG_HOST=$WG_HOST
PASSWORD=$(openssl rand -base64 12)  # Contraseña aleatoria
CLIENTS=5
EOF

# Reemplazar la IP estática en docker-compose.yml por la IP dinámica obtenida
echo "Actualizando el archivo docker-compose.yml con la IP pública..."
sed -i "s/raspberrypi.local/$WG_HOST/g" docker-compose.yml

# Construir los contenedores de Docker
echo "Construyendo los contenedores de Docker para WireGuard Easy..."
docker-compose up -d

# Verificar que los contenedores estén corriendo
echo "Verificando los contenedores en ejecución..."
docker ps

# Generar los archivos de configuración de WireGuard para los clientes
echo "Generando configuraciones para los clientes..."
docker exec -it wg-easy ./wg-gen-web

# Configuración de DNS
echo "Configurando DNS en /etc/resolv.conf..."
echo -e "nameserver 8.8.8.8\nnameserver 1.1.1.1" | sudo tee /etc/resolv.conf > /dev/null

# Mensaje de éxito
echo "WireGuard Easy Docker ha sido instalado y configurado con éxito."
echo "Accede a la interfaz web de WireGuard Easy en: http://$WG_HOST:51820"
echo "Contraseña de acceso: $(cat .env | grep PASSWORD | cut -d'=' -f2)"

# Finalizar
echo "El proceso ha finalizado. Disfruta de tu instalación de WireGuard con Docker."
