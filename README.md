# Autoref
The framework [Ra](https://github.com/robotics-erlangen/framework) is required
for running the autoref.

In order to use the Autoref run Ra and click on one of the buttons in the "Robots"
subwindow to load an AI for the blue or yellow team. Select the file
`"autoref/init.lua"`. If it is loaded successfully the AI button will
change its text to "Autoref" and two new buttons will appear. The first of
them will display "main". This is the only entrypoint of the Autoref. It is
however possible to define further entrypoints that can be used to test only a
certain behavior etc. The reload button on the right can be used to restart
the AI. While Ra is in competition mode, that is an external RefBox is used,
the AI will reload automatically if it crashes.

Then head down to the actual robot list and click on the circle left to
"Generation 2012" or "Generation 2014" and choose yellow or blue depending on
for which team the Autoref was loaded. It is also possible to assign
individual robots of that generation to the opposite or no team at all.

Assign the other Generation to the other team. Ensure that the simulator and
internal referee are disabled (the buttons shouldn't be highlighted or take a
look at the "Demo" menu).

Voila the Autoref will print its decisions on the log textbox below the
playing field.

The autoref detects the following rule infractions:
* Collisions between robots
* Shooting faster than 8 m/s
* Multiple defenders
* Ball out of field
