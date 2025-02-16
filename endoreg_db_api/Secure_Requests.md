For secure requests, we need to check if the user accessing the api endpoint registered in endoreg_db/views is authenticated.

A recommended approach here is rest_framework_simplejwt



To implement, please follow these steps

Below is a to‑do list outlining the steps to implement a view that returns the authenticated user’s data (and later you can swap in Keycloak‑issued tokens):
1. Choose Your Authentication Method

    Now: Implement token‑based authentication (e.g. using djangorestframework‑jwt or simplejwt) so your API endpoints require a valid token.
    Future: Since Keycloak issues JWTs, you can later update the backend to verify Keycloak tokens—either by adjusting your JWT settings or by adding a custom authentication class.

Reference: DRF Authentication Guide
2. Configure Your REST Framework Settings

    In your backend settings (e.g. in endoreg_db_api/settings.py), uncomment or add a REST_FRAMEWORK section:

    REST_FRAMEWORK = {
        'DEFAULT_AUTHENTICATION_CLASSES': [
            # For token-based auth (currently):
            'rest_framework_simplejwt.authentication.JWTAuthentication',
            # You can also include SessionAuthentication if needed:
            'rest_framework.authentication.SessionAuthentication',
        ],
        'DEFAULT_PERMISSION_CLASSES': [
            'rest_framework.permissions.IsAuthenticated',
        ],
    }

    This setting ensures that only authenticated users (i.e. those with valid tokens) can access endpoints that require it.

3. Create a Serializer for the User Model

    Define a serializer that returns the fields you want to expose (e.g. username, email). For example:

    # serializers.py
    from django.contrib.auth import get_user_model
    from rest_framework import serializers

    User = get_user_model()

    class UserSerializer(serializers.ModelSerializer):
        class Meta:
            model = User
            fields = ['id', 'username', 'email']

4. Implement an Authenticated User View

    Create an API view that returns the currently authenticated user’s data:

    # views.py
    from rest_framework.views import APIView
    from rest_framework.response import Response
    from rest_framework.permissions import IsAuthenticated
    from .serializers import UserSerializer

    class CurrentUserView(APIView):
        permission_classes = [IsAuthenticated]

        def get(self, request):
            serializer = UserSerializer(request.user)
            return Response(serializer.data)

    This view requires a valid token; if a token isn’t provided or is invalid, DRF will return a 401 Unauthorized response.

5. Wire Up the URL

    Add a URL pattern for your authenticated user view in your URL configuration (e.g. in endoreg_db_api/urls.py):

    from django.urls import path
    from .views import CurrentUserView

    urlpatterns = [
        # ... other url patterns ...
        path('api/current-user/', CurrentUserView.as_view(), name='current_user'),
    ]

6. Test the Endpoint

    Use a client (curl, Postman, or your frontend) to test the endpoint. For example, with curl:

    curl -X GET http://127.0.0.1:8000/api/current-user/ \
         -H "Authorization: Bearer <your_token_here>"

    Verify that the response contains the authenticated user’s data. If not, check your token issuance and REST framework settings.

7. Prepare for Future Keycloak Integration

    When your frontend switches to using Keycloak, it will obtain a JWT token that you can validate on the backend.
    You may only need to update your JWT settings (such as issuer, audience, and public key configuration) or write a custom authentication class that uses Keycloak’s token introspection endpoint.
    It’s also possible to support multiple authentication classes simultaneously (e.g. listing both your current JWT authentication class and a future Keycloak‑specific class).

8. Logging and Debugging

    Enable DEBUG mode and add detailed logging (as already set in your settings) so you can monitor authentication attempts.
    Use tools (like Postman) to verify that the correct headers (Authorization, etc.) are being sent by the frontend.