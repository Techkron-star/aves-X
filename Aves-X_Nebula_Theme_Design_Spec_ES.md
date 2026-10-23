# Aves-X · Nebula Engine
## Especificación visual propuesta para los 17 temas de fase 2

**Estado:** documento de diseño; no aplicado al repositorio.  
**Referencia inspeccionada:** rama `develop` de `Techkron-star/aves-X`.  
**Alcance:** identidad temática, paletas, superficies cristalinas, tokens visuales, VFX, movimiento y reglas de accesibilidad. No incluye otros subsistemas de Aves-X.

---

## 1. Auditoría del estado actual

El repositorio declara 19 valores en `NebulaTheme`: el tema base Aves, Nosferatu Glass y **17 temas de fase 2**. Las 19 paletas existen en `nebula_palettes.dart`; `NebulaTokens.fromPalette` contempla los tratamientos; y `nebulaEffectFor` ya conecta los 17 temas de fase 2 con un efecto propio. Sin embargo, `NebulaThemeInfo.phase` clasifica todo salvo Aves y Nosferatu como fase 2, y el selector usa `enabled: t.isPhase1`. Por tanto, **los 17 temas continúan deshabilitados en el selector aunque ya tengan implementación visual**.

Esto significa que el trabajo visual no parte de cero: conviene refinar y diferenciar las identidades existentes, no reemplazar todo sin necesidad. Se encontraron además algunas discrepancias entre comentarios y código: comentarios antiguos dicen que los VFX de fase 2 todavía no existen; el README solo enumera cinco temas; y el comentario del selector no refleja los 17 temas registrados.

### Riesgos visuales detectados

- **Eclipse / Sapphire:** ambos parten de azules oscuros con reflejos cian; necesitan siluetas y comportamientos diferentes, no solo otro tono de azul.
- **Solar Flare / Amber:** ambos usan naranja y oro; Solar Flare debe sentirse como plasma estelar y Amber como resina fosilizada con inclusiones.
- **Hermetic / Emerald / Void:** comparten el verde. Hermetic debe ser geométrico y alquímico; Emerald, orgánico y vegetal; Void, técnico, cuadriculado y casi vacío.
- **Pearl / Ivory:** se describen como claros y luminosos, pero las superficies actuales son oscuras. La propuesta los convierte en las dos excepciones claras de la colección, sujetos a pruebas de contraste en pantallas reales.
- **Imperial:** tiene una base prometedora —acero pavonado, remaches y luz de inspección— que merece un lenguaje industrial-gótico propio, no un simple tema gris con dorado.

---

## 2. Contrato común para todos los temas

### Funciones de cada capa

1. **Paleta (`NebulaPalette`):** define color de fondo, contenedores, contorno, acento, halo y facetas del material cristalino.
2. **Tokens (`NebulaTokens`):** deben transferir la identidad a tarjetas de Fail-Safe, pantallas de bloqueo, campos de entrada, burbujas y bordes de seguridad. Los colores semánticos de éxito, advertencia, alerta e información conservan significado y legibilidad; no se recolorean arbitrariamente para encajar con la decoración.
3. **VFX (`NebulaEffect`):** funciona como ambiente temático en la pestaña Nebula y en las previsualizaciones. No debe animar por encima de las fotografías, entorpecer la lectura ni convertir cada pantalla de la aplicación en una escena cargada.
4. **Material:** las superficies deben compartir una física reconocible de cristal, metal, resina, nácar o piedra, pero cada tema necesita una firma visual que no se pueda confundir con otra.

### Reglas de movimiento y rendimiento

- Cada animación debe tener un ciclo fluido y repetible, sin saltos visibles al reiniciarse.
- Ritmo lento por defecto: normalmente entre 10 y 22 segundos por ciclo. Evitar destellos rápidos, flashes de pantalla, parpadeo estroboscópico y cambios bruscos de luminancia.
- El ajuste de movimiento reducido y el modo de rendimiento deben detener el avance animado y dejar un fotograma estático compuesto deliberadamente, no una pantalla vacía.
- Mantener el VFX en una capa aislada (`RepaintBoundary` / `CustomPaint`) y evitar reconstrucciones generales por fotograma.
- No hacer que las señales de seguridad dependan del color o del VFX: icono, texto y jerarquía visual deben seguir bastando sin animación.
- En componentes interactivos, priorizar legibilidad sobre el brillo: el efecto de cristal sirve como borde o reflejo, nunca como una capa opaca sobre el texto.

### Escala de intensidad

- **Nivel 0 — material estático:** bordes, gradientes y facetas; sin animación.
- **Nivel 1 — ambiente:** movimiento de baja opacidad en el fondo de Nebula.
- **Nivel 2 — firma temática:** 1 efecto principal y 1 detalle secundario, con pausas visuales.
- Ningún tema necesita más de dos efectos simultáneos prominentes. La singularidad debe proceder de la forma y del movimiento, no de acumular partículas.

---

# 3. Definición propuesta por tema

Las paletas siguientes son **valores objetivo propuestos**, no cambios ya aplicados. Los niveles de superficie se expresan de oscuro a elevado. Los cuatro tonos cristalinos representan faceta iluminada, color central, sombra cromática y profundidad.

## 3.1 Obsidian Glass — *Fuego violeta bajo obsidiana*

**Fantasía visual:** una cámara de obsidiana volcánica con fuego violeta contenido en grietas. Misterioso, oscuro y aristocrático; no debe parecer una copia roja de Nosferatu.

**Paleta objetivo**
- Fondo: `#08050D`
- Superficies: `#0E0817` · `#180D24` · `#241237` · `#321B49`
- Contorno: `#54356F`
- Acento: `#B476FF`; brillo secundario: `#D5B7FF`
- Halo: `#9B5DE5`
- Facetas: `#E7D8FF` → `#A76AEF` → `#62319B` → `#241039`

**Material y componentes:** cristal ahumado con bordes violeta fríos y una sombra interior casi negra. Los botones principales tienen un relleno púrpura translúcido; los secundarios usan contorno fino. En las tarjetas de seguridad, fondo ciruela profundo y una línea violeta, sin teñir de morado los estados de alerta.

**VFX:** mantener el fuego espectral que nace en el borde inferior, con lenguas lentas y asimétricas. Añadir brasas violetas pequeñas que ascienden y desaparecen antes de llegar arriba. Un anillo de invocación casi invisible gira detrás, con opacidad muy baja y sin símbolos legibles que parezcan texto funcional. El núcleo inferior “respira” lentamente; las brasas viajan siempre en la misma dirección para que el bucle no parezca rebobinarse.

**Movimiento:** 16 s por ciclo; las brasas no deben competir con el contenido principal. En reposo, dejar solo una bruma violeta muy tenue.

**No hacer:** rojo sanguíneo dominante, llamas naranjas o demasiados símbolos. El violeta y la silueta ascendente son su firma.

## 3.2 Aureate Glass — *Reliquia de oro antiguo*

**Fantasía visual:** una reliquia conservada en una cámara ceremonial. El oro es noble, pesado y envejecido; no un amarillo neón ni fuego solar.

**Paleta objetivo**
- Fondo: `#100B04`
- Superficies: `#181207` · `#251B0A` · `#34260F` · `#463517`
- Contorno: `#66521F`
- Acento: `#E8C547`; luz: `#FFF0B4`
- Halo: `#F5C542`
- Facetas: `#FFF3C4` → `#E8C547` → `#B8860B` → `#5C430A`

**Material y componentes:** oro cepillado con cantos pulidos y sombras de bronce. Paneles oscuros de cuero o madera lacada, no metal amarillo plano. Los botones destacados simulan una pieza dorada con borde fino; las tarjetas informativas pueden utilizar una superficie tipo pergamino claro solo cuando el contraste lo permita.

**VFX:** un halo elevado sobre el centro superior proyecta rayos dorados anchos y suaves. Motas de oro flotan a distintas profundidades; las partículas grandes centellean ocasionalmente, sin flashes intensos. La luz cae sobre la superficie de manera direccional para dar sensación de volumen y ceremonia.

**Movimiento:** 14–16 s; rayos con vaivén leve y motas que completan trayectorias enteras por ciclo. En estático, mantener el halo y dos o tres rayos de baja opacidad.

**No hacer:** llamaradas naranjas, brillos constantes en todos los bordes ni estética de moneda brillante. Aureate representa prestigio y antigüedad; Solar Flare representa energía.

## 3.3 Forge Glass — *Forja cósmica y metal líquido*

**Fantasía visual:** una forja orbital en una cámara índigo. El violeta es el recinto frío y el naranja es metal incandescente en movimiento.

**Paleta objetivo**
- Fondo: `#070610`
- Superficies: `#0D0A1A` · `#151027` · `#1F1735` · `#2B2045`
- Contorno: `#44365F`
- Acento: `#FF762B`; contrapunto: `#A88AFA`
- Halo: `#FF762B`
- Facetas: `#FFE0A0` → `#FF8A42` → `#F0441E` → `#762009`

**Material y componentes:** cristal violeta sometido a calor desde dentro. El borde caliente aparece solo en tramos, como reflejos del metal; el resto del contorno permanece índigo. Los estados seleccionados utilizan una línea incandescente y no una gran mancha naranja.

**VFX:** remolino de metal fundido que gira lentamente alrededor de un núcleo oscuro, con dos o tres filamentos naranja-dorado y puntos brillantes viajando por sus curvas. El centro pulsa como metal calentado, pero no aumenta de tamaño bruscamente. Añadir una corriente secundaria más fina que sugiera que el material gira dentro de la forja.

**Movimiento:** ciclo continuo de 12–14 s, sin invertir la dirección en cada repetición. El modo estático conserva remolino, núcleo y gradientes en una composición estable.

**No hacer:** duplicar las prominencias solares de Solar Flare ni convertir toda la pantalla en naranja. La identidad Forge es *material fabricado y fundido*, no una estrella.

## 3.4 Hermetic Glass — *Laboratorio alquímico*

**Fantasía visual:** una mesa hermética de trabajo donde geometría, materia y energía se equilibran. Es intelectual, arcano y preciso; no una selva verde.

**Paleta objetivo**
- Fondo: `#030D09`
- Superficies: `#071610` · `#0C2118` · `#143125` · `#1D4030`
- Contorno: `#2F5B47`
- Acento: `#35D8A0`; segundo acento: `#A58AFF`
- Halo: `#35D8A0`
- Facetas: `#B7FFE0` → `#39DDA5` → `#17745A` → `#4B327D`

**Material y componentes:** cristal verde profundo con bordes violetas, como un artefacto tallado. Usar anillos, líneas finas y simetría radial en las previsualizaciones; ningún símbolo debe confundirse con controles reales o estados del sistema.

**VFX:** de tres a cinco anillos concéntricos rotan a distintas velocidades. Pequeños glifos geométricos aparecen en puntos cardinales, casi transparentes, mientras un sigilo central se ilumina lentamente. Una línea violeta recorre uno de los anillos y se apaga; la geometría debe sentirse calculada y no orgánica.

**Movimiento:** ciclo de 16 s; capas en direcciones opuestas, pero sin velocidad vertiginosa. El punto central respira cada 5–6 s.

**No hacer:** raíces, hojas o cintas de luz polar (pertenecen a Emerald y Aurora). Su firma es la geometría concéntrica y el equilibrio.

## 3.5 Eclipse Glass — *Corona durante la totalidad*

**Fantasía visual:** oscuridad espacial cortada por una corona cian que rodea una estrella eclipsada. La silueta circular de la sombra debe identificarlo al instante.

**Paleta objetivo**
- Fondo: `#02040B`
- Superficies: `#071026` · `#0C1940` · `#14245C` · `#1E3277`
- Contorno: `#2A477A`
- Acento: `#00D9FF`; luz: `#9AF5FF`
- Halo: `#00B8F5`
- Facetas: `#E5FCFF` → `#59DFFF` → `#0A83C9` → `#05234F`

**Material y componentes:** vidrio azul medianoche con una fina refracción cian en los bordes superiores. Las superficies se acercan al azul real en elevaciones altas, pero el fondo permanece casi negro. La selección puede formar un arco luminoso parcial, no un rectángulo cian sólido.

**VFX:** disco oscuro que cruza lentamente por delante de un halo de plasma; la corona se vuelve algo más brillante cerca de los “contactos” del eclipse. Añadir una dispersión cian muy fina y algunas partículas heladas lejanas. La escena debe transmitir ocultación y alineación, no una nube genérica.

**Movimiento:** tránsito de 18–22 s; corona continua, sin parpadeos. En estático, silueta y corona quedan visibles con una iluminación moderada.

**No hacer:** estrellas de alto brillo por toda la escena o anillos múltiples como Hermetic. Su firma es **un disco negro y una corona**.

## 3.6 Solar Flare Glass — *Eyección de plasma*

**Fantasía visual:** la superficie de una estrella activa: plasma caliente, arcos magnéticos y una corona que expulsa energía. Más violento que Aureate y menos sólido que Forge.

**Paleta objetivo**
- Fondo: `#0D0302`
- Superficies: `#1B0704` · `#2A0D06` · `#3A1409` · `#4C1E0D`
- Contorno: `#78321A`
- Acento: `#FF632F`; luz: `#FFE16A`
- Halo: `#FF9D24`
- Facetas: `#FFF3A8` → `#FFB33C` → `#FF5A24` → `#991B08`

**Material y componentes:** cristal carbonizado, iluminado por dentro en naranja-rojo. Los reflejos amarillos aparecen en los extremos más calientes; no usar oro uniforme. Los botones principales parecen vidrio oscuro con una fina línea de plasma.

**VFX:** pulsación de una corona solar, dos arcos largos que emergen y regresan a la estrella, y un pulso que recorre la periferia. Un pequeño estallido por ciclo puede iluminar el halo durante un instante controlado, sin flash de pantalla completa. La composición se basa en arcos magnéticos y expansión hacia fuera.

**Movimiento:** 10–12 s, con fases de reposo claramente perceptibles. Evitar pulsos rápidos de luminancia.

**No hacer:** burbujas, inclusiones inmóviles o anillos de miel (Amber). Solar Flare es plasma dinámico y radial.

## 3.7 Void Glass — *La cuadrícula hacia la nada*

**Fantasía visual:** un espacio técnico oscuro cuya rejilla pierde profundidad hacia un punto de vacío. Verde ácido, grafito y precisión; no vida vegetal.

**Paleta objetivo**
- Fondo: `#070A08`
- Superficies: `#101512` · `#19221B` · `#253026` · `#313D31`
- Contorno: `#3B5141`
- Acento: `#AEFF35`; luz secundaria: `#D2FF79`
- Halo: `#8EFF00`
- Facetas: `#F0FFC7` → `#A7F542` → `#4FC23A` → `#173D28`

**Material y componentes:** grafito industrial mate con líneas de luz verde. El brillo aparece como una señal de sistema, no como un cristal orgánico. Botones y controles usan contornos lineales y relleno oscuro; el verde debe mantenerse reservado para selección y acento.

**VFX:** rejilla en perspectiva que se comprime hacia un punto fuera del centro. Ondas rectangulares viajan por las líneas hacia el vacío; unas pocas columnas se encienden y se apagan suavemente. Un fino anillo de calibración puede contraerse lentamente cerca del punto focal, sin convertirse en un ojo circular como Eclipse.

**Movimiento:** 14–18 s, flujo centrípeto continuo. La versión estática mantiene la perspectiva y la retícula sin pulsación.

**No hacer:** raíces, enredaderas o partículas verdes abundantes. La rejilla y el movimiento hacia dentro son su firma.

## 3.8 Crimson Glass — *Corazón de granate*

**Fantasía visual:** granate oscuro bajo presión, como una gema viva encerrada en vino negro. Sensual, denso y contenido; no el rojo brillante de Nosferatu.

**Paleta objetivo**
- Fondo: `#0C0207`
- Superficies: `#18040C` · `#260711` · `#350A19` · `#470D22`
- Contorno: `#651B32`
- Acento: `#D52656`; reflejo: `#FF92B3`
- Halo: `#C21845`
- Facetas: `#FFD0DE` → `#E33264` → `#92123A` → `#400719`

**Material y componentes:** cristal de vino tinto, con un núcleo oscuro y bordes rosa-granate. La selección brilla primero en el borde y luego se estabiliza; no teñir todos los paneles de rojo saturado.

**VFX:** un solo orbe denso con reflejos que recorren su superficie. El orbe se contrae y expande con un latido lento, emitiendo un anillo translúcido que se disuelve antes del siguiente pulso. Un par de partículas oscuras pueden hundirse hacia el centro, sugiriendo presión líquida, no gotas literales.

**Movimiento:** pulso principal cada 7–8 s; el halo de borde queda presente entre pulsos. Reducir la variación de brillo para usuarios sensibles al movimiento.

**No hacer:** llamaradas, llamas ascendentes o destellos blancos. Su firma es el latido cerrado de una gema, no un incendio.

## 3.9 Neon Glass — *Circuito nocturno*

**Fantasía visual:** una instalación de neón futurista: carteles eléctricos, tubos transparentes y circuitos urbanos después de medianoche.

**Paleta objetivo**
- Fondo: `#08000B`
- Superficies: `#150018` · `#23002B` · `#330040` · `#460055`
- Contorno: `#65226C`
- Acento magenta: `#FF2BD6`; acento cian: `#24EFFF`
- Halo: `#FF35D8`
- Facetas: `#C8FFFF` → `#20E9FF` → `#FF42D8` → `#812EFF`

**Material y componentes:** vidrio negro reflectante con tubos magenta y cian separados en lugar de mezclarse siempre en violeta. La selección puede tener un pequeño segmento luminoso que recorre el contorno; no hacer que los textos parezcan neón borroso.

**VFX:** dos anillos tubulares desfasados, uno magenta y otro cian. Una línea de escaneo estrecha recorre la escena y un segmento de tubo puede apagarse y reencenderse una vez por ciclo, con una transición suave. Añadir una retícula urbana solo como detalle de muy baja opacidad.

**Movimiento:** 10–12 s; cualquier “glitch” es breve, ocasional y no implica flashes. Nunca usar intermitencia rápida ni alternar toda la pantalla entre colores.

**No hacer:** saturar cada superficie con magenta, ni usar ruido digital continuo. La firma es el contraste de dos tubos luminosos bien definidos.

## 3.10 Emerald Glass — *Raíces de esmeralda*

**Fantasía visual:** cristal verde profundo atravesado por venas vegetales y oro antiguo. Orgánico, antiguo y paciente; contrapunto natural a la precisión de Hermetic.

**Paleta objetivo**
- Fondo: `#00110B`
- Superficies: `#001A11` · `#00251A` · `#003629` · `#064638`
- Contorno: `#1C5A43`
- Acento: `#26C77A`; oro secundario: `#D8B45B`
- Halo: `#26C77A`
- Facetas: `#C4FFDE` → `#35CC84` → `#08734B` → `#073B2D`

**Material y componentes:** esmeralda de bosque húmedo, con profundidad verde-negra. Las venas doradas solo aparecen en reflejos o bordes seleccionados, como inclusiones minerales. Las tarjetas de seguridad mantienen el verde oscuro como soporte y oro para detalles decorativos; no usar oro como señal de éxito.

**VFX:** ramas de luz verde crecen de manera lenta desde una línea central y se dividen en venas cada vez más finas. Un destello dorado recorre una vena, como luz reflejada dentro de la piedra. La forma es irregular y orgánica: sin círculos perfectos ni símbolos geométricos.

**Movimiento:** 18–20 s, casi imperceptible. Las ramificaciones cambian de intensidad y posición suavemente, no aparecen como raíces dibujadas de golpe.

**No hacer:** verde ácido y cuadrículas (Void), ni anillos alquímicos (Hermetic). Su firma es la ramificación orgánica.

## 3.11 Aurora Glass — *Cintas polares*

**Fantasía visual:** una aurora boreal sobre un horizonte ártico negro. Ligero, etéreo y frío, más fluido que las gemas azules.

**Paleta objetivo**
- Fondo: `#000A12`
- Superficies: `#001520` · `#00232F` · `#003541` · `#0B4A57`
- Contorno: `#17616C`
- Acentos: verde polar `#54F5D0`; azul hielo `#75CAFF`
- Halo: `#28E7D1`
- Facetas: `#DEFFF8` → `#65F0D0` → `#3AB2D7` → `#1A4F91`

**Material y componentes:** cristal casi negro con reflejos cian-verdes muy suaves. Los reflejos se estiran horizontalmente en vez de formar facetas angulares. Las superficies elevadas pueden llevar un gradiente polar sutil de verde a azul.

**VFX:** un resplandor bajo en el horizonte y dos o tres cintas largas que ondulan por encima de él. Cada cinta lleva un desfase diferente; pequeñas motas heladas aparecen en puntos aislados. La corriente debe continuar siempre hacia el mismo lado, sin rebotes visibles.

**Movimiento:** 18–22 s, flujo continuo. Estático: conservar una silueta de cintas suaves y el brillo del horizonte.

**No hacer:** una nube espacial redonda como Eclipse o rayos de estrella como Sapphire. Su firma es el movimiento horizontal ondulado.

## 3.12 Sapphire Glass — *Zafiro tallado*

**Fantasía visual:** una gema de zafiro real iluminada por luz fría. Preciso, nítido y cristalográfico; no un eclipse ni una nebulosa.

**Paleta objetivo**
- Fondo: `#030619`
- Superficies: `#08102B` · `#0F1942` · `#19295D` · `#263979`
- Contorno: `#34518C`
- Acento: azul real `#347AFF`; destello: `#A0E8FF`
- Halo: `#438FFF`
- Facetas: `#EAF7FF` → `#62A7FF` → `#2858CB` → `#101E58`

**Material y componentes:** vidrio facetado con reflejos angulares definidos. Las caras cambian ligeramente de azul real a azul profundo; evitar bordes redondeados como tubos de neón. Los controles seleccionados reciben una pequeña arista cian en lugar de un halo circular grueso.

**VFX:** una forma facetada casi invisible en el centro sirve de reflector. Rayos finos se refractan entre planos y aparecen destellos estelares breves en puntos con fases independientes. El núcleo azul respira lentamente, pero no domina la composición. Los destellos deben ser muy cortos en duración, pero también de baja intensidad para evitar efecto de flash.

**Movimiento:** 12–14 s; los destellos no deben coincidir todos a la vez. Estático: tres o cuatro facetas y un punto de reflejo fijo.

**No hacer:** un disco negro central, anillos orbitales o cintas fluidas. La firma es la refracción angular de una gema.

## 3.13 Amber Glass — *Resina fósil*

**Fantasía visual:** ámbar natural que preserva pequeñas inclusiones dentro de una resina dorada. Cálido, táctil y arqueológico; no una estrella en erupción.

**Paleta objetivo**
- Fondo: `#100900`
- Superficies: `#1B1002` · `#291803` · `#392408` · `#4A300E`
- Contorno: `#68461B`
- Acento: miel `#FFC052`; luz: `#FFE6A1`
- Halo: `#FF9F24`
- Facetas: `#FFF5C7` → `#FFC052` → `#D4771C` → `#6E3409`

**Material y componentes:** resina translúcida de color miel con profundidad, inclusiones y reflejos redondeados. Los botones destacados deben parecer una gota tallada o una placa de ámbar, no metal dorado.

**VFX:** núcleo de miel que respira de forma lenta, con anillos finos que se expanden y se disuelven. Burbujas atrapadas derivan dentro del volumen y una o dos inclusiones oscuras evocan materia fosilizada. El movimiento ocurre en profundidad, como si se mirara a través de resina, no en ráfagas hacia fuera.

**Movimiento:** 16–18 s; los anillos no salen continuamente: alternar una expansión con una pausa. Estático: núcleo translúcido, dos burbujas y un reflejo dorado.

**No hacer:** arcos de plasma, llamaradas o corona solar. Amber es materia preservada; Solar Flare es energía expulsada.

## 3.14 Onyx Glass — *Monocromo absoluto*

**Fantasía visual:** ónix pulido negro, austero y técnico. Es el tema minimalista de la colección: todo lo ornamental se reduce a luz y textura.

**Paleta objetivo**
- Fondo: `#020202`
- Superficies: `#0A0A0A` · `#141414` · `#202020` · `#2D2D2D`
- Contorno: `#3B3B3B`
- Acento: plata gris `#B8B8B8`; reflejo: `#FFFFFF`
- Halo: `#8A8A8A` muy tenue
- Facetas: `#FFFFFF` → `#BDBDBD` → `#666666` → `#252525`

**Material y componentes:** piedra negra con reflejo de grafito en diagonal. Sin acentos cromáticos; los estados interactivos se distinguen por valor, borde y forma, no por una tonalidad brillante. La textura puede llevar pequeñas líneas grabadas, visibles solo cuando les pasa la luz.

**VFX:** una banda de luz gris barre diagonalmente la pantalla y revela un segundo unas marcas finas de grafito. Un viñeteado oscuro conserva la profundidad. No utilizar partículas, rayos ni destellos de color.

**Movimiento:** 14–16 s, barrido en una sola dirección y reinicio imperceptible. Estático: reflejo diagonal fijo de baja intensidad.

**No hacer:** neón blanco exagerado, cian, violeta o verde. La restricción cromática es la identidad, no una carencia.

## 3.15 Pearl Glass — *Nácar iridiscente*

**Fantasía visual:** nácar blanco con iridiscencias de concha. Luminoso y delicado; la belleza procede de cambios de color sutiles, no de alto brillo constante.

**Paleta objetivo**
- Fondo: `#F9F5F8`
- Superficies: `#FFFFFF` · `#F5EAF1` · `#EDE1EC` · `#E2D1E0`
- Contorno: `#CDBACB`
- Acento rosa concha: `#D879A6`; contrapunto opalino: `#A8A3F0`; detalle champán: `#E8D79B`
- Texto principal recomendado: `#2C2430`
- Facetas: `#FFFFFF` → `#F6C5DD` → `#D9D2FF` → `#B5E6F2`

**Material y componentes:** **superficies claras**, con texto oscuro y una sombra gris-lila muy suave. El cristal tiene una reflexión rosa-lila-cian que cambia con el ángulo ficticio. Los botones principales pueden usar rosa concha, pero deben mantener texto de alto contraste; los paneles no deben convertirse en bloques blancos planos.

**VFX:** una ostra o esfera de nácar abstracta, representada por una cáscara de gradientes iridiscentes que gira lentamente. Un halo blanco respira, mientras reflejos pastel recorren una curva. No usar partículas brillantes de gran tamaño.

**Movimiento:** 20–22 s; la iridiscencia cambia lentamente sin parpadeos. Para movimiento reducido, dejar un gradiente nacarado con un reflejo fijo.

**Nota técnica:** pasar la paleta a `Brightness.light` implica verificar estilos de todos los componentes y pantallas de seguridad. La propuesta requiere revisar contraste de texto, bordes, diálogos y estados antes de desbloquear el tema.

**No hacer:** mantener paneles gris-negro con solo una etiqueta rosa; eso contradice la promesa de Pearl.

## 3.16 Ivory Glass — *Pergamino y champán*

**Fantasía visual:** marfil cálido de una encuadernación antigua, con filetes de oro champán. Clásico, sereno y editorial; menos iridiscente que Pearl y menos metálico que Aureate.

**Paleta objetivo**
- Fondo: `#FCF8ED`
- Superficies: `#FFFCF2` · `#F4EEDD` · `#EAE0C8` · `#DCCCA7`
- Contorno: `#BCAE90`
- Acento: oro champán `#B58B42`; reflejo: `#DFBD6B`
- Texto principal recomendado: `#29251D`
- Facetas: `#FFFBE8` → `#F0E1B5` → `#D2AE68` → `#94702F`

**Material y componentes:** porcelana mate y papel de algodón, con contornos cálidos. El relieve se expresa mediante líneas finas y sombras color sepia, no con una gran aura luminosa. Botones y controles seleccionados recuerdan una placa con filete dorado.

**VFX:** un baño de luz marfil recorre lentamente la escena. Dos o tres vetas de champán se mecen como filigrana grabada; un reflejo pasa por ellas y se apaga. A diferencia de Pearl, no debe cambiar de rosa a azul: la temperatura se mantiene cálida y estable.

**Movimiento:** 18–20 s, casi estático. En modo reducido se conservan la luz ambiental y los filetes dorados en un estado fijo.

**Nota técnica:** igual que Pearl, requiere un tema claro real (`Brightness.light`) y validación de contraste en controles que tradicionalmente asumían tema oscuro.

**No hacer:** textura de metal amarillo, iridiscencia pastel o crema demasiado amarilla. Ivory es cálido, mate y legible.

## 3.17 Imperial Glass — *Acero, pergamino y autoridad*

**Fantasía visual:** una reliquia de un imperio industrial y gótico: acero pavonado, placas remachadas, sellos de cera, pergamino de archivo y oro de insignia. Debe sentirse monumental, disciplinado y antiguo, con tecnología pesada. Es el tema más ceremonial y arquitectónico de la colección.

**Paleta objetivo**
- Fondo: `#0B0D10`
- Superficies: `#121619` · `#1B2226` · `#252E32` · `#323D41`
- Contorno de acero: `#515D61`
- Metal claro: `#C9B896`; oro de insignia: `#D4A72A`
- Acento secundario, usado con mucha moderación: sello rojo `#8E3037`
- Texto principal: `#E9DFC6`; texto secundario: `#B8B4A8`
- Facetas: `#F0E3C2` → `#C9B896` → `#8B7355` → `#30383D`

**Material y superficies:** el fondo es acero gris-negro con un matiz frío. Las tarjetas se leen como placas montadas: borde exterior de acero, línea interior de latón en esquinas clave y sombreado pesado debajo. Los remaches son detalles puntuales, no decoración repetida en todos los controles. El pergamino se reserva para mensajes narrativos o documentación; nunca se usa detrás de campos sensibles sin comprobar contraste. Los sellos rojos aparecen como pequeñas marcas secundarias, no como un segundo color dominante.

**Botones y controles:** acción principal como una placa de metal oscurecido con texto marfil y una línea dorada fina. Selección: filete oro + un reflejo recorrido lentamente. Acción destructiva: conservar el color semántico de peligro; no camuflarla en oro imperial. Los elementos secundarios reciben borde de acero y menos relieve.

**VFX principal:** lámpara de inspección diagonal que barre una placa de acero. El haz debe revelar arañazos finos y una textura de metal pavonado, no inundar la pantalla de amarillo. Cuatro remaches de las esquinas captan un destello breve y desfasado, como metal que atrapa una fuente de luz. En el centro, una insignia imperial abstracta —inspirada en un águila heráldica sin convertirse en un botón— pulsa con una corona dorada muy tenue. Puede haber una marca de sello rojo apagado cerca del borde inferior, inmóvil.

**VFX secundarios:** micrograbados geométricos en los bordes de tarjetas hero; línea técnica de separación entre secciones; pequeñas marcas tipo inventario en la previsualización, nunca en la interfaz real si parecen texto clicable. El fondo debe sugerir un hangar ceremonial o un archivo de armaduras sin dibujar una escena recargada.

**Movimiento:** 18 s por barrido completo, siempre en una sola dirección. El pulso de la insignia es más lento, unos 14–16 s, y los remaches centellean cada uno en una fase distinta. El modo reducido conserva textura metálica, borde dorado y la insignia tenue, sin barrido animado.

**No hacer:** llenar toda la interfaz de aquilas, calaveras, sellos o remaches; poner oro brillante en cada borde; usar rojo como color de interacción normal; animar los controles de seguridad. Imperial debe parecer una pieza de ingeniería ceremonial, no una armadura de videojuego saturada.

---

## 4. Matriz de separación visual

| Tema | Silueta / forma que lo identifica | Movimiento principal | Material dominante | Color de acento |
|---|---|---|---|---|
| Obsidian | fuego y círculo tenue | brasas ascendentes | obsidiana ahumada | violeta |
| Aureate | halo y rayos descendentes | polvo dorado | oro antiguo | oro cálido |
| Forge | remolino de metal fundido | espiral | cristal índigo incandescente | naranja de forja |
| Hermetic | geometría concéntrica | rotación de anillos | cristal alquímico | esmeralda + violeta |
| Eclipse | disco negro y corona | tránsito orbital | vidrio azul medianoche | cian eléctrico |
| Solar Flare | corona abierta y arcos | eyección hacia fuera | plasma / cristal carbonizado | naranja solar |
| Void | perspectiva convergente | flujo hacia el centro | grafito técnico | verde ácido |
| Crimson | orbe compacto | latido lento | granate líquido | carmesí / rosa |
| Neon | tubos magenta y cian | barrido segmentado | vidrio negro reflectante | magenta + cian |
| Emerald | venas ramificadas | crecimiento orgánico | esmeralda mineral | verde bosque + oro viejo |
| Aurora | cintas horizontales | ondulación continua | cristal polar | verde polar + hielo |
| Sapphire | facetas angulares | refracción / destellos | zafiro tallado | azul real + cian hielo |
| Amber | núcleo con inclusiones | burbujas internas | resina fósil | miel / ámbar |
| Onyx | barrido diagonal neutro | reflejo de grafito | ónix pulido | plata monocroma |
| Pearl | cáscara iridiscente | giro lento | nácar | rosa, lila y cian pastel |
| Ivory | filetes y filigrana | luz suave | porcelana / papel | champán |
| Imperial | placas, remaches e insignia | lámpara de inspección | acero pavonado y latón | oro de insignia |

## 5. Criterios de aceptación antes de habilitar la fase 2

1. Cada tema se puede reconocer con una previsualización de dos segundos por su silueta y movimiento, incluso sin leer el nombre.
2. La paleta de cada tema se aplica de forma coherente a `ColorScheme`, cristales, botones, tokens de Fail-Safe, bloqueos, campos y burbujas; no queda ninguna tarjeta en el color heredado de Nosferatu salvo por decisión explícita.
3. Eclipse no se confunde con Sapphire; Solar Flare no se confunde con Amber; Hermetic no se confunde con Emerald; Void no se confunde con ninguno de los temas verdes.
4. Pearl e Ivory usan superficies claras legibles si se aprueba el cambio a `Brightness.light`; revisar texto primario/secundario, divisores, iconos, diálogos, interruptores, campos y estados de error en todo el flujo de ajustes y seguridad.
5. Ningún efecto interfiere con la lectura o el acceso a controles; el modo de rendimiento y el movimiento reducido presentan un resultado estático deliberado.
6. Cada animación tiene un ciclo estable y no depende de que el usuario mantenga abierta otra pantalla para actualizar estado.
7. Mantener el significado de éxito, información, advertencia y peligro, y no usar oro/violeta/verde temático para invalidar señales semánticas.
8. Probar en un dispositivo modesto con desenfoque activado y desactivado. Evitar combinar demasiados `BackdropFilter`, sombras amplias y pintores complejos simultáneos.
9. Solo después de revisar los criterios anteriores tiene sentido habilitar las 17 opciones en el selector. Habilitar un tema sin revisar el contraste y el modo de movimiento no equivale a darlo por terminado.

---

## 6. Archivos de referencia revisados

- [README.md](https://github.com/Techkron-star/aves-X/blob/develop/README.md) — descripción pública de Nebula Engine; actualmente enumera solo cinco temas.
- [nebula_theme.dart](https://github.com/Techkron-star/aves-X/blob/develop/lib/theme/nebula/nebula_theme.dart) — enum, IDs estables y clasificación de fase.
- [nebula_palettes.dart](https://github.com/Techkron-star/aves-X/blob/develop/lib/theme/nebula/nebula_palettes.dart) — las 19 entradas de paleta.
- [nebula_tokens.dart](https://github.com/Techkron-star/aves-X/blob/develop/lib/theme/nebula/nebula_tokens.dart) — materiales temáticos de superficies de seguridad.
- [nebula_effect.dart](https://github.com/Techkron-star/aves-X/blob/develop/lib/theme/nebula/nebula_effect.dart) — VFX propios y factoría de efectos.
- [nebula_theme_selector.dart](https://github.com/Techkron-star/aves-X/blob/develop/lib/widgets/settings/nebula/nebula_theme_selector.dart) — bloqueo de opciones mediante `isPhase1`.
- [themes.dart](https://github.com/Techkron-star/aves-X/blob/develop/lib/theme/themes.dart) — aplicación de paleta a `ThemeData` y elección entre tema claro y oscuro.

**Nota de ejecución:** esta entrega contiene diseño y criterios de aceptación solamente. No se modificaron archivos del repositorio, no se creó ningún commit, no se abrió ninguna rama ni se hizo push.
