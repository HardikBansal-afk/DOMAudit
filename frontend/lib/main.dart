import 'dart:async'; // Added for the Cooldown Timer
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;

// ─── Palette ────────────────────────────────────────────────────────────────
class _Palette {
  static const bg = Color(0xFF050505);
  static const surface = Color(0xFF0D0D0D);
  static const glassWhite = Color(0x0DFFFFFF); // 5 % white
  static const border = Color(0x14FFFFFF); // 8 % white
  static const violet = Color(0xFF6D28D9);
  static const violetGlow = Color(0x556D28D9);
  static const cyberGreen = Color(0xFF00FF94);
  static const cyberGreenDim = Color(0xFF003D25);
  static const neonRed = Color(0xFFFF2D55);
  static const neonRedDim = Color(0xFF3D0011);
  static const amber = Color(0xFFFFB800);
  static const textPrimary = Color(0xFFF0F0F0);
  static const textMuted = Color(0xFF6B7280);
  static const textCode = Color(0xFFB2EBF2);
  static const divider = Color(0xFF1A1A1A);
}

// ─── Entry Point ─────────────────────────────────────────────────────────────
void main() {
  runApp(const DOMAuditApp());
}

class DOMAuditApp extends StatelessWidget {
  const DOMAuditApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DOMAudit-AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: _Palette.bg,
        colorScheme: const ColorScheme.dark(
          primary: _Palette.cyberGreen,
          surface: _Palette.surface,
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: _Palette.cyberGreen,
          selectionColor: Color(0x3300FF94),
          selectionHandleColor: _Palette.cyberGreen,
        ),
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(_Palette.border),
          trackColor: WidgetStateProperty.all(Colors.transparent),
        ),
      ),
      home: const AuditScreen(),
    );
  }
}

// ─── Main Screen ─────────────────────────────────────────────────────────────
class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key});

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen>
    with SingleTickerProviderStateMixin {
  
  final TextEditingController _htmlController = TextEditingController();
  List<dynamic> _auditResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _totalIssues = 0;

  // ── RATE LIMIT COOLDOWN LOGIC ─────────────────────────────────────────────
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;
  bool get _isCoolingDown => _cooldownSeconds > 0;

  void _startCooldown() {
    setState(() => _cooldownSeconds = 45); // Start at 45 seconds
    
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownSeconds > 0) {
        setState(() => _cooldownSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _runAudit() async {
    // Prevent execution if loading or locked out
    if (_isLoading || _isCoolingDown) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _auditResults = [];
      _totalIssues = 0;
    });

    try {
      final response = await http.post(
        // Remember to change this to your Render URL for production!
        Uri.parse('http://127.0.0.1:8000/api/audit'), 
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'html_snippet': _htmlController.text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _auditResults = data['results'] ?? [];
          _totalIssues = data['total_issues_found'] ?? 0;
          if (_auditResults.isEmpty) {
            _errorMessage = "SYS.CHECK // ZERO_VIOLATIONS_FOUND";
          }
        });
      } else if (response.statusCode == 429) {
        // TRIGGER COOLDOWN
        _startCooldown();
        setState(() => _errorMessage = "SYS.HALT // RATE_LIMIT_EXCEEDED (AWAITING COOLDOWN)");
      } else {
        setState(() => _errorMessage = "ERR // CODE_${response.statusCode}");
      }
    } catch (e) {
      setState(() => _errorMessage = "ERR // CONNECTION_REFUSED");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel(); // Clean up timer
    _htmlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.bg,
      body: Stack(
        children: [
          const _GlowOrbs(),
          SafeArea(
            child: Column(
              children: [
                _TopBar(totalIssues: _totalIssues, hasResults: _auditResults.isNotEmpty),
                Expanded(
                  child: LayoutBuilder(
                    builder: (ctx, constraints) {
                      final isWide = constraints.maxWidth > 900;
                      if (isWide) {
                        return _DesktopLayout(
                          controller: _htmlController,
                          isLoading: _isLoading,
                          isCoolingDown: _isCoolingDown,
                          cooldownSeconds: _cooldownSeconds,
                          auditResults: _auditResults,
                          errorMessage: _errorMessage,
                          onRunAudit: _runAudit,
                          totalIssues: _totalIssues,
                        );
                      }
                      return _MobileLayout(
                        controller: _htmlController,
                        isLoading: _isLoading,
                        isCoolingDown: _isCoolingDown,
                        cooldownSeconds: _cooldownSeconds,
                        auditResults: _auditResults,
                        errorMessage: _errorMessage,
                        onRunAudit: _runAudit,
                        totalIssues: _totalIssues,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Background Glow Orbs ─────────────────────────────────────────────────────
class _GlowOrbs extends StatelessWidget {
  const _GlowOrbs();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -180,
          left: -140,
          child: Container(
            width: 520,
            height: 520,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _Palette.violet.withOpacity(0.35),
                  _Palette.violet.withOpacity(0.0),
                ],
              ),
            ),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(end: 1.12, duration: 7.seconds, curve: Curves.easeInOut),

        Positioned(
          bottom: -200,
          right: -160,
          child: Container(
            width: 600,
            height: 600,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _Palette.cyberGreen.withOpacity(0.18),
                  _Palette.cyberGreen.withOpacity(0.0),
                ],
              ),
            ),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(end: 1.08, duration: 9.seconds, curve: Curves.easeInOut),

        Positioned(
          top: MediaQuery.of(context).size.height * 0.4,
          left: MediaQuery.of(context).size.width * 0.45,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _Palette.neonRed.withOpacity(0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Top Bar ─────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final int totalIssues;
  final bool hasResults;
  const _TopBar({required this.totalIssues, required this.hasResults});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [_Palette.violet, _Palette.cyberGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: _Palette.violetGlow,
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: Text('⬡', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'DOMAudit',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _Palette.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            '-AI',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _Palette.cyberGreen,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(width: 8),
          const _GlassTag(label: 'v2.1.0', color: _Palette.textMuted),
          const Spacer(),
          if (hasResults)
            _GlassTag(
              label: '$totalIssues VIOLATIONS',
              color: totalIssues == 0 ? _Palette.cyberGreen : _Palette.neonRed,
              glow: true,
            ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.2),
          const SizedBox(width: 12),
          const _GlassTag(label: 'WCAG 2.1 AA', color: _Palette.amber),
          const SizedBox(width: 12),
          const _GlassTag(label: '● LIVE', color: _Palette.cyberGreen, pulse: true),
        ],
      ),
    );
  }
}

class _GlassTag extends StatelessWidget {
  final String label;
  final Color color;
  final bool glow;
  final bool pulse;
  const _GlassTag({required this.label, required this.color, this.glow = false, this.pulse = false});

  @override
  Widget build(BuildContext context) {
    Widget tag = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 0.8),
        boxShadow: glow
            ? [BoxShadow(color: color.withOpacity(0.25), blurRadius: 12)]
            : null,
      ),
      child: Text(
        label,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 1.2,
        ),
      ),
    );
    if (pulse) {
      tag = tag.animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(
            begin: 0.5,
            duration: 1200.ms,
            curve: Curves.easeInOut,
          );
    }
    return tag;
  }
}

// ─── Desktop Split Layout ─────────────────────────────────────────────────────
class _DesktopLayout extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final bool isCoolingDown;
  final int cooldownSeconds;
  final List<dynamic> auditResults;
  final String? errorMessage;
  final VoidCallback onRunAudit;
  final int totalIssues;

  const _DesktopLayout({
    required this.controller,
    required this.isLoading,
    required this.isCoolingDown,
    required this.cooldownSeconds,
    required this.auditResults,
    required this.errorMessage,
    required this.onRunAudit,
    required this.totalIssues,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 420,
            child: _InputPanel(
              controller: controller,
              isLoading: isLoading,
              isCoolingDown: isCoolingDown,
              cooldownSeconds: cooldownSeconds,
              onRunAudit: onRunAudit,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _ResultsPanel(
              isLoading: isLoading,
              auditResults: auditResults,
              errorMessage: errorMessage,
              totalIssues: totalIssues,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mobile Stacked Layout ────────────────────────────────────────────────────
class _MobileLayout extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final bool isCoolingDown;
  final int cooldownSeconds;
  final List<dynamic> auditResults;
  final String? errorMessage;
  final VoidCallback onRunAudit;
  final int totalIssues;

  const _MobileLayout({
    required this.controller,
    required this.isLoading,
    required this.isCoolingDown,
    required this.cooldownSeconds,
    required this.auditResults,
    required this.errorMessage,
    required this.onRunAudit,
    required this.totalIssues,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        children: [
          _InputPanel(
            controller: controller,
            isLoading: isLoading,
            isCoolingDown: isCoolingDown,
            cooldownSeconds: cooldownSeconds,
            onRunAudit: onRunAudit,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 600,
            child: _ResultsPanel(
              isLoading: isLoading,
              auditResults: auditResults,
              errorMessage: errorMessage,
              totalIssues: totalIssues,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Glass Container Helper ───────────────────────────────────────────────────
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final double blur;
  final Color? borderColor;
  final List<BoxShadow>? shadows;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.blur = 20,
    this.borderColor,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(20);
    return ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: _Palette.glassWhite,
            borderRadius: br,
            border: Border.all(
              color: borderColor ?? _Palette.border,
              width: 1,
            ),
            boxShadow: shadows ??
                [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─── Input Panel ─────────────────────────────────────────────────────────────
class _InputPanel extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final bool isCoolingDown;
  final int cooldownSeconds;
  final VoidCallback onRunAudit;

  const _InputPanel({
    required this.controller,
    required this.isLoading,
    required this.isCoolingDown,
    required this.cooldownSeconds,
    required this.onRunAudit,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _DotIndicator(color: _Palette.neonRed),
              const SizedBox(width: 6),
              const _DotIndicator(color: _Palette.amber),
              const SizedBox(width: 6),
              const _DotIndicator(color: _Palette.cyberGreen),
              const SizedBox(width: 16),
              Text(
                'INPUT // HTML_SOURCE',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  color: _Palette.textMuted,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: _Palette.border, height: 1),
          const SizedBox(height: 16),
          Text(
            'Raw HTML Snippet',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _Palette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Paste the HTML you want audited for WCAG 2.1 AA violations.',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              color: _Palette.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF080808),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _Palette.border, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F0F0F),
                      border: Border(bottom: BorderSide(color: _Palette.border, width: 1)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'index.html',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            color: _Palette.textMuted,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.code_rounded, size: 13, color: _Palette.textMuted.withOpacity(0.6)),
                      ],
                    ),
                  ),
                  TextField(
                    controller: controller,
                    maxLines: 14,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      color: _Palette.textCode,
                      height: 1.6,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          '\n<img src="hero.jpg">\n<button></button>\n<div onclick="go()">Click me</div>',
                      hintStyle: GoogleFonts.jetBrainsMono(
                        fontSize: 13,
                        color: _Palette.textMuted.withOpacity(0.4),
                        height: 1.6,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(14),
                    ),
                    cursorColor: _Palette.cyberGreen,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QuickPasteChip(
                label: '+ Missing Alt',
                snippet: '<img src="hero.jpg">',
                controller: controller,
              ),
              _QuickPasteChip(
                label: '+ Low Contrast',
                snippet: '<p style="color:#aaa; background:#999;">Text</p>',
                controller: controller,
              ),
              _QuickPasteChip(
                label: '+ Empty Button',
                snippet: '<button onclick="submit()"></button>',
                controller: controller,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Cooldown props passed into button
          _RunAuditButton(
            isLoading: isLoading, 
            isCoolingDown: isCoolingDown,
            cooldownSeconds: cooldownSeconds,
            onPressed: onRunAudit
          ),
          
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.lock_outline_rounded, size: 12, color: _Palette.textMuted.withOpacity(0.5)),
              const SizedBox(width: 6),
              Text(
                'Processed locally via 127.0.0.1:8000',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  color: _Palette.textMuted.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.04);
  }
}

class _DotIndicator extends StatelessWidget {
  final Color color;
  const _DotIndicator({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 11,
      height: 11,
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6)],
      ),
    );
  }
}

class _QuickPasteChip extends StatelessWidget {
  final String label;
  final String snippet;
  final TextEditingController controller;

  const _QuickPasteChip({
    required this.label,
    required this.snippet,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final current = controller.text;
        controller.text = current.isEmpty ? snippet : '$current\n$snippet';
        controller.selection = TextSelection.fromPosition(
          TextPosition(offset: controller.text.length),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _Palette.cyberGreen.withOpacity(0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _Palette.cyberGreen.withOpacity(0.2), width: 0.8),
        ),
        child: Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            color: _Palette.cyberGreen.withOpacity(0.7),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ─── Run Audit Button ─────────────────────────────────────────────────────────
class _RunAuditButton extends StatefulWidget {
  final bool isLoading;
  final bool isCoolingDown;
  final int cooldownSeconds;
  final VoidCallback onPressed;

  const _RunAuditButton({
    required this.isLoading, 
    required this.isCoolingDown,
    required this.cooldownSeconds,
    required this.onPressed
  });

  @override
  State<_RunAuditButton> createState() => _RunAuditButtonState();
}

class _RunAuditButtonState extends State<_RunAuditButton>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bool disabled = widget.isLoading || widget.isCoolingDown;

    // Helper for determining button background color based on state
    List<Color> _getGradientColors() {
      if (widget.isLoading) return [const Color(0xFF1A1A2E), const Color(0xFF1A1A2E)];
      if (widget.isCoolingDown) return [_Palette.neonRedDim, _Palette.neonRed.withOpacity(0.8)];
      if (_hovered) return [_Palette.cyberGreen, const Color(0xFF00C97A)];
      return [_Palette.cyberGreen.withOpacity(0.85), const Color(0xFF00E588).withOpacity(0.85)];
    }

    return MouseRegion(
      cursor: disabled
          ? SystemMouseCursors.wait
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: disabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: 200.ms,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: _getGradientColors(),
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: disabled
                ? []
                : [
                    BoxShadow(
                      color: _Palette.cyberGreen
                          .withOpacity(_hovered ? 0.5 : 0.3),
                      blurRadius: _hovered ? 28 : 16,
                      spreadRadius: _hovered ? 2 : 0,
                    ),
                  ],
          ),
          child: Center(
            child: widget.isLoading
                ? _ShimmerLoadingLabel()
                : widget.isCoolingDown
                    ? Text(
                        'SYS.LOCK // AWAIT ${widget.cooldownSeconds}S',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            color: Colors.black,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'RUN AUDIT',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
          ),
        ),
      ),
    );
  }
}

// ─── Shimmer Loading Label ─────────────────────────────────────────────────────
class _ShimmerLoadingLabel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: _Palette.cyberGreen.withOpacity(0.7),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'SCANNING VIOLATIONS...',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _Palette.cyberGreen.withOpacity(0.7),
            letterSpacing: 2,
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .fadeIn(begin: 0.3, duration: 800.ms, curve: Curves.easeInOut),
      ],
    );
  }
}

// ─── Results Panel ─────────────────────────────────────────────────────────────
class _ResultsPanel extends StatelessWidget {
  final bool isLoading;
  final List<dynamic> auditResults;
  final String? errorMessage;
  final int totalIssues;

  const _ResultsPanel({
    required this.isLoading,
    required this.auditResults,
    required this.errorMessage,
    required this.totalIssues,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'AUDIT RESULTS',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _Palette.textPrimary,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                if (auditResults.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _Palette.neonRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _Palette.neonRed.withOpacity(0.4)),
                    ),
                    child: Text(
                      '$totalIssues ISSUES',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        color: _Palette.neonRed,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ).animate().fadeIn(duration: 300.ms),
              ],
            ),
          ),
          const Divider(color: _Palette.border, height: 1),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideX(begin: 0.04);
  }

  Widget _buildBody() {
    if (isLoading) return const _ShimmerCardList();

    if (auditResults.isNotEmpty) {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: auditResults.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) {
          final item = auditResults[i] as Map<String, dynamic>;
          return _AuditResultCard(item: item, index: i)
              .animate(delay: Duration(milliseconds: i * 80))
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.08, curve: Curves.easeOut);
        },
      );
    }

    return _EmptyState(errorMessage: errorMessage);
  }
}

// ─── Shimmer Card List ─────────────────────────────────────────────────────────
class _ShimmerCardList extends StatelessWidget {
  const _ShimmerCardList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _ShimmerCard(delay: Duration(milliseconds: i * 120)),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  final Duration delay;
  const _ShimmerCard({required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Palette.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0F0F0F),
                    Color(0xFF1A1A1A),
                    Color(0xFF0F0F0F),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            )
                .animate(delay: delay, onPlay: (c) => c.repeat())
                .shimmer(
                  duration: 1400.ms,
                  color: _Palette.cyberGreen.withOpacity(0.06),
                  angle: 0.2,
                ),
          ],
        ),
      ),
    ).animate(delay: delay).fadeIn(duration: 300.ms);
  }
}

// ─── Audit Result Card ────────────────────────────────────────────────────────
class _AuditResultCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final int index;

  const _AuditResultCard({required this.item, required this.index});

  @override
  State<_AuditResultCard> createState() => _AuditResultCardState();
}

class _AuditResultCardState extends State<_AuditResultCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final originalElement = widget.item['original_element'] as String? ?? '';
    final rawPatch = widget.item['ai_patch'] as String? ?? '';

    String violationText = rawPatch;
    String patchText = '';
    final patchIndex = rawPatch.indexOf('Patch:');
    if (patchIndex != -1) {
      violationText = rawPatch.substring(0, patchIndex).trim();
      if (violationText.startsWith('Violation:')) {
        violationText = violationText.substring('Violation:'.length).trim();
      }
      patchText = rawPatch.substring(patchIndex + 'Patch:'.length).trim();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A).withOpacity(0.8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _Palette.border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    border: const Border(bottom: BorderSide(color: _Palette.border)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: _Palette.neonRed.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _Palette.neonRed.withOpacity(0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${widget.index + 1}',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _Palette.neonRed,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'VIOLATION_${(widget.index + 1).toString().padLeft(2, '0')}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          color: _Palette.textMuted,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      AnimatedRotation(
                        turns: _expanded ? 0 : -0.25,
                        duration: 200.ms,
                        child: Icon(
                          Icons.expand_more_rounded,
                          size: 18,
                          color: _Palette.textMuted.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedSize(
                duration: 280.ms,
                curve: Curves.easeInOut,
                child: _expanded
                    ? Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _CardSection(
                              icon: Icons.data_object_rounded,
                              label: 'TARGET ELEMENT',
                              labelColor: _Palette.textMuted,
                              child: _CodeBlock(
                                code: originalElement,
                                borderColor: _Palette.border,
                                backgroundColor: const Color(0xFF0F0F0F),
                                textColor: _Palette.textCode.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 10),
                            _CardSection(
                              icon: Icons.warning_amber_rounded,
                              label: 'ACCESSIBILITY VIOLATION',
                              labelColor: _Palette.neonRed,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _Palette.neonRed.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _Palette.neonRed.withOpacity(0.2),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  violationText.isNotEmpty
                                      ? violationText
                                      : rawPatch,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 12.5,
                                    color: _Palette.neonRed.withOpacity(0.85),
                                    height: 1.55,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (patchText.isNotEmpty)
                              _CardSection(
                                icon: Icons.auto_fix_high_rounded,
                                label: 'AI GENERATED PATCH',
                                labelColor: _Palette.cyberGreen,
                                trailing: _CopyButton(text: patchText),
                                child: _CodeBlock(
                                  code: patchText,
                                  borderColor:
                                      _Palette.cyberGreen.withOpacity(0.2),
                                  backgroundColor:
                                      _Palette.cyberGreen.withOpacity(0.04),
                                  textColor:
                                      _Palette.cyberGreen.withOpacity(0.9),
                                ),
                              ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardSection extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color labelColor;
  final Widget child;
  final Widget? trailing;

  const _CardSection({
    required this.icon,
    required this.label,
    required this.labelColor,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: labelColor.withOpacity(0.7)),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: labelColor.withOpacity(0.7),
                letterSpacing: 1.4,
              ),
            ),
            if (trailing != null) ...[
              const Spacer(),
              trailing!,
            ],
          ],
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _CodeBlock extends StatelessWidget {
  final String code;
  final Color borderColor;
  final Color backgroundColor;
  final Color textColor;

  const _CodeBlock({
    required this.code,
    required this.borderColor,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Text(
        code,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 12,
          color: textColor,
          height: 1.55,
        ),
      ),
    );
  }
}

class _CopyButton extends StatefulWidget {
  final String text;
  const _CopyButton({required this.text});

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: widget.text));
        setState(() => _copied = true);
        await Future.delayed(1800.ms);
        if (mounted) setState(() => _copied = false);
      },
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _copied
              ? _Palette.cyberGreen.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: _Palette.cyberGreen.withOpacity(_copied ? 0.4 : 0.15),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _copied ? Icons.check_rounded : Icons.copy_rounded,
              size: 10,
              color: _Palette.cyberGreen.withOpacity(0.7),
            ),
            const SizedBox(width: 4),
            Text(
              _copied ? 'COPIED' : 'COPY',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9,
                color: _Palette.cyberGreen.withOpacity(0.7),
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty / Error State ──────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String? errorMessage;
  const _EmptyState({this.errorMessage});

  bool get _isError =>
      errorMessage != null && errorMessage!.startsWith('ERR') || errorMessage?.contains('RATE_LIMIT') == true;

  bool get _isClean =>
      errorMessage == 'SYS.CHECK // ZERO_VIOLATIONS_FOUND';

  @override
  Widget build(BuildContext context) {
    final color = _isError
        ? _Palette.neonRed
        : _isClean
            ? _Palette.cyberGreen
            : _Palette.textMuted.withOpacity(0.3);

    final icon = _isError
        ? Icons.error_outline_rounded
        : _isClean
            ? Icons.verified_rounded
            : Icons.search_rounded;

    final label = errorMessage ??
        'AWAITING_INPUT\nPaste HTML on the left\nand hit Run Audit.';

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: color)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(
                end: 1.06,
                duration: 2200.ms,
                curve: Curves.easeInOut,
              ),
          const SizedBox(height: 20),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              color: color,
              height: 1.8,
              letterSpacing: 0.5,
            ),
          ).animate().fadeIn(duration: 500.ms),
        ],
      ),
    );
  }
}