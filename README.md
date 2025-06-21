# Pipeline - Datos Temporales (tweets.json)

El objetivo de esta parte del proyecto, es construir un pipeline de ingesta de datos en herramientas de visualización de datos tales como 'Superset', simulando un entorno en tiempo real para los datos de tipo temporales 'tweets.json'. Este archivo representa una fuente dinámica para ser procesada como flujo ´stream´ y contiene contiene múltiples tweets realizados por usuarios que se publican cada cierto tiempo.

El pipeline permitiría a un usuario poder tomar decisiones basadas en datos al visualizarlos de manera interactiva en herramientas de Bussiness Intelligence. 

Para cumplir con lo anterior, se ha diseñado una arquitectura distribuida que simula un entorno de producción mediante contenedores Docker. El flujo de datos sigue los siguientes pasos.

1. MQTT 

´MQTT´ es un protocolo de mensajería ligero para transmitir datos entre un ´publicador´ y un ´suscriptor´.

Un script en Python (´sender.py´) se encarga de leer tweets del archivo ´tweets.json´ para ir publicandolos uno a uno en un topic de ´MQTT´ llamado ´tweets´.

2. Broker MQTT: Mosquitto 

Actúa como intermediario entre los 'publicadores' y los 'suscriptores' del tópico de mensajería para recibir los mensajes publicados en el tópico ´tweets´ y enrutarlos a los ´suscriptores´.

3. Kafka Connect

Permite la integración de sistemas externos con Kafka. 

Tiene dos tipos de conectores, uno que permite ingresar datos a Kafka desde sistemas externos (en este caso ´MQTT´), y otro que permite sacar datos desde Kafka hacia sistemas externos (´Druid´).

4. Apache Kafka 

Plataforma distribuida de mensajería en tiempo real. Diseñada para manejar flujos de **grandes volumenes** de datos de manera persistente, escalable y persistente. Recibe los datos del protocolo de mensajería ´MQTT´ definido **tweets**.

5. Apache Druid 

Druid es una base de datos analítica en tiempo real para hacer consultas de manera rápida en grandes volumenes de datos (especialemente en datos temporales). Se encarga de consumir los mensajes desde el topic tweets y estructurarlos, preparandolos para una exploración analítica amigable.


## Procedimiento

Aqui ponemos una muestra de la ejecución del pipeline, con los comandos que usamos en el sh y los docker que se consumen dentro de este, explicando que hacen y poniendo screenshots de outputs (como por ejemplo de conectores inicializados correctamente o el despliegue de las tecnologías, que las interfaces están operativas y cosas así.)


## Requirements

1. jq
2. Docker


# Author

Diego Yáñez
Jorge Galvis