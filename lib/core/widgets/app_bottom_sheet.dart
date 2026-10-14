import 'dart:math' as math;
import 'package:flutter/material.dart';

/// How far the bottom of a sheet's content must be lifted: above the Android
/// navigation bar / iOS home indicator ([MediaQueryData.viewPadding]) and above
/// the keyboard ([MediaQueryData.viewInsets]).
///
/// `viewPadding` keeps the system bar height even while the keyboard is open,
/// and on Android the keyboard's inset already covers that bar, so the two are
/// combined with `max` rather than added (adding would leave a nav-bar-sized
/// gap above the keyboard).
double sheetBottomInset(MediaQueryData mq) =>
    math.max(mq.viewPadding.bottom, mq.viewInsets.bottom);

/// [sheetBottomInset] for the nearest [MediaQuery].
double sheetBottomInsetOf(BuildContext context) =>
    sheetBottomInset(MediaQuery.of(context));

/// The one way to open a bottom sheet in this app.
///
/// Always `useSafeArea: true` (status bar / cutout on top) and lifts the
/// content above the system navigation bar and the keyboard, inside the sheet's
/// own surface so the sheet colour still runs behind the nav bar. The content
/// sees a [MediaQuery] with the bottom inset already spent, so a nested
/// `SafeArea` or `viewInsets` padding does not apply it twice.
///
/// Set [padContent] to false for a sheet that scrolls edge to edge (a
/// `DraggableScrollableSheet`): it then takes the inset itself through
/// [sheetBottomInsetOf] and pads its scrollable's end with it.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool showDragHandle = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool padContent = true,
  Color? backgroundColor,
  ShapeBorder? shape,
  Clip? clipBehavior,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useSafeArea: true,
    isScrollControlled: isScrollControlled,
    showDragHandle: showDragHandle,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: backgroundColor ?? Colors.white,
    shape: shape ??
        const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
    clipBehavior: clipBehavior ?? Clip.antiAlias,
    builder: (sheetContext) {
      if (!padContent) return builder(sheetContext);
      final mq = MediaQuery.of(sheetContext);
      return MediaQuery(
        data: mq.copyWith(
          padding: mq.padding.copyWith(bottom: 0),
          viewPadding: mq.viewPadding.copyWith(bottom: 0),
          viewInsets: mq.viewInsets.copyWith(bottom: 0),
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: sheetBottomInset(mq)),
          child: Builder(builder: builder),
        ),
      );
    },
  );
}
