import 'dart:math';

// Fail-Safe's sarcastic lines, said by the character when a code is wrong.
// Tiers: 1 = first failure (mild), 2 = second, 3 = third, 4 = four or more (full roast).
// Everything is just banter aimed at whoever keeps failing: add as many lines as you like.
class FailsafeQuips {
  static final _random = Random();

  static String pick(String languageCode, int fails) {
    final tiers = languageCode == 'es' ? _es : _en;
    final list = tiers[fails.clamp(1, 4) - 1];
    return list[_random.nextInt(list.length)];
  }

  static const _es = <List<String>>[
    [
      'Wao, seguro fue un missclick eso.',
      'Uy. Los dedos gordos, ¿verdad?',
      'Eso no era. Pero tranquilo, a todos nos pasa. A los dueños, al menos.',
      'Casi. Bueno, no. Pero casi.',
      'Ajá. Otra vez, con más convicción.',
      'Primer error. Lo anoto en tu expediente.',
      'Se nota que lo escribiste con seguridad. Lástima que estaba mal.',
      'Mmm... ese no es. ¿Probamos con el número correcto?',
    ],
    [
      '¿Estás seguro de que eres el dueño del teléfono?',
      'Dos. Voy llevando la cuenta, por si preguntan.',
      'Interesante. Ese tampoco.',
      '¿Y si lo pruebas con los ojos abiertos?',
      'Hasta mi abuela adivinaba más rápido, y ni siquiera tengo abuela.',
      'Ese PIN es tan secreto que ni tú lo conoces.',
      'Segundo intento fallido. Mi paciencia es infinita, pero mi sarcasmo no.',
      '¿Así le fallas a tu familia también?',
    ],
    [
      'Ya van tres... empiezo a dudar de tu identidad.',
      'Tres intentos. Un récord de ineptitud, o de mala intención.',
      'Mira que los números son solo diez y aun así.',
      'Yo no juzgo. Bueno, sí. Y me da la risa.',
      'Qué constancia en el error, la verdad. Admirable.',
      'A este ritmo el PIN lo adivinas en el año 2090.',
      'Estás tocando cosas que no son tuyas, ¿verdad?',
      'Esa cara de "yo sí sé el PIN" se te debe estar cayendo ahora mismo.',
    ],
    [
      'Deberías llamar al dueño del teléfono, pareces muy interesado en sus fotos.',
      'Ya. Dime quién eres y de quién es este teléfono. Te escucho.',
      'Esto ya no es un error, es un hobby.',
      'Voy a guardar todo esto con mucho cariño en mi bitácora.',
      'Qué pena que no hayas tenido tanta determinación en cosas más productivas.',
      'No te voy a mentir: me estoy divirtiendo. Tú, no sé.',
      'Cuatro o más. Ni mi calculadora tiene tanta paciencia contigo.',
      'Sigue, sigue, que el que persevera alcanza... un bloqueo más largo.',
      'Si esto fuera un examen, ya estarías repitiendo el año.',
      'Dime que al menos el dueño sabe que estás aquí.',
      'Tanto empeño y tan poco cerebro. Un combo raro.',
      'Mi nivel de sarcasmo sube con cada fallo. Y el tuyo de vergüenza, espero.',
    ],
  ];

  static const _en = <List<String>>[
    [
      'Wow, that was surely a misclick.',
      'Oops. Fat fingers, right?',
      'Not quite. Happens to everyone. Owners, at least.',
      'Close. Well, no. But close.',
      'First mistake. Noted in your file.',
    ],
    [
      'Are you sure you are the owner of this phone?',
      'Two. I am keeping count, in case anyone asks.',
      'Interesting. That one was wrong too.',
      'That PIN is so secret even you do not know it.',
      'Try with your eyes open this time?',
    ],
    [
      'That is three... I am starting to doubt who you are.',
      'There are only ten digits and still.',
      'I do not judge. Well, I do. And it makes me laugh.',
      'At this pace you will guess it around the year 2090.',
      'Touching things that are not yours, are we?',
    ],
    [
      'You should call the phone owner, you seem very interested in their photos.',
      'This is no longer a mistake, it is a hobby.',
      'I will keep all this in my logbook, fondly.',
      'I am not going to lie: I am having fun. You, I am not sure.',
      'If this were an exam you would be repeating the year.',
      'So much effort and so little brain. A rare combo.',
      'My sarcasm goes up with every failure. I hope your embarrassment does too.',
    ],
  ];
}
