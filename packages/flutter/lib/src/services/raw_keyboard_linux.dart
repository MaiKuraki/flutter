// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'hardware_keyboard.dart';
library;

import 'package:flutter/foundation.dart';

import 'keyboard_maps.g.dart';
import 'raw_keyboard.dart';

export 'package:flutter/foundation.dart' show DiagnosticPropertiesBuilder;

export 'keyboard_key.g.dart' show LogicalKeyboardKey, PhysicalKeyboardKey;

/// Platform-specific key event data for Linux.
///
/// This class is deprecated and will be removed. Platform specific key event
/// data will no longer be available. See [KeyEvent] for what is available.
///
/// Different window toolkit implementations can map to different key codes. This class
/// will use the correct mapping depending on the [keyHelper] provided.
///
/// See also:
///
///  * [RawKeyboard], which uses this interface to expose key data.
@Deprecated(
  'Platform specific key event data is no longer available. See KeyEvent for what is available. '
  'This feature was deprecated after v3.18.0-2.0.pre.',
)
class RawKeyEventDataLinux extends RawKeyEventData {
  /// Creates a key event data structure specific for Linux.
  @Deprecated(
    'Platform specific key event data is no longer available. See KeyEvent for what is available. '
    'This feature was deprecated after v3.18.0-2.0.pre.',
  )
  const RawKeyEventDataLinux({
    required this.keyHelper,
    this.unicodeScalarValues = 0,
    this.scanCode = 0,
    this.keyCode = 0,
    this.modifiers = 0,
    required this.isDown,
    this.specifiedLogicalKey,
  }) : assert((unicodeScalarValues & ~LogicalKeyboardKey.valueMask) == 0);

  /// A helper class that abstracts the fetching of the toolkit-specific mappings.
  ///
  /// There is no real concept of a "native" window toolkit on Linux, and each implementation
  /// (GLFW, GTK, QT, etc) may have a different key code mapping.
  final KeyHelper keyHelper;

  /// An int with up to two Unicode scalar values generated by a single keystroke. An assertion
  /// will fire if more than two values are encoded in a single keystroke.
  ///
  /// This is typically the character that [keyCode] would produce without any modifier keys.
  /// For dead keys, it is typically the diacritic it would add to a character. Defaults to 0,
  /// asserted to be not null.
  final int unicodeScalarValues;

  /// The hardware scan code id corresponding to this key event.
  ///
  /// These values are not reliable and vary from device to device, so this
  /// information is mainly useful for debugging.
  final int scanCode;

  /// The hardware key code corresponding to this key event.
  ///
  /// This is the physical key that was pressed, not the Unicode character.
  /// This value may be different depending on the window toolkit used. See [KeyHelper].
  final int keyCode;

  /// A mask of the current modifiers using the values in Modifier Flags.
  /// This value may be different depending on the window toolkit used. See [KeyHelper].
  final int modifiers;

  /// Whether or not this key event is a key down (true) or key up (false).
  final bool isDown;

  /// A logical key specified by the embedding that should be used instead of
  /// deriving from raw data.
  ///
  /// The GTK embedding detects the keyboard layout and maps some keys to
  /// logical keys in a way that can not be derived from per-key information.
  ///
  /// This is not part of the native GTK key event.
  final int? specifiedLogicalKey;

  @override
  String get keyLabel => unicodeScalarValues == 0 ? '' : String.fromCharCode(unicodeScalarValues);

  @override
  PhysicalKeyboardKey get physicalKey =>
      kLinuxToPhysicalKey[scanCode] ?? PhysicalKeyboardKey(LogicalKeyboardKey.webPlane + scanCode);

  @override
  LogicalKeyboardKey get logicalKey {
    if (specifiedLogicalKey != null) {
      final int key = specifiedLogicalKey!;
      return LogicalKeyboardKey.findKeyByKeyId(key) ?? LogicalKeyboardKey(key);
    }
    // Look to see if the keyCode is a printable number pad key, so that a
    // difference between regular keys (e.g. "=") and the number pad version
    // (e.g. the "=" on the number pad) can be determined.
    final LogicalKeyboardKey? numPadKey = keyHelper.numpadKey(keyCode);
    if (numPadKey != null) {
      return numPadKey;
    }

    // If it has a non-control-character label, then either return the existing
    // constant, or construct a new Unicode-based key from it. Don't mark it as
    // autogenerated, since the label uniquely identifies an ID from the Unicode
    // plane.
    if (keyLabel.isNotEmpty && !LogicalKeyboardKey.isControlCharacter(keyLabel)) {
      final int keyId =
          LogicalKeyboardKey.unicodePlane | (unicodeScalarValues & LogicalKeyboardKey.valueMask);
      return LogicalKeyboardKey.findKeyByKeyId(keyId) ?? LogicalKeyboardKey(keyId);
    }

    // Look to see if the keyCode is one we know about and have a mapping for.
    final LogicalKeyboardKey? newKey = keyHelper.logicalKey(keyCode);
    if (newKey != null) {
      return newKey;
    }

    // This is a non-printable key that we don't know about, so we mint a new
    // code.
    return LogicalKeyboardKey(keyCode | keyHelper.platformPlane);
  }

  @override
  bool isModifierPressed(ModifierKey key, {KeyboardSide side = KeyboardSide.any}) {
    return keyHelper.isModifierPressed(
      key,
      modifiers,
      side: side,
      keyCode: keyCode,
      isDown: isDown,
    );
  }

  @override
  KeyboardSide getModifierSide(ModifierKey key) {
    return keyHelper.getModifierSide(key);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<String>('toolkit', keyHelper.debugToolkit));
    properties.add(DiagnosticsProperty<int>('unicodeScalarValues', unicodeScalarValues));
    properties.add(DiagnosticsProperty<int>('scanCode', scanCode));
    properties.add(DiagnosticsProperty<int>('keyCode', keyCode));
    properties.add(DiagnosticsProperty<int>('modifiers', modifiers));
    properties.add(DiagnosticsProperty<bool>('isDown', isDown));
    properties.add(
      DiagnosticsProperty<int?>('specifiedLogicalKey', specifiedLogicalKey, defaultValue: null),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is RawKeyEventDataLinux &&
        other.keyHelper.runtimeType == keyHelper.runtimeType &&
        other.unicodeScalarValues == unicodeScalarValues &&
        other.scanCode == scanCode &&
        other.keyCode == keyCode &&
        other.modifiers == modifiers &&
        other.isDown == isDown;
  }

  @override
  int get hashCode =>
      Object.hash(keyHelper.runtimeType, unicodeScalarValues, scanCode, keyCode, modifiers, isDown);
}

/// Abstract class for window-specific key mappings.
///
/// Given that there might be multiple window toolkit implementations (GLFW,
/// GTK, QT, etc), this creates a common interface for each of the
/// different toolkits.
///
/// This class is deprecated and will be removed. Platform specific key event
/// data will no longer be available. See [KeyEvent] for what is available.
@Deprecated(
  'No longer supported. '
  'This feature was deprecated after v3.18.0-2.0.pre.',
)
abstract class KeyHelper {
  /// Create a KeyHelper implementation depending on the given toolkit.
  @Deprecated(
    'No longer supported. '
    'This feature was deprecated after v3.18.0-2.0.pre.',
  )
  factory KeyHelper(String toolkit) {
    if (toolkit == 'glfw') {
      return GLFWKeyHelper();
    } else if (toolkit == 'gtk') {
      return GtkKeyHelper();
    } else {
      throw FlutterError('Window toolkit not recognized: $toolkit');
    }
  }

  /// Returns the name for the toolkit.
  ///
  /// This is used in debug mode to generate readable string.
  String get debugToolkit;

  /// Returns a [KeyboardSide] enum value that describes which side or sides of
  /// the given keyboard modifier key were pressed at the time of this event.
  @Deprecated(
    'No longer supported. '
    'This feature was deprecated after v3.18.0-2.0.pre.',
  )
  KeyboardSide getModifierSide(ModifierKey key);

  /// Returns true if the given [ModifierKey] was pressed at the time of this
  /// event.
  @Deprecated(
    'No longer supported. '
    'This feature was deprecated after v3.18.0-2.0.pre.',
  )
  bool isModifierPressed(
    ModifierKey key,
    int modifiers, {
    KeyboardSide side = KeyboardSide.any,
    required int keyCode,
    required bool isDown,
  });

  /// The numpad key from the specific key code mapping.
  LogicalKeyboardKey? numpadKey(int keyCode);

  /// The logical key from the specific key code mapping.
  LogicalKeyboardKey? logicalKey(int keyCode);

  /// The platform plane mask value of this platform.
  int get platformPlane;
}

/// Helper class that uses GLFW-specific key mappings.
///
/// This class is deprecated and will be removed. Platform specific key event
/// data will no longer be available. See [KeyEvent] for what is available.
@Deprecated(
  'No longer supported. '
  'This feature was deprecated after v3.18.0-2.0.pre.',
)
class GLFWKeyHelper implements KeyHelper {
  /// This mask is used to check the [RawKeyEventDataLinux.modifiers] field to
  /// test whether the CAPS LOCK modifier key is on.
  ///
  /// {@template flutter.services.GLFWKeyHelper.modifierCapsLock}
  /// Use this value if you need to decode the [RawKeyEventDataLinux.modifiers]
  /// field yourself, but it's much easier to use [isModifierPressed] if you
  /// just want to know if a modifier is pressed. This is especially true on
  /// GLFW, since its modifiers don't include the effects of the current key
  /// event.
  /// {@endtemplate}
  static const int modifierCapsLock = 0x0010;

  /// This mask is used to check the [RawKeyEventDataLinux.modifiers] field to
  /// test whether one of the SHIFT modifier keys is pressed.
  ///
  /// {@macro flutter.services.GLFWKeyHelper.modifierCapsLock}
  static const int modifierShift = 0x0001;

  /// This mask is used to check the [RawKeyEventDataLinux.modifiers] field to
  /// test whether one of the CTRL modifier keys is pressed.
  ///
  /// {@macro flutter.services.GLFWKeyHelper.modifierCapsLock}
  static const int modifierControl = 0x0002;

  /// This mask is used to check the [RawKeyEventDataLinux.modifiers] field to
  /// test whether one of the ALT modifier keys is pressed.
  ///
  /// {@macro flutter.services.GLFWKeyHelper.modifierCapsLock}
  static const int modifierAlt = 0x0004;

  /// This mask is used to check the [RawKeyEventDataLinux.modifiers] field to
  /// test whether one of the Meta(SUPER) modifier keys is pressed.
  ///
  /// {@macro flutter.services.GLFWKeyHelper.modifierCapsLock}
  static const int modifierMeta = 0x0008;

  /// This mask is used to check the [RawKeyEventDataLinux.modifiers] field to
  /// test whether any key in the numeric keypad is pressed.
  ///
  /// {@macro flutter.services.GLFWKeyHelper.modifierCapsLock}
  static const int modifierNumericPad = 0x0020;

  @override
  String get debugToolkit => 'GLFW';

  int _mergeModifiers({required int modifiers, required int keyCode, required bool isDown}) {
    // GLFW Key codes for modifier keys.
    const int shiftLeftKeyCode = 340;
    const int shiftRightKeyCode = 344;
    const int controlLeftKeyCode = 341;
    const int controlRightKeyCode = 345;
    const int altLeftKeyCode = 342;
    const int altRightKeyCode = 346;
    const int metaLeftKeyCode = 343;
    const int metaRightKeyCode = 347;
    const int capsLockKeyCode = 280;
    const int numLockKeyCode = 282;

    // On GLFW, the "modifiers" bitfield is the state as it is BEFORE this event
    // happened, not AFTER, like every other platform. Consequently, if this is
    // a key down, then we need to add the correct modifier bits, and if it's a
    // key up, we need to remove them.

    final int modifierChange = switch (keyCode) {
      shiftLeftKeyCode || shiftRightKeyCode => modifierShift,
      controlLeftKeyCode || controlRightKeyCode => modifierControl,
      altLeftKeyCode || altRightKeyCode => modifierAlt,
      metaLeftKeyCode || metaRightKeyCode => modifierMeta,
      capsLockKeyCode => modifierCapsLock,
      numLockKeyCode => modifierNumericPad,
      _ => 0,
    };

    return isDown ? modifiers | modifierChange : modifiers & ~modifierChange;
  }

  @override
  bool isModifierPressed(
    ModifierKey key,
    int modifiers, {
    KeyboardSide side = KeyboardSide.any,
    required int keyCode,
    required bool isDown,
  }) {
    modifiers = _mergeModifiers(modifiers: modifiers, keyCode: keyCode, isDown: isDown);
    return switch (key) {
      ModifierKey.controlModifier => modifiers & modifierControl != 0,
      ModifierKey.shiftModifier => modifiers & modifierShift != 0,
      ModifierKey.altModifier => modifiers & modifierAlt != 0,
      ModifierKey.metaModifier => modifiers & modifierMeta != 0,
      ModifierKey.capsLockModifier => modifiers & modifierCapsLock != 0,
      ModifierKey.numLockModifier => modifiers & modifierNumericPad != 0,
      // These are not used in GLFW keyboards.
      ModifierKey.functionModifier => false,
      ModifierKey.symbolModifier => false,
      ModifierKey.scrollLockModifier => false,
    };
  }

  @override
  KeyboardSide getModifierSide(ModifierKey key) {
    // Neither GLFW nor X11 provide a distinction between left and right
    // modifiers, so defaults to KeyboardSide.all.
    // https://code.woboq.org/qt5/include/X11/X.h.html#_M/ShiftMask
    return KeyboardSide.all;
  }

  @override
  LogicalKeyboardKey? numpadKey(int keyCode) {
    return kGlfwNumpadMap[keyCode];
  }

  @override
  LogicalKeyboardKey? logicalKey(int keyCode) {
    return kGlfwToLogicalKey[keyCode];
  }

  @override
  int get platformPlane => LogicalKeyboardKey.glfwPlane;
}

/// Helper class that uses GTK-specific key mappings.
///
/// This class is deprecated and will be removed. Platform specific key event
/// data will no longer be available. See [KeyEvent] for what is available.
@Deprecated(
  'No longer supported. '
  'This feature was deprecated after v3.18.0-2.0.pre.',
)
class GtkKeyHelper implements KeyHelper {
  /// This mask is used to check the [RawKeyEventDataLinux.modifiers] field to
  /// test whether one of the SHIFT modifier keys is pressed.
  ///
  /// {@template flutter.services.GtkKeyHelper.modifierShift}
  /// Use this value if you need to decode the [RawKeyEventDataLinux.modifiers] field yourself, but
  /// it's much easier to use [isModifierPressed] if you just want to know if a
  /// modifier is pressed. This is especially true on GTK, since its modifiers
  /// don't include the effects of the current key event.
  /// {@endtemplate}
  static const int modifierShift = 1 << 0;

  /// This mask is used to check the [RawKeyEventDataLinux.modifiers] field to
  /// test whether the CAPS LOCK modifier key is on.
  ///
  /// {@macro flutter.services.GtkKeyHelper.modifierShift}
  static const int modifierCapsLock = 1 << 1;

  /// This mask is used to check the [RawKeyEventDataLinux.modifiers] field to
  /// test whether one of the CTRL modifier keys is pressed.
  ///
  /// {@macro flutter.services.GtkKeyHelper.modifierShift}
  static const int modifierControl = 1 << 2;

  /// This mask is used to check the [RawKeyEventDataLinux.modifiers] field to
  /// test whether the first modifier key is pressed (usually mapped to alt).
  ///
  /// {@macro flutter.services.GtkKeyHelper.modifierShift}
  static const int modifierMod1 = 1 << 3;

  /// This mask is used to check the [RawKeyEventDataLinux.modifiers] field to
  /// test whether the second modifier key is pressed (assumed to be mapped to
  /// num lock).
  ///
  /// {@macro flutter.services.GtkKeyHelper.modifierShift}
  static const int modifierMod2 = 1 << 4;

  /// This mask is used to check the [RawKeyEventDataLinux.modifiers] field to
  /// test whether one of the Meta(SUPER) modifier keys is pressed.
  ///
  /// {@macro flutter.services.GtkKeyHelper.modifierShift}
  static const int modifierMeta = 1 << 26;

  @override
  String get debugToolkit => 'GTK';

  int _mergeModifiers({required int modifiers, required int keyCode, required bool isDown}) {
    // GTK Key codes for modifier keys.
    const int shiftLeftKeyCode = 0xffe1;
    const int shiftRightKeyCode = 0xffe2;
    const int controlLeftKeyCode = 0xffe3;
    const int controlRightKeyCode = 0xffe4;
    const int capsLockKeyCode = 0xffe5;
    const int shiftLockKeyCode = 0xffe6;
    const int altLeftKeyCode = 0xffe9;
    const int altRightKeyCode = 0xffea;
    const int metaLeftKeyCode = 0xffeb;
    const int metaRightKeyCode = 0xffec;
    const int numLockKeyCode = 0xff7f;

    // On GTK, the "modifiers" bitfield is the state as it is BEFORE this event
    // happened, not AFTER, like every other platform. Consequently, if this is
    // a key down, then we need to add the correct modifier bits, and if it's a
    // key up, we need to remove them.

    final int modifierChange = switch (keyCode) {
      shiftLeftKeyCode || shiftRightKeyCode => modifierShift,
      controlLeftKeyCode || controlRightKeyCode => modifierControl,
      altLeftKeyCode || altRightKeyCode => modifierMod1,
      metaLeftKeyCode || metaRightKeyCode => modifierMeta,
      capsLockKeyCode || shiftLockKeyCode => modifierCapsLock,
      numLockKeyCode => modifierMod2,
      _ => 0,
    };

    return isDown ? modifiers | modifierChange : modifiers & ~modifierChange;
  }

  @override
  bool isModifierPressed(
    ModifierKey key,
    int modifiers, {
    KeyboardSide side = KeyboardSide.any,
    required int keyCode,
    required bool isDown,
  }) {
    modifiers = _mergeModifiers(modifiers: modifiers, keyCode: keyCode, isDown: isDown);
    return switch (key) {
      ModifierKey.controlModifier => modifiers & modifierControl != 0,
      ModifierKey.shiftModifier => modifiers & modifierShift != 0,
      ModifierKey.altModifier => modifiers & modifierMod1 != 0,
      ModifierKey.metaModifier => modifiers & modifierMeta != 0,
      ModifierKey.capsLockModifier => modifiers & modifierCapsLock != 0,
      ModifierKey.numLockModifier => modifiers & modifierMod2 != 0,
      // These are not used in GTK keyboards.
      ModifierKey.functionModifier => false,
      ModifierKey.symbolModifier => false,
      ModifierKey.scrollLockModifier => false,
    };
  }

  @override
  KeyboardSide getModifierSide(ModifierKey key) {
    // Neither GTK nor X11 provide a distinction between left and right
    // modifiers, so defaults to KeyboardSide.all.
    // https://code.woboq.org/qt5/include/X11/X.h.html#_M/ShiftMask
    return KeyboardSide.all;
  }

  @override
  LogicalKeyboardKey? numpadKey(int keyCode) {
    return kGtkNumpadMap[keyCode];
  }

  @override
  LogicalKeyboardKey? logicalKey(int keyCode) {
    return kGtkToLogicalKey[keyCode];
  }

  @override
  int get platformPlane => LogicalKeyboardKey.gtkPlane;
}
