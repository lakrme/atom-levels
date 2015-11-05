## 0.1.0 (2015-09-29)
* First release

## 0.2.0 (2015-10-15)
* Execution can now be stopped on all platforms

## 0.3.0 (2015-11-01)
* The Levels package now provides an API for other packages (for now the language registry is available to enable the embedding of language packages)
* Languages are now installable as Atom packages (see the [Levels language package template](https://github.com/lakrme/atom-levels-language-template))
* Fast execution output from spawned child processes no longer freezes Atom
* Added some documentation
* General bug fixing and other adjustments

## 0.3.1 (2015-11-01)
* Fixed a bug that made it impossible for language packages to consume the Levels package

## 0.3.2 (2015-11-01)
* Fixed a bug that caused warning/error parsing to fail on Windows

## 0.4.0 (2015-11-03)
* Running a program now automatically saves the buffer (or opens the save dialog if the buffer has not yet been saved)
* The terminal now is styled (colored) based on the UI theme
* The maximum terminal font size has been increased
* Annotation overlays now dynamically resize when changing the text editor's font size or width

## 0.4.1 (2015-11-03)
* Fixed a bug that caused annotation overlays to be too small for short warning/error messages

## 0.4.2 (2015-11-05)
* Fixed a bug that caused the terminal cursor to have a incorrect position when changing the font size after clearing the terminal
