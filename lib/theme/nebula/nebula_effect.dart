import 'dart:math' as math;
import 'dart:ui' show BlurStyle, MaskFilter, Path, StrokeCap;
import 'package:flutter/material.dart';
import 'package:aves/theme/nebula/nebula_theme.dart';

// Nebula Engine — visual soul layer.
// Each theme is built from a small number of deterministic vector primitives,
// gradients and glows. The important rule is that the animation describes a
// material or a world; it is never decorative noise.

abstract class NebulaEffect extends StatelessWidget {
  final bool animate;
  const NebulaEffect({super.key, required this.animate});
  CustomPainter painter(double t);
  Duration get duration => const Duration(seconds: 14);
  bool get reverse => false;

  @override
  Widget build(BuildContext context) => _NebulaEffectHost(
    animate: animate,
    duration: duration,
    reverse: reverse,
    painterBuilder: painter,
  );
}

class _NebulaEffectHost extends StatefulWidget {
  final bool animate;
  final Duration duration;
  final bool reverse;
  final CustomPainter Function(double) painterBuilder;
  const _NebulaEffectHost({required this.animate, required this.duration, required this.reverse, required this.painterBuilder});
  @override
  State<_NebulaEffectHost> createState() => _NebulaEffectHostState();
}

class _NebulaEffectHostState extends State<_NebulaEffectHost> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: widget.duration);
  @override
  void initState() { super.initState(); if (widget.animate) _controller.repeat(reverse: widget.reverse); }
  @override
  void didUpdateWidget(covariant _NebulaEffectHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) _controller.repeat(reverse: widget.reverse);
    if (!widget.animate && _controller.isAnimating) _controller.stop();
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (_, __) => RepaintBoundary(child: CustomPaint(
      painter: widget.painterBuilder(_controller.value),
      isComplex: true,
      willChange: widget.animate,
    )),
  );
}

abstract class NebulaEffectPainter extends CustomPainter {
  final double t;
  const NebulaEffectPainter(this.t);
  @override
  bool shouldRepaint(covariant NebulaEffectPainter old) => old.t != t;
}

class _SoulEffect extends NebulaEffect {
  final Duration cycle;
  final bool pingPong;
  final NebulaEffectPainter Function(double) builder;
  const _SoulEffect({required super.animate, required this.cycle, this.pingPong = false, required this.builder});
  @override Duration get duration => cycle;
  @override bool get reverse => pingPong;
  @override CustomPainter painter(double t) => builder(t);
}

// ---------------------------------------------------------------------------
// Forge — a real forge, not a rotating orange gradient.
// ---------------------------------------------------------------------------
class _ForgePainter extends NebulaEffectPainter {
  const _ForgePainter(super.t);
  @override void paint(Canvas c, Size s) {
    final w=s.width,h=s.height,m=math.min(w,h),p=.5+.5*math.sin(t*2*math.pi);
    final bg=Paint()..shader=RadialGradient(colors: const [Color(0x664D1B0A),Color(0x33160B20),Colors.transparent]).createShader(Rect.fromCircle(center: Offset(w*.5,h*.72),radius:m*.9));
    c.drawRect(Offset.zero& s,bg);
    // Heavy furnace plates.
    final plate=Paint()..style=PaintingStyle.stroke..strokeWidth=m*.018..color=const Color(0x447A6A63);
    for(var i=0;i<3;i++){ final y=h*(.28+i*.2); c.drawLine(Offset(w*.08,y),Offset(w*.92,y),plate); }
    // Molten channels.
    final glow=Paint()..style=PaintingStyle.stroke..strokeCap=StrokeCap.round..strokeWidth=m*(.045+.012*p)..color=const Color(0x44FF6D00)..maskFilter=const MaskFilter.blur(BlurStyle.normal,9);
    final hot=Paint()..style=PaintingStyle.stroke..strokeCap=StrokeCap.round..strokeWidth=m*.009..color=const Color(0xFFFFA11A);
    for(var i=0;i<4;i++){
      final x=w*(.16+i*.22); final path=Path()..moveTo(x,h*.94)..cubicTo(x-m*.08,h*.7,x+m*.1,h*.54,x-m*.015,h*.16);
      c.drawPath(path,glow); c.drawPath(path,hot);
    }
    // Flying sparks.
    final rnd=math.Random(41); final dot=Paint();
    for(var i=0;i<28;i++){final q=(t*(1+rnd.nextInt(3))+(i*.071))%1; final x=(rnd.nextDouble()*w+math.sin(q*8+i)*10); final y=h*(.9-q*.78); final a=math.sin(math.pi*q); dot.color=const Color(0xFFFFC247).withValues(alpha:a*.8); c.drawCircle(Offset(x,y),.7+rnd.nextDouble()*1.5,dot);}
  }
}

// ---------------------------------------------------------------------------
// Hermetic — measured alchemical instrument.
// ---------------------------------------------------------------------------
class _HermeticPainter extends NebulaEffectPainter {
  const _HermeticPainter(super.t);
  void ring(Canvas c,Offset o,double r,double rot,Color color){final p=Paint()..style=PaintingStyle.stroke..strokeWidth=1.2..color=color; c.save();c.translate(o.dx,o.dy);c.rotate(rot);c.drawCircle(Offset.zero,r,p);c.drawLine(Offset(-r,-r*.28),Offset(r,r*.28),p);c.drawLine(Offset(-r,r*.28),Offset(r,-r*.28),p);c.restore();}
  @override void paint(Canvas c,Size s){final o=Offset(s.width*.5,s.height*.5),r=s.shortestSide*.27,a=t*2*math.pi;
    c.drawRect(Offset.zero&s,Paint()..shader=RadialGradient(colors:const[Color(0x331B6A45),Color(0x140A1020),Colors.transparent]).createShader(Rect.fromCircle(center:o,radius:s.shortestSide*.75)));
    for(var i=0;i<4;i++) ring(c,o,r*(.72+i*.23),a*(i.isEven?1:-.6)+i*.8, i.isEven?const Color(0x6638D39A):const Color(0x553E75FF));
    final sig=Paint()..style=PaintingStyle.stroke..strokeWidth=2..color=const Color(0xAA4DE7B0); final path=Path()..moveTo(o.dx,o.dy-r*.45)..lineTo(o.dx+r*.39,o.dy+r*.25)..lineTo(o.dx-r*.39,o.dy+r*.25)..close();c.drawPath(path,sig);
    c.drawCircle(o,r*.1,Paint()..color=const Color(0x6638D39A)..maskFilter=const MaskFilter.blur(BlurStyle.normal,10));
  }
}

// ---------------------------------------------------------------------------
// Eclipse — occultation, corona and gravitational distortion.
// ---------------------------------------------------------------------------
class _EclipsePainter extends NebulaEffectPainter {
  const _EclipsePainter(super.t);
  @override void paint(Canvas c,Size s){final o=Offset(s.width*.5,s.height*.45),r=s.shortestSide*.23,a=t*2*math.pi;
    c.drawRect(Offset.zero&s,Paint()..shader=RadialGradient(colors:const[Color(0x221C5B8F),Color(0x08051428),Colors.transparent]).createShader(Rect.fromCircle(center:o,radius:s.shortestSide)));
    final corona=Paint()..style=PaintingStyle.stroke..strokeWidth=r*.22..shader=SweepGradient(colors:const[Color(0x0029D9FF),Color(0xAA9AF5FF),Color(0x3300B8F5),Color(0x0029D9FF)],transform:GradientRotation(a)).createShader(Rect.fromCircle(center:o,radius:r*1.3))..maskFilter=const MaskFilter.blur(BlurStyle.normal,5);c.drawCircle(o,r*1.22,corona);
    c.drawCircle(o,r,Paint()..shader=RadialGradient(colors:const[Color(0xFF000207),Color(0xFF07111E)]).createShader(Rect.fromCircle(center:o,radius:r)));
    final thin=Paint()..style=PaintingStyle.stroke..strokeWidth=1..color=const Color(0x669AF5FF);c.drawCircle(o,r,thin);
    for(var i=0;i<10;i++){final q=a+i*2.399963; final d=r*1.55; c.drawCircle(o+Offset(math.cos(q)*d,math.sin(q)*d),1.1,Paint()..color=const Color(0x779AF5FF));}
  }
}

// ---------------------------------------------------------------------------
// Solar Flare — preserved as the flagship plasma identity.
// ---------------------------------------------------------------------------
class _SolarPainter extends NebulaEffectPainter {
  const _SolarPainter(super.t);
  @override void paint(Canvas c,Size s){final w=s.width,h=s.height,pulse=.5+.5*math.sin(t*2*math.pi);
    c.drawRect(Offset.zero&s,Paint()..shader=RadialGradient(center:Alignment(0,-.9),radius:1.2,colors:[Color(0x33FFF3C4).withValues(alpha:.5+.2*pulse),Color(0x22FF6D00),Colors.transparent]).createShader(Offset.zero&s));
    final rnd=math.Random(9);final cloud=Paint();for(var i=0;i<10;i++){final q=(t+rnd.nextDouble())%1;final x=rnd.nextDouble()*w+math.sin(q*6+i)*18;final y=h*(1.08-q*1.1);final rr=s.shortestSide*(.09+rnd.nextDouble()*.12);cloud.shader=RadialGradient(colors:[const Color(0x55FFB300),const Color(0x00FF6D00)]).createShader(Rect.fromCircle(center:Offset(x,y),radius:rr));c.drawCircle(Offset(x,y),rr,cloud);}
    final arc=Paint()..style=PaintingStyle.stroke..strokeCap=StrokeCap.round;for(var i=0;i<3;i++){final q=(t+i/3)%1,g=math.sin(math.pi*q);final x=w*(.2+i*.3);final path=Path()..moveTo(x-w*.1,h)..cubicTo(x-w*.06,h-h*.55*g,x+w*.06,h-h*.55*g,x+w*.1,h);arc..strokeWidth=7..color=const Color(0x66FF6D00)..maskFilter=const MaskFilter.blur(BlurStyle.normal,5);c.drawPath(path,arc);arc..strokeWidth=1.5..color=const Color(0xDDFFF3C4)..maskFilter=null;c.drawPath(path,arc);}
  }
}

// ---------------------------------------------------------------------------
// Void — a perspective grid being swallowed by a singularity.
// ---------------------------------------------------------------------------
class _VoidPainter extends NebulaEffectPainter {
  const _VoidPainter(super.t);
  @override void paint(Canvas c,Size s){final cx=s.width*.5,cy=s.height*.5,r=s.shortestSide*.18;final p=Paint()..style=PaintingStyle.stroke..strokeWidth=.8..color=const Color(0x553DFF88);
    for(var i=-8;i<=8;i++){final x=s.width*.5+i*s.width*.055; c.drawLine(Offset(cx+(x-cx)*.22,cy-r),Offset(x,s.height),p);}
    for(var i=0;i<11;i++){final y=cy+r+i*i*s.height*.018;final q=Path()..moveTo(0,y)..quadraticBezierTo(cx,cy+r+i*s.height*.015,s.width,y);c.drawPath(q,p);}
    c.drawCircle(Offset(cx,cy),r*1.8,Paint()..color=const Color(0x553DFF88)..maskFilter=const MaskFilter.blur(BlurStyle.normal,18));
    c.drawCircle(Offset(cx,cy),r,Paint()..shader=RadialGradient(colors:const[Color(0xFF020A06),Color(0xFF000000)]).createShader(Rect.fromCircle(center:Offset(cx,cy),radius:r)));
    final a=t*2*math.pi;for(var i=0;i<16;i++){final q=a+i*.8;final d=r*1.3+math.sin(q*2)*r*.3;c.drawCircle(Offset(cx+math.cos(q)*d,cy+math.sin(q)*d),1.2,Paint()..color=const Color(0xAA5DFF9B));}
  }
}

// ---------------------------------------------------------------------------
// Crimson — a living garnet under pressure.
// ---------------------------------------------------------------------------
class _CrimsonPainter extends NebulaEffectPainter {
  const _CrimsonPainter(super.t);
  @override void paint(Canvas c,Size s){final o=Offset(s.width*.5,s.height*.5),r=s.shortestSide*.26,p=.5+.5*math.sin(t*2*math.pi);
    final path=Path()..moveTo(o.dx,o.dy-r)..lineTo(o.dx+r*.78,o.dy-r*.45)..lineTo(o.dx+r,o.dy+r*.42)..lineTo(o.dx+r*.2,o.dy+r)..lineTo(o.dx-r*.65,o.dy+r*.8)..lineTo(o.dx-r,o.dy)..lineTo(o.dx-r*.55,o.dy-r*.7)..close();
    c.drawPath(path,Paint()..shader=LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:const[Color(0xFF7E102A),Color(0xFF23040D),Color(0xFFB51D45)]).createShader(Rect.fromCircle(center:o,radius:r)));
    final crack=Paint()..style=PaintingStyle.stroke..strokeWidth=1.8..color=const Color(0xCCFF365E);final q=Path()..moveTo(o.dx-r*.72,o.dy-r*.25)..lineTo(o.dx-r*.12,o.dy-r*.05)..lineTo(o.dx+r*.18,o.dy+r*.42)..lineTo(o.dx+r*.65,o.dy+r*.2);c.drawPath(q,crack);
    c.drawCircle(o,r*(.18+.035*p),Paint()..color=const Color(0x55FF1744)..maskFilter=const MaskFilter.blur(BlurStyle.normal,12));
  }
}

// ---------------------------------------------------------------------------
// Neon — separated cyan/magenta tubes and reflections.
// ---------------------------------------------------------------------------
class _NeonPainter extends NebulaEffectPainter {
  const _NeonPainter(super.t);
  @override void paint(Canvas c,Size s){final a=t*2*math.pi,w=s.width,h=s.height;final glow=Paint()..style=PaintingStyle.stroke..strokeCap=StrokeCap.round..strokeWidth=10..maskFilter=const MaskFilter.blur(BlurStyle.normal,10);final line=Paint()..style=PaintingStyle.stroke..strokeCap=StrokeCap.round..strokeWidth=2.2;
    for(var i=0;i<4;i++){final y=h*(.22+i*.18)+math.sin(a+i)*8;final path=Path()..moveTo(w*.08,y)..cubicTo(w*.28,y-20,w*.42,y+24,w*.62,y)..cubicTo(w*.78,y-24,w*.82,y+18,w*.94,y-4);glow.color=(i.isEven?const Color(0x7740D9FF):const Color(0x77FF2BC2));c.drawPath(path,glow);line.color=i.isEven?const Color(0xFF4FE7FF):const Color(0xFFFF4DCE);c.drawPath(path,line);}
    c.drawRect(Offset(w*.06,h*.82)&Size(w*.88,h*.012),Paint()..color=const Color(0x4479E8FF));
  }
}

// ---------------------------------------------------------------------------
// Emerald — mineral growth and living golden veins.
// ---------------------------------------------------------------------------
class _EmeraldPainter extends NebulaEffectPainter {
  const _EmeraldPainter(super.t);
  @override void paint(Canvas c,Size s){final o=Offset(s.width*.5,s.height*.52),r=s.shortestSide*.3,a=t*2*math.pi;
    final rock=Path()..moveTo(o.dx-r*.2,o.dy-r)..lineTo(o.dx+r*.7,o.dy-r*.5)..lineTo(o.dx+r,o.dy+r*.35)..lineTo(o.dx+r*.2,o.dy+r)..lineTo(o.dx-r*.7,o.dy+r*.75)..lineTo(o.dx-r,o.dy-r*.05)..close();c.drawPath(rock,Paint()..shader=LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:const[Color(0xFF0E5D43),Color(0xFF031B13),Color(0xFF1B8B5E)]).createShader(Rect.fromCircle(center:o,radius:r)));
    final vein=Paint()..style=PaintingStyle.stroke..strokeWidth=1.8..color=const Color(0xCCDBB84A);for(var i=0;i<6;i++){final q=i*.9;final path=Path()..moveTo(o.dx-r*.8+math.sin(q)*r*.2,o.dy+r*.55)..cubicTo(o.dx-r*.35,o.dy+r*.1,o.dx+r*.05,o.dy-r*.25,o.dx+r*.7*math.cos(q+a),o.dy-r*.65);c.drawPath(path,vein);}
    c.drawCircle(o,r*.75,Paint()..style=PaintingStyle.stroke..strokeWidth=1..color=const Color(0x334DE3A1));
  }
}

// ---------------------------------------------------------------------------
// Aurora — broad translucent curtains, never point-like neon ribbons.
// ---------------------------------------------------------------------------
class _AuroraPainter extends NebulaEffectPainter {
  const _AuroraPainter(super.t);
  @override void paint(Canvas c,Size s){final w=s.width,h=s.height,a=t*2*math.pi;for(var i=0;i<6;i++){final x=w*(.08+i*.17);final path=Path()..moveTo(x,h)..cubicTo(x+w*.08,h*.65,x-w*.1,h*.35,x+w*.02,h*.05);final p=Paint()..style=PaintingStyle.stroke..strokeWidth=w*.10..strokeCap=StrokeCap.round..color=(i.isEven?const Color(0x2238F0B0):const Color(0x2238BFFF));p.maskFilter=const MaskFilter.blur(BlurStyle.normal,16);c.save();c.translate(math.sin(a+i)*10,0);c.drawPath(path,p);c.restore();}
    final dust=Paint();final rnd=math.Random(12);for(var i=0;i<22;i++){final x=rnd.nextDouble()*w;final y=h*(.1+rnd.nextDouble()*.8);dust.color=const Color(0x667CE8D0).withValues(alpha:.15+.15*math.sin(a+i));c.drawCircle(Offset(x,y),.8,dust);}
  }
}

// ---------------------------------------------------------------------------
// Sapphire — precision-cut crystal and cold refraction.
// ---------------------------------------------------------------------------
class _SapphirePainter extends NebulaEffectPainter {
  const _SapphirePainter(super.t);
  @override void paint(Canvas c,Size s){final o=Offset(s.width*.5,s.height*.5),r=s.shortestSide*.29,a=t*2*math.pi;final outer=Path()..moveTo(o.dx,o.dy-r)..lineTo(o.dx+r*.72,o.dy-r*.28)..lineTo(o.dx+r*.92,o.dy+r*.45)..lineTo(o.dx+r*.15,o.dy+r)..lineTo(o.dx-r*.72,o.dy+r*.62)..lineTo(o.dx-r*.95,o.dy-r*.18)..close();c.drawPath(outer,Paint()..shader=LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:const[Color(0xFF123E8E),Color(0xFF03102D),Color(0xFF1C63D0)]).createShader(Rect.fromCircle(center:o,radius:r)));
    final facet=Paint()..style=PaintingStyle.stroke..strokeWidth=1.1..color=const Color(0x779AF5FF);for(var i=0;i<5;i++){final q=a+i*1.256;final pt=o+Offset(math.cos(q)*r*.82,math.sin(q)*r*.82);c.drawLine(o,pt,facet);}c.drawPath(outer,facet);
    final ray=Paint()..style=PaintingStyle.stroke..strokeWidth=2..color=const Color(0xAA9AF5FF);final q=a; c.drawLine(o+Offset(math.cos(q)*r*.35,math.sin(q)*r*.35),o+Offset(math.cos(q)*r*.95,math.sin(q)*r*.95),ray);
  }
}

// ---------------------------------------------------------------------------
// Amber — ancient resin with trapped inclusions and internal light.
// ---------------------------------------------------------------------------
class _AmberPainter extends NebulaEffectPainter {
  const _AmberPainter(super.t);
  @override void paint(Canvas c,Size s){final o=Offset(s.width*.5,s.height*.5),r=s.shortestSide*.3,a=t*2*math.pi;final blob=Path()..moveTo(o.dx-r*.5,o.dy-r*.75)..cubicTo(o.dx+r*.65,o.dy-r*.9,o.dx+r*.85,o.dy+r*.3,o.dx+r*.25,o.dy+r*.85)..cubicTo(o.dx-r*.55,o.dy+r*.8,o.dx-r*.8,o.dy-r*.1,o.dx-r*.5,o.dy-r*.75)..close();c.drawPath(blob,Paint()..shader=RadialGradient(colors:const[Color(0xFFFFD46A),Color(0xFFB95B0A),Color(0xFF5C2503)]).createShader(Rect.fromCircle(center:o,radius:r*1.2)));
    // fossil inclusion
    final fossil=Paint()..style=PaintingStyle.stroke..strokeWidth=1.3..color=const Color(0x66804412);final fp=Path()..moveTo(o.dx-r*.4,o.dy+r*.35)..cubicTo(o.dx-r*.1,o.dy,o.dx+r*.1,o.dy-r*.3,o.dx+r*.42,o.dy-r*.52);c.drawPath(fp,fossil);for(var i=0;i<5;i++){final q=a+i*.9;c.drawCircle(o+Offset(math.cos(q)*r*.45,math.sin(q)*r*.45),1.4,Paint()..color=const Color(0x88FFF0A3));}
    c.drawCircle(o+Offset(math.cos(a)*r*.35,math.sin(a)*r*.35),r*.15,Paint()..color=const Color(0x44FFF3B0)..maskFilter=const MaskFilter.blur(BlurStyle.normal,8));
  }
}

// ---------------------------------------------------------------------------
// Onyx — almost nothing, but every reflection has a purpose.
// ---------------------------------------------------------------------------
class _OnyxPainter extends NebulaEffectPainter {
  const _OnyxPainter(super.t);
  @override void paint(Canvas c,Size s){final o=Offset(s.width*.5,s.height*.52),r=s.shortestSide*.31,a=t*2*math.pi;final shape=Path()..moveTo(o.dx-r*.72,o.dy-r*.55)..lineTo(o.dx+r*.45,o.dy-r*.78)..lineTo(o.dx+r*.9,o.dy+r*.35)..lineTo(o.dx+r*.1,o.dy+r*.78)..lineTo(o.dx-r*.78,o.dy+r*.42)..close();c.drawPath(shape,Paint()..shader=LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:const[Color(0xFF08090B),Color(0xFF1A1B1F),Color(0xFF030405)]).createShader(Rect.fromCircle(center:o,radius:r)));
    final hi=Paint()..style=PaintingStyle.stroke..strokeWidth=2.4..color=const Color(0x667F858D);final x=o.dx+math.sin(a)*r*.8;c.drawLine(Offset(x-r*.55,o.dy-r*.75),Offset(x+r*.3,o.dy+r*.65),hi);c.drawPath(shape,Paint()..style=PaintingStyle.stroke..strokeWidth=1..color=const Color(0x55666B73));
  }
}

// ---------------------------------------------------------------------------
// Pearl — mother-of-pearl, broad iridescence, soft and alive.
// ---------------------------------------------------------------------------
class _PearlPainter extends NebulaEffectPainter {
  const _PearlPainter(super.t);
  @override void paint(Canvas c,Size s){final o=Offset(s.width*.5,s.height*.5),r=s.shortestSide*.32,a=t*2*math.pi;final pearl=Paint()..shader=SweepGradient(colors:const[Color(0xFFEFFAFF),Color(0xFFF0D9F4),Color(0xFFD9F5F0),Color(0xFFFFE7D0),Color(0xFFEFFAFF)],transform:GradientRotation(a)).createShader(Rect.fromCircle(center:o,radius:r));c.drawCircle(o,r,pearl);c.drawCircle(o,r,Paint()..style=PaintingStyle.stroke..strokeWidth=2..color=const Color(0x66FFFFFF));for(var i=0;i<7;i++){final q=a+i*.897;final d=r*(.35+i*.055);c.drawArc(Rect.fromCircle(center:o,radius:d),q,.8, false,Paint()..style=PaintingStyle.stroke..strokeWidth=1.2..color=Color(0x55FFFFFF).withValues(alpha:.35));}}
}

// ---------------------------------------------------------------------------
// Ivory — porcelain, engraving and champagne light.
// ---------------------------------------------------------------------------
class _IvoryPainter extends NebulaEffectPainter {
  const _IvoryPainter(super.t);
  @override void paint(Canvas c,Size s){final o=Offset(s.width*.5,s.height*.5),r=s.shortestSide*.34,a=t*2*math.pi;c.drawCircle(o,r,Paint()..shader=RadialGradient(colors:const[Color(0xFFFFFBEE),Color(0xFFE9DCC1),Color(0xFF8B7657)]).createShader(Rect.fromCircle(center:o,radius:r)));final fil=Paint()..style=PaintingStyle.stroke..strokeWidth=1..color=const Color(0x665E4A2E);for(var i=0;i<8;i++){final q=i*math.pi/4+a*.15;final p=Path()..moveTo(o.dx+math.cos(q)*r*.22,o.dy+math.sin(q)*r*.22)..cubicTo(o.dx+math.cos(q+.4)*r*.5,o.dy+math.sin(q+.4)*r*.5,o.dx+math.cos(q+.8)*r*.7,o.dy+math.sin(q+.8)*r*.7,o.dx+math.cos(q+1.2)*r*.88,o.dy+math.sin(q+1.2)*r*.88);c.drawPath(p,fil);}c.drawCircle(o,r*.68,Paint()..style=PaintingStyle.stroke..strokeWidth=1..color=const Color(0x44D8B96B));}
}

// ---------------------------------------------------------------------------
// Imperial — kept as its own steel/brass machinery language.
// ---------------------------------------------------------------------------
class _ImperialPainter extends NebulaEffectPainter {
  const _ImperialPainter(super.t);
  void gear(Canvas c,Offset o,double r,double rot){final p=Paint()..style=PaintingStyle.stroke..strokeWidth=r*.08..color=const Color(0x669D8A68);c.save();c.translate(o.dx,o.dy);c.rotate(rot);for(var i=0;i<10;i++){final a=i*math.pi/5; c.drawLine(Offset(math.cos(a)*r*.72,math.sin(a)*r*.72),Offset(math.cos(a)*r,math.sin(a)*r),p);}c.drawCircle(Offset.zero,r*.68,p);c.restore();}
  @override void paint(Canvas c,Size s){final o=Offset(s.width*.5,s.height*.55),m=s.shortestSide;gear(c,o-Offset(m*.18,0),m*.13,t*2*math.pi);gear(c,o+Offset(m*.17,m*.05),m*.18,-t*2*math.pi*1.1);c.drawRect(Offset.zero&s,Paint()..shader=LinearGradient(colors:const[Color(0x221A1814),Color(0x00000000)]).createShader(Offset.zero&s));final riv=Paint()..color=const Color(0xFFD4A72A);for(var i=0;i<8;i++){final a=i*math.pi/4;c.drawCircle(o+Offset(math.cos(a)*m*.37,math.sin(a)*m*.3),2.2,riv);}}
}

// ---------------------------------------------------------------------------
// Abyss — bioluminescent ecosystem.
// ---------------------------------------------------------------------------
class _AbyssPainter extends NebulaEffectPainter {
  const _AbyssPainter(super.t);
  @override void paint(Canvas c,Size s){final w=s.width,h=s.height,a=t*2*math.pi; c.drawRect(Offset.zero&s,Paint()..shader=LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:const[Color(0x2200C7D9),Color(0x08102C43),Color(0x33000112)]).createShader(Offset.zero&s));
    // light shafts
    for(var i=0;i<4;i++){final x=w*(.15+i*.24)+math.sin(a+i)*8;final p=Path()..moveTo(x-w*.04,0)..lineTo(x+w*.04,0)..lineTo(x+w*.16,h)..lineTo(x-w*.16,h)..close();c.drawPath(p,Paint()..color=const Color(0x1124E6E0));}
    // jellyfish
    for(var i=0;i<5;i++){final q=(t+i*.2)%1;final x=w*(.12+i*.19)+math.sin(q*math.pi*2+i)*18;final y=h*(.35+q*.55);final r=s.shortestSide*.035;final p=Paint()..color=const Color(0x8836F5E6)..maskFilter=const MaskFilter.blur(BlurStyle.normal,7);c.drawOval(Rect.fromCenter(center:Offset(x,y),width:r*2.2,height:r*1.2),p);for(var j=0;j<3;j++){final path=Path()..moveTo(x-r+j*r*.5,y+r*.45)..quadraticBezierTo(x-r+j*r*.5+math.sin(q*7+j)*8,y+r*1.6,x-r+j*r*.5,y+r*2.5);c.drawPath(path,Paint()..style=PaintingStyle.stroke..strokeWidth=1..color=const Color(0x664FEFE2));}}
    final rnd=math.Random(55);for(var i=0;i<28;i++){final x=rnd.nextDouble()*w,y=h*(.25+rnd.nextDouble()*.7);c.drawCircle(Offset(x,y),.7,Paint()..color=const Color(0x889AF9EF));}
  }
}

// ---------------------------------------------------------------------------
// Sakura — moon, mist and drifting petals.
// ---------------------------------------------------------------------------
class _SakuraPainter extends NebulaEffectPainter {
  const _SakuraPainter(super.t);
  @override void paint(Canvas c,Size s){final w=s.width,h=s.height,a=t*2*math.pi;final moon=Offset(w*.72,h*.22),mr=s.shortestSide*.11;c.drawCircle(moon,mr,Paint()..shader=RadialGradient(colors:const[Color(0xFFFBEEDB),Color(0x55FBEEDB),Colors.transparent]).createShader(Rect.fromCircle(center:moon,radius:mr*2.5)));c.drawCircle(moon,mr,Paint()..color=const Color(0xDDF7EBD9));
    c.drawRect(Offset(0,h*.72)&Size(w,h*.28),Paint()..shader=LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:const[Color(0x335E5260),Color(0x00000000)]).createShader(Rect.fromLTWH(0,h*.6,w,h*.4)));
    final rnd=math.Random(73);for(var i=0;i<34;i++){final q=(t*(.45+rnd.nextDouble())+i*.083)%1;final x=(rnd.nextDouble()*w+math.sin(q*6+i)*18)%w;final y=h*(.1+q*.95);final rot=math.sin(q*5+i);c.save();c.translate(x,y);c.rotate(rot);c.drawOval(Rect.fromCenter(center:Offset.zero,width=5,height:2.8),Paint()..color=(i.isEven?const Color(0xD9F29AB0):const Color(0xC9D85B72)));c.restore();}
  }
}

// ---------------------------------------------------------------------------
// Public selector. The flagship seven retain their existing engine identities;
// the remaining themes now use the richer soul painters above.
// ---------------------------------------------------------------------------
NebulaEffect? nebulaEffectFor(NebulaTheme theme, {required bool animate}) {
  switch(theme){
    case NebulaTheme.aves:
    case NebulaTheme.nosferatuGlass:
      return null;
    case NebulaTheme.obsidianGlass:
      return _SoulEffect(animate:animate,cycle:const Duration(seconds:18),builder:(t)=>_OnyxPainter(t));
    case NebulaTheme.aureateGlass:
      return _SoulEffect(animate:animate,cycle:const Duration(seconds:20),builder:(t)=>_IvoryPainter(t));
    case NebulaTheme.forgeGlass:
      return _SoulEffect(animate:animate,cycle:const Duration(seconds:12),builder:(t)=>_ForgePainter(t),pingPong:true);
    case NebulaTheme.hermeticGlass:
      return _SoulEffect(animate:animate,cycle:const Duration(seconds:18),builder:(t)=>_HermeticPainter(t));
    case NebulaTheme.eclipseGlass:
      return _SoulEffect(animate:animate,cycle:const Duration(seconds:22),builder:(t)=>_EclipsePainter(t));
    case NebulaTheme.solarFlareGlass:
      return _SoulEffect(animate:animate,cycle:const Duration(seconds:14),builder:(t)=>_SolarPainter(t));
    case NebulaTheme.voidGlass:
      return _SoulEffect(animate:animate,cycle:const Duration(seconds:20),builder:(t)=>_VoidPainter(t));
    case NebulaTheme.crimsonGlass:
      return _SoulEffect(animate:animate,cycle:const Duration(seconds:16),builder:(t)=>_CrimsonPainter(t),pingPong:true);
    case NebulaTheme.neonGlass:
      return _SoulEffect(animate:animate,cycle:const Duration(seconds:11),builder:(t)=>_NeonPainter(t));
    case NebulaTheme.emeraldGlass:
      return _SoulEffect(animate:animate,cycle:const Duration(seconds:19),builder:(t)=>_EmeraldPainter(t));
    case NebulaTheme.auroraGlass:
      return _SoulEffect(animate:animate,cycle:const Duration(seconds:24),builder:(t)=>_AuroraPainter(t),pingPong:true);
    case NebulaTheme.sapphireGlass:
      return _SoulEffect(animate:animate,cycle:const Duration(seconds:17),builder:(t)=>_SapphirePainter(t));
    case NebulaTheme.amberGlass:
      return _SoulEffect(animate:animate,cycle:const Duration(seconds:21),builder:(t)=>_AmberPainter(t));
    case NebulaTheme.onyxGlass:
      return _SoulEffect(animate:animate,cycle:const Duration(seconds:26),builder:(t)=>_OnyxPainter(t));
    case NebulaTheme.pearlGlass:
      return _SoulEffect(animate:animate,cycle:const Duration(seconds:23),builder:(t)=>_PearlPainter(t));
    case NebulaTheme.ivoryGlass:
      return _SoulEffect(animate:animate,cycle:const Duration(seconds:25),builder:(t)=>_IvoryPainter(t));
    case NebulaTheme.imperialGlass:
      return _SoulEffect(animate:animate,cycle:const Duration(seconds:18),builder:(t)=>_ImperialPainter(t));
    case NebulaTheme.abyssalGlass:
      return _SoulEffect(animate:animate,cycle:const Duration(seconds:20),builder:(t)=>_AbyssPainter(t));
    case NebulaTheme.sakuraGlass:
      return _SoulEffect(animate:animate,cycle:const Duration(seconds:17),builder:(t)=>_SakuraPainter(t));
  }
}
