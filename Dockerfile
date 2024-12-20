FROM debian:12.1
LABEL maintainer="you@example.com"
LABEL org.opencontainers.image.description="Vulnerable Debian 12.1 image with known CVEs - FOR RESEARCH ONLY"

ENV DEBIAN_FRONTEND=noninteractive

# Install vulnerable packages
RUN apt-get update && apt-get install -y \
    apache2 \
    php8.2 \
    mariadb-client \
    curl \
    wget \
    openssh-server \
    python3 \
    gcc \
    sudo \
    --no-install-recommends

# Create vulnerable user configuration
RUN useradd -ms /bin/bash insecureuser && echo "insecureuser:password123" | chpasswd
RUN usermod -aG sudo insecureuser
RUN echo "insecureuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set up vulnerable Apache configuration
RUN echo '<VirtualHost *:80> \
    DocumentRoot "/var/www/html" \
    ServerSignature On \
    ServerTokens Full \
    <Directory "/var/www/html"> \
        AllowOverride All \
        Options Indexes FollowSymLinks \
        Require all granted \
    </Directory> \
</VirtualHost>' > /etc/apache2/sites-available/000-default.conf

# Create test files for vulnerability scanning
RUN echo '<?php if(isset($_GET["cmd"])) { system($_GET["cmd"]); } ?>' > /var/www/html/shell.php
RUN echo '<?php phpinfo(); ?>' > /var/www/html/info.php

# Set insecure permissions
RUN chmod -R 777 /var/www/html
RUN chmod -R 777 /etc/apache2

# Add EICAR test file
WORKDIR /opt/malware-test
RUN echo "X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*" > eicar.com

EXPOSE 80 22 3306

CMD ["/bin/bash", "-c", "service apache2 start && tail -f /dev/null"]
