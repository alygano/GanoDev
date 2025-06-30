@echo off
:: Script de test local pour simuler la pipeline CI/CD sur Windows
setlocal

echo 🚀 Starting local CI/CD pipeline simulation on Windows...

:: Vérifier si Docker est installé
docker --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker n'est pas installé
    exit /b 1
)

:: Vérifier si Python est installé
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Python n'est pas installé
    exit /b 1
)

echo =================================
echo 🔹 Code Quality ^& Tests
echo =================================

echo 📦 Installing dependencies...
python -m pip install --upgrade pip
pip install -r requirements-dev.txt

echo 🎨 Running Black (code formatting)...
black --check --diff .
if errorlevel 1 (
    echo ⚠️ Code formatting issues found - run 'black .' to fix
) else (
    echo ✅ Code formatting is correct
)

echo 📋 Running isort (import sorting)...
isort --check-only --diff .
if errorlevel 1 (
    echo ⚠️ Import sorting issues found - run 'isort .' to fix
) else (
    echo ✅ Import sorting is correct
)

echo 🔍 Running flake8 (linting)...
flake8 .
if errorlevel 1 (
    echo ⚠️ Linting issues found
) else (
    echo ✅ Linting passed
)

echo 🧪 Running tests with coverage...
pytest src/tests/ -v --cov=src --cov-report=term-missing --cov-fail-under=80
if errorlevel 1 (
    echo ❌ Tests failed or coverage too low
) else (
    echo ✅ Tests passed with sufficient coverage
)

echo =================================
echo 🔹 Security Scanning
echo =================================

echo 🔍 Running Bandit (Python security)...
bandit -r src/ -f json -o bandit-report.json
if errorlevel 1 (
    echo ⚠️ Security issues found by Bandit - check bandit-report.json
) else (
    echo ✅ No security issues found by Bandit
)

echo 🛡️ Running Safety (dependency vulnerabilities)...
safety check --json --output safety-report.json
if errorlevel 1 (
    echo ⚠️ Vulnerable dependencies found - check safety-report.json
) else (
    echo ✅ No vulnerable dependencies found
)

echo =================================
echo 🔹 Docker Build ^& Security
echo =================================

echo 🐳 Building Docker image...
docker build -t flask-api:test .
if errorlevel 1 (
    echo ❌ Docker build failed
    exit /b 1
) else (
    echo ✅ Docker image built successfully
)

echo 🔍 Checking for Trivy...
trivy --version >nul 2>&1
if errorlevel 1 (
    echo ⚠️ Trivy not installed - skipping container security scan
    echo Install from: https://aquasecurity.github.io/trivy/
) else (
    echo Running Trivy security scan...
    trivy image --severity HIGH,CRITICAL flask-api:test
    echo ✅ Trivy scan completed
)

echo =================================
echo 🔹 Integration Test
echo =================================

echo 🚀 Starting Docker Compose services...
docker-compose up -d

echo ⏳ Waiting for services to be ready...
timeout /t 10 /nobreak >nul

echo 🧪 Running integration tests...
curl -f http://localhost:5004/ping
if errorlevel 1 (
    echo ❌ API is not responding
    docker-compose logs api
) else (
    echo ✅ API is responding
)

echo 🛑 Stopping Docker Compose services...
docker-compose down

echo =================================
echo 🔹 Cleanup
echo =================================

echo 🧹 Cleaning up...
docker image prune -f >nul 2>&1
echo ✅ Cleanup completed

echo.
echo ✅ 🎉 Local pipeline simulation completed successfully!
echo.
echo Next steps:
echo 1. Fix any warnings shown above
echo 2. Commit and push your changes
echo 3. Check GitHub Actions for the full CI/CD pipeline
echo.

pause 