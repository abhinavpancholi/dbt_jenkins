# Use Python 3.11 as base image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements files
COPY backend/requirements.txt backend/requirements-python311.txt ./

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Install frontend dependencies
WORKDIR /app/frontend
RUN npm install

# Build frontend
RUN npm run build

# Set environment variables
ENV DBT_PROJECTS_DIR=/app/pk
ENV API_HOST=0.0.0.0
ENV API_PORT=8085

# Expose port
EXPOSE 8085

# Run the application
CMD ["python", "backend/run.py", "--host", "0.0.0.0", "--port", "8085"] 