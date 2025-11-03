# Multi-stage build for sleepless-agent
FROM node:20-slim AS node-base

# Install Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code

# Python stage
FROM python:3.11-slim

# Install git and other system dependencies
RUN apt-get update && apt-get install -y \
    git \
    && rm -rf /var/lib/apt/lists/*

# Copy Node and Claude Code CLI from node-base stage
COPY --from=node-base /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=node-base /usr/local/bin/node /usr/local/bin/node
COPY --from=node-base /usr/local/bin/npm /usr/local/bin/npm
COPY --from=node-base /usr/local/bin/npx /usr/local/bin/npx

# Create symlink for claude command
RUN ln -s /usr/local/lib/node_modules/@anthropic-ai/claude-code/bin/claude /usr/local/bin/claude

# Set working directory
WORKDIR /app

# Copy project files
COPY pyproject.toml ./
COPY src/ ./src/

# Install Python dependencies
RUN pip install --no-cache-dir -e .

# Create necessary directories with proper permissions
RUN mkdir -p /app/workspace/data \
    /app/workspace/tasks \
    /app/workspace/shared \
    /app/workspace/projects \
    /app/workspace/trash \
    && chmod -R 755 /app/workspace

# Set environment variables for paths
ENV SLEEPLESS_WORKSPACE_ROOT=/app/workspace
ENV SLEEPLESS_DB_PATH=/app/workspace/data/tasks.db
ENV SLEEPLESS_RESULTS_PATH=/app/workspace/data/results

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import sys; from pathlib import Path; sys.exit(0 if Path('/app/workspace/data/tasks.db').exists() else 1)"

# Run daemon by default
CMD ["sle", "daemon"]