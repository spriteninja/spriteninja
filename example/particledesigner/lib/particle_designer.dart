import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:spritewidget/spritewidget.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:url_launcher/url_launcher.dart';

import 'particle_presets.dart';
import 'particle_world.dart';
import 'colorsequence_designer.dart';

typedef void PropertyDoubleCallback(double value);
typedef void PropertyIntCallback(int value);
typedef void PropertyBoolCallback(bool value);
typedef void PropertyBlendModeCallback(BlendMode value);
typedef void PropertyColorCallback(Color value);
typedef void PropertyColorSequenceCallback(ColorSequence value);

class ParticleDesigner extends StatefulWidget {
  final ImageMap images;

  ParticleDesigner({this.images});

  ParticleDesignerState createState() => new ParticleDesignerState();
}

class ParticleDesignerState extends State<ParticleDesigner> with SingleTickerProviderStateMixin {
  ParticleWorld _particleWorld;
  TabController _tabController;
  Color _backgroundColor;

  @override
  void initState() {
    super.initState();
    _particleWorld = new ParticleWorld(images: widget.images);
    _tabController = new TabController(length: 5, vsync: this);
    _tabController.index = 0;
    _backgroundColor = Colors.blueGrey[700];
  }

  Widget build(BuildContext context) {
    List<Widget> presets = <Widget>[];
    for (ParticlePresetType type in ParticlePresetType.values) {
      ListTile tile = new ListTile(
        title: new Text(type.toString().substring(19)),
        onTap: () {
          setState(() {
            ParticlePreset.updateParticles(
              _particleWorld,
              type,
              (Color bg) {
                _backgroundColor = bg;
              },
            );
          });
        },
      );
      presets.add(tile);
    }

    Widget propertyEditor = new Column(
      children: <Widget>[
        new Container(
          color: Theme.of(context).accentColor,
          child: new TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: <Tab>[
              new Tab(text: 'PRESETS',),
              new Tab(text: 'EMISSION',),
              new Tab(text: 'MOVEMENT',),
              new Tab(text: 'SIZE & ROTATION',),
              new Tab(text: 'TEXTURE & COLORS',),
            ],
          ),
        ),
        new Expanded(
          child: new TabBarView(
            controller: _tabController,
            children: <Widget>[
              new ListView(
                padding: EdgeInsets.zero,
                children: presets,
              ),
              new ListView(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                children: <Widget>[
                  new PropertyDouble(
                    name: 'Life',
                    value: _particleWorld.particleSystem.life,
                    minValue: 0.0,
                    maxValue: 10.0,
                    onUpdated: (double value) {
                      setState(() {
                        _particleWorld.particleSystem.life = value;
                      });
                    },
                  ),
                  new PropertyDouble(
                    name: 'Life variance',
                    value: _particleWorld.particleSystem.lifeVar,
                    minValue: 0.0,
                    maxValue: 10.0,
                    onUpdated: (double value) {
                      setState(() {
                        _particleWorld.particleSystem.lifeVar = value;
                      });
                    },
                  ),
                  new PropertyDouble(
                    name: 'Max particles',
                    digits: false,
                    value: _particleWorld.particleSystem.maxParticles.toDouble(),
                    minValue: 0.0,
                    maxValue: 500.0,
                    onUpdated: (double value) {
                      setState(() {
                        _particleWorld.particleSystem.maxParticles = value.toInt();
                      });
                    },
                  ),
                  new PropertyDouble(
                    name: 'Emission rate',
                    value: _particleWorld.particleSystem.emissionRate,
                    minValue: 0.0,
                    maxValue: 200.0,
                    onUpdated: (double value) {
                      setState(() {
                        _particleWorld.particleSystem.emissionRate = value;
                      });
                    },
                  ),
                  new PropertyDouble(
                    name: 'Num particles to emit',
                    digits: false,
                    value: _particleWorld.particleSystem.numParticlesToEmit.toDouble(),
                    minValue: 0.0,
                    maxValue: 500.0,
                    onUpdated: (double value) {
                      setState(() {
                        _particleWorld.particleSystem.numParticlesToEmit = value.toInt();
                      });
                    },
                  ),
                ],
              ),
              new ListView(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                children: <Widget>[
                  new PropertyDouble(
                    name: 'Position variance x',
                    value: _particleWorld.particleSystem.posVar.dx,
                    minValue: 0.0,
                    maxValue: 512.0,
                    onUpdated: (double value) {
                      setState(() {
                        Offset oldVar = _particleWorld.particleSystem.posVar;
                        _particleWorld.particleSystem.posVar = new Offset(value, oldVar.dy);
                      });
                    },
                  ),
                  new PropertyDouble(
                    name: 'Position variance y',
                    value: _particleWorld.particleSystem.posVar.dy,
                    minValue: 0.0,
                    maxValue: 512.0,
                    onUpdated: (double value) {
                      setState(() {
                        Offset oldVar = _particleWorld.particleSystem.posVar;
                        _particleWorld.particleSystem.posVar = new Offset(oldVar.dx, value);
                      });
                    },
                  ),
                  new PropertyDouble(
                    name: 'Gravity x',
                    value: _particleWorld.particleSystem.gravity.dx,
                    minValue: -512.0,
                    maxValue: 512.0,
                    onUpdated: (double value) {
                      setState(() {
                        Offset oldVar = _particleWorld.particleSystem.gravity;
                        _particleWorld.particleSystem.gravity = new Offset(value, oldVar.dy);
                      });
                    },
                  ),
                  new PropertyDouble(
                    name: 'Gravity y',
                    value: _particleWorld.particleSystem.gravity.dy,
                    minValue: -512.0,
                    maxValue: 512.0,
                    onUpdated: (double value) {
                      setState(() {
                        Offset oldVar = _particleWorld.particleSystem.gravity;
                        _particleWorld.particleSystem.gravity = new Offset(oldVar.dx, value);
                      });
                    },
                  ),
                  new PropertyDouble(
                    name: 'Direction',
                    value: _particleWorld.particleSystem.direction,
                    minValue: -360.0,
                    maxValue: 360.0,
                    onUpdated: (double value) {
                      setState(() {
                        _particleWorld.particleSystem.direction = value;
                      });
                    },
                  ),
                  new PropertyDouble(
                    name: 'Direction variance',
                    value: _particleWorld.particleSystem.directionVar,
                    minValue: 0.0,
                    maxValue: 360.0,
                    onUpdated: (double value) {
                      setState(() {
                        _particleWorld.particleSystem.directionVar = value;
                      });
                    },
                  ),
                  new PropertyDouble(
                    name: 'Speed',
                    value: _particleWorld.particleSystem.speed,
                    minValue: 0.0,
                    maxValue: 250.0,
                    onUpdated: (double value) {
                      setState(() {
                        _particleWorld.particleSystem.speed = value;
                      });
                    },
                  ),
                  new PropertyDouble(
                    name: 'Speed variance',
                    value: _particleWorld.particleSystem.speedVar,
                    minValue: 0.0,
                    maxValue: 250.0,
                    onUpdated: (double value) {
                      setState(() {
                        _particleWorld.particleSystem.speedVar = value;
                      });
                    },
                  ),
                  new PropertyDouble(
                    name: 'Radial acceleration',
                    value: _particleWorld.particleSystem.radialAcceleration,
                    minValue: -500.0,
                    maxValue: 500.0,
                    onUpdated: (double value) {
                      setState(() {
                        _particleWorld.particleSystem.radialAcceleration = value;
                      });
                    },
                  ),
                  new PropertyDouble(
                    name: 'Radial acceleration variance',
                    value: _particleWorld.particleSystem.radialAccelerationVar,
                    minValue: 0.0,
                    maxValue: 500.0,
                    onUpdated: (double value) {
                      setState(() {
                        _particleWorld.particleSystem.radialAccelerationVar = value;
                      });
                    },
                  ),
                  new PropertyDouble(
                    name: 'Tangential acceleration',
                    value: _particleWorld.particleSystem.tangentialAcceleration,
                    minValue: -500.0,
                    maxValue: 500.0,
                    onUpdated: (double value) {
                      setState(() {
                        _particleWorld.particleSystem.tangentialAcceleration = value;
                      });
                    },
                  ),
                  new PropertyDouble(
                    name: 'Tangential acceleration variance',
                    value: _particleWorld.particleSystem.tangentialAccelerationVar,
                    minValue: 0.0,
                    maxValue: 500.0,
                    onUpdated: (double value) {
                      setState(() {
                        _particleWorld.particleSystem.tangentialAccelerationVar = value;
                      });
                    },
                  ),
                ],
              ),
              new ListView(
                padding: const EdgeInsets.only(bottom: 16.0),
                children: <Widget>[
                  new PropertyBool(
                    name: 'Rotate to movement',
                    value: _particleWorld.particleSystem.rotateToMovement,
                    onUpdated: (bool value) {
                      setState(() {
                        _particleWorld.particleSystem.rotateToMovement = value;
                      });
                    },
                  ),
                  new PropertyDouble(
                    name: 'Start size',
                    value: _particleWorld.particleSystem.startSize,
                    minValue: 0.0,
                    maxValue: 10.0,
                    onUpdated: (double value) {
                      setState(() {
                        _particleWorld.particleSystem.startSize = value;
                      });
                    },
                  ),
                  new PropertyDouble(
                    name: 'Start size variance',
                    value: _particleWorld.particleSystem.startSizeVar,
                    minValue: 0.0,
                    maxValue: 10.0,
                    onUpdated: (double value) {
                      setState(() {
                        _particleWorld.particleSystem.startSizeVar = value;
                      });
                    },
                  ),
                  new PropertyDouble(
                    name: 'End size',
                    value: _particleWorld.particleSystem.endSize,
                    minValue: 0.0,
                    maxValue: 10.0,
                    onUpdated: (double value) {
                      setState(() {
                        _particleWorld.particleSystem.endSize = value;
                      });
                    },
                  ),
                  new PropertyDouble(
                    name: 'End size variance',
                    value: _particleWorld.particleSystem.endSizeVar,
                    minValue: 0.0,
                    maxValue: 10.0,
                    onUpdated: (double value) {
                      setState(() {
                        _particleWorld.particleSystem.endSizeVar = value;
                      });
                    },
                  ),
                  new PropertyDouble(
                    name: 'Start rotation',
                    value: _particleWorld.particleSystem.startRotation,
                    minValue: -360.0,
                    maxValue: 360.0,
                    onUpdated: (double value) {
                      setState(() {
                        _particleWorld.particleSystem.startRotation = value;
                      });
                    },
                  ),
                  new PropertyDouble(
                    name: 'Start rotation variance',
                    value: _particleWorld.particleSystem.startRotationVar,
                    minValue: 0.0,
                    maxValue: 360.0,
                    onUpdated: (double value) {
                      setState(() {
                        _particleWorld.particleSystem.startRotationVar = value;
                      });
                    },
                  ),
                  new PropertyDouble(
                    name: 'End rotation',
                    value: _particleWorld.particleSystem.endRotation,
                    minValue: -360.0,
                    maxValue: 360.0,
                    onUpdated: (double value) {
                      setState(() {
                        _particleWorld.particleSystem.endRotation = value;
                      });
                    },
                  ),
                  new PropertyDouble(
                    name: 'End rotation varience',
                    value: _particleWorld.particleSystem.endRotationVar,
                    minValue: 0.0,
                    maxValue: 360.0,
                    onUpdated: (double value) {
                      setState(() {
                        _particleWorld.particleSystem.endRotationVar = value;
                      });
                    },
                  ),
                ],
              ),
              new ListView(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                children: <Widget>[
                  new PropertyColor(
                    name: 'Background color',
                    value: _backgroundColor,
                    onUpdated: (Color c) {
                      setState(() {
                        _backgroundColor = c;
                      });
                    },
                  ),
                  new PropertyColorSequence(
                    name: 'Color sequence',
                    value: _particleWorld.particleSystem.colorSequence,
                    onUpdated: (ColorSequence c) {
                      setState(() {
                        _particleWorld.particleSystem.colorSequence = c;
                      });
                    },
                  ),
                  new PropertyTexture(
                    name: 'Texture',
                    value: _particleWorld.selectedTexture,
                    onUpdated: (int value) {
                      setState(() {
                        _particleWorld.selectedTexture = value;
                      });
                    },
                  ),
                  new PropertyBlendMode(
                    name: 'Transfer Mode',
                    value: _particleWorld.particleSystem.transferMode,
                    onUpdated: (BlendMode value) {
                      setState(() {
                        _particleWorld.particleSystem.transferMode = value;
                      });
                    },
                  ),
                  new PropertyDouble(
                    name: 'Alpha variance',
                    digits: false,
                    value: _particleWorld.particleSystem.alphaVar.toDouble(),
                    minValue: 0.0,
                    maxValue: 255.0,
                    onUpdated: (double value) {
                      setState(() {
                        _particleWorld.particleSystem.alphaVar = value.toInt();
                      });
                    },
                  ),
                  new PropertyDouble(
                    name: 'Red variance',
                    digits: false,
                    value: _particleWorld.particleSystem.redVar.toDouble(),
                    minValue: 0.0,
                    maxValue: 255.0,
                    onUpdated: (double value) {
                      setState(() {
                        _particleWorld.particleSystem.redVar = value.toInt();
                      });
                    },
                  ),
                  new PropertyDouble(
                    name: 'Green variance',
                    digits: false,
                    value: _particleWorld.particleSystem.greenVar.toDouble(),
                    minValue: 0.0,
                    maxValue: 255.0,
                    onUpdated: (double value) {
                      setState(() {
                        _particleWorld.particleSystem.greenVar = value.toInt();
                      });
                    },
                  ),
                  new PropertyDouble(
                    name: 'Blue variance',
                    digits: false,
                    value: _particleWorld.particleSystem.blueVar.toDouble(),
                    minValue: 0.0,
                    maxValue: 255.0,
                    onUpdated: (double value) {
                      setState(() {
                        _particleWorld.particleSystem.blueVar = value.toInt();
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    return new MainEditorLayout(
      spriteDisplay: new ClipRect(
        child: new Container(
          color: _backgroundColor,
          key: _myKey,
          child: new Stack(
            children: <Widget>[
              new SpriteWidget(_particleWorld),
              new Positioned(
                right: 16.0,
                bottom: 16.0,
                child: new IconButton(
                  icon: new Icon(Icons.email),
                  color: Colors.white,
                  onPressed: () {
                    String body = Uri.encodeComponent(
                      json.encode(
                        serializeParticleSystem(_particleWorld.particleSystem)
                      )
                    );
                    launch('mailto:?subject=ParticleSystem&body=' + body);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      propertyEditor: propertyEditor,
    );
  }
}

UniqueKey _myKey = new UniqueKey();


class PropertyDouble extends StatelessWidget {
  final String name;
  final double value;
  final double minValue;
  final double maxValue;
  final PropertyDoubleCallback onUpdated;
  final bool digits;

  PropertyDouble({this.name, this.value, this.minValue, this.maxValue, this.onUpdated, this.digits=true});

  @override
  Widget build(BuildContext context) {
    return new Padding(
      padding: const EdgeInsets.all(0.0),
      child: new Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          new PropertyDescription(
            name: name,
            value: value.toStringAsFixed(digits ? 2 : 0),
          ),
          new Slider(
            value: value,
            onChanged: (double value) { onUpdated(value); },
            min: minValue,
            max: maxValue,
          ),
        ],
      ),
    );
  }
}

class PropertyBool extends StatelessWidget {
  final String name;
  final bool value;
  final PropertyBoolCallback onUpdated;

  PropertyBool({this.name, this.value, this.onUpdated});

  @override
  Widget build(BuildContext context) {
    return new Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: new Row(
        children: <Widget>[
          new Text(name),
          new Expanded(
            child: new Container(),
          ),
          new Checkbox(value: value, onChanged: onUpdated),
        ],
      ),
    );
  }
}

class PropertyBlendMode extends StatelessWidget {
  final String name;
  final BlendMode value;
  final PropertyBlendModeCallback onUpdated;

  PropertyBlendMode({this.name, this.value, this.onUpdated});

  @override
  Widget build(BuildContext context) {
    List<DropdownMenuItem<BlendMode>> items = <DropdownMenuItem<BlendMode>>[];
    for (BlendMode mode in BlendMode.values)
      items.add(_buildItem(mode));

    return new Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0),
      child: new Row(
        children: <Widget>[
          new Text(name),
          new Expanded(
            child: new Container(),
          ),
          new DropdownButton<BlendMode>(
            items: items,
            value: value,
            onChanged: onUpdated,
          ),
        ],
      ),
    );
  }

  DropdownMenuItem<BlendMode> _buildItem(BlendMode mode) {
    return new DropdownMenuItem<BlendMode>(
      child: new Text(mode.toString().substring(10, 11).toUpperCase() + mode.toString().substring(11)),
      value: mode,
    );
  }
}

class PropertyColor extends StatelessWidget {
  final String name;
  final Color value;
  final PropertyColorCallback onUpdated;

  PropertyColor({this.name, this.value, this.onUpdated});

  @override
  Widget build(BuildContext context) {
    return new Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0),
      child: new Row(
        children: <Widget>[
          new Text(name),
          new Expanded(
            child: new Container(),
          ),
          new Container(
            width: 50.0,
            height: 30.0,
            color: value,
            child: new GestureDetector(
              onTap: () {
                _openColorPickerDialog(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openColorPickerDialog(BuildContext context) {
    showDialog(
      context: context,
      child: new Builder(
        builder: (BuildContext context) {
          return new AlertDialog(
            title: const Text('Background color'),
            content: new SingleChildScrollView(
              child: new ColorPicker(
                pickerColor: value,
                onColorChanged: onUpdated,
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
        }
      )
    );
  }
}

class PropertyColorSequence extends StatefulWidget {
  final String name;
  final ColorSequence value;
  final PropertyColorSequenceCallback onUpdated;

  PropertyColorSequence({this.name, this.value, this.onUpdated});

  @override
  PropertyColorSequenceState createState() => new PropertyColorSequenceState();
}

class PropertyColorSequenceState extends State<PropertyColorSequence> {
  ColorSequence _newColorSequence;

  @override
  Widget build(BuildContext context) {
    return new Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0),
      child: new Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          new Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: new Text(widget.name),
          ),
          new ColorSequenceWell(
            colorSequence: widget.value,
            onTap: () {
              _openColorSequenceDesignerDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _openColorSequenceDesignerDialog(BuildContext context) {
    showDialog(
      context: context,
      child: new Builder(
        builder: (BuildContext context) {
          return new AlertDialog(
            title: const Text('Color sequence'),
            content: new SingleChildScrollView(
              child: new ColorSequenceDesigner(
                colorSequence: widget.value,
                onChanged: (ColorSequence cs) {
                  _newColorSequence = cs;
                },
              ),
            ),
            actions: <Widget>[
              new FlatButton(
                child: new Text('DONE'),
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onUpdated(_newColorSequence);
                },
              ),
            ],
          );
        }
      )
    );
  }
}

List<String> _textureNames = <String>[
  'Line',
  'Firework',
  'Star',
  'Circle',
  'Smoke',
  'Gradient Sphere',
];

class PropertyTexture extends StatelessWidget {
  final String name;
  final int value;
  final PropertyIntCallback onUpdated;

  PropertyTexture({this.name, this.value, this.onUpdated});

  @override
  Widget build(BuildContext context) {
    List<DropdownMenuItem<int>> items = <DropdownMenuItem<int>>[];
    for (int i = 0; i < _textureNames.length; i++)
      items.add(_buildItem(i));

    return new Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0),
      child: new Row(
        children: <Widget>[
          new Text(name),
          new Expanded(
            child: new Container(),
          ),
          new DropdownButton<int>(
            items: items,
            value: value,
            onChanged: onUpdated,
          ),
        ],
      ),
    );
  }

  DropdownMenuItem<int> _buildItem(int mode) {
    return new DropdownMenuItem<int>(
      child: new Text(_textureNames[mode]),
      value: mode,
    );
  }
}

class PropertyDescription extends StatelessWidget {
  final String name;
  final String value;

  PropertyDescription({this.name, this.value});

  @override
  Widget build(BuildContext context) {
    return new Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: new Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          new Text(name),
          new Expanded(
            child: new Container(),
          ),
          new Text(value),
        ],
      ),
    );
  }
}

class MainEditorLayout extends StatelessWidget {
  MainEditorLayout({this.spriteDisplay, this.propertyEditor});

  final Widget spriteDisplay;
  final Widget propertyEditor;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      return new Column(
        children: <Widget>[
          new AspectRatio(
            aspectRatio: 1.3,
            child: spriteDisplay,
          ),
          new Expanded(
            child: propertyEditor,
          ),
        ],
      );
    } else {
      return new Row(
        children: <Widget>[
          new AspectRatio(
            aspectRatio: 1.0,
            child: spriteDisplay,
          ),
          new Expanded(
            child: propertyEditor,
          ),
        ],
      );
    }
  }
}