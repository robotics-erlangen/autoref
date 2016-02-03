# Autoref

## Compilation
Follow the instructions in [COMPILE.md](COMPILE.md). Building the framework
separately is **not** neccesary!

## Usage
In order to use the Autoref, run the previously built `autoref`.

The program receives the Protobuf data via network from SSL-Vision and the
Refbox.

Referee decisions will be printed on the log textbox next to the playing field.
The Autoref connects to a refbox[4] running on the same machine and tries
to use it in order to send referee commands to the game.
You can disable refbox remote control in the "Configuration" menu.

In case you do not see a "Successfully loaded" message in the lower left box,
you probably moved the autorefs directory after building.


## Features
Currently, the Autoref detects the ball going out of play and is able to
autonomously stop the game, conduct ball placement and send free kick commands
via the refbox.

Handling of the following rule infractions is planned:
- Collisions between robots
- Shooting faster than 8 m/s
- Multiple defenders/attackers in defense area
- Double touch after free kicks
- Icing
- Correct number of players on the field
- Correct behavior of players during Stop and penalties

## Implementation/Testing
Game rules are implemented as Lua scripts and live in the 'autoref' directory.
If you want to test them with a simulated game, you can use the [framework][1]
and load `autoref/init.lua` as a yellow strategy.

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

[1]: https://github.com/robotics-erlangen/framework
[2]: https://github.com/michael-bleier/ssl-logtools
[3]: https://www.robotics-erlangen.de//gamelogs/robocup2013/2013-06-30-130702_cmdragons_zjunlict.log.gz
[4]: https://github.com/RoboCup-SSL/ssl-refbox
