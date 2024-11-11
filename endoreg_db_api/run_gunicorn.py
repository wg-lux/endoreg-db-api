# run_gunicorn.py

import sys
from gunicorn.app.wsgiapp import run

if __name__ == "__main__":
    # Add Gunicorn arguments, for example:
    sys.argv.extend([
        'gunicorn',
        'endoreg_db_api.wsgi:application',
        '--bind', '0.0.0.0:8000',  # Example of binding to all IPs on port 8000
        '--workers', '3',  # Specify number of worker processes
    ])
    run()
