from django.http import HttpResponse


def home(request):
    return HttpResponse("Hello, world. This is EndoReg DB API.")
