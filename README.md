# SpriteWidget

SpriteWidget is a toolkit for building complex, high performance animations and 2D games with [Flutter](https://flutter.io). Your sprite render tree lives inside a widget that mixes seamlessly with other Flutter and Material widgets. You can use SpriteWidget to create anything from an animated icon to a full fledged game.

This guide assumes a basic knowledge of Flutter and Dart. Get support by posting a question tagged `spritewidget` on [StackOverflow](https://stackoverflow.com/).

You can find examples in the [examples](https://github.com/spritewidget/spritewidget/tree/master/examples) directory, or check out the complete [Space Blast](https://github.com/spritewidget/spaceblast) game.

![SpriteWidget](https://static1.squarespace.com/static/593b245d1e5b6ca18c9ffd52/t/5aa2b91324a6948406f5dee5/1520613684486/SpriteWidget?format=2500w)

## Adding SpriteWidget to your project
SpriteWidget is available as a standard package. Just add it as a dependency to your pubspec.yaml and you are good to go.

    dependencies:
      flutter:
        sdk: flutter
      spritewidget:

## Creating a SpriteWidget

The first thing you need to do to use SpriteWidget is to setup a root node that is used to draw it's contents. Any sprite nodes that you add to the root node will be rendered by the SpriteWidget. Typically, your root node is part of your app's state. This is an example of how you can setup a custom stateful widget with a SpriteWidget:

    import 'package:flutter/material.dart';
    import 'package:spritewidget/spritewidget.dart';

    class MyWidget extends StatefulWidget {
      @override
      MyWidgetState createState() => new MyWidgetState();
    }

    class MyWidgetState extends State<MyWidget> {
      NodeWithSize rootNode;

      @override
      void initState() {
        super.initState();
        rootNode = new NodeWithSize(const Size(1024.0, 1024.0));
      }

      @override
      Widget build(BuildContext context) {
      	return new SpriteWidget(rootNode);
      }
    }

The root node that you provide the SpriteWidget is a NodeWithSize, the size of the root node defines the coordinate system used by the SpriteWidget. By default the SpriteWidget uses letterboxing to display its contents. This means that the size that you give the root node will determine how the SpriteWidget's contents will be scaled to fit. If it doesn't fit perfectly in the area of the widget, either its top and bottom or the left and right side will be trimmed. You can optionally pass in a parameter to the SpriteWidget for other scaling options depending on your needs.

When you have added the SpriteWidget to your app's build method it will automatically start running animations and handling user input. There is no need for any other extra setup.

## Adding objects to your node graph

Your SpriteWidget manages a node graph, the root node is the NodeWithSize that is passed in to the SpriteWidget when it's created. To render sprites, particles systems, or any other objects simply add them to the node graph.

Each node in the node graph has a transform. The transform is inherited by its children, this makes it possible to build more complex structures by grouping objects together as children to a node and then manipulating the parent node. For example the following code creates a car sprite with two wheels attached to it. The car is added to the root node.

    Sprite car = new Sprite.fromImage(carImage);
    Sprite frontWheel = new Sprite.fromImage(wheelImage);
    Sprite rearWheel = new Sprite.fromImage(wheelImage);

    frontWheel.position = const Offset(100, 50);
    rearWheel.position = const Offset(-100, 50);

    car.addChild(frontWheel);
    car.addChild(rearWheel);

    rootNode.addChild(car);

You can manipulate the transform by setting the position, rotation, scale, and skew properties.

## Sprites, textures, and sprite sheets

To load image resources, the easiest way is to use the `ImageMap` class. The `ImageMap` can load one or multiple images at once.

The `Image` class isn't automatically imported through flutter/material, so you may need to add an import at the top of your file.

    import 'dart:ui' as ui show Image;

 Now you can load images using the `ImageMap`. Note that the loading methods are asynchronous, so this example code will need to go in an asynch method. For a full example of loading images see the [Weather Demo](https://github.com/spritewidget/spritewidget/tree/master/examples/weather).

    ImageMap images = new ImageMap(rootBundle);

    // Load a single image
    ui.Image image = await images.loadImage('assets/my_image.png');

    // Load multiple images
    await images.load(<String>[
      'assets/image_0.png',
      'assets/image_1.png',
      'assets/image_2.png',
    ]);

    // Access a loaded image from the ImageMap
    image = images['assets/image_0.png'];

The most common node type is the Sprite node. A sprite simply draws an image to the screen. Sprites can be drawn from Image objects or SpriteTexture objects. A texture is a part of an Image. Using a SpriteSheet you can pack several texture elements within a single image. This saves space in the device's gpu memory and also make drawing faster. Currently SpriteWidget supports sprite sheets in json format and produced with a tool such as TexturePacker. It's uncommon to manually edit the sprite sheet files. You can create a SpriteSheet with a definition in json and an image:

    SpriteSheet sprites = new SpriteSheet(myImage, jsonCode);
    SpriteTexture texture = sprites['texture.png'];

## The frame cycle

Each time a new frame is rendered to screen SpriteWidget will perform a number of actions. Sometimes when creating more advanced interactive animations or games, the order in which these actions are performed may matter.

This is the order things will happen:

1. Handle input events
2. Run animation motions
3. Call update functions on nodes
4. Apply constraints
5. Render the frame to screen

Read more about each of the different phases below.

## Handling user input

You can subclass any node type to handle touches. To receive touches, you need to set the userInteractionEnabled property to true and override the handleEvent method. If the node you are subclassing doesn't have a size, you will also need to override the isPointInside method.

    class EventHandlingNode extends NodeWithSize {
      EventHandlingNode(Size size) : super(size) {
        userInteractionEnabled = true;
      }

      @override handleEvent(SpriteBoxEvent event) {
        if (event.type == PointerDownEvent)
          ...
        else if (event.type == PointerMoveEvent)
          ...

        return true;
      }
    }

If you want your node to receive multiple touches, set the handleMultiplePointers property to true. Each touch down or dragged touch will generate a separate call to the handleEvent method, you can distinguish each touch by its pointer property.

## Animating using motions

SpriteWidget provides easy to use functions for animating nodes through motions. You can combine simple motion blocks to create more complex animations.

To execute a motion animation you first build the motion itself, then pass it to the run method of a nodes motion manager (see the Tweens section below for an example).

### Tweens

Tweens are the simplest building block for creating an animation. It will interpolate a value or property over a specified time period. You provide the MotionTween class with a setter function, its start and end value, and the duration for the tween.

After creating a tween, execute it by running it through a node's motion manager.

	Node myNode = new Node();

    MotionTween myTween = new MotionTween<Offset> (
      (a) => myNode.position = a,
      Offset.zero,
      const Offset(100.0, 0.0),
      1.0
    );

    myNode.motions.run(myTween);

You can animate values of different types, such as floats, points, rectangles, and even colors. You can also optionally provide the MotionTween class with an easing function.

### Sequences

When you need to play two or more motions in a sequence, use the MotionSequence class:

    MotionSequence sequence = new MotionSequence([
      firstMotion,
      middleMotion,
      lastMotion
    ]);

### Groups

Use MotionGroup to play motions in parallel:

    MotionGroup group = new MotionGroup([
      motion0,
      motion1
    ]);

### Repeat

You can loop any motion, either a fixed number of times, or until the end of times:

    MotionRepeat repeat = new MotionRepeat(loopedMotion, 5);

    MotionRepeatForever longLoop = new MotionRepeatForever(loopedMotion);

### Composition

It's possible to create more complex motions by composing them in any way:

    MotionSequence complexMotion = new MotionSequence([
      new MotionRepeat(myLoop, 2),
      new MotionGroup([
      	motion0,
      	motion1
      ])
    ]);

## Handle update events

Each frame, update events are sent to each node in the current node tree. Override the update method to manually do animations or to perform game logic.

    MyNode extends Node {
      @override
      update(double dt) {
        // Move the node at a constant speed
      	position += new Offset(dt * 1.0, 0.0);
      }
    }

## Defining constraints

Constraints are used to constrain properties of nodes. They can be used to position nodes relative other nodes, or adjust the rotation or scale. You can apply more than one constraint to a single node.

For example, you can use a constraint to make a node follow another node at a specific distance with a specified dampening. The dampening will smoothen out the following node's movement.

    followingNode.constraints = [
      new ConstraintPositionToNode(
        targetNode,
        offset: const Offset(0.0, 100.0),
        dampening: 0.5
      )
    ];

Constraints are applied at the end of the frame cycle. If you need them to be applied at any other time, you can directly call the applyConstraints method of a Node object.

## Perform custom drawing

SpriteWidget provides a default set of drawing primitives, but there are cases where you may want to perform custom drawing. To do this you will need to subclass either the Node or NodeWithSize class and override the paint method:

    class RedCircle extends Node {
      RedCircle(this.radius);

      double radius;

      @override
      void paint(Canvas canvas) {
        canvas.drawCircle(
          Offset.zero,
          radius,
          new Paint()..color = const Color(0xffff0000)
        );
      }
    }

If you are overriding a NodeWithSize you may want to call applyTransformForPivot before starting drawing to account for the node's pivot point. After the call the coordinate system is setup so you can perform drawing starting at origo to the size of the node.

    @override
    void paint(Canvas canvas) {
      applyTransformForPivot(canvas);

      canvas.drawRect(
        new Rect.fromLTWH(0.0, 0.0, size.width, size.height),
        myPaint
      );
    }

## Add effects using particle systems

Particle systems are great for creating effects such as rain, smoke, or fire. It's easy to setup a particle system, but there are very many properties that can be tweaked. The best way of to get a feel for how they work is to simply play around with the them.

This is an example of how a particle system can be created, configured, and added to the scene:

    ParticleSystem particles = new ParticleSystem(
      particleTexture,
      posVar: const Point(100, 100.0),
      startSize: 1.0,
      startSizeVar: 0.5,
      endSize: 2.0,
      endSizeVar: 1.0,
      life: 1.5 * distance,
      lifeVar: 1.0 * distance
    );

    rootNode.addChild(particles);
