import '../models/image_item.dart';

/// Utilities for mapping secret photo slots to their asset/network identifiers.
class SecretImageUtils {
  /// Slots 1-4 use the B-set, slot 5+ switch to C-set assets.
  static String typeLetter(int slotIndex) => slotIndex <= 4 ? 'b' : 'c';

  static ImageType imageType(int slotIndex) =>
      slotIndex <= 4 ? ImageType.B : ImageType.C;

  static String canonicalId(int setId, int slotIndex) =>
      'secret_${setId}_$slotIndex';

  /// Normalize legacy IDs like `secret_2_b_5` into `secret_2_5`.
  static String normalizeImageId(String imageId) {
    final secretLegacy =
        RegExp(r'^secret_(\d+)_([abc])_(\d+)$').firstMatch(imageId);
    if (secretLegacy != null) {
      final setId = int.parse(secretLegacy.group(1)!);
      final slot = int.parse(secretLegacy.group(3)!);
      return canonicalId(setId, slot);
    }
    return imageId;
  }
}
