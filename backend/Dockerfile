FROM python:3.11-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Set work directory
WORKDIR /app

# Install system dependencies required for psycopg2 and other packages
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Install python dependencies
COPY requirements.txt .
RUN pip install --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

# Copy the backend project (from backend context into /app)
# Assuming docker build context is the 'backend' folder
COPY . /app

# Expose port (Railway will set PORT env var, but 8080 is a good default fallback)
EXPOSE 8080

# Command to run the application using python
CMD ["python", "main.py"]
