"""
ASGI config for endoreg_db_api project.

It exposes the ASGI callable as a module-level variable named ``application``.

For more information on this file, see
https://docs.djangoproject.com/en/5.1/howto/deployment/asgi/
"""

import os

from django.core.asgi import get_asgi_application
from django.core.wsgi import get_wsgi_application
from django.urls import re_path
from channels.routing import ProtocolTypeRouter, URLRouter
from asgiref.wsgi import WsgiToAsgi
from whitenoise import WhiteNoise

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'endoreg_db_api.settings_prod')

asgi_application = get_asgi_application()

wsgi_application = get_wsgi_application()

staticfiles_dir = os.path.join(
    os.path.dirname(
        os.path.dirname(
            os.path.abspath(__file__)
        )
    ), 
    'staticfiles'
)

print(staticfiles_dir)
whitenoise_application = WhiteNoise(wsgi_application, root=staticfiles_dir)
wsgi_asgi_application = WsgiToAsgi(wsgi_application)

application = ProtocolTypeRouter({
    "http": URLRouter([
        re_path(r"^static/", wsgi_asgi_application),  # Serve static files using the WhiteNoise WSGI app
        re_path(r"", asgi_application),  # Serve everything else with ASGI
    ]),
})
