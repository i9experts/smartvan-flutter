import 'package:flutter/material.dart';

/// Full-screen van/school photo with a navy scrim at the top, shared by the
/// auth screens. Pair it with [AuthSheet] for forms that sit on the photo.
class AuthBackdrop extends StatelessWidget {
  const AuthBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF0B1B3F)),
        Image.asset(
          'assets/images/login_bg.jpg',
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x660B1B3F), Color(0x000B1B3F)],
              stops: [0, 0.2],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Bottom-anchored form area: wraps its content, fades from the photo into
/// navy so text and fields stay readable, and scrolls when space runs out.
class AuthSheet extends StatelessWidget {
  const AuthSheet({
    super.key,
    required this.children,
    this.topPadding = 48,
    this.bottomPadding = 16,
  });

  final List<Widget> children;
  final double topPadding;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x000B1B3F), Color(0xE60B1B3F), Color(0xFF0B1B3F)],
            stops: [0, 0.22, 0.45],
          ),
        ),
        padding: EdgeInsets.only(top: topPadding),
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPadding + bottomInset),
          children: children,
        ),
      ),
    );
  }
}

/// Outlined, transparent input used on the auth screens (sits on the photo).
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffix,
    this.scale = 1,
  });

  /// 1 = regular size; below 1 shrinks padding and text so more fields fit
  /// on short screens.
  final double scale;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color, [double width = 1.2]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );
    final compact = scale < 1;
    final fontSize = 14 * (scale < 0.85 ? 0.85 : scale);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      cursorColor: const Color(0xFFFEC610),
      style: TextStyle(
        fontSize: fontSize,
        color: Colors.white,
        fontFamily: 'Poppins',
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white54,
          fontSize: fontSize,
          fontFamily: 'Poppins',
        ),
        prefixIcon: Icon(icon, color: Colors.white70, size: 20 * scale),
        prefixIconConstraints:
            compact ? const BoxConstraints(minWidth: 44, minHeight: 0) : null,
        suffixIcon: suffix,
        suffixIconConstraints:
            compact ? const BoxConstraints(minWidth: 44, minHeight: 0) : null,
        isDense: compact,
        filled: false,
        contentPadding:
            EdgeInsets.symmetric(horizontal: 16, vertical: 16 * scale),
        border: border(Colors.white38),
        enabledBorder: border(Colors.white38),
        focusedBorder: border(const Color(0xFFFEC610), 1.6),
      ),
    );
  }
}

/// Eye icon that toggles a password field, styled for the dark auth screens.
Widget authVisibilityToggle({
  required bool obscured,
  required VoidCallback onPressed,
  bool compact = false,
}) {
  return IconButton(
    icon: Icon(
      obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
      color: Colors.white70,
      size: compact ? 18 : 20,
    ),
    padding: compact ? EdgeInsets.zero : const EdgeInsets.all(8),
    constraints:
        compact ? const BoxConstraints(minWidth: 44, minHeight: 32) : null,
    onPressed: onPressed,
  );
}

/// Back arrow + title pinned over the top of the photo.
class AuthTopBar extends StatelessWidget {
  const AuthTopBar({super.key, required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: onBack,
            ),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Centered icon, title and subtitle at the top of an [AuthSheet].
class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    // Drop the icon while the keyboard is up so the form keeps its room.
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Column(
      children: [
        if (!keyboardOpen) ...[
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
            ),
            child: Icon(icon, size: 34, color: const Color(0xFFFEC610)),
          ),
          const SizedBox(height: 12),
        ],
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

/// Small outlined info note for the dark auth screens.
class AuthInfoBox extends StatelessWidget {
  const AuthInfoBox({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFFEC610), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
