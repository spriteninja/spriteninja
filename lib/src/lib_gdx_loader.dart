// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of spritewidget;


class LibGDXLoader {
  /// Parses a atlas file into a list of frames
  static List<LibGDXFrame> parseFrames(String atlas) {
    var result = new List<LibGDXFrame>();

    var frameLines = _splitAtlasIntoFrameLines(atlas);

    for (int i = 0; i < frameLines.length; ++i) {
      var frame = new LibGDXFrame.FromAtlasFileLines(frameLines[i]);
      result.add(frame);
    }
    return result;
  }

  /// Split a atlas file into the lines corresponding to a frame
  static List<List<String>> _splitAtlasIntoFrameLines(String atlas) {
    var result = new List<List<String>>();

    // Split the atlas into lines, so we can iterate over them
    var lines = atlas.split("\n");

    // Find the start of the first frame
    var startLine = 0;
    while (startLine < lines.length &&
        !_isLineFromInsideFrameDefinition(lines[startLine])) {
      ++startLine;
    }
    // Are we through the whole file? Than we cannot find any frames!
    if (startLine >= lines.length) {
      return result;
    }

    // Move one line up, because the frame starts one line above the 'inside' lines
    --startLine;

    // Now go through the remaining lines and find the frames
    var endLine = startLine+1;
    while (endLine < lines.length) {
      while(endLine < lines.length && _isLineFromInsideFrameDefinition(lines[endLine])) {
        ++endLine;
      }

      // Add the lines for the frame
      result.add(lines.sublist(startLine, endLine));

      // Reset for finding next frame definition
      startLine = endLine;
      endLine = startLine + 1;
    }
    return result;
  }

  /// Test if the line of an atlas file is inside a lib gdx frame
  static bool _isLineFromInsideFrameDefinition(String line) {
    // All lines inside frame definition are indented, that is the criteria
    return line.length > 0 && (line[0] == ' ' || line[0] == '\t');
  }
}