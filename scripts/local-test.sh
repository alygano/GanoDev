#!/bin/bash

# Script de test local pour simuler la pipeline CI/CD
set -e

echo "🚀 Starting local CI/CD pipeline simulation..."

# Couleurs pour la sortie
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les étapes
step() {
    echo -e "${BLUE}===================================${NC}"
    echo -e "${BLUE}🔹 $1${NC}"
    echo -e "${BLUE}===================================${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# Vérifier si Docker est installé
if ! command -v docker &> /dev/null; then
    error "Docker n'est pas installé"
    exit 1
fi

# Vérifier si Python est installé
if ! command -v python3 &> /dev/null; then
    error "Python 3 n'est pas installé"
    exit 1
fi

# 1. Code Quality & Tests
step "Code Quality & Tests"

echo "📦 Installing dependencies..."
python3 -m pip install --upgrade pip
pip install -r requirements-dev.txt

echo "🎨 Running Black (code formatting)..."
if black --check --diff .; then
    success "Code formatting is correct"
else
    warning "Code formatting issues found - run 'black .' to fix"
fi

echo "📋 Running isort (import sorting)..."
if isort --check-only --diff .; then
    success "Import sorting is correct"
else
    warning "Import sorting issues found - run 'isort .' to fix"
fi

echo "🔍 Running flake8 (linting)..."
if flake8 .; then
    success "Linting passed"
else
    warning "Linting issues found"
fi

echo "🧪 Running tests with coverage..."
if pytest src/tests/ -v --cov=src --cov-report=term-missing --cov-fail-under=80; then
    success "Tests passed with sufficient coverage"
else
    error "Tests failed or coverage too low"
fi

# 2. Security Scanning
step "Security Scanning"

echo "🔍 Running Bandit (Python security)..."
if bandit -r src/ -f json -o bandit-report.json; then
    success "No security issues found by Bandit"
else
    warning "Security issues found by Bandit - check bandit-report.json"
fi

echo "🛡️ Running Safety (dependency vulnerabilities)..."
if safety check --json --output safety-report.json; then
    success "No vulnerable dependencies found"
else
    warning "Vulnerable dependencies found - check safety-report.json"
fi

# 3. Docker Build & Security
step "Docker Build & Security"

echo "🐳 Building Docker image..."
if docker build -t flask-api:test .; then
    success "Docker image built successfully"
else
    error "Docker build failed"
    exit 1
fi

echo "🔍 Running Trivy security scan (if available)..."
if command -v trivy &> /dev/null; then
    trivy image --severity HIGH,CRITICAL flask-api:test
    success "Trivy scan completed"
else
    warning "Trivy not installed - skipping container security scan"
    echo "Install with: curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin"
fi

# 4. Integration Test
step "Integration Test"

echo "🚀 Starting Docker Compose services..."
docker-compose up -d

echo "⏳ Waiting for services to be ready..."
sleep 10

echo "🧪 Running integration tests..."
if curl -f http://localhost:5004/ping; then
    success "API is responding"
else
    error "API is not responding"
    docker-compose logs api
fi

echo "🛑 Stopping Docker Compose services..."
docker-compose down

# 5. Cleanup
step "Cleanup"

echo "🧹 Cleaning up..."
docker image prune -f
success "Cleanup completed"

echo ""
success "🎉 Local pipeline simulation completed successfully!"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Fix any warnings shown above"
echo "2. Commit and push your changes"
echo "3. Check GitHub Actions for the full CI/CD pipeline"
echo "" 