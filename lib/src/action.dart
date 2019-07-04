// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of spritewidget;

/// Signature for callbacks used by the [ActionCallFunction].
typedef void ActionCallback();

/// Actions are used to animate properties of nodes or any other type of
/// objects. The actions are powered by an [ActionController], typically
/// associated with a [Node]. The most commonly used action is the
/// [ActionTween] which interpolates a property between two values over time.
///
/// Actions can be nested in different ways; played in sequence using the
/// [ActionSequence], or looped using the [ActionRepeat].
///
/// You should typically not override this class directly, instead override
/// [ActionInterval] or [ActionInstant] if you need to create a new action
/// class.
abstract class Action {
  Object _tag;
  bool _finished = false;
  bool _added = false;

  /// Moves to the next time step in an action, [dt] is the delta time since
  /// the last time step in seconds. Typically this method is called from the
  /// [ActionController].
  void step(double dt);

  /// Sets the action to a specific point in time. The [t] value that is passed
  /// in is a normalized value 0.0 to 1.0 of the duration of the action. Every
  /// action will always recieve a callback with the end time point (1.0),
  /// unless it is cancelled.
  void update(double t) {
  }

  void _reset() {
    _finished = false;
  }

  /// The total time it will take to complete the action, in seconds.
  double get duration => 0.0;
}

/// Signature for callbacks for setting properties, used by [ActionTween].
typedef void SetterCallback(dynamic value);

/// The abstract class for an action that changes properties over a time
/// interval, optionally using an easing curve.
abstract class ActionInterval extends Action {

  /// Creates a new ActionInterval, typically you will want to pass in a
  /// [duration] to specify how long time the action will take to complete.
  ActionInterval([this._duration = 0.0, this.curve]);

  @override
  double get duration => _duration;
  double _duration;

  /// The animation curve used to ease the animation.
  ///
  ///     myAction.curve = bounceOut;
  Curve curve;

  bool _firstTick = true;
  double _elapsed = 0.0;

  @override
  void step(double dt) {
    if (_firstTick) {
      _firstTick = false;
    } else {
      _elapsed += dt;
    }

    double t;
    if (this._duration == 0.0) {
      t = 1.0;
    } else {
      t = (_elapsed / _duration).clamp(0.0, 1.0);
    }

    if (curve == null) {
      update(t);
    } else {
      update(curve.transform(t));
    }

    if (t >= 1.0) _finished = true;
  }
}

/// An action that repeats another action a fixed number of times.
class ActionRepeat extends ActionInterval {

  /// The number of times the [action] is repeated.
  final int numRepeats;

  /// The action that is repeated.
  final ActionInterval action;
  int _lastFinishedRepeat = -1;

  /// Creates a new action that is repeats the passed in action a fixed number
  /// of times.
  ///
  ///     var myLoop = new ActionRepeat(myAction);
  ActionRepeat(this.action, this.numRepeats) {
    _duration = action.duration * numRepeats;
  }

  @override
  void update(double t) {
    int currentRepeat = math.min((t * numRepeats.toDouble()).toInt(), numRepeats - 1);
    for (int i = math.max(_lastFinishedRepeat, 0); i < currentRepeat; i++) {
      if (!action._finished) action.update(1.0);
      action._reset();
    }
    _lastFinishedRepeat = currentRepeat;

    double ta = (t * numRepeats.toDouble()) % 1.0;
    action.update(ta);

    if (t >= 1.0) {
      action.update(1.0);
      action._finished = true;
    }
  }
}

/// An action that repeats an action an indefinite number of times.
class ActionRepeatForever extends Action {

  /// The action that is repeated indefinitely.
  final ActionInterval action;
  double _elapsedInAction = 0.0;

  /// Creates a new action with the action that is passed in.
  ///
  ///     var myInifiniteLoop = new ActionRepeatForever(myAction);
  ActionRepeatForever(this.action);

  @override
  void step(double dt) {
    _elapsedInAction += dt;
    while (_elapsedInAction > action.duration) {
      _elapsedInAction -= action.duration;
      if (!action._finished) action.update(1.0);
      action._reset();
    }
    _elapsedInAction = math.max(_elapsedInAction, 0.0);

    double t;
    if (action._duration == 0.0) {
      t = 1.0;
    } else {
      t = (_elapsedInAction / action._duration).clamp(0.0, 1.0);
    }

    action.update(t);
  }
}

/// An action that plays a number of supplied actions in sequence. The duration
/// of the [ActionSequence] with be the sum of the durations of the actions
/// passed in to the constructor.
class ActionSequence extends ActionInterval {
  Action _a;
  Action _b;
  double _split;

  /// Creates a new action with the list of actions passed in.
  ///
  ///     var mySequence = new ActionSequence([myAction0, myAction1, myAction2]);
  ActionSequence(List<Action> actions) {
    assert(actions.length >= 2);

    if (actions.length == 2) {
      // Base case
      _a = actions[0];
      _b = actions[1];
    } else {
      _a = actions[0];
      _b = new ActionSequence(actions.sublist(1));
    }

    // Calculate split and duration
    _duration = _a.duration + _b.duration;
    if (_duration > 0) {
      _split = _a.duration / _duration;
    } else {
      _split = 1.0;
    }
  }

  @override
  void update(double t) {
    if (t < _split) {
      // Play first action
      double ta;
      if (_split > 0.0) {
        ta = (t / _split).clamp(0.0, 1.0);
      } else {
        ta = 1.0;
      }
      _updateWithCurve(_a, ta);
    } else if (t >= 1.0) {
      // Make sure everything is finished
      if (!_a._finished) _finish(_a);
      if (!_b._finished) _finish(_b);
    } else {
      // Play second action, but first make sure the first has finished
      if (!_a._finished) _finish(_a);
      double tb;
      if (_split < 1.0) {
        tb = (1.0 - (1.0 - t) / (1.0 - _split)).clamp(0.0, 1.0);
      } else {
        tb = 1.0;
      }
      _updateWithCurve(_b, tb);
    }
  }

  void _updateWithCurve(Action action, double t) {
    if (action is ActionInterval) {
      ActionInterval actionInterval = action;
      if (actionInterval.curve == null) {
        action.update(t);
      } else {
        action.update(actionInterval.curve.transform(t));
      }
    } else {
      action.update(t);
    }

    if (t >= 1.0) {
      action._finished = true;
    }
  }

  void _finish(Action action) {
    action.update(1.0);
    action._finished = true;
  }

  @override
  void _reset() {
    super._reset();
    _a._reset();
    _b._reset();
  }
}

/// An action that plays the supplied actions in parallell. The duration of the
/// [ActionGroup] will be the maximum of the durations of the actions used to
/// compose this action.
class ActionGroup extends ActionInterval {
  List<Action> _actions;

  /// Creates a new action with the list of actions passed in.
  ///
  ///     var myGroup = new ActionGroup([myAction0, myAction1, myAction2]);
  ActionGroup(this._actions) {
    for (Action action in _actions) {
      if (action.duration > _duration) {
        _duration = action.duration;
      }
    }
  }

  @override
  void update(double t) {
    if (t >= 1.0) {
      // Finish all unfinished actions
      for (Action action in _actions) {
        if (!action._finished) {
          action.update(1.0);
          action._finished = true;
        }
      }
    } else {
      for (Action action in _actions) {
        if (action.duration == 0.0) {
          // Fire all instant actions immediately
          if (!action._finished) {
            action.update(1.0);
            action._finished = true;
          }
        } else {
          // Update child actions
          double ta = (t / (action.duration / duration)).clamp(0.0, 1.0);
          if (ta < 1.0) {
            if (action is ActionInterval) {
              ActionInterval actionInterval = action;
              if (actionInterval.curve == null) {
                action.update(ta);
              } else {
                action.update(actionInterval.curve.transform(ta));
              }
            } else {
              action.update(ta);
            }
          } else if (!action._finished){
            action.update(1.0);
            action._finished = true;
          }
        }
      }
    }
  }

  @override
  void _reset() {
    for (Action action in _actions) {
      action._reset();
    }
  }
}

/// An action that doesn't perform any other task than taking time. This action
/// is typically used in a sequence to space out other events.
class ActionDelay extends ActionInterval {
  /// Creates a new action with the specified [delay]
  ActionDelay(double delay) : super(delay);
}

/// An action that doesn't have a duration. If this class is overridden to
/// create custom instant actions, only the [fire] method should be overriden.
abstract class ActionInstant extends Action {

  @override
  void step(double dt) {
  }

  @override
  void update(double t) {
    fire();
    _finished = true;
  }

  /// Called when the action is executed. If you are implementing your own
  /// ActionInstant, override this method.
  void fire();
}

/// An action that calls a custom function when it is fired.
class ActionCallFunction extends ActionInstant {
  ActionCallback _function;

  /// Creates a new callback action with the supplied callback.
  ///
  ///     var myAction = new ActionCallFunction(() { print("Hello!";) });
  ActionCallFunction(this._function);

  @override
  void fire() {
    _function();
  }
}

/// An action that removes the supplied node from its parent when it's fired.
class ActionRemoveNode extends ActionInstant {
  Node _node;

  /// Creates a new action with the node to remove as its argument.
  ///
  ///     var myAction = new ActionRemoveNode(myNode);
  ActionRemoveNode(this._node);

  @override
  void fire() {
    _node.removeFromParent();
  }
}

/// An action that tweens a property between two values, optionally using an
/// animation curve. This is one of the most common building blocks when
/// creating actions. The tween class can be used to animate properties of the
/// type [Point], [Size], [Rect], [double], or [Color].
class ActionTween<T> extends ActionInterval {

  /// Creates a new tween action. The [setter] will be called to update the
  /// animated property from [startVal] to [endVal] over the [duration] time in
  /// seconds. Optionally an animation [curve] can be passed in for easing the
  /// animation.
  ///
  ///     // Animate myNode from its current position to 100.0, 100.0 during
  ///     // 1.0 second and a bounceOut easing
  ///     var myTween = new ActionTween(
  ///       (a) => myNode.position = a,
  ///       myNode.position,
  ///       new Point(100.0, 100.0,
  ///       1.0,
  ///       bounceOut
  ///     );
  ///     myNode.actions.run(myTween);
  ActionTween(this.setter, this.startVal, this.endVal, double duration, [Curve curve]) : super(duration, curve) {
    _computeDelta();
  }

  /// The setter method used to set the property being animated.
  final SetterCallback setter;

  /// The start value of the animation.
  final T startVal;

  /// The end value of the animation.
  final T endVal;

  dynamic _delta;

  void _computeDelta() {
    if (startVal is Offset) {
      // Point
      double xStart = (startVal as Offset).dx;
      double yStart = (startVal as Offset).dy;
      double xEnd = (endVal as Offset).dx;
      double yEnd = (endVal as Offset).dy;
      _delta = new Offset(xEnd - xStart, yEnd - yStart);
    } else if (startVal is Size) {
      // Size
      double wStart = (startVal as Size).width;
      double hStart = (startVal as Size).height;
      double wEnd = (endVal as Size).width;
      double hEnd = (endVal as Size).height;
      _delta = new Size(wEnd - wStart, hEnd - hStart);
    } else if (startVal is Rect) {
      // Rect
      double lStart = (startVal as Rect).left;
      double tStart = (startVal as Rect).top;
      double rStart = (startVal as Rect).right;
      double bStart = (startVal as Rect).bottom;
      double lEnd = (endVal as Rect).left;
      double tEnd = (endVal as Rect).top;
      double rEnd = (endVal as Rect).right;
      double bEnd = (endVal as Rect).bottom;
      _delta = new Rect.fromLTRB(lEnd - lStart, tEnd - tStart, rEnd - rStart, bEnd - bStart);
    } else if (startVal is double) {
      // Double
      _delta = (endVal as double) - (startVal as double);
    } else if (startVal is Color) {
      // Color
      int aDelta = (endVal as Color).alpha - (startVal as Color).alpha;
      int rDelta = (endVal as Color).red - (startVal as Color).red;
      int gDelta = (endVal as Color).green - (startVal as Color).green;
      int bDelta = (endVal as Color).blue - (startVal as Color).blue;
      _delta = new _ColorDiff(aDelta, rDelta, gDelta, bDelta);
    } else {
      assert(false);
    }
  }

  @override
  void update(double t) {
    dynamic newVal;

    if (startVal is Offset) {
      // Point
      double xStart = (startVal as Offset).dx;
      double yStart = (startVal as Offset).dy;
      double xDelta = _delta.dx;
      double yDelta = _delta.dy;
      newVal = new Offset(xStart + xDelta * t, yStart + yDelta * t);
    } else if (startVal is Size) {
      // Size
      double wStart = (startVal as Size).width;
      double hStart = (startVal as Size).height;
      double wDelta = _delta.width;
      double hDelta = _delta.height;
      newVal = new Size(wStart + wDelta * t, hStart + hDelta * t);
    } else if (startVal is Rect) {
      // Rect
      double lStart = (startVal as Rect).left;
      double tStart = (startVal as Rect).top;
      double rStart = (startVal as Rect).right;
      double bStart = (startVal as Rect).bottom;
      double lDelta = _delta.left;
      double tDelta = _delta.top;
      double rDelta = _delta.right;
      double bDelta = _delta.bottom;
      newVal = new Rect.fromLTRB(lStart + lDelta * t, tStart + tDelta * t, rStart + rDelta * t, bStart + bDelta * t);
    } else if (startVal is double) {
      // Doubles
      newVal = (startVal as double) + _delta * t;
    } else if (startVal is Color) {
      // Colors
      int aNew = ((startVal as Color).alpha + (_delta.alpha * t).toInt()).clamp(0, 255);
      int rNew = ((startVal as Color).red + (_delta.red * t).toInt()).clamp(0, 255);
      int gNew = ((startVal as Color).green + (_delta.green * t).toInt()).clamp(0, 255);
      int bNew = ((startVal as Color).blue + (_delta.blue * t).toInt()).clamp(0, 255);
      newVal = new Color.fromARGB(aNew, rNew, gNew, bNew);
    } else {
      // Oopses
      assert(false);
    }

    setter(newVal);
  }
}

/// A class the controls the playback of actions. To play back an action it is
/// passed to the [ActionController]'s [run] method. The [ActionController]
/// itself is typically a property of a [Node] and powered by the [SpriteBox].
class ActionController {

  bool _paused = false;
  List<Action> _actions = <Action>[];

  /// Creates a new [ActionController]. However, for most uses a reference to
  /// an [ActionController] is acquired through the [Node.actions] property.
  ActionController();

  /// Runs an [action], can optionally be passed a [tag]. The [tag] can be used
  /// to reference the action or a set of actions with the same tag.
  ///
  ///     myNode.actions.run(myAction, "myActionGroup");
  void run(Action action, [Object tag]) {
    assert(!action._added);

    action._tag = tag;
    action._added = true;
    action.update(0.0);
    _actions.add(action);
  }

  /// Stops an [action] and removes it from the controller.
  ///
  ///     myNode.actions.stop(myAction);
  void stop(Action action) {
    if (_actions.remove(action)) {
      action._added = false;
      action._reset();
    }
  }

  void _stopAtIndex(int i) {
    Action action = _actions[i];
    action._added = false;
    action._reset();
    _actions.removeAt(i);
  }

  /// Stops all actions with the specified tag and removes them from the
  /// controller.
  ///
  ///     myNode.actions.stopWithTag("myActionGroup");
  void stopWithTag(Object tag) {
    for (int i = _actions.length - 1; i >= 0; i--) {
      Action action = _actions[i];
      if (action._tag == tag) {
        _stopAtIndex(i);
      }
    }
  }

  /// Stops all actions currently being run by the controller and removes them.
  ///
  ///     myNode.actions.stopAll();
  void stopAll() {
    for (int i = _actions.length - 1; i >= 0; i--) {
      _stopAtIndex(i);
    }
  }

  /// Pause actions currently being run by the controller
  ///
  ///     myNode.actions.pause();
  void pause() {
    _paused = true;
  }

  /// Unpause actions being run by the controller
  ///
  ///     myNode.actions.unpause();
  void unpause() {
    _paused = false;
  }

  /// Steps the action forward by the specified time, typically there is no need
  /// to directly call this method.
  void step(double dt) {
    if (_paused)
      return;

    for (int i = _actions.length - 1; i >= 0; i--) {
      Action action = _actions[i];
      action.step(dt);

      if (action._finished) {
        action._added = false;
        _actions.removeAt(i);
      }
    }
  }
}

class _ColorDiff {
  final int alpha;
  final int red;
  final int green;
  final int blue;

  _ColorDiff(this.alpha, this.red, this.green, this.blue);
}
