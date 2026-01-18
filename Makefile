# NPL + React Replit Template Makefile
# Alternative to workflow buttons for those who prefer make

.PHONY: help setup setup-quick env install check-setup deploy deploy-npl deploy-npl-clean deploy-frontend client users keycloak add-redirect run build clean login preflight lsp bootstrap

# Default target
help:
	@echo "NPL + React Replit Template"
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "Setup targets:"
	@echo "  setup      - Full interactive setup (includes login prompt)"
	@echo "  setup-quick - Setup without login (use if already logged in)"
	@echo "  env        - Generate .env from NPL_TENANT and NPL_APP"
	@echo "  install    - Install NPL CLI and npm dependencies"
	@echo "  deploy     - Deploy both NPL and frontend to Noumena Cloud"
	@echo "  deploy-npl - Deploy NPL protocols to Noumena Cloud"
	@echo "  deploy-npl-clean - Clear and deploy NPL (use when changing protocols)"
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
	@echo "  add-redirect URL=<url> - Add custom redirect URI for external hosting"
	@echo "  lsp        - Install NPL Language Server"
	@echo "  bootstrap  - Create initial protocol instances (customize scripts/bootstrap.sh first)"
	@echo ""
	@echo "Configuration (edit noumena.config file):"
	@echo "  NPL_TENANT          - Your Noumena Cloud tenant"
	@echo "  NPL_APP             - Your Noumena Cloud app name"
	@echo ""
	@echo "Secrets (add in Replit Secrets tab, only for user provisioning):"
	@echo "  KEYCLOAK_ADMIN_USER     - Keycloak admin username"
	@echo "  KEYCLOAK_ADMIN_PASSWORD - Keycloak admin password"

# Full setup (interactive - will prompt for login and optional steps)
setup: env install lsp
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "📦 Dependencies installed! Now you need to login."
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "🔐 Opening browser for Noumena Cloud login..."
	@export PATH="$$HOME/.npl/bin:$$PATH" && npl cloud login
	@echo ""
	@echo "✅ Logged in! Continuing with deployment..."
	@$(MAKE) deploy-npl client
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "✅ Core setup complete!"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "📋 Optional configuration steps:"
	@echo ""
	@read -p "🔑 Configure Keycloak for Replit? (REQUIRED for Replit) [Y/n]: " keycloak_choice; \
	if [ "$$keycloak_choice" = "n" ] || [ "$$keycloak_choice" = "N" ]; then \
		echo "   ⚠️  Skipped. Run 'make keycloak' if login fails!"; \
	else \
		$(MAKE) keycloak; \
	fi
	@echo ""
	@read -p "👥 Provision test users (alice, bob, etc.)? [y/N]: " users_choice; \
	if [ "$$users_choice" = "y" ] || [ "$$users_choice" = "Y" ]; then \
		$(MAKE) users; \
	else \
		echo "   Skipped. Run 'make users' later if needed."; \
	fi
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🎉 Setup complete! Ready to develop."
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "Start the frontend with:"
	@echo "  make run"
	@echo ""
	@echo "Or click the 'Run' button in Replit."

# Quick setup (assumes already logged in)
setup-quick: env install lsp deploy-npl client
	@echo ""
	@echo "✅ Setup complete! Use 'make run' to start the frontend."

# Generate environment configuration
env:
	@./scripts/setup-env.sh

# Install dependencies
install:
	@./scripts/install-npl-cli.sh
	@cd frontend && npm install

# Check that setup has been run
check-setup:
	@if [ ! -f .env ]; then \
		echo ""; \
		echo "❌ Error: .env file not found!"; \
		echo ""; \
		echo "You must run 'make setup' first to configure the environment."; \
		echo "This creates the .env file with Keycloak and NPL Engine URLs."; \
		echo ""; \
		exit 1; \
	fi

# Deploy both NPL and frontend
deploy: check-setup deploy-npl build deploy-frontend
	@echo ""
	@echo "✅ Full deployment complete!"

# Deploy NPL to Noumena Cloud
deploy-npl: check-setup
	@./scripts/deploy-npl.sh
	@echo ""
	@echo "💡 Don't forget: run 'make client' to regenerate TypeScript types!"

# Deploy NPL with clear (recommended when changing protocols)
deploy-npl-clean: check-setup
	@echo "🧹 Clearing existing protocols..."
	@export PATH="$$HOME/.npl/bin:$$PATH" && npl cloud clear --tenant $$NPL_TENANT --app $$NPL_APP
	@./scripts/deploy-npl.sh
	@echo ""
	@echo "💡 Don't forget: run 'make client' to regenerate TypeScript types!"

# Generate TypeScript client
client:
	@./scripts/generate-client.sh

# Provision seed users
users:
	@./scripts/provision-users.sh

# Configure Keycloak client (add redirect URIs)
keycloak:
	@./scripts/configure-keycloak-client.sh

# Add custom redirect URI for external hosting (e.g., Replit published app)
# Usage: make add-redirect URL=https://your-app.replit.app
add-redirect:
ifndef URL
	@echo "Usage: make add-redirect URL=https://your-app.replit.app"
	@exit 1
endif
	@./scripts/add-redirect-uri.sh $(URL)

# Start development server
run: check-setup
	@cd frontend && npm run dev

# Build for production
build: check-setup
	@echo "🏗️  Building frontend for production (VITE_DEV_MODE=false)..."
	@cd frontend && VITE_DEV_MODE=false npm run build

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

# Install NPL Language Server for syntax highlighting
lsp:
	@./scripts/install-language-server.sh

# Login to Noumena Cloud
login:
	@echo "🔐 Logging in to Noumena Cloud..."
	@echo "   This will open a browser window for authentication."
	@export PATH="$$HOME/.npl/bin:$$PATH" && npl cloud login

# Run pre-flight checks
preflight:
	@./scripts/preflight-check.sh

# Bootstrap initial data (customize scripts/bootstrap.sh first)
bootstrap: check-setup
	@./scripts/bootstrap.sh
