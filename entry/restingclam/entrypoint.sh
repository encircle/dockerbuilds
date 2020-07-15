echo "Starting freshclam"
freshclam -d &
echo "Starting clamd"
clamd &
echo "Starting gunicorn"
gunicorn --bind=0.0.0.0:10101 rest:app
