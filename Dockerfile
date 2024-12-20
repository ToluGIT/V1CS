FROM debian:sid-slim
LABEL maintainer="you@example.com"
LABEL org.opencontainers.image.description="Vulnerable image with multiple CVEs - FOR RESEARCH ONLY"

ENV DEBIAN_FRONTEND=noninteractive

# Install packages without version pinning to get potentially vulnerable versions
RUN apt-get update && apt-get install -y \
    apache2 \
    php \
    mariadb-client \
    curl \
    wget \
    nano \
    python3 \
    gcc \
    openssh-server \
    php-mysql \
    libapache2-mod-php \
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
        Options Indexes FollowSymLinks MultiViews \
        Require all granted \
    </Directory> \
    TraceEnable On \
</VirtualHost>' > /etc/apache2/sites-available/000-default.conf

# Vulnerable PHP configuration
RUN echo "display_errors = On\n\
allow_url_fopen = On\n\
allow_url_include = On\n\
expose_php = On\n\
disable_functions = \n\
allow_url_include = On\n\
memory_limit = -1\n\
max_execution_time = 0" >> /etc/php/*/apache2/php.ini

# Set up SSH with weak configuration
RUN echo "PermitRootLogin yes\n\
PasswordAuthentication yes\n\
PermitEmptyPasswords yes\n\
StrictModes no\n\
X11Forwarding yes" >> /etc/ssh/sshd_config

# Make directories world-writable
RUN chmod 777 -R /var/www/html /etc/apache2 /etc/php

# Create vulnerable web application files
RUN echo '<?php if(isset($_GET["cmd"])) { system($_GET["cmd"]); } ?>' > /var/www/html/shell.php
RUN echo '<?php phpinfo(); ?>' > /var/www/html/info.php
RUN echo '<?php include($_GET["file"]); ?>' > /var/www/html/lfi.php

# Add EICAR test file and fake sensitive data
WORKDIR /opt/malware-test
RUN echo "X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*" > eicar.com
RUN echo "root:password123" >> /etc/shadow
RUN echo "DB_ROOT_PASSWORD=admin123\nDB_USER=admin\nDB_PASS=password123" > /opt/credentials.txt
RUN chmod 644 /etc/shadow /opt/credentials.txt

# Expose vulnerable ports
EXPOSE 80 22 3306 445 139

# Start services with vulnerable configurations
CMD ["/bin/bash", "-c", "service ssh start && apache2ctl -D FOREGROUND"]
