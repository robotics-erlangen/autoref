# Autoref

## Compilation
Follow the instructions in [COMPILE.md](COMPILE.md). Building the framework
separately is **not** neccesary!

## Usage
In order to use the Autoref, run the previously built binary `autoref`.

The program receives the Protobuf data via network from SSL-Vision and the
Refbox.

Referee decisions will be printed on the log textbox next to the playing field.
The Autoref connects to a [refbox][4] running on the same machine and tries
to use it in order to send referee commands to the game.
You can disable refbox remote control in the "Configuration" menu.

In case you do not see a "Successfully loaded" message in the lower left box,
you probably moved the autorefs directory after building.


## Features
Currently, the Autoref detects a number of fouls according to the
[Technical Challgenge 2016][5]. It is able to autonomously stop the game,
conduct ball placement and send free kick commands via the refbox.

The next step should be to exhaustively categorize the rules into infringements
which can either be:
- currently detected by Autoref
- detectable but not yet implemented
- hard to detect/decide upon by a machine
- not detectable with the available data sources

## Implementation/Testing
Game rules are implemented as Lua scripts and live in the 'autoref' directory.
For details see below. If you want to test them with a simulated game, you can
use the [framework][1] and load `autoref/init.lua` as a yellow strategy.

Another possibility to test the Autoref without an actual field is to use
Michael Bleier's [logplayer][2] with a [recorded game][3]. Make sure to
configure the vision port to 10002.

Feedback regarding the implementation of rules is highly welcome, especially
in the form of pull requests!


## Advanced usage

### User interface
You can rotate and flip the field by right-clicking into it and select the
appropriate action.

### Log recorder
You can record games via the "Logging" menu or by pressing Ctrl-R.
Log files will be saved in the directory from where the Autoref was started.
These can be played with the logplayer, which is part of the [framework][1].

### Ball speed plotter
If you experience GUI freezes, try to enable "Plotter in extra window" in the
configuration menu. This needs an application restart to take effect.

### Implementing rules
Rules are implemented as lua tables. Each of them is located in a distinct file
inside the `autoref` folder. They have then to be included in `init.lua`.
A rule must define the following attributes:
- `possibleRefStates`: A table which indicates the referee states in which this
foul can occur
- `occuring`: A function which either returns true or false. true means that
the foul occurs and that the `print` and `consequence` attributes have to be set
- `message`: Describes the foul and possibly involved robots
- `consequence`: The referee command which follows the foul, e.g. "INDIRECT_FREE_BLUE".
If it is not "STOP" or a card, `freekickPosition` has to be set
- `freekickPosition`: A vector with the position where the resulting free kick
will be executed. This field is used for autonomous ball placement
- `executingTeam`: This should either be World.YellowColorStr or World.BlueColorStr
It has to be set whenever `freekickPosition` is set


[1]: https://github.com/robotics-erlangen/framework
[2]: https://github.com/michael-bleier/ssl-logtools
[3]: https://www.robotics-erlangen.de//gamelogs/robocup2013/2013-06-30-130702_cmdragons_zjunlict.log.gz
[4]: https://github.com/RoboCup-SSL/ssl-refbox
[5]: http://wiki.robocup.org/wiki/Small_Size_League/RoboCup_2016/Autoref_Challenge
