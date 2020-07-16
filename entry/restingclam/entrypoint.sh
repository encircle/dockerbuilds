echo "Starting freshclam"
freshclam -d &

echo "Starting clamd"
clamd &

echo "Starting gunicorn"
gunicorn --bind=unix:/var/run/gunicorn/gunicorn.sock --workers=3 --threads=3 rest:app
