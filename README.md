# Autoref

## Compilation
Follow the instructions in [COMPILE.md](COMPILE.md). Building the framework
separately is **not** neccesary!

## Usage
In order to use the Autoref, run the previously built `autoref`.

The program receives the Protobuf data via network from SSL-Vision and the
Refbox.

Referee decisions will be printed on the log textbox next to the playing field.
The Autoref connects to a [refbox][4] running on the same machine and tries
to use it in order to send referee commands to the game.
You can disable refbox remote control in the "Configuration" menu.

In case you do not see a "Successfully loaded" message in the lower left box,
you probably moved the autorefs directory after building.


## Features
Currently, the Autoref detects the ball going out of play and fast shots. It is
able to autonomously stop the game, conduct ball placement and send free kick
commands via the refbox.

Handling of the following rule infractions is planned:
- Collisions between robots
- Multiple defenders/attackers in defense area
- Double touch after free kicks
- Icing
- Correct number of players on the field
- Correct behavior of players during Stop and penalties

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

### Implementing rules
Rules are implemented as lua tables. Each of them is located in a distinct file
inside the `autoref` folder. They have then to be included in `init.lua`.
A rule must define the following attributes:
- `possibleRefStates`: A table which indicates the referee states in which this
foul can occur
- `occuring`: A function which either returns true or false. true means that
the foul occurs and that all of the following attributes have to be set
- `print`: This function prints a message for the user in case the foul occurs,
but should not implement any other referee logics
- `executingTeam`: This should either be World.YellowColorStr or World.BlueColorStr
- `consequence`: The referee command which follows the foul, e.g. "INDIRECT_FREE_BLUE"
- `freekickPosition`: A vector with the position where the resulting free kick
will be executed. This field is used for autonomous ball placement

[1]: https://github.com/robotics-erlangen/framework
[2]: https://github.com/michael-bleier/ssl-logtools
[3]: https://www.robotics-erlangen.de//gamelogs/robocup2013/2013-06-30-130702_cmdragons_zjunlict.log.gz
[4]: https://github.com/RoboCup-SSL/ssl-refbox
