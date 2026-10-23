# Nebula Engine V2 — arquitectura, migración y dirección visual

> **Estado:** documento de planificación. No es una especificación de implementación aprobada ni una instrucción para reescribir todo el motor de una vez.
>
> **Regla principal:** preservar todos los temas existentes, sus identificadores persistidos, sus características visuales y el comportamiento actual mientras se migra por capas. No hacer un reemplazo masivo de temas, paletas, materiales, pintores o preferencias.

## 1. Visión y objetivo

Nebula debe evolucionar de una colección de temas con materiales y efectos personalizados a un **sistema de diseño y renderizado visual de primera clase para Aves-X**.

El objetivo no es simplemente tener más colores, blur o glow. El motor debe:

- Dar a cada tema una identidad visual completa y consistente.
- Permitir añadir temas integrados con el mínimo de cambios transversales.
- Permitir instalar, previsualizar, activar, exportar y retirar temas externos sin recompilar la app ni conectarse a un servidor.
- Aplicar la misma identidad desde la galería hasta el visor, los metadatos, los ajustes y las pantallas de seguridad.
- Separar identidad, recetas de componentes, efectos, animación y preferencias de rendimiento.
- Mantener el rendimiento y la legibilidad en dispositivos modestos.
- Evitar que los temas se conviertan en variantes intercambiables de una misma interfaz llena de cristales, gradientes y resplandores.
- Migrar el código existente de forma compatible, reversible y comprobable.

## 2. Principio de migración: no romper los temas actuales

Actualizar todas las capas a la vez sería arriesgado. Los temas dependen unos de otros mediante identificadores, enum, paletas, materiales, tokens, efectos, preferencias y estilos de Flutter. Una modificación global puede causar:

- Un tema externo que use por accidente la identidad visual de Aves.
- Un efecto que no corresponda a la paleta seleccionada.
- Identificadores guardados que ya no se puedan deserializar.
- Cambios de apariencia en widgets que antes usaban un tratamiento específico.
- Pérdida de características propias de temas como Solar Flare, Abyss, Imperial, Sakura, Obsidian, Nosferatu y Aureate.
- Regresiones en seguridad, contraste, animación o rendimiento.
- Migraciones de preferencias incompatibles o datos personalizados perdidos.

Por ello, V2 se debe construir **por adaptación progresiva**, manteniendo los tipos y las rutas actuales mientras se introducen las nuevas abstracciones. No borrar un enum, un mapa ni un pintor hasta identificar todos sus consumidores y demostrar que existe un reemplazo equivalente.

### Reglas no negociables

1. Mantener IDs históricos de temas y sus alias de migración.
2. Mantener la importación del formato de tema personalizado actual (v1).
3. Conservar los pintores especializados cuando expresen una identidad que no pueda reproducirse con primitivas genéricas.
4. No cambiar la lógica de seguridad para conseguir una apariencia común.
5. No hacer que Glass-Everywhere sea obligatorio para todos los temas.
6. No introducir ejecución de código arbitrario desde paquetes de temas externos.
7. No declarar que el rendimiento mejora sin mediciones; no declarar que CI pasó si sigue pendiente.
8. Trabajar en commits pequeños, uno por responsabilidad, sobre el HEAD actual de `develop`; comprobar los cambios concurrentes antes de cada escritura.
9. Capturar el aspecto de referencia antes de migrar y revisar regresiones visuales después de cada fase.
10. Cada fase debe poder revisarse y revertirse sin dejar el motor a medias.

## 3. Arquitectura actual: piezas que hay que comprender y preservar

Los archivos y áreas que deben formar parte del inventario inicial incluyen:

- `lib/theme/nebula/nebula_theme.dart`: identidad enum y temas conocidos.
- `lib/theme/nebula/nebula_palettes.dart`: paletas, colores y recetas cromáticas.
- `lib/theme/nebula/nebula_material.dart`: materiales, formas, estilos y tratamientos.
- `lib/theme/nebula/nebula_tokens.dart`: tokens usados en particular por superficies de seguridad.
- `lib/theme/nebula/nebula_custom_theme.dart`: modelo de tema personalizado y conversión a paleta.
- `lib/theme/nebula/nebula_custom_theme_store.dart`: persistencia y almacenamiento de temas personalizados.
- `lib/model/settings/modules/custom_nebula_theme.dart`: integración del tema personalizado en las preferencias.
- `lib/model/settings/modules/display.dart`: preferencias de apariencia y animación.
- `lib/theme/themes.dart`: construcción del ThemeData y estilos de widgets Flutter.
- `lib/theme/nebula/nebula_effect.dart`: efectos animados y pintores.
- `lib/widgets/common/fx/nebula_surfaces.dart`: decoración de superficies.
- `lib/widgets/common/fx/diamond.dart`: renderizado de materiales y geometrías decorativas.
- `lib/widgets/common/fx/liquid.dart`: infraestructura de efectos líquidos/GlassThemeScope y comportamiento relacionado.
- `lib/widgets/settings/nebula/nebula_tab.dart`: página de Nebula, demostraciones, tarjetas y selección/visualización de efectos.
- `lib/widgets/aves_app.dart`: integración global del tema de la aplicación.
- `lib/widgets/common/fx/black_hole.dart`, `failsafe_badge.dart` y otros efectos especializados: candidatos para revisión de límites, glow y coste de dibujo.

Esta lista es un punto de partida, no un inventario exhaustivo. Antes de cambiar nada hay que buscar todos los imports y usos reales de los tipos, constructores, enums, preferencias y pintores mencionados.

## 4. Problema arquitectónico central

Actualmente la identidad de un tema está repartida entre varias representaciones:

- `NebulaTheme`: identidad/ID.
- `NebulaPalette`: colores y tratamiento cromático.
- `NebulaMaterialStyle`: receta material y geometría.
- `NebulaTokens`: tokens específicos, actualmente con énfasis en seguridad.
- `NebulaEffect` y sus pintores: efectos visuales/animación.
- `CustomNebulaTheme`: representación importable de un tema externo.
- `ThemeData`: estilos que consume Flutter.
- `GlassThemeScope` y widgets decorativos: consumidores particulares.

Estas capas tienen valor, pero no están unificadas por una definición de tema completa. Hay mappings y decisiones condicionales repartidos en varios archivos. Añadir una nueva identidad puede requerir modificar varios switches/mapas y consumidores.

La solución no es borrar toda especialización. Es tener una única definición autoritativa y mantener los tratamientos únicos como implementaciones explícitas registradas.

## 5. Arquitectura objetivo de V2

### 5.1 NebulaThemeDefinition

Definición inmutable de una identidad visual completa. Debe reunir o referenciar:

- Identificador estable.
- Nombre visible y descripción.
- Versión de la definición.
- Origen: integrado o externo.
- Paleta semántica.
- Familia de material y parámetros.
- Geometría y lenguaje de formas.
- Recetas de componentes.
- Perfil de efectos y movimiento.
- Variantes de accesibilidad.
- Recursos visuales permitidos.
- Capacidades compatibles y requisitos de versión.

La definición no debe mezclar la identidad del tema con el estado temporal de animación ni con preferencias globales del usuario.

### 5.2 NebulaThemeRegistry

Registro de definiciones instaladas y temas integrados. Debe:

- Resolver temas por ID estable, no por etiqueta localizada.
- Distinguir integrados y externos sin fingir que un externo es un enum integrado.
- Validar duplicados y compatibilidad de versiones.
- Conservar un tema válido de respaldo.
- Exponer una colección estable para selector, vista previa y exportación.
- Permitir a los temas integrados aportar renderizadores especializados mediante una interfaz explícita.
- Evitar switches distribuidos que enumeren todos los temas.

### 5.3 NebulaThemeResolver

Resuelve la selección actual y las preferencias relevantes en una configuración inmutable, por ejemplo `ResolvedNebulaTheme`.

Debe resolver de manera coherente:

- Definición/ID seleccionado.
- Esquema cromático y tokens semánticos.
- Recetas de superficies/componentes.
- Material y parámetros geométricos.
- Efectos compatibles con el tema.
- Modo claro/oscuro si la arquitectura existente lo permite.
- Preferencias de Glass-Everywhere.
- Preferencias de movimiento y rendimiento.
- Ajustes de contraste/accesibilidad.

El resto de la app debe consumir el resultado resuelto en vez de consultar por separado `settings.nebulaTheme`, la paleta personalizada y el material activo para decidir una misma representación visual.

### 5.4 Adaptadores a la arquitectura existente

Mantener inicialmente los modelos y APIs actuales. Crear adaptadores que conviertan las definiciones actuales en definiciones V2 y las definiciones V2 en las estructuras que hoy esperan los widgets.

No eliminar una API heredada hasta que:

1. Todos sus consumidores estén identificados.
2. Exista un adaptador o reemplazo.
3. Las pruebas de regresión cubran los consumidores.
4. Se haya comprobado la serialización/migración de preferencias.
5. Se haya comparado visualmente cada tema afectado.

### 5.5 ThemeData es un adaptador, no el motor entero

Flutter `ThemeData` debe seguir dando soporte a Material y sus componentes. Nebula debe complementar ese contrato con tokens semánticos, materiales, recetas y efectos propios.

No reemplazar `ThemeData`; construirlo desde la definición resuelta y proporcionar una extensión de tema tipada para los consumidores específicos de Nebula.

### 5.6 NebulaThemeScope

Proveer la definición resuelta a través de un scope/contexto común. Los widgets deben poder pedir recetas tipadas, por ejemplo:

- Superficie de contenido.
- Superficie flotante.
- Superficie elevada.
- Superficie de selección.
- Campo de entrada.
- Menú contextual.
- Panel de metadatos.
- Barra de navegación.
- Overlay del visor.
- Insignia/estado de seguridad.

El scope debe evitar reconstrucciones masivas cuando cambia un parámetro que no afecta a una subrama y permitir la actualización del tema sin reiniciar la aplicación cuando sea seguro.

## 6. Modelo semántico de tokens

Ampliar la semántica de tokens para abarcar toda la app, no solo Fail-Safe.

### Tokens cromáticos mínimos

- Fondo principal y fondo secundario.
- Superficie base, elevada, flotante y atenuada.
- Texto principal, secundario, terciario y deshabilitado.
- Acento principal/secundario.
- Contorno normal, contorno fuerte y divisor.
- Selección, foco y estado activo.
- Error, advertencia, éxito e información.
- Scrim/overlay.
- Estados de carga y progreso.

Los colores deben derivarse con reglas verificables y contrastes suficientes. Los temas personalizados no deben poder definir estados semánticos indistinguibles de manera que errores y avisos se vuelvan ilegibles.

### Tokens de forma y material

- Radios y jerarquía de esquinas.
- Espaciado y densidad.
- Grosor y opacidad de bordes.
- Elevación/sombra.
- Opacidad y blur por nivel de superficie.
- Intensidad y radio del glow.
- Facetado, veta, trama, reflejo o textura.
- Tratamiento de iconos.
- Curvas y duración de transiciones.

No todo debe ser configurable por un archivo externo. Las propiedades que afectan a estabilidad, accesibilidad o coste de renderizado deben tener rangos y valores predeterminados controlados por el motor.

## 7. Temas externos: formato de paquete V2

### 7.1 Compatibilidad con el formato actual

El JSON personalizado v1 existente debe seguir importándose. La migración debe transformar sus campos al modelo V2 y conservar la paleta y el resultado visual de forma razonablemente equivalente. No sobrescribir archivos originales hasta validar la conversión.

Los temas externos actuales se deben tratar como perfiles cromáticos que usan recetas del motor, no como si ya pudieran declarar cualquier material o efecto.

### 7.2 Paquete propuesto

Formato de paquete sugerido: `.nebula`, con estructura ZIP y contenido declarativo:

```text
mi-tema.nebula
├── manifest.json
├── theme.json
├── assets/
│   ├── preview.webp
│   └── textures/
└── LICENSE.txt
```

El manifiesto debe declarar ID, nombre, autor, versión, versión del esquema, requisitos mínimos del motor, licencia y capacidades usadas.

El archivo de tema define tokens semánticos, familia de material, geometría, recetas y perfil de efectos. Los recursos deben estar localizados dentro del paquete y referenciados de forma relativa y validada.

### 7.3 Sin código ejecutable externo

Los paquetes de tema nunca deben ejecutar Dart, JavaScript, scripts, shaders arbitrarios ni código nativo.

El sistema puede exponer primitivas seguras y combinables, como:

- Gradientes y mezclas.
- Facetas y polígonos limitados.
- Líneas, tramas y vetas.
- Reflejos y highlights.
- Texturas rasterizadas permitidas.
- Anillos, ondas y partículas de presupuesto limitado.
- Escenas compuestas mediante una lista declarativa de capas.
- Parámetros de animación acotados.

Los temas integrados pueden conservar pintores Dart especializados para diseños únicos, ya que forman parte del código auditado de la aplicación.

### 7.4 Validación y aislamiento

Validar antes de instalar:

- Esquema y versión.
- IDs duplicados o reservados.
- Tipos, valores numéricos y rangos.
- Cantidad de capas, puntos, partículas y operaciones.
- Tamaño comprimido y descomprimido.
- Dimensiones y formato de imágenes.
- Rutas de ZIP y traversal de directorios.
- Referencias a recursos ausentes.
- Capacidades desconocidas.
- Colores y contraste semántico.
- Coste máximo permitido de las escenas declarativas.

No cargar rutas arbitrarias ni acceder a la red. Un paquete inválido no debe cambiar el tema actual, borrar datos ni bloquear el arranque.

### 7.5 Almacenamiento y ciclo de vida

Separar, si es necesario, la configuración ligera del contenido de paquetes con recursos. No mantener paquetes grandes codificados como una única preferencia JSON.

Operaciones necesarias:

- Importar desde archivo local.
- Validar y mostrar errores legibles.
- Vista previa antes de activar.
- Aplicar y volver al tema anterior.
- Exportar el tema instalado.
- Actualizar versión sin perder el original si la actualización falla.
- Eliminar un tema sin romper el tema activo.
- Seleccionar automáticamente un fallback válido si el tema activo se elimina o deja de ser compatible.

El motor debe funcionar completamente offline.

## 8. Tema personalizado y discordancia entre paleta y efecto

Hay un caso prioritario que debe corregirse en la primera fase: `CustomNebulaTheme.toPalette()` usa la identidad interna `NebulaTheme.aves` como parte de su conversión. Al mismo tiempo, la aplicación puede construir `ThemeData` con una paleta personalizada mientras algunos consumidores consultan el enum `settings.nebulaTheme`.

La pestaña Nebula (`lib/widgets/settings/nebula/nebula_tab.dart`) selecciona efectos usando esa identidad enum. Por tanto, la paleta y el efecto podrían representar identidades diferentes.

### Corrección propuesta

- Dar a los temas externos un ID propio e independiente del enum integrado.
- Resolver una única definición activa para paleta, material y efecto.
- Hacer que la selección de efectos use la definición activa y sus capacidades.
- Definir un comportamiento neutral explícito para un tema externo que no declare escena.
- No inventar que todo tema externo corresponde a un tema integrado.
- Mantener la persistencia actual durante la migración mediante adaptadores.
- Añadir pruebas que cambien entre tema integrado, personalizado, eliminado, corrupto y restaurado.

Este arreglo debe hacerse antes de ampliar la superficie de temas externos.

## 9. Dirección visual: identidades distintas, no «AI slop»

No diseñar los temas como un conjunto de fondos negros con un color distinto y el mismo resplandor. Cada tema necesita una gramática visual consistente.

### Reglas de arte comunes

1. Un motivo principal reconocible y, como máximo, uno o dos motivos secundarios.
2. El glow debe sugerir luz real o profundidad, no ser un contorno universal.
3. Blur solo cuando la transparencia y las capas aporten algo; no usarlo como decoración automática.
4. Las formas y el material deben reconocerse incluso con animaciones desactivadas.
5. El movimiento debe comunicar una idea: respiración, pulso, deriva, destello, onda o energía.
6. Evitar partículas, rayos, gradientes, halos y ornamentos simultáneos sin jerarquía.
7. La interfaz funcional siempre tiene prioridad frente a los efectos.
8. Las fotos, miniaturas y metadatos deben seguir siendo el centro de la galería.
9. Diseñar primero una superficie y una tarjeta representativas; luego trasladar las reglas a otros componentes.
10. Revisar el tema en pantallas reales, no solo en la miniatura del selector.

### Direcciones artísticas de referencia

Estas son directrices de diseño que deben validarse visualmente, no especificaciones finales de código.

- **Nosferatu Glass:** cristal rubí gótico, facetas cortadas, rojo profundo, bordes precisos y destellos puntuales. No bañar toda la interfaz en rojo brillante.
- **Obsidian Glass:** negro mineral, cortes oscuros y fisuras violetas; luz localizada y movimiento lento.
- **Aureate Glass:** oro envejecido, grabados y relieves ceremoniales, reflejos cálidos; no simplemente negro y amarillo.
- **Sakura Glass:** papel oscuro, tinta caligráfica, composición asimétrica y pétalos discretos; evitar saturar de rosa.
- **Imperial:** placas industriales, acero, remaches y oro envejecido.
- **Solar Flare:** fuente de energía identificable, plasma y prominencias puntuales.
- **Hermetic:** geometría deliberada, simetría donde corresponda y simbología ordenada.
- **Void:** retículas técnicas, líneas y espacios negros amplios.
- **Aurora:** luz atmosférica difusa y transiciones cromáticas amplias, sin anillos repetitivos.
- **Pearl:** nácar, reflexión suave y luminosidad clara.
- **Ivory:** porcelana/papel cálido, sombras suaves y detalle discreto.
- **Abyssal:** profundidad oscura y bioluminiscencia localizada, con sensación orgánica.
- **Onyx:** minimalismo, grafito, bordes limpios y reflejos discretos.

La misma revisión debe extenderse a Solar Flare, Abyss, Imperial, Sakura, Obsidian, Nosferatu, Aureate y al resto de las identidades existentes. No uniformar los temas para que compartan un mismo tipo de cristal o animación.

## 10. Glass-Everywhere debe ser un sistema de superficies opcional

Separar claramente:

1. Identidad del tema: paleta, formas, material y personalidad.
2. Recetas de componentes: aspecto de tarjetas, campos, menús, navegación, etc.
3. Glass-Everywhere: política opcional de transparencia, blur, capas y profundidad.

Un tema opaco debe poder verse completo sin depender de blur. Las superficies transparentes deben tener una alternativa opaca que mantenga la jerarquía visual. Las opciones de Glass-Everywhere deben estar en el lugar apropiado de los ajustes propios del fork y no confundirse con el selector de identidad.

No todas las superficies necesitan ser vidrio. Los temas pueden usar metal, papel, cerámica, piedra, obsidiana, plasma u otros materiales coherentes.

## 11. Ampliar Nebula a toda la aplicación

Primero inventariar consumidores actuales, buscar estilos locales y determinar qué se debe unificar. No asumir que toda decoración local es deuda: algunas son parte del diseño original de Aves o tienen una función específica.

### Prioridad 1 — navegación y estructura

- AppBar y barras de navegación.
- Cajón/rail de navegación.
- Estado activo, hover/focus y feedback de interacción.
- Nav Lens.
- Transiciones entre secciones.
- Superficies estructurales.

### Prioridad 2 — galería y álbumes

- Selección y foco.
- Marcadores y favoritos.
- Tarjetas, encabezados y paneles.
- Menús contextuales.
- Selección múltiple.
- Estados vacíos, carga y error.

### Prioridad 3 — visor

- HUD y controles.
- Tira de miniaturas.
- Overlay de vídeo.
- Controles de reproducción.
- Transiciones de entrada/salida.
- Elementos flotantes sin tapar el contenido.

### Prioridad 4 — metadatos

- Fichas EXIF.
- Tablas, etiquetas y valores.
- Paneles de localización/mapas.
- Secciones de información.
- Controles de exploración.

### Prioridad 5 — ajustes

- Campos y toggles.
- Selectores y listas.
- Tarjetas y agrupaciones.
- Diálogos, sheets y confirmaciones.
- Pantallas de importación/exportación.

### Prioridad 6 — seguridad y privacidad

- App Lock y bloqueo de elementos.
- Fail-Safe y Lockdown.
- Vaults y papelera protegida.
- Badges y alertas de seguridad.

Las pantallas de seguridad requieren pruebas especiales de contraste y claridad. No sacrificar señales de alerta ni hacer que un tema pueda disimular estados importantes.

### Criterio de migración por zona

Cada grupo se migra en un conjunto pequeño de cambios. Identificar el widget y su estilo actual, agregar tokens/receta si es una necesidad común, migrar el consumidor y comparar capturas. No sustituir todo el archivo ni todas las decoraciones por una abstracción genérica.

## 12. Rendimiento del motor

La optimización debe hacerse con mediciones y preservar el comportamiento visual. Los efectos complejos deben ser una opción controlada, no una carga obligatoria.

### 12.1 Efectos y CustomPainter

En `lib/theme/nebula/nebula_effect.dart`:

- Identificar la geometría que no cambia entre frames y calcularla una sola vez.
- Revisar pintores que recrean datos deterministas dentro de `paint`.
- Separar capas estáticas de capas animadas cuando permita evitar repintados innecesarios.
- Reutilizar Path, Paint y estructuras geométricas cuando sea correcto y seguro.
- Evitar que cada efecto tenga su propio controlador sin necesidad.
- Suspender animaciones cuando no se vean o la aplicación esté en segundo plano.
- Mantener loops continuos solo donde formen parte de la identidad del tema.
- Revisar el coste de MaskFilter/blur y limitar el área pintada.
- Respetar la preferencia de animación y movimiento reducido.

La optimización no debe eliminar el carácter único de un efecto. Medir antes y después.

### 12.2 Cachés gráficas

En `nebula_surfaces.dart` y `diamond.dart` ya se almacenan escenas grabadas como `ui.Picture`. Revisar los límites y la política de limpieza actual.

Objetivos:

- Caché acotada por presupuesto y cantidad de entradas.
- Política de descarte explícita (por ejemplo LRU).
- Liberación de recursos gráficos al descartar entradas.
- Claves que incluyan solo parámetros que afectan al dibujo.
- No invalidar una escena estática por cambios irrelevantes.
- Evitar que cambiar rápidamente de tema provoque acumulación de imágenes o escenas.
- Registrar métricas de hit/miss en builds de desarrollo, sin telemetría ni datos enviados fuera de la app.

### 12.3 Niveles de rendimiento

El modo de rendimiento no debe sustituir la identidad del tema. Debe reducir su costo de representación:

- **Completo:** material y efectos previstos para el tema.
- **Reducido:** superficie y geometría esencial, con menos blur y menos animación.
- **Mínimo:** paleta, silueta, contornos y feedback funcional; sin efectos dinámicos costosos.

El cambio de nivel debe ser predecible. Si el usuario desactiva animaciones, no se debe mantener un loop invisible consumiendo recursos. Si una superficie pierde blur, debe seguir siendo legible y coherente.

### 12.4 Presupuesto y medición

Medir como mínimo:

- Tiempo de frame en pantallas representativas.
- FPS/jank en un dispositivo modesto y un dispositivo más potente cuando estén disponibles.
- Memoria y cantidad de entradas de caché.
- Tiempo de cambio entre temas.
- Costo de la pestaña Nebula con cada tipo de efecto.
- Comportamiento al volver del background.
- Coste de scroll en galerías grandes.

No introducir una métrica objetivo inventada sin baseline; establecerla tras capturar el comportamiento actual.

## 13. Calidad, accesibilidad y consistencia

- Contraste de texto, iconos y estados semánticos.
- Soporte de movimiento reducido.
- Layouts estrechos y textos largos.
- Escalado de texto.
- Tema claro/oscuro y colores dinámicos si forman parte de la configuración soportada.
- Widgets sin animación.
- Fallos de recursos externos.
- Temas desconocidos y versiones futuras.
- Cambio de tema con una pantalla abierta.
- Cambios concurrentes de preferencias.
- Coherencia entre selector, vista previa y tema activo.
- No mostrar blur/glow recortado en límites de iconos o widgets.
- Mantener comportamiento original cuando no haya definición externa válida.

## 14. Plan de trabajo detallado por fases

### Fase 0 — inventario y línea base

1. Recuperar el HEAD actual de `develop`.
2. Buscar todos los usos de `NebulaTheme`, `NebulaPalette`, `NebulaMaterialStyle`, `NebulaTokens`, `CustomNebulaTheme`, `GlassThemeScope`, los efectos y los ajustes.
3. Dibujar el grafo de dependencias real y localizar todos los puntos de selección/persistencia.
4. Capturar pantallas representativas de cada tema integrado.
5. Anotar los temas externos actuales y el resultado visual que producen.
6. Medir los efectos y la memoria base.
7. Identificar pruebas existentes y carencias.
8. Corregir discrepancias documentales, por ejemplo un recuento de temas en README que no coincida con el catálogo real, preferiblemente generando la información desde la fuente autoritativa.

**Salida de fase:** inventario y baseline revisables; sin cambios visuales masivos.

### Fase 1 — definición y resolver

1. Diseñar tipos inmutables V2.
2. Crear registro y resolver.
3. Adaptar las definiciones actuales a través de un adaptador, sin recrearlas todas manualmente.
4. Mantener enum/IDs y migraciones antiguas.
5. Unificar la selección de paleta, material y efecto.
6. Resolver la discordancia de temas personalizados.
7. Añadir pruebas unitarias del resolver y persistencia.
8. Confirmar que todos los temas existentes se ven igual antes y después, salvo bugs documentados que se corrijan intencionalmente.

**Salida de fase:** un único tema resuelto, manteniendo APIs heredadas.

### Fase 2 — formato externo V2

1. Especificar manifest y schema.
2. Definir límites de contenido y capacidades declarativas.
3. Implementar validador puro con pruebas.
4. Implementar conversión de v1 a v2.
5. Separar almacenamiento de metadata y recursos cuando sea necesario.
6. Añadir importación, preview, activación, exportación y eliminación.
7. Probar paquetes inválidos, IDs duplicados, assets faltantes y tema activo eliminado.
8. Crear un tema externo de prueba que demuestre una identidad visual propia.

**Salida de fase:** temas externos instalables y seguros, sin modificar el código de la app.

### Fase 3 — tokens y recetas de componentes

1. Extender tokens semánticos.
2. Crear recetas para superficies, navegación, campos, tarjetas, paneles y overlays.
3. Integrar las recetas con ThemeData.
4. Migrar consumidores actuales sin forzar una abstracción sobre componentes especiales.
5. Extender el scope de tema.
6. Probar estados de error/éxito/selección y accesibilidad.

**Salida de fase:** un lenguaje visual compartido por los componentes centrales.

### Fase 4 — runtime y optimización

1. Medir pintores y efectos.
2. Precalcular geometría determinista.
3. Revisar invalidación de escenas.
4. Introducir presupuesto y descarte de caché.
5. Consolidar el ciclo de vida de animaciones.
6. Añadir niveles de rendimiento.
7. Medir nuevamente y comparar con la línea base.

**Salida de fase:** rendimiento cuantificado y ciclo de vida de efectos controlado.

### Fase 5 — cobertura por áreas

Migrar en lotes independientes:

1. Navegación.
2. Galería/álbumes.
3. Visor.
4. Metadatos.
5. Ajustes y diálogos.
6. Seguridad.

Para cada lote: identificar consumidores, implementar receta/tokens, migrar, capturar pantallas, probar layout y accesibilidad y revisar diferencias.

**Salida de fase:** la identidad Nebula está presente en las principales zonas, no solo en la pestaña de temas.

### Fase 6 — dirección de arte y selector

1. Revisar cada tema integrado con su propia gramática visual.
2. Eliminar adornos repetitivos sin función.
3. Comprobar temas con animación desactivada.
4. Rediseñar vista previa para mostrar tarjeta, superficie, controles y escena.
5. Integrar temas externos en el mismo selector con una separación clara.
6. Mejorar Glass-Everywhere como preferencia independiente.
7. Comprobar que no se pierdan características de Solar Flare, Abyss, Imperial, Sakura, Obsidian, Nosferatu, Aureate y demás temas.

**Salida de fase:** identidades distinguibles y selector coherente.

### Fase 7 — regresión y cierre

1. Ejecutar análisis estático y pruebas.
2. Ejecutar builds/CI y esperar resultados reales.
3. Comparar capturas por tema y área.
4. Probar migraciones desde preferencias antiguas.
5. Probar importar, activar, exportar y eliminar temas externos.
6. Verificar animación y modo rendimiento.
7. Probar layouts pequeños y escalado de texto.
8. Documentar limitaciones conocidas y versión del formato.
9. Solo entonces marcar Nebula Engine V2 como estable.

## 15. Criterios de aceptación globales

V2 no se considera completo hasta que:

- Añadir un tema integrado no requiere editar una multitud de switches o mapas independientes.
- La definición resuelta controla paleta, material, geometría, recetas y efectos.
- Un tema externo tiene un ID propio y nunca se hace pasar por Aves u otro tema integrado.
- El formato v1 se sigue importando.
- Los paquetes externos son declarativos, validados y offline.
- Cambiar o eliminar un tema no deja preferencias inválidas.
- Los principales componentes consumen tokens y recetas compartidos.
- Cada tema sigue siendo reconocible sin blur ni animaciones.
- Los efectos se suspenden cuando no son visibles y respetan preferencias de movimiento.
- Las cachés tienen límites y un ciclo de vida definido.
- No hay regresiones de contraste ni de lógica de seguridad.
- Se han comparado pantallas representativas de todos los temas existentes.
- Las mejoras de rendimiento están medidas y no solo supuestas.
- CI y las pruebas están realmente terminados y sus resultados se conocen.

## 16. Primeros pasos concretos para la implementación futura

Cuando se autorice implementar V2, empezar por este pequeño conjunto, en este orden:

1. Inspeccionar HEAD y cambios concurrentes de `develop`.
2. Crear el inventario de consumidores y el baseline visual.
3. Diseñar `NebulaThemeDefinition` y `ResolvedNebulaTheme` con el mínimo de campos necesarios.
4. Adaptar un tema integrado y el tema personalizado actual como prueba de concepto.
5. Unificar la resolución de paleta/material/efecto y corregir la discordancia actual.
6. Añadir pruebas de persistencia y selección.
7. Migrar el resto de temas integrados al adaptador sin cambiar su apariencia.
8. Después, diseñar el paquete externo V2.
9. Luego extender tokens y componentes por áreas.

No implementar todas las fases en un solo cambio. Cada etapa debe compilar, tener pruebas apropiadas, ser visualmente revisable y poder revertirse por separado.

---

## Referencias principales del repositorio

- [Nebula theme IDs](https://github.com/Techkron-star/aves-X/blob/develop/lib/theme/nebula/nebula_theme.dart)
- [Nebula palettes](https://github.com/Techkron-star/aves-X/blob/develop/lib/theme/nebula/nebula_palettes.dart)
- [Nebula materials](https://github.com/Techkron-star/aves-X/blob/develop/lib/theme/nebula/nebula_material.dart)
- [Nebula tokens](https://github.com/Techkron-star/aves-X/blob/develop/lib/theme/nebula/nebula_tokens.dart)
- [Custom theme model](https://github.com/Techkron-star/aves-X/blob/develop/lib/theme/nebula/nebula_custom_theme.dart)
- [Custom theme store](https://github.com/Techkron-star/aves-X/blob/develop/lib/theme/nebula/nebula_custom_theme_store.dart)
- [Custom theme settings integration](https://github.com/Techkron-star/aves-X/blob/develop/lib/model/settings/modules/custom_nebula_theme.dart)
- [Display settings](https://github.com/Techkron-star/aves-X/blob/develop/lib/model/settings/modules/display.dart)
- [Flutter ThemeData integration](https://github.com/Techkron-star/aves-X/blob/develop/lib/theme/themes.dart)
- [Nebula effects](https://github.com/Techkron-star/aves-X/blob/develop/lib/theme/nebula/nebula_effect.dart)
- [Nebula surface decorations](https://github.com/Techkron-star/aves-X/blob/develop/lib/widgets/common/fx/nebula_surfaces.dart)
- [Nebula material decorations](https://github.com/Techkron-star/aves-X/blob/develop/lib/widgets/common/fx/diamond.dart)
- [Nebula settings tab](https://github.com/Techkron-star/aves-X/blob/develop/lib/widgets/settings/nebula/nebula_tab.dart)
- [Aves app theme integration](https://github.com/Techkron-star/aves-X/blob/develop/lib/widgets/aves_app.dart)

> Estas referencias son puntos de entrada. Antes de implementar, verificar las rutas y el contenido actuales en el HEAD de la rama objetivo; no asumir que el repositorio permanece inmóvil entre fases.
