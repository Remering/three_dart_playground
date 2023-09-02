import 'dart:math';

import 'package:image/image.dart';

extension SkinImageExtension on Image {
  void copyImage(
      int sX, int sY, int w, int h, int dX, int dY, bool flipHorizontal) {
    Image newImage = Image(w, h);
    drawImage(newImage, this, srcX: sX, srcY: sY);
    if (flipHorizontal) {
      flip(newImage, Flip.horizontal);
    }
    drawImage(this, newImage, dstX: dX, dstY: dY);
  }

  bool hasTransparency(int x, int y, int w, int h) {
    for (int x0 = x; x0 < min(w, width); x0++) {
      for (int y0 = y; y0 < min(y, height); y0++) {
        if (getPixel(x0, y0) & 0xFF != 0xFF) {
          return true;
        }
      }
    }
    return false;
  }

  void fixOpaqueSkin(int width, bool format1_8) {
    if (format1_8) {
      if (hasTransparency(0, 0, width, width)) {
        return;
      }
    } else if (hasTransparency(0, 0, width, width ~/ 2)) {
      return;
    }

    final scale = computeSkinScale();
    void clearArea(int x, int y, int w, int h) {
      drawRect(
        this,
        x * scale as int,
        y * scale as int,
        (x + w) * scale as int,
        (y + h) * scale as int,
        0,
      );
    }

    clearArea(40, 0, 8, 8); // Helm Top
    clearArea(48, 0, 8, 8); // Helm Bottom
    clearArea(32, 8, 8, 8); // Helm Right
    clearArea(40, 8, 8, 8); // Helm Front
    clearArea(48, 8, 8, 8); // Helm Left
    clearArea(56, 8, 8, 8); // Helm Back

    if (format1_8) {
      clearArea(4, 32, 4, 4); // Right Leg Layer 2 Top
      clearArea(8, 32, 4, 4); // Right Leg Layer 2 Bottom
      clearArea(0, 36, 4, 12); // Right Leg Layer 2 Right
      clearArea(4, 36, 4, 12); // Right Leg Layer 2 Front
      clearArea(8, 36, 4, 12); // Right Leg Layer 2 Left
      clearArea(12, 36, 4, 12); // Right Leg Layer 2 Back
      clearArea(20, 32, 8, 4); // Torso Layer 2 Top
      clearArea(28, 32, 8, 4); // Torso Layer 2 Bottom
      clearArea(16, 36, 4, 12); // Torso Layer 2 Right
      clearArea(20, 36, 8, 12); // Torso Layer 2 Front
      clearArea(28, 36, 4, 12); // Torso Layer 2 Left
      clearArea(32, 36, 8, 12); // Torso Layer 2 Back
      clearArea(44, 32, 4, 4); // Right Arm Layer 2 Top
      clearArea(48, 32, 4, 4); // Right Arm Layer 2 Bottom
      clearArea(40, 36, 4, 12); // Right Arm Layer 2 Right
      clearArea(44, 36, 4, 12); // Right Arm Layer 2 Front
      clearArea(48, 36, 4, 12); // Right Arm Layer 2 Left
      clearArea(52, 36, 12, 12); // Right Arm Layer 2 Back
      clearArea(4, 48, 4, 4); // Left Leg Layer 2 Top
      clearArea(8, 48, 4, 4); // Left Leg Layer 2 Bottom
      clearArea(0, 52, 4, 12); // Left Leg Layer 2 Right
      clearArea(4, 52, 4, 12); // Left Leg Layer 2 Front
      clearArea(8, 52, 4, 12); // Left Leg Layer 2 Left
      clearArea(12, 52, 4, 12); // Left Leg Layer 2 Back
      clearArea(52, 48, 4, 4); // Left Arm Layer 2 Top
      clearArea(56, 48, 4, 4); // Left Arm Layer 2 Bottom
      clearArea(48, 52, 4, 12); // Left Arm Layer 2 Right
      clearArea(52, 52, 4, 12); // Left Arm Layer 2 Front
      clearArea(56, 52, 4, 12); // Left Arm Layer 2 Left
      clearArea(60, 52, 4, 12); // Left Arm Layer 2 Back
    }
  }

  void convertSkinTo1_8(int width) {
    final scale = computeSkinScale();
    void copySkin(
      int sX,
      int sY,
      int w,
      int h,
      int dX,
      int dY,
      bool flipHorizontal,
    ) {
      copyImage(
        sX * scale as int,
        sY * scale as int,
        w * scale as int,
        h * scale as int,
        dX * scale as int,
        dY * scale as int,
        flipHorizontal,
      );
    }

    copySkin(4, 16, 4, 4, 20, 48, true); // Top Leg
    copySkin(8, 16, 4, 4, 24, 48, true); // Bottom Leg
    copySkin(0, 20, 4, 12, 24, 52, true); // Outer Leg
    copySkin(4, 20, 4, 12, 20, 52, true); // Front Leg
    copySkin(8, 20, 4, 12, 16, 52, true); // Inner Leg
    copySkin(12, 20, 4, 12, 28, 52, true); // Back Leg
    copySkin(44, 16, 4, 4, 36, 48, true); // Top Arm
    copySkin(48, 16, 4, 4, 40, 48, true); // Bottom Arm
    copySkin(40, 20, 4, 12, 40, 52, true); // Outer Arm
    copySkin(44, 20, 4, 12, 36, 52, true); // Front Arm
    copySkin(48, 20, 4, 12, 32, 52, true); // Inner Arm
    copySkin(52, 20, 4, 12, 44, 52, true); // Back Arm
  }

  Image loadSkinToImage() {
    bool isOldFormat = false;
    if (width != height) {
      if (width == 2 * height) {
        isOldFormat = true;
      } else {
        throw 'Bad skin size: ${width}x$height';
      }
    }
    if (isOldFormat) {
      final sideLength = width;
      final newImage = Image(sideLength, sideLength);
      drawRect(newImage, 0, 0, sideLength, sideLength, 0);
      drawImage(newImage, this, srcH: sideLength, dstH: sideLength ~/ 2);
      newImage.convertSkinTo1_8(sideLength);
      newImage.fixOpaqueSkin(width, false);
      return newImage;
    } else {
      fixOpaqueSkin(width, true);
      return this;
    }
  }

  bool isAreaBlack(int x, int y, int w, int h) {
    for (int x0 = x; x0 < min(w, width); x0++) {
      for (int y0 = y; y0 < min(y, height); y0++) {
        if (getPixel(x0, y0) != 0xFF) {
          return false;
        }
      }
    }
    return true;
  }

  bool isAreaWhite(int x, int y, int w, int h) {
    for (int x0 = x; x0 < min(w, width); x0++) {
      for (int y0 = y; y0 < min(y, height); y0++) {
        if (getPixel(x0, y0) != 0xFFFFFFFF) {
          return false;
        }
      }
    }
    return true;
  }

  String inferModelType() {
    // The right arm area of *default* skins:
    // (44,16)->*-------*-------*
    // (40,20)  |top    |bottom |
    // \|/      |4x4    |4x4    |
    //  *-------*-------*-------*-------*
    //  |right  |front  |left   |back   |
    //  |4x12   |4x12   |4x12   |4x12   |
    //  *-------*-------*-------*-------*
    // The right arm area of *slim* skins:
    // (44,16)->*------*------*-*
    // (40,20)  |top   |bottom| |<----[x0=50,y0=16,w=2,h=4]
    // \|/      |3x4   |3x4   | |
    //  *-------*------*------***-----*-*
    //  |right  |front |left   |back  | |<----[x0=54,y0=20,w=2,h=12]
    //  |4x12   |3x12  |4x12   |3x12  | |
    //  *-------*------*-------*------*-*
    // Compared with default right arms, slim right arms have 2 unused areas.
    //
    // The same is true for left arm:
    // The left arm area of *default* skins:
    // (36,48)->*-------*-------*
    // (32,52)  |top    |bottom |
    // \|/      |4x4    |4x4    |
    //  *-------*-------*-------*-------*
    //  |right  |front  |left   |back   |
    //  |4x12   |4x12   |4x12   |4x12   |
    //  *-------*-------*-------*-------*
    // The left arm area of *slim* skins:
    // (36,48)->*------*------*-*
    // (32,52)  |top   |bottom| |<----[x0=42,y0=48,w=2,h=4]
    // \|/      |3x4   |3x4   | |
    //  *-------*------*------***-----*-*
    //  |right  |front |left   |back  | |<----[x0=46,y0=52,w=2,h=12]
    //  |4x12   |3x12  |4x12   |3x12  | |
    //  *-------*------*-------*------*-*
    //
    // If there is a transparent pixel in any of the 4 unused areas, the skin must be slim,
    // as transparent pixels are not allowed in the first layer.
    // If the 4 areas are all black or all white, the skin is also considered as slim.
    final scale = computeSkinScale();
    bool checkTransparency(
      int x,
      int y,
      int w,
      int h,
    ) =>
        hasTransparency(
          x * scale as int,
          y * scale as int,
          w * scale as int,
          h * scale as int,
        );

    bool checkBlack(
      int x,
      int y,
      int w,
      int h,
    ) =>
        isAreaBlack(
          x * scale as int,
          y * scale as int,
          w * scale as int,
          h * scale as int,
        );

    bool checkWhite(
      int x,
      int y,
      int w,
      int h,
    ) =>
        isAreaWhite(
          x * scale as int,
          y * scale as int,
          w * scale as int,
          h * scale as int,
        );

    final isSlim = (checkTransparency(50, 16, 2, 4) ||
            checkTransparency(54, 20, 2, 12) ||
            checkTransparency(42, 48, 2, 4) ||
            checkTransparency(46, 52, 2, 12)) ||
        (checkBlack(50, 16, 2, 4) &&
            checkBlack(54, 20, 2, 12) &&
            checkBlack(42, 48, 2, 4) &&
            checkBlack(46, 52, 2, 12)) ||
        (checkWhite(50, 16, 2, 4) &&
            checkWhite(54, 20, 2, 12) &&
            checkWhite(42, 48, 2, 4) &&
            checkWhite(46, 52, 2, 12));
    return isSlim ? 'slim' : 'default';
  }

  void checkSkinSize() {
    if (width != height && width != height) {
      throw 'Bad skin size: ${width}x$height';
    }
  }

  double computeSkinScale() => width / 64;

  Image loadEarsToImageFromSkin() {
    checkSkinSize();
    final scale = computeSkinScale();
    final int w = 14 * scale as int;
    final int h = 7 * scale as int;
    final earsImage = Image(w, h);
    drawRect(earsImage, 0, 0, w, h, 0);
    drawImage(
      earsImage,
      this,
      srcX: 24 * scale as int,
      srcY: 0,
      srcW: w,
      srcH: h,
      dstX: 0,
      dstY: 0,
      dstW: w,
      dstH: h,
    );
    return earsImage;
  }
}
