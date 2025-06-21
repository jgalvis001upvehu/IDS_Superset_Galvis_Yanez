# Infraestructura de Datos para el Análisis de Personalidad en Twitter

El objetivo general del proyecto es:

El presente proyecto tiene como finalidad el diseño e implementación de una arquitectura de infraestructura de datos que permita la integración, procesamiento y análisis conjunto de datos estáticos y temporales extraídos de Twitter. Para ello, se emplean tecnologías de transmisión y almacenamiento como MQTT, Kafka, Druid, Hive y Superset, con el propósito de habilitar un entorno de visualización de datos capaz de realizar una toma de desiciones basadas en datos. El desarrollo de este proyecto está orientado al estudio de las diferentes herramientas de infraestructura de datos existentes en entornos dockerizados.

## Pipeline - Datos Temporales (tweets.json)

El objetivo de esta parte del proyecto, es construir un pipeline de ingesta de datos en herramientas de visualización de datos tales como 'Superset', simulando un entorno en tiempo real para los datos de tipo temporales 'tweets.json'. Este archivo representa una fuente dinámica para ser procesada como flujo ´stream´ y contiene contiene múltiples tweets realizados por usuarios que se publican cada cierto tiempo.

El pipeline permitiría a un usuario poder tomar decisiones basadas en datos al visualizarlos de manera interactiva en herramientas de Bussiness Intelligence. 

Para cumplir con lo anterior, se ha diseñado una arquitectura distribuida que simula un entorno de producción mediante contenedores Docker. El flujo de datos sigue los siguientes pasos.

#### MQTT 

´MQTT´ es un protocolo de mensajería ligero para transmitir datos entre un ´publicador´ y un ´suscriptor´.

Un script en Python (´sender.py´) se encarga de leer tweets del archivo ´tweets.json´ para ir publicandolos uno a uno en un topic de ´MQTT´ llamado ´tweets´.

### Broker MQTT: Mosquitto 

Actúa como intermediario entre los 'publicadores' y los 'suscriptores' del tópico de mensajería para recibir los mensajes publicados en el tópico ´tweets´ y enrutarlos a los ´suscriptores´.

#### Kafka Connect

Permite la integración de sistemas externos con Kafka. 

Tiene dos tipos de conectores, uno que permite ingresar datos a Kafka desde sistemas externos (en este caso ´MQTT´), y otro que permite sacar datos desde Kafka hacia sistemas externos (´Druid´).

#### Apache Kafka 

Plataforma distribuida de mensajería en tiempo real. Diseñada para manejar flujos de **grandes volumenes** de datos de manera persistente, escalable y persistente. Recibe los datos del protocolo de mensajería ´MQTT´ definido **tweets**.

#### Apache Druid 

Druid es una base de datos analítica en tiempo real para hacer consultas de manera rápida en grandes volumenes de datos (especialemente en datos temporales). Se encarga de consumir los mensajes desde el topic tweets y estructurarlos, preparandolos para una exploración analítica amigable.

Para lograr lo anterior, *Druid* ocupa los siguientes componentes:

| Componente     | Función                                                                 |
|----------------|-------------------------------------------------------------------------|
| **Broker**     | Recibe consultas desde Superset y coordina su resolución. |
| **Historical** | Almacena y consulta datos antiguos.                                     |
| **MiddleManager** | Ingresa datos desde fuentes como Kafka en tiempo real.             |
| **Coordinator** | Administra la distribución de los datos.                             |
| **Router**     | Enruta las peticiones al componente adecuado.                           |

#### Superset 

Es una herramienta de Bussiness Intelligence de código abierto que permite visualizar, explorar y analizar datos de manera interactiva a través de una interfaz web. Permite conectarse a múltiples bases de datos, ejecutar consultas *SQL* directamente y consultar gráficos. Gracias a su integración con herramientas como *Druid*, es ideal para explorar grandes volúmenes de datos.

En el proyecto, es la pieza que permite visualizar los tweets en tiempo real y realizar análisis sobre los datos procesados en el pipeline.



### Procedimiento

Aqui ponemos una muestra de la ejecución del pipeline, con los comandos que usamos en el sh y los docker que se consumen dentro de este, explicando que hacen y poniendo screenshots de outputs (como por ejemplo de conectores inicializados correctamente o el despliegue de las tecnologías, que las interfaces están operativas y cosas así.)


### Requirements

1. jq
2. Docker






## Author

Diego Yáñez


Jorge Galvis