import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:spritewidget/spritewidget.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ColorSequenceWell extends StatelessWidget {
  final ColorSequence colorSequence;
  final VoidCallback onTap;

  static final String _baseEncodedImage = 'iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAIAAADZF8uwAAAAGUlEQVQYV2M4gwH+YwCGIasIUwhT25BVBADtzYNYrHvv4gAAAABJRU5ErkJggg==';
  final Uint8List _chessTexture = base64.decode(_baseEncodedImage);

  ColorSequenceWell({this.colorSequence, this.onTap});

  @override
  Widget build(BuildContext context) {

    // TODO: implement build
    LinearGradient gradient = new LinearGradient(
      colors: colorSequence.colors,
      stops: colorSequence.colorStops,
    );

    return new Container(
      height: 30.0,
      child: new Stack(
        fit: StackFit.expand,
        children: <Widget>[
          new DecoratedBox(
            decoration: new BoxDecoration(
              image: new DecorationImage(
                image: new MemoryImage(_chessTexture),
                repeat: ImageRepeat.repeat,
              ),
            )
          ),
          new DecoratedBox(
            decoration: new BoxDecoration(
              gradient: gradient,
            ),
          ),
          new Material(
            type: MaterialType.transparency,
            child: onTap != null ? new InkWell(
              onTap: onTap,
            ) : null,
          ),
        ],
      ),
    );
  }
}

typedef void ColorSequenceDesignerCallback(ColorSequence value);

class ColorSequenceDesigner extends StatefulWidget {
  final ColorSequence colorSequence;
  final ColorSequenceDesignerCallback onChanged;

  ColorSequenceDesigner({this.colorSequence, this.onChanged});

  @override
  _ColorSequenceDesignerState createState() => new _ColorSequenceDesignerState();
}

class _ColorSequenceDesignerState extends State<ColorSequenceDesigner> {
  static final int _numMaxStops = 4;

  ColorSequence _colorSequence;

  List<Color> _colors = new List<Color>(4);
  List<double> _stops = new List<double>(4);

  @override
  void initState() {
    super.initState();

    int numColors = widget.colorSequence.colors.length;
    for (int i = 0; i < numColors; i++) {
      _colors[i] = widget.colorSequence.colors[i];
      _stops[i] = widget.colorSequence.colorStops[i];
    }

    _updateColorSequence();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = <Widget>[];

    children.add(
      new Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: new ColorSequenceWell(
          colorSequence: _colorSequence,
        ),
      ),
    );

    for (int i = 0; i < _numMaxStops; i++) {
      int stopNum = i;

      children.add(
        new Row(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            new Checkbox(
              value: _colors[stopNum] != null,
              onChanged: (bool value) {
                setState(() {
                  if (value) {
                    _addColorStop(stopNum);
                  } else {
                    _removeColorStop(stopNum);
                  }
                });
              },
            ),
            new Expanded(
              child: new Slider(
                value: _stops[stopNum] != null ? _stops[stopNum] : 0.0,
                onChanged: (double value) {
                  setState(() {
                    _updateStop(stopNum, value);
                  });
                },
                max: _stops[stopNum] != null ? 1.0 : 0.0,
              ),
            ),
            new Container(
              width: 50.0,
              height: 30.0,
              color: _colors[stopNum] != null ? _colors[stopNum] : Colors.grey,
              child: new GestureDetector(
                onTap: () {
                  _pickColor(stopNum);
                },
              ),
            ),
          ],
        ),
      );
    }

    return new Column(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  void _updateStop(int stop, double value) {
    for (int i = 0; i < stop; i ++) {
      if (_stops[i] != null && _stops[i] > value)
        _stops[i] = value;
    }

    _stops[stop] = value;

    for (int i = stop + 1; i < _numMaxStops; i++) {
      if (_stops[i] != null && _stops[i] < value)
        _stops[i] = value;
    }

    _updateColorSequence();
  }

  void _addColorStop(int stopNum) {
    int firstStop = _numMaxStops -1;
    int lastStop = 0;
    for (int i = 0; i < _numMaxStops; i++) {
      if (_colors[i] != null && i < firstStop)
        firstStop = i;
      if (_colors[i] != null && i > lastStop)
        lastStop = i;
    }

    if (stopNum < firstStop)
      _stops[stopNum] = 0.0;
    else if (stopNum > lastStop)
      _stops[stopNum] = 1.0;
    else {
      int prevStop = 0;
      for (int i = stopNum - 1; i >= 0; i --) {
        if (_stops[i] != null) {
          prevStop = i;
          break;
        }
      }

      int nextStop = _numMaxStops - 1;
      for (int i = stopNum + 1; i < _numMaxStops; i++) {
        if (_stops[i] != null) {
          nextStop = i;
          break;
        }
      }
      _stops[stopNum] = (_stops[prevStop] + _stops[nextStop]) / 2.0;
    }

    _colors[stopNum] = Colors.black;

    _updateColorSequence();
  }

  void _removeColorStop(int stopNum) {
    int numStops = 0;
    for (int i = 0; i < _numMaxStops; i++) {
      if (_stops[i] != null)
        numStops += 1;
    }

    if (numStops <= 1)
      return;

    _stops[stopNum] = null;
    _colors[stopNum] = null;

    _updateColorSequence();
  }

  void _pickColor(int stopNum) {
    showDialog(
      context: context,
      child: new Builder(
        builder: (BuildContext context) {
          return new AlertDialog(
            title: const Text('Color stop'),
            content: new SingleChildScrollView(
              child: new ColorPicker(
                pickerColor: _colors[stopNum],
                onColorChanged: (Color c) {
                  setState(() {
                    _colors[stopNum] = c;
                    _updateColorSequence();
                  });
                },
                enableLabel: false,
                pickerAreaHeightPercent: 0.8,
              ),
            ),
            actions: <Widget>[
              new FlatButton(
                child: new Text('DONE'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      )
    );

    _updateColorSequence();
  }

  void _updateColorSequence() {
    List<Color> colors = <Color>[];
    List<double> stops = <double>[];

    for (int i = 0; i < _numMaxStops; i++) {
      if (_colors[i] != null) {
        colors.add(_colors[i]);
        stops.add(_stops[i]);
      }
    }

    _colorSequence = new ColorSequence(colors, stops);

    if (widget.onChanged != null)
      return widget.onChanged(_colorSequence);
  }
}