// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of spritewidget;

/// A frame for a sprite inside the sprite atlas. Used for loading a libGDX Sprite Atlas.
class LibGDXFrame {
  String name;

  /// The position of the frame inside the texture
  Offset xy;

  /// The size of the frame inside the texture
  Size size;

  /// The original size of the frame
  Size orig;

  /// The offset of the trimmed frame to the original untrimmed frame
  Offset offset;
  bool rotate;
  int index;

  /// Create a [LibGDXFrame] from the corresponding lines in the atlas file
  LibGDXFrame.FromAtlasFileLines(List<String> lines) {
    // Set the name, which is given by the first line
    this.name = lines[0];

    // Extract the remaining properties from the remaining lines
    for (String line in lines.sublist(1)) {
      // Split the name into name and value, which are separated by ":"
      var splitList = line.split(":");
      if (splitList.length != 2) {
        throw new FormatException("Expected line in form of 'name': 'value'");
      }
      var name = splitList[0].trim();
      var value = splitList[1].trim();

      switch (name) {
        case "rotate":
          this.rotate = value.toLowerCase() == "true";
          break;
        case "xy":
          this.xy = this._readPoint(value);
          break;
        case "size":
          this.size = this._readSize(value);
          break;
        case "orig":
          this.orig = this._readSize(value);
          break;
        case "offset":
          this.offset = this._readPoint(value);
          break;
        case "index":
          this.index = int.parse(value);
          break;
      }
    }
  }

  Size _readSize(String value) {
    // its a comma separated list 'x, y'
    var splitList = value.split(",");
    if (splitList.length != 2) {
      throw new FormatException("Expected Size in the format 'x, y'");
    }
    return new Size(double.parse(splitList[0]), double.parse(splitList[1]));
  }

  Offset _readPoint(String value) {
    // its a comma separated list 'x, y'
    var splitList = value.split(",");
    if (splitList.length != 2) {
      throw new FormatException("Expected Offset in the format 'x, y'");
    }
    return new Offset(double.parse(splitList[0]), double.parse(splitList[1]));
  }
}
