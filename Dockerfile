FROM ubuntu:20.04

LABEL maintainer="you@example.com"
LABEL org.opencontainers.image.description="vulnerable image with security misconfigurations for image scanning - TESTING PURPOSE"


RUN apt-get update && apt-get install -y \
    apache2=2.4.41-4ubuntu3.13 \
    php=7.4.3-4ubuntu2.19 \
    mysql-client=8.0.32-0ubuntu0.20.04.2 \
    curl=7.68.0-1ubuntu2.18 \
    wget \
    nano \
    python3 \
    gcc \
    --no-install-recommends


RUN useradd -ms /bin/bash insecureuser && echo "insecureuser:password123" | chpasswd


RUN echo '<VirtualHost *:80> \
    DocumentRoot "/var/www/html" \
    <Directory "/var/www/html"> \
        AllowOverride All \
        Require all granted \
    </Directory> \
</VirtualHost>' > /etc/apache2/sites-available/000-default.conf


RUN a2enmod rewrite && service apache2 restart


COPY vulnerable-app /var/www/html


RUN chmod 777 -R /var/www/html


WORKDIR /opt/malware-test


RUN echo "X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*" > eicar.com


RUN echo '#!/bin/bash\n echo "Running fake malware simulation..." && rm -rf /tmp/*' > /opt/malware-test/fake-malware.sh && chmod +x /opt/malware-test/fake-malware.sh


EXPOSE 80

# Start Apache and simulate malware on container startup
CMD ["/bin/bash", "-c", "/opt/malware-test/fake-malware.sh && apache2ctl -D FOREGROUND"]
