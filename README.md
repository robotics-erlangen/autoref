# Autoref
## Checkout code
Initialize the git submodules using
> ```
> git submodule init
> git submodule update --recursive
> ```

## Compilation
Follow the instructions in [COMPILE.md](COMPILE.md). Building the framework
separately is **not** neccesary!

## Usage
In order to use the Autoref run Autoref and click on one of the buttons in the
"Autoref" subwindow to load an AI. Select the file `"autoref/init.lua"`. If it
is loaded successfully the AI button will change its text to "Autoref" and two
new buttons will appear. The first of them will display "main". This is the
only entrypoint of the Autoref. It is however possible to define further
entrypoints that can be used to test only a certain behavior etc. The reload
button on the right can be used to restart the AI. The autoref will reload
automatically if it crashes.

Voila the Autoref will print its decisions on the log textbox below the
playing field.

## Features
The autoref detects the following rule infractions:
* Collisions between robots
* Shooting faster than 8 m/s
* Multiple defenders
* Ball out of field
