# Autoref

## Compilation
Follow the instructions in [COMPILE.md](COMPILE.md). Building the framework
separately is **not** neccesary!

## Usage
In order to use the Autoref, run the previously built `autoref`.

The program receives the Protobuf data via network from SSL-Vision and the
Refbox.

Referee decisions will be printed on the log textbox below the playing field.

In case you see "Autoref disabled" inside the green box, you probably moved the
autorefs directory after building. You then have to select the file
`"autoref/init.lua"` manually.


## Features
The autoref detects the following rule infractions:

- Collisions between robots
- Shooting faster than 8 m/s
- Multiple defenders
- Ball out of field

## Implementation/Testing
Game rules are implemented as Lua scripts and live in the 'autoref' directory.
If you want to test them with a simulated game, you can use the [framework][1]
and load `autoref/init.lua` as a yellow strategy.


Feedback regarding the implementation of rules is highly welcome, especially
in the form of pull requests!


## Advanced usage

### Plotter
The Plotter can be started by clicking its button in the top bar.
It is particularly handy for observing the ball speed over time, but can be used
to display all kind of information which is provided by the Tracking.

### Script entrypoints
The buttons in the green (or red, when crashing) box are responsible for
selecting a strategy script. In the main [framework][1], it is used to select
game strategies which control robots. The Autoref has only one entrypoint (main).
It is however possible to define further entrypoints that can be used to test
only a certain behavior etc. The reload button on the right can be used to
restart the AI. The autoref will reload automatically if it crashes.

### Visualizations
In order to highlight certain points of interest on the field, you can define
visualizations in the referee scripts by using the module in `base/vis.lua`.
One example can be found in the function `Referee.illustrateRefereeStates`
inside `base/referee.lua`.
You can toggle them in the Visualizations-widget.

### User interface
You can rotate and flip the field by right-clicking into it and select the
appropriate action.

### Log recorder
You can record games with the red button in the top bar.
Log files will be saved in the directory from where the Autoref was started.
These can be played with the logplayer, which is part of the [framework][1].

[1]: https://github.com/robotics-erlangen/framework
