import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;

/// Fluent visual sizing with a larger, phone-friendly interaction area.
abstract final class MobileFluentTheme {
  static f.FluentThemeData fluent() => f.FluentThemeData(
    brightness: Brightness.light,
    accentColor: const Color(0xff0078d4).toAccentColor(),
    scaffoldBackgroundColor: const Color(0xfff3f3f3),
    cardColor: Colors.white,
    visualDensity: VisualDensity.standard,
  );

  // Material supplies the video/gesture infrastructure, not the visible controls.
  static ThemeData foundation() => ThemeData(
    useMaterial3: false,
    colorScheme: const ColorScheme.light(
      primary: Color(0xff0078d4),
      surface: Colors.white,
      onSurface: Color(0xff1b1b1b),
    ),
    scaffoldBackgroundColor: const Color(0xfff3f3f3),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    dividerColor: const Color(0xffe5e5e5),
    iconTheme: const IconThemeData(size: 18, color: Color(0xff323130)),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.45,
        color: Color(0xff1b1b1b),
      ),
      bodySmall: TextStyle(fontSize: 12, height: 1.4, color: Color(0xff616161)),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
    ),
  );
}

enum MobileButtonKind { standard, primary, link }

class MobileButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final MobileButtonKind kind;
  const MobileButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.kind = MobileButtonKind.standard,
  }) : icon = null;
  const MobileButton.icon({
    super.key,
    required this.onPressed,
    required this.icon,
    required Widget label,
    this.kind = MobileButtonKind.standard,
  }) : child = label;
  @override
  Widget build(BuildContext context) {
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 22),
      child: icon == null
          ? Center(widthFactor: 1, child: child)
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon!,
                const SizedBox(width: 8),
                Flexible(child: child),
              ],
            ),
    );
    const style = f.ButtonStyle(
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      ),
    );
    return switch (kind) {
      MobileButtonKind.primary => f.FilledButton(
        onPressed: onPressed,
        style: style,
        child: content,
      ),
      MobileButtonKind.link => f.HyperlinkButton(
        onPressed: onPressed,
        style: style,
        child: content,
      ),
      MobileButtonKind.standard => f.Button(
        onPressed: onPressed,
        style: style,
        child: content,
      ),
    };
  }
}

class MobileIconButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback? onPressed;
  final Widget icon;
  const MobileIconButton({
    super.key,
    required this.tooltip,
    required this.onPressed,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) => f.Tooltip(
    message: tooltip,
    child: Semantics(
      label: tooltip,
      child: SizedBox(
        width: 44,
        height: 44,
        child: f.IconButton(onPressed: onPressed, icon: icon),
      ),
    ),
  );
}

class MobileCard extends StatelessWidget {
  final Widget child;
  final ShapeBorder? shape;
  const MobileCard({super.key, required this.child, this.shape});
  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(4),
      border: Border.fromBorderSide(
        shape is OutlinedBorder
            ? (shape as OutlinedBorder).side
            : const BorderSide(color: Color(0xffe0e0e0)),
      ),
    ),
    child: child,
  );
}

class MobileToggle extends StatelessWidget {
  final Widget title;
  final bool value;
  final ValueChanged<bool>? onChanged;
  const MobileToggle({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onChanged == null ? null : () => onChanged!(!value),
              child: DefaultTextStyle.merge(
                style: TextStyle(
                  color: onChanged == null ? const Color(0xff8a8886) : null,
                ),
                child: title,
              ),
            ),
          ),
          const SizedBox(width: 20),
          SizedBox(
            height: 44,
            child: Center(
              child: f.ToggleSwitch(checked: value, onChanged: onChanged),
            ),
          ),
        ],
      ),
    ),
  );
}

class MobileCheck extends StatelessWidget {
  final bool? value;
  final ValueChanged<bool?>? onChanged;
  const MobileCheck({super.key, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 44,
    height: 44,
    child: Center(
      child: f.Checkbox(checked: value, onChanged: onChanged),
    ),
  );
}

class MobileProgress extends StatelessWidget {
  final double? value;
  const MobileProgress({super.key, this.value});
  @override
  Widget build(BuildContext context) =>
      f.ProgressBar(value: value == null ? null : value! * 100);
}

class MobilePreviewDialog extends StatelessWidget {
  final Widget child;
  const MobilePreviewDialog({super.key, required this.child});
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 640,
            maxHeight: MediaQuery.sizeOf(context).height * .85,
          ),
          child: MobileCard(child: child),
        ),
      ),
    ),
  );
}

class MobileHeader extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final List<Widget> actions;
  const MobileHeader({super.key, required this.title, required this.actions});
  @override
  Size get preferredSize => const Size.fromHeight(64);
  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xfff3f3f3),
        border: Border(bottom: BorderSide(color: Color(0xffe5e5e5))),
      ),
      child: Row(
        children: [
          Expanded(
            child: DefaultTextStyle(
              style: Theme.of(context).textTheme.titleLarge!,
              child: title,
            ),
          ),
          const SizedBox(width: 12),
          ...actions,
        ],
      ),
    ),
  );
}

Future<void> showFluentSettings({
  required BuildContext context,
  required WidgetBuilder builder,
}) => showGeneralDialog<void>(
  context: context,
  barrierDismissible: true,
  barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
  barrierColor: const Color(0x66000000),
  transitionDuration: const Duration(milliseconds: 160),
  pageBuilder: (context, animation, secondaryAnimation) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: FractionallySizedBox(
            heightFactor: .9,
            child: MobileCard(
              child: Material(
                color: Colors.transparent,
                child: builder(context),
              ),
            ),
          ),
        ),
      ),
    ),
  ),
  transitionBuilder: (context, animation, secondaryAnimation, child) =>
      FadeTransition(opacity: animation, child: child),
);
