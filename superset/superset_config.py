import os

print("Cargando superset_config.py...") 

# Configuración básica de la clave secreta
SECRET_KEY = 'g4lHu3r+FPvNQzAia90dVKYzPlVURgR8XNw4K+EK3W2JAVtKsF5HsZps'  # Reemplaza con la clave generada

CACHE_CONFIG = {
    "CACHE_TYPE": "RedisCache",
    "CACHE_DEFAULT_TIMEOUT": 300,
    "CACHE_KEY_PREFIX": "superset_",
    "CACHE_REDIS_URL": "redis://redis:6379/0"
}

# Configuración de la base de datos (si estás utilizando SQLite o MySQL, por ejemplo)
SQLALCHEMY_DATABASE_URI = 'sqlite:////app/superset_home/superset.db'  # Si usas SQLite, cambia esto si usas otra base de datos
SQLALCHEMY_TRACK_MODIFICATIONS = False  # Deshabilitar seguimiento de modificaciones

# Configurar los recursos de memoria de los workers
SUPERSET_WORKERS = 4  # Número de workers para manejar las solicitudes

# Configuración para habilitar o deshabilitar el modo de depuración
DEBUG = True  # Desactívalo en producción

# Configuración del correo electrónico (para notificaciones)
EMAIL_NOTIFICATIONS = True
MAIL_DEFAULT_SENDER = 'noreply@example.com'
MAIL_SERVER = 'smtp.example.com'
MAIL_PORT = 587
MAIL_USE_TLS = True
MAIL_USERNAME = 'tu_correo@example.com'
MAIL_PASSWORD = 'tu_contraseña'

# Otros parámetros de configuración de Superset
FEATURE_FLAGS = {
    "ALERT_REPORTS": True,
    "THUMBNAILS": True,
}
