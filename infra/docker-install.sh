#!/bin/bash

# Обновляем пакеты
sudo apt-get update

# Устанавливаем необходимые пакеты для работы с репозиториями через HTTPS
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

# Добавляем официальный GPG-ключ Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Добавляем репозиторий Docker в источники APT
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

# Обновляем пакеты после добавления репозитория Docker
sudo apt-get update

# Устанавливаем Docker CE
sudo apt-get install -y docker-ce

# Добавляем текущего пользователя в группу docker, чтобы не использовать sudo для команд docker
sudo usermod -aG docker $USER

# Перезагружаем систему для применения изменений (опционально)
echo "Docker успешно установлен. Для применения изменений перезагрузите систему."