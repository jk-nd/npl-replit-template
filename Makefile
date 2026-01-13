# NPL + React Replit Template Makefile
# Alternative to workflow buttons for those who prefer make

.PHONY: help setup env install deploy client users keycloak run build clean

# Default target
help:
	@echo "NPL + React Replit Template"
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "Setup targets:"
	@echo "  setup      - Full setup (env + install + deploy + client)"
	@echo "  env        - Generate .env from NPL_TENANT and NPL_APP_NAME"
	@echo "  install    - Install NPL CLI and npm dependencies"
	@echo "  deploy     - Deploy NPL protocols to Noumena Cloud"
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
	@echo "Required environment variables:"
	@echo "  NPL_TENANT          - Your Noumena Cloud tenant"
	@echo "  NPL_APP_NAME        - Your Noumena Cloud app name"
	@echo ""
	@echo "Optional (for user provisioning):"
	@echo "  KEYCLOAK_ADMIN_USER     - Keycloak admin username"
	@echo "  KEYCLOAK_ADMIN_PASSWORD - Keycloak admin password"

# Full setup
setup: env install deploy client
	@echo ""
	@echo "✅ Setup complete! Run 'make run' to start the frontend."

# Generate environment configuration
env:
	@./scripts/setup-env.sh

# Install dependencies
install:
	@./scripts/install-npl-cli.sh
	@npm install

# Deploy NPL to Noumena Cloud
deploy:
	@./scripts/deploy-to-cloud.sh

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
	@npm run dev

# Build for production
build:
	@npm run build

# Validate NPL code
check:
	@export PATH="$$HOME/.npl/bin:$$PATH" && npl check --source-dir ./npl/src/main

# Run NPL tests
test:
	@export PATH="$$HOME/.npl/bin:$$PATH" && npl test --test-source-dir ./npl/src

# Clean generated files
clean:
	@rm -rf node_modules dist src/generated .env
	@echo "Cleaned generated files"
