FROM python:3.11-slim

WORKDIR /app

# Copy requirements first so Docker caches this layer
# (only re-installs packages if requirements.txt changes)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the Flask app
COPY app.py .

# 1. Run init_db() to create the tasks table in MySQL
# 2. Start gunicorn with 2 workers to serve the app
CMD ["sh", "-c", "python -c 'from app import init_db; init_db()' && gunicorn --bind 0.0.0.0:5000 --workers 2 --timeout 60 app:app"]