# NPL + React Replit Template Makefile
# Alternative to workflow buttons for those who prefer make

.PHONY: help setup env install deploy deploy-npl deploy-frontend client users keycloak run build clean login preflight

# Default target
help:
	@echo "NPL + React Replit Template"
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "Setup targets:"
	@echo "  setup      - Full setup (env + install + deploy-npl + client)"
	@echo "  env        - Generate .env from NPL_TENANT and NPL_APP"
	@echo "  install    - Install NPL CLI and npm dependencies"
	@echo "  deploy     - Deploy both NPL and frontend to Noumena Cloud"
	@echo "  deploy-npl - Deploy NPL protocols to Noumena Cloud"
	@echo "  deploy-frontend - Deploy frontend to Noumena Cloud"
	@echo "  client     - Generate TypeScript API client from OpenAPI"
	@echo "  users      - Provision seed users in Keycloak"
	@echo "  keycloak   - Configure Keycloak client (redirect URIs)"
	@echo ""
	@echo "Development targets:"
	@echo "  run        - Start the development server"
	@echo "  build      - Build for production"
	@echo "  check      - Validate NPL code"
	@echo "  test       - Run NPL tests"
	@echo ""
	@echo "Utility targets:"
	@echo "  login      - Login to Noumena Cloud"
	@echo "  preflight  - Run pre-flight checks"
	@echo ""
	@echo "Required environment variables:"
	@echo "  NPL_TENANT          - Your Noumena Cloud tenant"
	@echo "  NPL_APP        - Your Noumena Cloud app name"
	@echo ""
	@echo "Optional (for user provisioning):"
	@echo "  KEYCLOAK_ADMIN_USER     - Keycloak admin username"
	@echo "  KEYCLOAK_ADMIN_PASSWORD - Keycloak admin password"

# Full setup
setup: env install deploy-npl client
	@echo ""
	@echo "✅ Setup complete! Use the '▶️ Start Dev Server' workflow or click 'Run' button."

# Generate environment configuration
env:
	@./scripts/setup-env.sh

# Install dependencies
install:
	@./scripts/install-npl-cli.sh
	@cd frontend && npm install

# Deploy both NPL and frontend
deploy: deploy-npl build deploy-frontend
	@echo ""
	@echo "✅ Full deployment complete!"

# Deploy NPL to Noumena Cloud
deploy-npl:
	@./scripts/deploy-npl.sh

# Generate TypeScript client
client:
	@./scripts/generate-client.sh

# Provision seed users
users:
	@./scripts/provision-users.sh

# Configure Keycloak client (add redirect URIs)
keycloak:
	@./scripts/configure-keycloak-client.sh

# Start development server
run:
	@cd frontend && npm run dev

# Build for production
build:
	@cd frontend && npm run build

# Deploy frontend to Noumena Cloud
deploy-frontend:
	@./scripts/deploy-frontend.sh

# Validate NPL code
check:
	@export PATH="$$HOME/.npl/bin:$$PATH" && npl check --source-dir ./npl/src/main

# Run NPL tests
test:
	@export PATH="$$HOME/.npl/bin:$$PATH" && npl test --test-source-dir ./npl/src

# Clean generated files
clean:
	@rm -rf frontend/node_modules frontend/dist frontend/src/generated .env
	@echo "Cleaned generated files"

# Login to Noumena Cloud
login:
	@echo "🔐 Logging in to Noumena Cloud..."
	@echo "   This will open a browser window for authentication."
	@export PATH="$$HOME/.npl/bin:$$PATH" && npl cloud login

# Run pre-flight checks
preflight:
	@./scripts/preflight-check.sh
