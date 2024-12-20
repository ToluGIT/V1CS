# Using latest tag (vulnerability: no version pinning)
FROM ubuntu:latest

# Running as root (vulnerability: privileged container)
USER root

# Installing packages without versions and leaving package lists
# (vulnerabilities: no version pinning, larger attack surface, cached package lists)
RUN apt-get update && \
    apt-get install -y \
    curl \
    wget \
    netcat-openbsd \
    nmap \
    python3 \
    python3-pip \
    openssh-server \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Installing outdated packages and adding an insecure repository
# (vulnerability: potential malicious packages)
RUN curl -fsSL https://deb.nodesource.com/setup_14.x | bash - && \
    apt-get update && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Download EICAR test file (simulated malware)
RUN curl -OL https://secure.eicar.org/eicarcom2.zip

# Creating world-writeable directories
# (vulnerability: anyone can modify contents)
RUN mkdir /app && chmod 777 /app
WORKDIR /app

# Copy all files including potential secrets
# (vulnerability: might include .git, .env, etc.)
COPY . .

# Exposing multiple ports
# (vulnerability: unnecessary exposure)
EXPOSE 22 80 443 3306 5432 27017

# Create SSH directory and generate keys
RUN mkdir /run/sshd && \
    ssh-keygen -A && \
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config

# Running multiple services in foreground
# (vulnerability: violates container best practices)
CMD service ssh start && \
    python3 -m http.server 80
