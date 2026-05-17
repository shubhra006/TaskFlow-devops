from flask import Flask, request, jsonify
from flask_cors import CORS
import pymysql
import os
import time

app = Flask(__name__)
CORS(app)

# DB settings come from environment variables set in docker-compose.yml
DB_CONFIG = {
    'host':        os.getenv('MYSQL_HOST',     'db'),
    'user':        os.getenv('MYSQL_USER',     'root'),
    'password':    os.getenv('MYSQL_PASSWORD', 'Root@123'),
    'database':    os.getenv('MYSQL_DB',       'taskflow'),
    'cursorclass': pymysql.cursors.DictCursor,
    'autocommit':  True,
}


def get_db():
    """Open a new connection. Called at the start of every request."""
    return pymysql.connect(**DB_CONFIG)


def init_db():
    """
    Create the tasks table if it doesn't exist.
    Retries 10 times with 5s gaps — MySQL takes ~20-30s to start
    inside Docker before it accepts connections.
    """
    print("Waiting for MySQL to be ready...")
    for attempt in range(10):
        try:
            conn = get_db()
            with conn.cursor() as cur:
                cur.execute("""
                    CREATE TABLE IF NOT EXISTS tasks (
                        id    INT AUTO_INCREMENT PRIMARY KEY,
                        title VARCHAR(255) NOT NULL,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                """)
            conn.close()
            print("✅ Database is ready. Table created (or already exists).")
            return
        except Exception as e:
            print(f"  Attempt {attempt + 1}/10 — DB not ready: {e}")
            time.sleep(5)
    raise RuntimeError("❌ Could not connect to MySQL after 10 attempts.")


# ── Health check — Jenkins and load balancers use this ────────────
@app.route('/health')
def health():
    return jsonify({"status": "ok"})


# ── Get all tasks ─────────────────────────────────────────────────
@app.route('/tasks', methods=['GET'])
def get_tasks():
    conn = get_db()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT id, title FROM tasks ORDER BY id DESC")
            tasks = cur.fetchall()
        return jsonify(tasks)
    finally:
        conn.close()  # Always close, even if an error occurs


# ── Add a task ────────────────────────────────────────────────────
@app.route('/tasks', methods=['POST'])
def add_task():
    data = request.get_json()
    if not data or not data.get('title'):
        return jsonify({"error": "title field is required"}), 400
    conn = get_db()
    try:
        with conn.cursor() as cur:
            cur.execute("INSERT INTO tasks (title) VALUES (%s)", (data['title'],))
        return jsonify({"status": "added"}), 201
    finally:
        conn.close()


# ── Delete a task ─────────────────────────────────────────────────
@app.route('/tasks/<int:tid>', methods=['DELETE'])
def delete_task(tid):
    conn = get_db()
    try:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM tasks WHERE id = %s", (tid,))
        return jsonify({"status": "deleted"})
    finally:
        conn.close()


if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=5000, debug=False)