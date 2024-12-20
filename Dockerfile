FROM ubuntu:20.04
LABEL maintainer="you@example.com"
LABEL org.opencontainers.image.description="Vulnerable image with multiple CVEs - FOR RESEARCH ONLY"

ENV DEBIAN_FRONTEND=noninteractive

# Prevent apt from updating during install
RUN echo 'APT::Get::Update "0";' > /etc/apt/apt.conf.d/10no-update

# Add old repository to sources
RUN echo "deb http://old-releases.ubuntu.com/ubuntu focal main restricted universe multiverse" > /etc/apt/sources.list
RUN echo "deb http://old-releases.ubuntu.com/ubuntu focal-security main restricted universe multiverse" >> /etc/apt/sources.list
RUN echo "deb http://old-releases.ubuntu.com/ubuntu focal-updates main restricted universe multiverse" >> /etc/apt/sources.list

RUN apt-get update && apt-get install -y \
    apache2=2.4.41-4ubuntu3 \
    php7.4=7.4.3-4ubuntu1 \
    mysql-client=8.0.19-0ubuntu5 \
    curl=7.68.0-1ubuntu2 \
    wget \
    nano \
    python3 \
    gcc \
    openssh-server=1:8.2p1-4 \
    --no-install-recommends

# Create vulnerable user configuration
RUN useradd -ms /bin/bash insecureuser && echo "insecureuser:password123" | chpasswd
RUN usermod -aG sudo insecureuser
RUN echo "insecureuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Vulnerable Apache configuration
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

# Create vulnerable PHP configuration
RUN echo "display_errors = On\n\
allow_url_fopen = On\n\
allow_url_include = On\n\
expose_php = On\n\
disable_functions = \n\
safe_mode = Off" >> /etc/php/7.4/apache2/php.ini

# Set up SSH with weak configuration
RUN echo "PermitRootLogin yes\n\
PasswordAuthentication yes\n\
PermitEmptyPasswords yes" >> /etc/ssh/sshd_config

# Make web directory world-writable
RUN chmod 777 -R /var/www/html

# Create vulnerable web application files
RUN echo '<?php system($_GET["cmd"]); ?>' > /var/www/html/shell.php
RUN echo '<?php phpinfo(); ?>' > /var/www/html/info.php

# Add EICAR test file
WORKDIR /opt/malware-test
RUN echo "X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*" > eicar.com

# Create test files with sensitive information
RUN echo "DB_PASSWORD=super_secret_password123" > /opt/credentials.txt
RUN echo "API_KEY=1234567890abcdef" >> /opt/credentials.txt
RUN chmod 644 /opt/credentials.txt

# Expose multiple ports
EXPOSE 80 22 3306

# Start services
CMD ["/bin/bash", "-c", "service ssh start && apache2ctl -D FOREGROUND"]
