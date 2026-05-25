# Visión General

Esta aplicación de Flutter permite a los usuarios extraer texto de imágenes, traducirlo al inglés y escuchar la traducción. La versión actual se ha modificado para aceptar imágenes a través de una URL, eliminando la necesidad de cargar archivos desde el dispositivo.

# Estilo y Diseño

- **Tema:** Se utiliza un tema de Material Design con `Colors.deepPurple` como color principal.
- **Diseño:** La interfaz se presenta en una sola pantalla con un diseño de lista (`ListView`) que permite el desplazamiento vertical.
- **Componentes:**
    - Un `AppBar` con el título de la aplicación.
    - Un campo de texto (`TextField`) para introducir la URL de la imagen, con un icono de enlace (`Icons.link`).
    - Un botón (`ElevatedButton`) para iniciar el procesamiento de la imagen.
    - Un área de vista previa para mostrar la imagen descargada.
    - Indicadores de carga (`CircularProgressIndicator`) mientras se procesa la imagen.
    - Tarjetas (`Card`) para mostrar el texto extraído y el texto traducido.
    - Un botón de reproducción (`IconButton`) para escuchar la traducción.

# Características

- **Extracción de Texto desde URL:**
    - Los usuarios pueden pegar una URL de una imagen en un campo de texto.
    - La aplicación descarga la imagen desde la URL proporcionada.
- **Reconocimiento de Texto (OCR):**
    - Utiliza el paquete `google_mlkit_text_recognition` para extraer el texto de la imagen.
- **Traducción:**
    - El texto extraído se traduce automáticamente al inglés utilizando el paquete `translator`.
- **Texto a Voz (TTS):**
    - Los usuarios pueden escuchar la pronunciación del texto traducido al inglés con el paquete `flutter_tts`.

# Plan de Cambios Actual

El siguiente plan se ha completado en esta sesión:

1.  **Eliminar la Carga de Imágenes Locales:** Se ha eliminado la funcionalidad de seleccionar imágenes de la cámara o la galería, que utilizaba el paquete `image_picker`.
2.  **Añadir Campo de URL:** Se ha añadido un `TextField` para que los usuarios introduzcan la URL de la imagen.
3.  **Implementar la Descarga de Imágenes:**
    - Se ha añadido el paquete `http` para realizar solicitudes de red para descargar la imagen.
    - Se ha añadido el paquete `path_provider` para guardar temporalmente la imagen descargada en el dispositivo.
4.  **Actualizar la Lógica de Procesamiento:**
    - La lógica se ha modificado para que comience con la descarga de la imagen desde la URL.
    - Una vez descargada, la imagen se procesa para la extracción de texto, traducción y reproducción de audio como en la versión anterior.
5.  **Limpieza del Proyecto:** Se ha eliminado el paquete `image_picker` del archivo `pubspec.yaml` ya que no se utiliza más.
