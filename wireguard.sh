#!/bin/bash

# Actualizar e instalar dependencias básicas
echo "Actualizando el sistema y instalando dependencias necesarias..."
apt-get update && apt-get upgrade -y
apt-get install -y curl gnupg2 lsb-release sudo

# Instalar Docker
echo "Instalando Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
rm get-docker.sh

# Agregar el usuario actual al grupo de Docker (para ejecutar Docker sin sudo)
echo "Añadiendo el usuario al grupo de Docker..."
usermod -aG docker $USER

# Verificar que Docker se haya instalado correctamente
echo "Verificando la instalación de Docker..."
docker --version

# Instalar Docker Compose (si es necesario)
echo "Instalando Docker Compose..."
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Verificar que Docker Compose se haya instalado correctamente
echo "Verificando la instalación de Docker Compose..."
docker-compose --version

# Descargar y configurar WireGuard Easy Docker
echo "Clonando el repositorio WireGuard Easy Docker..."
git clone https://github.com/WeeJeWel/wg-easy.git
cd wg-easy

# Crear el archivo .env con la configuración personalizada
echo "Configurando archivo .env para WireGuard Easy Docker..."
cat > .env <<EOF
# Configuración básica
WG_HOST=45.32.155.185
PASSWORD=beta2024#

# Configuración de clientes
CLIENTS=5
EOF

# Construir los contenedores de Docker
echo "Construyendo los contenedores de Docker para WireGuard Easy..."
docker-compose up -d

# Verificar que los contenedores estén corriendo
echo "Verificando los contenedores en ejecución..."
docker ps

# Generar los archivos de configuración de WireGuard para los clientes
echo "Generando configuraciones para los clientes..."
docker exec -it wg-easy ./wg-gen-web

# Mensaje de éxito
echo "WireGuard Easy Docker ha sido instalado y configurado con éxito."
echo "Accede a la interfaz web de WireGuard Easy en: http://45.32.155.185:51820"
echo "Contraseña de acceso: beta2024#"

# Finalizar
echo "El proceso ha finalizado. Disfruta de tu instalación de WireGuard con Docker."
