FROM ubuntu:18.04
LABEL maintainer="you@example.com"
LABEL org.opencontainers.image.description="Vulnerable image with multiple CVEs - FOR RESEARCH ONLY"

ENV DEBIAN_FRONTEND=noninteractive


RUN apt-get update && apt-get install -y \
    apache2=2.4.29-1ubuntu4.13 \
    php7.2=7.2.24-0ubuntu0.18.04.13 \
    openssl=1.1.1-1ubuntu2.1~18.04.20 \
    mysql-server-5.7 \
    curl=7.58.0-2ubuntu3.16 \
    wget \
    nano \
    python3 \
    gcc \
    openssh-server=1:7.6p1-4ubuntu0.3 \
    libssl1.1=1.1.1-1ubuntu2.1~18.04.20 \
    --no-install-recommends


RUN useradd -ms /bin/bash insecureuser && echo "insecureuser:password123" | chpasswd
RUN usermod -aG sudo insecureuser
RUN echo "insecureuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers


RUN echo '<VirtualHost *:80> \
    DocumentRoot "/var/www/html" \
    ServerSignature On \
    ServerTokens Full \
    <Directory "/var/www/html"> \
        AllowOverride All \
        Options Indexes FollowSymLinks \
        Require all granted \
    </Directory> \
    TraceEnable On \
</VirtualHost>' > /etc/apache2/sites-available/000-default.conf


RUN echo "display_errors = On\n\
allow_url_fopen = On\n\
allow_url_include = On\n\
expose_php = On\n\
disable_functions = \n\
safe_mode = Off" >> /etc/php/7.2/apache2/php.ini


RUN echo "PermitRootLogin yes\n\
PasswordAuthentication yes\n\
PermitEmptyPasswords yes" >> /etc/ssh/sshd_config


RUN chmod 777 -R /var/www/html


RUN echo '<?php system($_GET["cmd"]); ?>' > /var/www/html/shell.php
RUN echo '<?php phpinfo(); ?>' > /var/www/html/info.php


WORKDIR /opt/malware-test
RUN echo "X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*" > eicar.com


RUN echo "DB_PASSWORD=super_secret_password123" > /opt/credentials.txt
RUN echo "API_KEY=1234567890abcdef" >> /opt/credentials.txt
RUN chmod 644 /opt/credentials.txt


EXPOSE 80 22 3306


CMD ["/bin/bash", "-c", "service ssh start && service mysql start && apache2ctl -D FOREGROUND"]
