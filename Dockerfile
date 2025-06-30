# ================================
# Stage 1: Build stage
# ================================
FROM python:3.10.3-slim-buster as builder

# Métadonnées
LABEL maintainer="your-email@example.com"
LABEL version="1.0"
LABEL description="Flask API with PostgreSQL"

# Variables d'environnement pour le build
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Créer un utilisateur non-root
RUN groupadd -r appgroup && useradd -r -g appgroup appuser

# Installer les dépendances système nécessaires pour le build
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        libpq-dev \
        gcc \
        netcat \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Créer et définir le répertoire de travail
WORKDIR /usr/src/app

# Installer les dépendances Python
COPY requirements.txt .
RUN pip install --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt \
    && pip install psycopg2-binary --no-binary psycopg2-binary

# ================================
# Stage 2: Production stage
# ================================
FROM python:3.10.3-slim-buster as production

# Variables d'environnement pour la production
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    FLASK_ENV=production \
    PATH="/home/appuser/.local/bin:$PATH"

# Installer seulement les dépendances runtime nécessaires
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libpq5 \
        netcat \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Créer un utilisateur non-root
RUN groupadd -r appgroup && useradd -r -g appgroup appuser

# Créer les répertoires nécessaires
WORKDIR /usr/src/app

# Copier les dépendances Python installées depuis le builder
COPY --from=builder /usr/local/lib/python3.10/site-packages /usr/local/lib/python3.10/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copier le code de l'application
COPY --chown=appuser:appgroup . .

# Copier et rendre exécutable le script d'entrée
COPY --chown=appuser:appgroup entrypoint.sh .
RUN chmod +x /usr/src/app/entrypoint.sh

# Changer vers l'utilisateur non-root
USER appuser

# Exposer le port
EXPOSE 5000

# Healthcheck
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD netcat -z localhost 5000 || exit 1

# Point d'entrée
ENTRYPOINT ["/usr/src/app/entrypoint.sh"]



