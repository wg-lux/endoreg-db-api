#!/bin/sh
exec gunicorn endoreg_db_api.endoreg_db_api.wsgi:application --bind 0.0.0.0:8000
