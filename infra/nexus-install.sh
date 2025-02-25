#!/bin/bash

# Обновляем пакеты
sudo apt-get update

# Устанавливаем Java 8
sudo apt-get install -y openjdk-8-jdk

# Проверяем установку Java
java -version

# Создаем пользователя для Nexus
sudo useradd -m -U -d /opt/nexus -s /bin/bash nexus
sudo passwd nexus

# Скачиваем Nexus
cd /opt
sudo wget https://download.sonatype.com/nexus/3/latest-unix.tar.gz

# Распаковываем архив
sudo tar -xzf latest-unix.tar.gz

# Переименовываем папку для удобства
sudo mv nexus-* nexus

# Устанавливаем владельца папки
sudo chown -R nexus:nexus /opt/nexus

# Настраиваем Nexus для запуска от пользователя nexus
sudo sed -i 's/#RUN_AS_USER=/RUN_AS_USER=nexus/' /opt/nexus/bin/nexus.rc

# Создаем службу для автоматического запуска Nexus
sudo bash -c 'cat > /etc/systemd/system/nexus.service <<EOF
[Unit]
Description=Sonatype Nexus
After=network.target

[Service]
Type=forking
User=nexus
Group=nexus
ExecStart=/opt/nexus/bin/nexus start
ExecStop=/opt/nexus/bin/nexus stop
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF'

# Перезагружаем systemd и включаем автозапуск Nexus
sudo systemctl daemon-reload
sudo systemctl enable nexus

# Запускаем Nexus
sudo systemctl start nexus

# Проверяем статус службы
sudo systemctl status nexus

echo "Установка завершена. Nexus доступен по адресу http://<IP_вашей_машины>:8081"