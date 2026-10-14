import 'package:flutter/material.dart';

/// [base] with the system navigation bar / home indicator height added to its
/// bottom, so the last item of a full-screen scrollable can scroll up clear of
/// it.
///
/// Reads `padding`, not `viewPadding`: a Scaffold with a bottom bar has already
/// consumed the nav bar for its body, and this must not add it a second time.
EdgeInsets withBottomInset(BuildContext context, EdgeInsets base) =>
    base.copyWith(bottom: base.bottom + MediaQuery.paddingOf(context).bottom);
