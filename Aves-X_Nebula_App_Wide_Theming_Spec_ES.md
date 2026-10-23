# Aves-X · Nebula Engine
## Especificación de temática visual para toda la aplicación

**Tipo:** documento de diseño y criterios de implementación para los agentes de Aves-X.  
**Rama auditada:** develop.  
**Documento complementario:** Aves-X_Nebula_Theme_Design_Spec_ES.md, que describe la identidad cromática y los VFX individuales de los temas.  
**Alcance de este documento:** cómo debe extenderse cada tema a toda la interfaz, desde iconos y navegación hasta App Lock, Master Code, objetos protegidos, Fail-Safe, Lockdown, diálogos, visor, reproductor y componentes secundarios.  
**Estado:** especificación; no sustituye la revisión del código ni demuestra que los requisitos estén implementados.

---

## 1. Objetivo: una identidad coherente, no solo un color de fondo

Nebula Engine debe sentirse como un sistema visual integral de Aves-X. Cambiar el tema debe modificar de forma coherente las superficies, los materiales, el acento, los reflejos, la navegación, los iconos seleccionados y los componentes especiales de seguridad. No debe limitarse a cambiar unas tarjetas o el fondo de Ajustes.

La app debe seguir siendo reconocible como Aves-X: silueta del murciélago, significado de los iconos, estructura de navegación, jerarquía de los controles y comportamiento de seguridad no cambian de un tema a otro. Lo que cambia es la presentación visual que envuelve esas funciones.

**La meta es que cada tema sea reconocible incluso con una captura pequeña y sin animaciones**, pero que ninguno dificulte leer una foto, reconocer un botón peligroso, introducir un código o identificar un error.

### Estado actual revisado

- La rama develop incluye 19 opciones de tema en NebulaTheme: Aves, Nosferatu Glass y 17 temas de fase 2.
- nebula_palettes.dart declara las 19 paletas; nebula_tokens.dart contiene tokens compartidos de seguridad; nebula_effect.dart proporciona efectos específicos; nebula_material.dart mantiene familias de materiales históricos.
- En la versión consultada, nebula_theme_selector.dart permite elegir las 19 opciones. El ROADMAP mantiene pendiente la validación de rendimiento en dispositivos de gama baja y describe una fase visual posterior para completar la coherencia de algunas pantallas de seguridad.
- Ya hay puntos de integración en AppMark, LockedBadge, ItemLockScreen, App Lock, Lockdown, burbujas de Fail-Safe y Nav Lens. El trabajo debe extender y unificar esos puntos, no reemplazarlos a ciegas.
- Existen algunos colores visuales fijos en componentes especiales, un número limitado de recetas de material y diferencias entre los comentarios de fase, el selector, el README y el roadmap. Se deben auditar en la rama vigente.

La documentación existente sobre los 17 temas define sus paletas y efectos. Este documento se concentra en la superficie completa de producto.

---

## 2. Principios que no se pueden romper

### 2.1 El tema cambia la presentación, nunca la seguridad

El tema no puede alterar:
- La lógica de App Lock, credenciales, biometría, PIN, Master Code o Master Guard.
- Contadores de intentos, enfriamientos, reglas de Lockdown, Safe Mode, Fail-Safe o Nuke.
- Cifrado, destrucción de claves, borrado, permisos, acceso a archivos, reglas de Gargantua o salidas de datos.
- Los estados reales de un proceso, operación, permiso o error.

Un tema puede pintar una superficie violeta, verde o dorada, pero el estado de peligro debe seguir identificado como peligro. El éxito no puede parecer error; un bloqueo no puede parecer desbloqueado; un botón destructivo no puede ocultarse dentro de un brillo temático.

### 2.2 El contenido del usuario es sagrado

Las fotos, vídeos, miniaturas, panoramas, imágenes en mapas y contenido exportado no deben recibir tintes globales, filtros, halos ni partículas por cambiar de tema. La temática pertenece a la interfaz que los rodea, no a los píxeles de la fotografía.

El tema puede cambiar el borde de selección, el panel de herramientas, la barra superpuesta o la insignia de protección. No puede volver azul la foto, oscurecer un vídeo ni alterar lo que se exporta, imprime, comparte o guarda.

### 2.3 La semántica de los iconos es estable

Una papelera sigue siendo papelera, una flecha atrás sigue siendo atrás y un candado cerrado no se transforma en otro símbolo por el tema. Se pueden cambiar tintes, material, borde, halo y estado seleccionado; no se debe cambiar el glifo funcional por uno decorativo que comunique otra acción.

### 2.4 Preferencias independientes deben componerse

El tema activo, la selección de material, Glass-Everywhere, el estilo de navegación, el desenfoque, el modo de rendimiento, el movimiento reducido y los ajustes de accesibilidad no son sinónimos. Deben combinarse con una prioridad clara y sin desactivar entre sí opciones independientes.

### 2.5 Un solo sistema de tokens

No crear una paleta distinta dentro de cada pantalla ni introducir una colección de colores literales por cada widget. Usar ColorScheme para la interfaz general; NebulaTokens para los elementos especiales de seguridad; y las recetas de material para cristales, cadenas, reflejos y superficies especiales. Si un valor se repite en varias pantallas, debe venir de un token compartido o de una receta derivada de la paleta.

---

## 3. Contrato visual y precedencia de configuración

### 3.1 Capas recomendadas

1. **NebulaPalette:** fuente base del color temático: fondo, superficies, bordes, acento, halo y facetas. Los temas personalizados deben poder proporcionar sus propios valores.
2. **ColorScheme / ThemeData:** aplicación de la paleta a componentes estándar: texto, iconos, AppBar, navegación, campos, botones, listas, tarjetas, menús, diálogos y controles Material.
3. **NebulaTokens:** propiedades que la UI ordinaria no puede deducir solo de ColorScheme: scrim de seguridad, superficie de bloqueo, tinta sobre esa superficie, burbuja de Fail-Safe, cristal, campos de código, acento de seguridad, bordes y reflejos.
4. **NebulaMaterialStyle:** receta especializada para elementos decorativos como el cristal del candado, cadenas, la insignia, el Nav Lens o superficies personalizadas. Actualmente el enum de material es más pequeño que la colección de temas; proporcionar un fallback derivado del tema activo en lugar de exigir un widget separado por tema.
5. **Widgets:** consumen los tokens. No deben escoger una paleta por su cuenta ni duplicar constantes conocidas.

### 3.2 Precedencia de los ajustes

- **Tema Nebula activo:** define identidad cromática, superficies y acabado predeterminado.
- **Material elegido explícitamente por el usuario:** conserva su geometría y acabado específico, pero sus colores deben integrarse con la identidad del tema cuando la receta lo permita. No anular el material seleccionado a escondidas.
- **Glass-Everywhere:** controla cuánto vidrio translúcido o desenfoque se aplica; no debe elegir una nueva paleta.
- **Estilo de navegación:** modifica geometría y disposición; los colores y el material del Nav Lens proceden del tema.
- **Modo de rendimiento o movimiento reducido:** detiene la animación y desactiva efectos caros; conserva colores, jerarquía, estado seleccionado y material reconocible.
- **Contraste elevado, texto grande u otras preferencias de accesibilidad:** tienen prioridad sobre decoración, transparencia, sombras y brillos.
- **Tema personalizado válido:** debe seguir el mismo contrato que uno integrado. No depender de un switch exhaustivo de enum que olvide automáticamente futuras paletas.

Si un tema o una receta no tiene datos suficientes, el sistema debe degradar a una presentación plana legible usando ColorScheme, sin valores nulos, pantallas vacías ni colores residuales de Nosferatu.

---

## 4. Iconos básicos, App Mark y símbolos de marca

### 4.1 Iconos de funciones

AIcons utiliza principalmente Material Symbols y algunos iconos de Material Design Icons. Mantener esa semántica homogénea. El tema debe llegar a los iconos mediante IconTheme, estados de componentes y ColorScheme:

- **Normal:** onSurfaceVariant o el color de icono definido por el componente.
- **Seleccionado/activo:** primary, con indicador de selección además del color cuando sea posible.
- **Deshabilitado:** estado disabled de Material; no simular deshabilitado únicamente bajando la saturación.
- **Éxito / información / advertencia / error:** colores semánticos, no el acento libre del tema.
- **Peligro destructivo:** error/danger, texto explícito y jerarquía apropiada.
- **En foco con teclado o mando:** contorno visible además de cualquier brillo.
- **Iconos decorativos:** pueden usar facetas del material del tema; jamás competir con el icono funcional de un control.

No aplicar glows a todos los iconos pequeños. El halo debe reservarse para elementos destacados, el estado activo o una previsualización temática; de lo contrario, la interfaz se vuelve ruidosa y el modo de contraste pierde claridad.

### 4.2 App Mark y logotipo

El dibujo principal de Aves-X y la silueta del murciélago son constantes de marca. El tema cambia el tratamiento material alrededor del símbolo, no su forma.

- **AppMark.brand:** conservar la identidad de marca Nosferatu/rubí.
- **AppMark.monochrome:** permanecer monocromático para contextos que lo requieran.
- **AppMark.scheme / auto:** derivar gradiente, borde y brillo de tokens de la paleta activa, no de una lista incompleta de temas concretos.
- No deformar, reflejar de manera inconsistente ni cambiar la silueta para que encaje con un tema.
- En Lockdown, la marca puede llevar la receta del tema, pero no debe parecer un indicador de que el dispositivo está seguro cuando se encuentra bloqueado.

### 4.3 Iconos del launcher y del sistema

El icono de launcher, el adaptive icon, el icono monocromático de Android, el icono de notificación y los accesos directos deben preservar la identidad estable de Aves-X. No deberían cambiar con cada tema si eso hace que la app parezca otra aplicación en el launcher. Si en el futuro se ofrece una variante personalizable del launcher, debe ser una opción explícita y separada, no un efecto secundario del selector Nebula.

---

## 5. Navegación y contenedor de la aplicación

### 5.1 Barra inferior, rail, pestañas y Nav Lens

La navegación debe ser el primer lugar donde el cambio de tema se percibe después del fondo:

- El destino activo usa el acento de la paleta, un indicador de forma y un texto legible.
- Los destinos inactivos usan el tono secundario de icono y no reciben el glow completo.
- El Nav Lens conserva su forma y su interacción, pero debe tomar los gradientes y el borde desde una receta derivada del tema activo.
- Evitar el fallback blanco genérico si el tema tiene un material propio; un fallback genérico solo debe usarse para temas sin material adicional.
- La sombra del Lens debe ser neutral y discreta; el color de borde y el brillo sí pueden ser temáticos.
- Debe seguir funcionando en barra inferior, rail lateral, layouts de TV y variantes de navegación personalizadas.
- El estado actual de navegación debe ser reconocible sin desenfoque y con animaciones deshabilitadas.

### 5.2 AppBar, scaffolds y superficies globales

AppBar, barras de selección, cabeceras, paneles laterales, bottom sheets, menús y superficies flotantes deben tomar colores del ColorScheme. No introducir un segundo fondo distinto por pantalla. Establecer niveles de superficie coherentes —fondo, contenedor, contenedor elevado, diálogo— y limitar las transparencias a las recetas de material.

Si Glass-Everywhere está desactivado, no aplicar blur por la puerta trasera desde un widget temático. Con el desenfoque activado, preservar contraste de texto y controles. Para componentes de seguridad, el uso de transparencia siempre debe favorecer la lectura por encima de la apariencia.

### 5.3 Barras de sistema, edge-to-edge y orientación

AvesApp contiene la lógica que calcula SystemUiOverlayStyle según el brillo y el fondo. El tema debe actualizar:
- Brillo de iconos del status bar.
- Color de fondo de la barra de navegación del sistema cuando Android no usa transparencia.
- Contraste de iconos del sistema en Edge-to-edge.
- Scrims en la parte inferior/superior cuando la interfaz se superpone al sistema.

Para Pearl e Ivory, si se implementan como temas claros, deben utilizar iconos de sistema oscuros en fondos claros. Para los temas oscuros, usar iconos claros. No suponer que todos los temas Nebula son oscuros. El cambio de tema debe actualizar estos valores sin esperar a reiniciar la app.

---

## 6. Listas, álbumes, colecciones y cuadrículas

El tema debe personalizar el marco y los estados funcionales, no las fotografías:

- Tarjetas de álbum, filas de lista, cabeceras de sección, selección múltiple, selección por rango y contador de elementos: fondos, divisores y acentos procedentes de ColorScheme.
- Álbum o elemento seleccionado: borde y superficie temática más un indicador explícito; no usar solo un halo.
- Favoritos: mantener el símbolo y su significado. El rojo/rubí puede ser la identidad de Nosferatu, pero en los demás temas no forzar que el corazón copie el acento si eso dificulta distinguirlo del estado de peligro.
- Etiquetas y chips: superficie, texto y contorno accesibles. Los chips semánticos (error, estado, archivo, formato) conservan categorías claras.
- Miniaturas seleccionadas: overlay sutil en la zona de interfaz, borde definido; la imagen interior no debe recibir tinte.
- Cargas y placeholders: shimmer discreto usando el acento o la faceta clara del tema, desactivable en rendimiento. No usar un falso error visual mientras carga.
- Estados vacíos: icono funcional y mensaje legible; ilustración temática opcional en segundo plano, sin ocultar instrucciones.
- Error de miniatura: usar el color semántico de error y el icono de contenido roto, no el material especial del candado.

---

## 7. Visor de imágenes, metadatos y reproducción de vídeo

### 7.1 Visor de imágenes

El visor debe proteger la fidelidad visual de la foto. Tema aplicado a:
- Barras y menús superpuestos.
- Botones anterior/siguiente, cerrar, selección, favoritos, protección y más opciones.
- Indicadores de zoom, progreso y controles.
- Paneles de información, metadatos, caption y herramientas.
- Feedback táctil/visual de acciones y borde de selección.

La fotografía en sí, su balance de blancos, brillo, contraste, colores y filtros no se deben modificar al cambiar de tema. Los controles flotantes pueden usar una superficie translúcida temática, pero al tocar una imagen clara la barra necesita scrim suficiente para que sus iconos sigan visibles.

### 7.2 Metadatos y paneles técnicos

Nombres de campo, valores, rutas, EXIF/XMP/IPTC, GPS, histogramas, datos de archivo y detalles técnicos deben mantener jerarquía tipográfica estable. El tema puede distinguir etiquetas, valores, títulos y separadores, pero no asignar colores diferentes a datos simplemente para decorar. Si existe un color por tipo de dato, debe ser constante entre temas y conservar su significado.

En los flujos de eliminar metadatos, mantener el orden visual de resumen, opciones, advertencia y confirmación. El tratamiento del panel puede variar; la semántica de la acción no.

### 7.3 Vídeo y reproductor

Los controles del reproductor son una capa de interfaz: barra de progreso, buffer, botón de loop, play/pause, volumen, brillo, modo de decodificación, errores y overlays. El tema debe colorear sus controles y feedback, pero nunca tintar el frame de vídeo. No tematizar gestos de brillo/volumen como si modificaran los colores del material. En modo rendimiento reducir animaciones decorativas sin comprometer la respuesta al gesto ni el feedback de reproducción.

### 7.4 Panoramas, miniaturas y reproducción en segundo plano

Los fondos inmersivos, panoramas, transiciones de imagen y miniaturas mantienen el contenido original. Si hay un error de carga, usar indicadores de sistema y no una superficie temática que parezca un contenido cifrado.

---

## 8. Privacidad visual: objetos protegidos, ocultos, vaults y papelera

### 8.1 LockedBadge y candados

El sistema visual debe reforzar el estado cerrado sin alterar el significado universal del candado:
- Con el material Rubí/Nosferatu: cadenas rubí, cristal translúcido y el lenguaje del murciélago.
- Obsidian: cadenas o bordes violeta sobre cristal oscuro.
- Aureate: cantos dorados y metal noble, sin confundirlo con una acción exitosa.
- Forge: eslabones con reflejos cálidos de metal fundido.
- Hermetic: contornos geométricos y marcas de precisión, nunca runas que parezcan contraseña.
- Eclipse/Sapphire: luz fría y cristal facetado con formas diferentes.
- Solar Flare/Amber: borde térmico frente a inclusión resinosa.
- Void/Emerald/Aurora: rejilla, veta orgánica y cinta polar respectivamente.
- Crimson/Neon/Onyx/Pearl/Ivory/Imperial: seguir las identidades de la matriz de la sección 13.

El candado no debe depender del color para comunicar que algo está protegido. En rendimiento debe quedar una insignia estática nítida. Las animaciones de recién bloqueado/desbloqueado se reproducen solo cuando corresponda y no en cada rebuild o scroll.

### 8.2 Álbumes protegidos, fotos, favoritos y Hidden Items

El estado protegido debe tener consistencia entre vista de grid, visor, búsqueda, selección y lista de álbumes. Cuando el elemento esté bloqueado, conservar el thumbnail oculto o desenfocado según la lógica existente; no dejar que un overlay de tema revele el contenido ni tape el candado.

La revelación por gesto secreto, el cierre al ir a segundo plano y los controles de privacidad siguen siendo estados de lógica, no estados visuales. Cambiar el tema jamás debe revelar una miniatura ni mantener una vista oculta abierta.

### 8.3 Advanced Vaults

Bóvedas visibles, ocultas, cifradas y en estados de error deben compartir un lenguaje temático coherente:
- Bóveda cerrada: candado, borde y estado cerrado.
- Bóveda desbloqueada: indicador explícito de acceso, sin sustituir el candado por solo un color verde.
- Bóveda cifrada o con error: texto y símbolo específicos; los errores no son una variante estética del tema.
- Compartir/exportar desde un vault: usar el mismo diseño de confirmación de Gargantua que el resto de la app.
- Si no se tiene permiso para abrir la bóveda, el mensaje de bloqueo debe permanecer legible bajo todos los temas.

### 8.4 Papelera protegida

La apariencia de la papelera, sus filas y sus contadores puede ser temática. La diferencia entre eliminar, restaurar y borrar definitivamente debe ser inconfundible. El borrado definitivo conserva el color semántico de peligro y los pasos de confirmación. No reemplazar el rojo de peligro por el verde, violeta o dorado del tema.

---

## 9. App Lock, PIN, Master Code y biometría

Los accesos de seguridad necesitan ser más sobrios que el escaparate Nebula. El tema debe sentirse en materiales, superficies, bordes y acentos; la pantalla de código no debe convertirse en una animación de fondo con texto encima.

### 9.1 App Lock

- Scrim y fondo: tokens de seguridad del tema, con un contraste sólido.
- Campo PIN, dots, cursor y botón de aceptar: tokens comunes de entrada.
- Error de PIN: icono/mensaje de error y color semántico de alerta; la sacudida/háptica existente sigue ligada al evento real y nunca a decoración.
- Enfriamiento: cuenta atrás clara, sin movimiento ornamental que haga parecer que el tiempo corre más rápido o se detiene.
- Biométrico: usar el flujo de sistema cuando corresponda. La UI de Aves-X solo tematiza el antes/después y el feedback que controla.
- Botón atrás/cancelación: igual significado en todos los temas; no usar el color de acento como sustituto de permiso concedido.

### 9.2 Master Code / cambio de credenciales

La pantalla debe comunicar que es una operación sensible: títulos claros, estado de entrada, aviso de irreversibilidad cuando corresponda y acción primaria visible. Usar el tema para el borde cristalino y la superficie del campo, pero mantener el texto de advertencia y la semántica de fallo fuera de la paleta ornamental.

El tema no debe filtrar el código mediante animaciones, reflejos sobre los dígitos, capturas adicionales ni efectos que cambien la forma en que se ocultan las entradas. La apariencia del teclado puede ser temática; los dígitos, estados y validaciones deben seguir un patrón estable.

### 9.3 Pantalla de objeto protegido

ItemLockScreen ya usa tokens de scrim, superficie y texto, además de una animación de desbloqueo. Extender el acabado por receta y token compartido. El contenido cubierto debe permanecer ilegible en todo momento hasta completar la autenticación válida. El efecto de cristal no debe reducir el scrim de manera que una foto quede visible por detrás.

---

## 10. Fail-Safe, Safe Mode, bienvenida y Lockdown

Esta área requiere la revisión visual más estricta. El tema afecta a la apariencia, pero **Fail-Safe debe conservar autoridad visual y semántica por encima de cualquier efecto temático**.

### 10.1 Principio visual de Lockdown

Lockdown no es una pantalla hero para mostrar VFX. Es una pantalla de restricción real que debe comunicar estado, causa y siguiente paso sin ambigüedad. No mostrar fotos ni miniaturas detrás. No montar la Nebula animada como fondo. No reproducir llamaradas, partículas rápidas o destellos que compitan con el texto de bloqueo.

El lenguaje recomendado es:
1. Scrim de seguridad opaco o suficientemente denso.
2. Panel principal con la superficie y borde del tema.
3. AppMark reconocible.
4. Título de Lockdown claramente jerarquizado.
5. Motivo/explicación legible.
6. Campo y acción para la vía autorizada de recuperación.
7. Estado de cooldown/validación.
8. Mensaje de voz/diagnóstico con un tono secundario, no confundido con el estado principal.

### 10.2 Tokens que debe consumir

Los widgets de Lockdown deben leer NebulaTokens:
- securityScrim: oscurece y oculta el contenido de debajo.
- securitySurface y securityOnSurface: tarjeta de bloqueo y texto.
- securityAccent: borde, foco y control primario.
- securityAlert: alerta real, Safe Mode o fallo.
- securityOk: estado seguro cuando el modelo confirme que lo es.
- securityWarning / securityInfo: advertencias e información.
- securityBubbleSurface, securityBubbleBorder, securityBubbleTail, securityBubbleGlow, securityBubbleShadow y securityBubbleInk: burbuja de la mascota Fail-Safe.
- securityCrystalEdge, securityCrystalHighlight y securityCrystalBody: cristal decorativo.
- securityInputFieldBg / Border: campos de código.
- securityScrimOverlay: bloqueo visual que cubre contenido.

Evitar colores fijos para el texto de la burbuja y el control de audio si existe ya securityBubbleInk u otro token semántico adecuado. Los colores fijos solo se admiten para significados semánticos que deban ser estables y con contraste verificado.

### 10.3 Un toque temático por tema, no una animación completa

- Nosferatu: rubí oscuro y borde carmesí; brillo breve en el cristal, sin una animación continua que sugiera salida de Lockdown.
- Obsidian: superficie negra violeta; una faceta o grieta fría, contenida.
- Aureate: latón envejecido en el marco; nada de rayos divinos activos en una pantalla de restricción.
- Forge: borde de metal caliente muy tenue; evitar una llamarada debajo del código.
- Hermetic: contorno geométrico estático; sigilo decorativo fuera del área de entrada.
- Eclipse: halo cian tenue, no corona móvil tras el texto.
- Solar Flare: degradado oscuro térmico en el borde, sin pulsos de gran brillo.
- Void: rejilla casi invisible; el mensaje debe dominar.
- Crimson: acento granate controlado y alerta siempre semántica.
- Neon: detalles magenta/cian limitados a bordes; sin tubos parpadeantes.
- Emerald: una veta fija fuera del texto.
- Aurora: degradado verde-hielo estático.
- Sapphire: facetas sutiles en los bordes, campo de entrada liso.
- Amber: resina translúcida solo en el marco, no detrás de los dígitos.
- Onyx: grafito y alto contraste sin efectos saturados.
- Pearl/Ivory: superficies claras solamente si el texto oscuro y todos los estados de bloqueo superan revisión específica de contraste; si aún no están certificados, usar un modo de seguridad de alto contraste y no dejar texto claro sobre blanco.
- Imperial: acero y filetes de latón, con sello o insignia estática, sin que parezca un panel de juego.

### 10.4 Safe Mode y Fail-Safe Badge

La insignia de Fail-Safe puede usar el material de AppMark y la paleta del tema; el color de su estado debe proceder del token semántico adecuado. Safe Mode no es un tema alternativo y no debe forzar la interfaz a rojo completo. La alerta se expresa con icono, título y texto claros.

En el estado normal, el indicador puede usar animación de radar suave. En alerta, modo de rendimiento o movimiento reducido, debe detenerse o quedar estático sin perder su significado. La insignia no debe implicar que Fail-Safe está activo si el modelo indica lo contrario.

### 10.5 Bienvenida, configuración y burbujas de voz

La bienvenida de Fail-Safe debe conservar el orden y la claridad de sus pasos en todos los temas. Las burbujas cómicas pueden adoptar el material del tema con un contraste sólido para texto. Los mensajes por voz, el indicador de audio no disponible y los reportes de diagnóstico deben usar iconos y textos coherentes, no depender de animación.

### 10.6 Nuke y confirmaciones destructivas

No themedizar el peligro hasta volverlo un acento opcional. Conservar:
- Título explícito de borrado irreversible.
- Color semántico de peligro.
- Retraso, hold o palabra de confirmación que ya requiera el flujo.
- Cancelación igual de legible y accesible.
- Estado de progreso y finalización sin falsos estados de éxito.
- No usar la misma animación para un borrado destructivo y una acción común.

El tema puede aportar una superficie oscura, borde y reflejo sutil, pero no reemplazar el lenguaje de peligro ni la verificación existente.

---

## 11. Gargantua: compartir, exportar, copiar, abrir con y transmitir

Gargantua es una política de salida de archivos, no un adorno visual. Todas sus pantallas deben compartir un marco visual coherente y mantener claro qué salida se está solicitando.

- El encabezado y cada categoría pueden adoptar el tema, con iconos semánticos de compartir/exportar/portapapeles/open-with/cast.
- Toggles, resumen de políticas y reglas de Master Code deben utilizar estados estándar de Material con acento temático.
- El estado bloqueado por política debe diferenciarse de error técnico, permiso del sistema denegado y acción cancelada.
- Si compartir exige Master Code, la vista de autenticación debe seguir el contrato de App Lock/Master Code.
- La pantalla de aprobación de salida puede tener un borde cristalino o una tarjeta, pero no un indicador verde previo a que la salida haya sido autorizada realmente.
- Errores de lectura de política deben seguir cerrándose de forma segura (fail-closed); el tema nunca debe cambiar un estado bloqueado a permitir.
- La selección de tema no puede modificar el alcance de compartición, permisos, destinos o el contenido del archivo que sale.

---

## 12. Ajustes, controles comunes, Nebula y temas personalizados

### 12.1 Controles comunes de Ajustes

Aplicar el ColorScheme de forma consistente a:
- AppBar y cabeceras de sección.
- Tiles, subsecciones y tarjetas.
- Interruptores, checkbox, radio, slider, segmented control, dropdown, campo de texto y botones.
- Divisores, tooltips, menús contextuales y barra de búsqueda de ajustes.
- Pegatinas NEW/Experimental, indicadores de progreso y estados informativos.

Las pegatinas deben mantener una diferencia semántica entre nuevo y experimental. No asignar a cada tema su propia etiqueta saturada; usar un sistema común y legible.

### 12.2 Pestaña Nebula y selector

La pestaña Nebula es el lugar principal para mostrar efectos completos y personalidad visual. Puede presentar el VFX activo, un título, una descripción y una previsualización. La lista de temas debe:
- Indicar tema seleccionado con borde/indicador y texto, no solo color.
- Identificar las opciones experimentales si corresponde según el estado comprobado en la rama actual.
- Mantener descripciones cortas que expliquen material y movimiento.
- Evitar iniciar 17 controladores de animación a la vez solo porque todos los temas se muestran en un Wrap.
- Detener y destruir efectos de la previsualización anterior al cambiar de tema.
- Permitir que el usuario previsualice sin que los efectos se propaguen a su galería.
- Dejar constancia si un tema es oscuro o claro cuando esa diferencia tenga importancia práctica.
- Conservar el modo de rendimiento y las preferencias de accesibilidad.

### 12.3 Temas personalizados

El editor de temas personalizados necesita los mismos principios:
- Vista previa fiel a la paleta que se está editando, con muestra de fondo, tarjetas, texto, iconos, acción primaria, error, alerta y selección.
- Contraste y validación antes de importar o activar. Valores ausentes/corruptos deben caer en defaults seguros.
- Importar/exportar el tema como datos visuales, sin introducir código ejecutable ni efectos inseguros.
- Tema desconocido o efecto ausente: render estático seguro, nunca crash o superficie en blanco.
- El tema personalizado debe poder teñir AppMark, Nav Lens, LockedBadge y las tarjetas de seguridad a partir de tokens; no depender de un switch por nombre enum.
- Borrar un tema personalizado usa el color semántico de peligro y confirmación común, no el acento de la paleta que se está borrando.
- El contenido exportado por Aves-X no debe quedar modificado por el tema de la UI.

---

## 13. Identidad aplicada por tema en toda la aplicación

Esta tabla establece el matiz que debe percibirse en iconos activos, AppMark de tono temático, Nav Lens, selección, tarjetas y material de bloqueo. La geometría funcional permanece estable.

| Tema | Tratamiento global de UI | AppMark / iconos destacados | Material de controles protegidos |
|---|---|---|---|
| Aves | Material nativo, sin VFX adicionales | Colores estándar del tema Aves y marca estable | Candado estándar |
| Nosferatu Glass | Cristal rubí ahumado, bordes granate y reflejos carmesí | Facetas rubí; identidad Bat-Curity | Cadenas rubí y cristal rojo |
| Obsidian Glass | Superficies negras-violetas y bordes facetados | Brillo violeta frío | Cristal de obsidiana y cadenas violetas |
| Aureate Glass | Oro antiguo, bronce y reflejos cálidos | Facetas oro/champán | Metal dorado ceremonial |
| Forge Glass | Base índigo con costuras naranjas discretas | Reflejo de metal fundido | Eslabón oscuro con glints cálidos |
| Hermetic Glass | Verde esmeralda geométrico y detalles violeta | Sigilo geométrico decorativo | Bordes precisos y anillos estáticos |
| Eclipse Glass | Medianoche azul con halo orbital cian | Corona circular sutil | Cristal oscuro con halo cian |
| Solar Flare Glass | Carbón térmico, naranja solar y oro luminoso | Destello radial controlado | Reflejo térmico en el borde |
| Void Glass | Grafito mate y señales verdes precisas | Línea técnica verde, poco glow | Borde de cuadrícula técnica |
| Crimson Glass | Granate oscuro, un halo compacto y reflejo rosa | Pulso granate de baja intensidad | Cristal carmesí contenido |
| Neon Glass | Negro reflectante y contraste magenta/cian | Doble acento en botones principales | Segmentos neón, sin parpadeo |
| Emerald Glass | Mineral verde profundo con vetas doradas | Veta orgánica y oro envejecido | Cristal mineral con una veta |
| Aurora Glass | Ondas polares turquesa y azul hielo | Gradiente polar, movimiento opcional | Borde polar difuso estático |
| Sapphire Glass | Zafiro tallado y refracción cian | Facetas angulares azules | Cristal facetado frío |
| Amber Glass | Resina fósil, miel e inclusiones discretas | Núcleo miel translúcido | Material resinoso contenido |
| Onyx Glass | Negro puro, grafito y plata monocroma | Reflejo diagonal sin saturación | Grafito minimalista |
| Pearl Glass | Nácar claro, iridiscencia pastel suave | Reflejo perla/pastel controlado | Superficie clara validada y candado oscuro |
| Ivory Glass | Porcelana/papel de algodón y filigrana champán | Oro champán y marfil | Contorno claro cálido con texto oscuro |
| Imperial Glass | Acero pavonado, remaches, latón y archivos de pergamino | Acero con acento de insignia dorada | Placa metálica y filetes de latón |

Los tratamientos de tabla son pautas para la aplicación completa; los colores concretos se definen en Aves-X_Nebula_Theme_Design_Spec_ES.md. No crear un color semántico de peligro diferente para cada fila.

---

## 14. Superficies menores y estados que suelen olvidarse

La cobertura temática no estará completa hasta revisar también:

- Menús emergentes, menús de contexto de álbum/foto y el menú del visor.
- Tooltips, banners, snackbars, mensajes de confirmación, mensajes de error y estados de operación completada.
- Búsqueda global, query chips, filtros expandibles y estados sin resultados.
- Explorador de carpetas, rutas, control de .nomedia y carpetas ocultas.
- Página de estadísticas, contadores, gráficos, histograma y leyendas.
- Mapas, marcadores, etiquetas de mapa y paneles geográficos. No tematizar los tiles/mapas de forma que falseen sus colores o símbolos.
- Editor, herramientas, selección de recorte/área, botones de confirmar/cancelar y estados de guardado.
- Captions, etiquetas, favoritos, etiquetas de formato y mensajes de metadatos.
- Pantallas de impresión, exportación e informe: el tema puede afectar el diálogo mientras está en la app, nunca cambiar el contenido del archivo exportado.
- Accesos directos, home widgets y páginas Acerca de. Mantener la marca estable y seguir el ColorScheme local solo en los widgets que el usuario perciba como parte de la app.
- Rotación, cambio entre móvil/tablet/TV, pantallas estrechas y foco con teclado o mando.
- Estados de conectividad o permisos que dependan del sistema: el componente de sistema no siempre se puede tematizar; la UI de Aves-X sí debe armonizarse al regresar.

No perseguir cambios cosméticos en rutas que muestran contenido nativo del sistema operativo fuera del control de Aves-X. Documentar esas limitaciones en lugar de crear una imitación de una UI del sistema que no se puede controlar.

---

## 15. Pearl e Ivory: excepción clara con verificación reforzada

Pearl e Ivory deben convertirse en temas claros reales, no en fondos negros con acentos claros. Para ello el agente debe comprobar la implementación efectiva, incluida la propiedad de brillo de NebulaPalette, darkOnly, el ColorScheme resultante y los tokens.

Pruebas obligatorias:
- Texto normal, pequeño y secundario.
- Iconos seleccionados y no seleccionados.
- Divisores, contornos, campos de código y sus errores.
- Diálogos, bottom sheets, nav bar y Nav Lens.
- LockedBadge y candado sobre imágenes claras y oscuras.
- ItemLockScreen, App Lock, Fail-Safe Welcome y Lockdown.
- Burbujas de Fail-Safe y controles de audio no disponible.
- Nuke/confirmación de borrado, error real y alerta.
- Barra de estado Android, barra inferior del sistema, Edge-to-edge.
- Glass-Everywhere encendido/apagado, modo de rendimiento y movimiento reducido.

No asumir que un token de seguridad originalmente diseñado para fondos oscuros sirve para un tema claro. Si el contraste no puede garantizarse, utilizar un modo de seguridad de alto contraste separado del acabado ornamental.

---

## 16. Rendimiento, accesibilidad y respuesta de interacción

### Movimiento
- El ajuste settings.animate y el modo de rendimiento deben detener animaciones no esenciales.
- Al detener una animación, dejar un estado estático atractivo; no una opacidad a cero, un reflejo cortado o una tarjeta vacía.
- Las animaciones del candado solo responden al evento real y deben evitar reproducirse de nuevo por rebuild.
- Los temas dinámicos no deben ejecutar varios VFX complejos simultáneamente fuera de la pestaña de previsualización.

### Cristal y desenfoque
- No exigir blur como requisito para que un panel sea legible.
- La transparencia debe ajustarse según la superficie y el brillo de la imagen que hay detrás.
- Con Glass-Everywhere desactivado, las tarjetas deben seguir pareciendo parte del tema mediante color, borde y elevación, sin una capa de blur oculta.

### Contraste y accesibilidad
- Objetivo mínimo: contraste equivalente a WCAG AA para texto ordinario (4.5:1) y controles/bordes relevantes (3:1), salvo los casos de texto grande según el estándar.
- Las señales de estado no dependen solo de color; combinar color, icono, texto y forma.
- Respetar tamaño de fuente, navegación por teclado/mando, foco visible y etiquetas semánticas.
- Evitar flashes, luces en frecuencia alta y animaciones que hagan difícil concentrarse.
- Usar los mismos nombres y el mismo orden semántico de controles en todos los temas para que el tema no implique reaprender cómo bloquear o confirmar algo.

### Prueba de rendimiento
Nebula puede producir efectos ricos en su pestaña, pero el resto de la galería debe priorizar fluidez. Medir scroll de grid, navegación, cambio de tema, aparición de paneles y Lockdown sobre un dispositivo de gama baja. No inferir que es liviano solo porque el pintor esté aislado.

---

## 17. Mapa de integración por archivos y límites de propiedad

Los archivos de esta lista fueron confirmados en la rama actual o aparecen como rutas de propiedad explícitas en AGENTS.md. El agente debe revisar el archivo antes de modificarlo, porque puede haber cambios posteriores.

### Tema, paletas y material
- lib/theme/themes.dart
- lib/theme/icons.dart
- lib/theme/colors.dart
- lib/theme/nebula/nebula_palette.dart
- lib/theme/nebula/nebula_palettes.dart
- lib/theme/nebula/nebula_theme.dart
- lib/theme/nebula/nebula_tokens.dart
- lib/theme/nebula/nebula_material.dart
- lib/theme/nebula/nebula_effect.dart
- lib/widgets/aves_app.dart
- lib/widgets/common/fx/app_mark.dart

### Navegación, controles y superficies
- lib/widgets/navigation/nav_bar/nav_bar.dart
- lib/widgets/common/basic/feature_sticker.dart
- lib/widgets/common/fx/lock_animation.dart
- lib/widgets/common/fx/failsafe_badge.dart
- lib/widgets/dialogs/aves_dialog.dart
- lib/widgets/dialogs/danger_confirmation.dart
- lib/widgets/dialogs/failsafe_comic_dialog.dart
- lib/widgets/settings/display/display.dart
- lib/widgets/settings/nebula/nebula_tab.dart
- lib/widgets/settings/nebula/nebula_theme_selector.dart
- lib/widgets/settings/nebula/custom_nebula_theme_page.dart

### Seguridad y privacidad
- lib/widgets/security/app_lock_gate.dart
- lib/widgets/security/failsafe_lockdown.dart
- lib/widgets/security/failsafe_welcome.dart
- lib/widgets/security/item_lock_screen.dart
- lib/widgets/settings/security/security.dart
- lib/widgets/settings/security/failsafe_section.dart
- lib/widgets/settings/privacy/gargantua_page.dart
- lib/widgets/viewer/action/
- lib/widgets/collection/action/
- lib/model/security/
- android/

### Reglas de coordinación de AGENTS.md
- nebula-theme es propietario del motor visual en lib/theme/**, la mayor parte de lib/widgets/common/fx/**, ciertos ajustes visuales y aves_app.dart.
- aves-ui es propietario de navegación, iconos y UI general; Nav Lens y el tile del selector se consideran superficies compartidas.
- failsafe-ui es propietario de lib/widgets/security/**, lib/widgets/settings/security/**, failsafe_comic_dialog.dart, failsafe_badge.dart y lock_animation.dart.
- gargantua es propietario de la lógica de salidas, acciones, modelo de seguridad y android/**.
- Nebula define tokens; Fail-Safe los consume. Los agentes de tema/UI no deben tocar la lógica de seguridad para hacer que una prueba pase.
- AGENTS.md reserva compilación/publicación al auditor. La implementación debe mantener la revisión y el build remoto del repositorio; esta especificación no solicita una build.

La matriz anterior es un contrato visual, no permiso para saltarse la propiedad de archivos. Si un cambio cruza de tema/UI a lógica de seguridad o exportación, coordinar con el propietario correspondiente.

---

## 18. Orden recomendado de implementación

1. **Mapa real de tokens y hardcodes:** localizar colores literales de componentes temáticos; distinguir decoración de colores semánticos. Priorizar colores residuales en Lockdown, burbuja, app mark, candado, Nav Lens y diálogos.
2. **Definir la receta común:** asegurar un fallback temático derivado de NebulaPalette para todos los temas, incluidos temas personalizados. Evitar nuevos switches parciales por enum.
3. **App shell y componentes globales:** ColorScheme, AppBar, system bars, navegación, Lens, botones, campos, chips, dividers, loading/error.
4. **Marca e iconos:** AppMark por tokens; mantener glifos funcionales estables; asegurar estado activo/deshabilitado/foco.
5. **Contenido visual:** grid, selección, filtros, búsqueda, visor, vídeo, metadata, mapas y estadísticas; validar que la foto/video no cambian.
6. **Elementos protegidos:** LockedBadge, ItemLockScreen, vaults, trash, hidden items; mismo material y semántica en todas las vistas.
7. **Seguridad crítica:** App Lock, PIN, Master Code, Fail-Safe, Safe Mode, bienvenida, Lockdown y confirmaciones. Cambios visuales revisados por failsafe-ui; no tocar lógica.
8. **Temas claros:** implementar y validar Pearl/Ivory como excepciones claras, incluyendo estados de seguridad y barras del sistema.
9. **Personalización y estados extremos:** importar/exportar tema, esquema corrupto, paleta ausente, rendimiento, movimiento reducido, tamaño de fuente alto y UI para TV.
10. **Documentación y release:** actualizar README/ROADMAP para describir el estado actual de cada tema; incluir capturas comparables y los resultados del build remoto auditado.

No implementar todas las áreas en una sola modificación gigante. Dividir por propietario y mantener cambios pequeños, revisables y reversibles.

---

## 19. Matriz de aceptación de extremo a extremo

Cada tema debe pasar esta matriz antes de considerarse pulido:

| Contexto | Qué comprobar |
|---|---|
| Inicio / app shell | Fondo, AppBar, iconos, status bar, navegación del sistema |
| Navegación | Activo/inactivo, Nav Lens, foco, navegación móvil/TV |
| Grid de álbumes | Scroll fluido, selección, favoritos, estados vacíos/error |
| Visor de foto | Controles legibles; píxeles de la foto no cambian |
| Reproductor de vídeo | Controles, timeline, loop; frame de vídeo sin tinte |
| Metadatos / captions | Etiquetas, valores, errores y texto largo |
| Explorador | Ruta, carpetas ocultas y .nomedia |
| Diálogos | Normal, confirmación, error, snackbar y menú |
| Objetos protegidos | LockedBadge, ItemLockScreen, vault, trash, Hidden Items |
| App Lock | Entrada de PIN, error, cooldown y biometría |
| Master Code | Entrada, advertencia y validación legible |
| Fail-Safe | Estado normal, badge, welcome, burbuja y reporte |
| Lockdown | Scrim opaco, mensaje, código y alerta semántica |
| Nuke | Peligro, retraso/hold, palabra, cancelación y progreso |
| Gargantua | Reglas de salida, Master Code, bloqueos y error fail-closed |
| Temas personalizados | Importar, previsualizar, valores ausentes y eliminar |
| Accesibilidad | Texto grande, foco, movimiento reducido, contraste elevado |
| Rendimiento | Modo rendimiento y dispositivo modesto |
| Brillo claro | Pearl/Ivory con contraste validado si están habilitados |
| Contenido exportado | Sin tintes, bordes, overlays ni elementos de tema |

### Condiciones mínimas de aprobación

- No quedan colores literales que contradigan el tema activo, salvo colores semánticos documentados.
- No existe una pantalla de seguridad que se vea desbloqueada, exitosa o segura cuando su estado real dice lo contrario.
- Ningún efecto oculta texto, un campo de PIN, un botón de cancelar o un aviso de borrado irreversible.
- Con animaciones y desenfoque desactivados, todas las pantallas siguen claramente temáticas y utilizables.
- Todos los temas importados o futuros usan los tokens sin necesidad de modificar decenas de widgets.
- No cambia el comportamiento de seguridad, el contenido de media, permisos ni reglas de exportación.
- Las pruebas y la revisión se completan según el flujo de AGENTS.md; no declarar la cobertura completa sin resultado verificable.

---

## 20. Referencias de código

- AGENTS.md: roles, propiedad de archivos y proceso de build/publicación.
- ROADMAP.md: estado declarado de Nebula Engine y Fail-Safe.
- README.md: descripción pública de los temas actualmente anunciados.
- lib/theme/nebula/nebula_theme.dart: catálogo, IDs persistentes y fases.
- lib/theme/nebula/nebula_palettes.dart: paletas de color.
- lib/theme/nebula/nebula_tokens.dart: materiales y tokens especiales de seguridad.
- lib/theme/nebula/nebula_material.dart: recetas de material existentes.
- lib/theme/nebula/nebula_effect.dart: VFX individuales y factoría.
- lib/theme/themes.dart: aplicación de la paleta a ThemeData.
- lib/theme/icons.dart: catálogo de iconos funcionales.
- lib/widgets/aves_app.dart: app shell y configuración de barras del sistema.
- lib/widgets/common/fx/app_mark.dart: identidad visual dentro de la app.
- lib/widgets/common/fx/lock_animation.dart: insignia y animación de elementos bloqueados.
- lib/widgets/common/fx/failsafe_badge.dart: indicador de estado de Fail-Safe.
- lib/widgets/navigation/nav_bar/nav_bar.dart: navegación y Nav Lens.
- lib/widgets/security/app_lock_gate.dart: entrada de App Lock.
- lib/widgets/security/failsafe_lockdown.dart: puerta y pantalla de Lockdown.
- lib/widgets/security/failsafe_welcome.dart: configuración inicial de Fail-Safe.
- lib/widgets/security/item_lock_screen.dart: protección de un elemento.
- lib/widgets/dialogs/aves_dialog.dart y lib/widgets/dialogs/danger_confirmation.dart: diálogos y confirmaciones destructivas.

**Resultado esperado:** el agente implementador debe entregar una temática integral que se sienta coherente en toda la app, informe los componentes cubiertos y los pendientes, documente toda excepción y adjunte verificación real de rendimiento, contraste y build. Este documento por sí solo no afirma que la implementación esté terminada.
