## 0.6.0 (xxxx-xx-xx)

* Removed the `atom-space-pen-views` dependency
* Removed the soon to be deprecated and undocumented Atom function `::showSaveDialogSync`
* Converted all CoffeeScript files to JavaScript
* Disabled the level select view when executing
* Improved handling of typed messages
* Added `run` command to start execution
* Added description for available commands to the help message
* Added terminal welcome description on how to start and stop execution
* Added doc comments for the public `workspace` functions
* Bug fixes and performance improvements

## 0.5.5 (2017-11-08)

* Fixed a bug where the execution started before the file was saved

## 0.5.4 (2017-11-07)

* Removed the `atom-space-pen-views` dependency from several modules
* Converted the level select view into an `atom-select-list` view

## 0.5.3 (2017-09-24)

* Removed the parentheses from the level status view
* Removed the `underscore-plus` dependency
* Fixed a bug where a non-existing line was written to the terminal

## 0.5.2 (2017-05-15)

* Fixed a bug in the level status view that is caused by an upgrade of CoffeeScript
* Removed the `atom-text-editor` shadow DOM boundary

## 0.5.1 (2016-05-20)

* Added support for custom level properties

## 0.5.0 (2016-04-05)

* It is now possible to deactivate the language information file header in the package settings
* The package API has been updated to provide access to the levels workspace
* Other internal adjustments

## 0.4.3 (2015-11-18)

* Fixed an error that caused level code editor deserialization to fail due to changes to Atom's `DeserializerManager` API (especially the `deserialize` function)

## 0.4.2 (2015-11-05)

* Fixed a bug that caused the terminal cursor to have an incorrect position when changing the font size after clearing the terminal

## 0.4.1 (2015-11-03)

* Fixed a bug that caused annotation overlays to be too small for short warning or error messages

## 0.4.0 (2015-11-03)

* Running a program now automatically saves the buffer (or opens the save dialog if the buffer has not yet been saved)
* The terminal now is styled (colored) based on the UI theme
* The maximum terminal font size has been increased
* Annotation overlays now dynamically resize when changing the text editor's font size or width

## 0.3.2 (2015-11-01)

* Fixed a bug that caused warning or error parsing to fail on Windows

## 0.3.1 (2015-11-01)

* Fixed a bug that made it impossible for language packages to consume the levels package

## 0.3.0 (2015-11-01)

* The levels package now provides an API for other packages (for now the language registry is available to enable the embedding of language packages)
* Languages are now installable as Atom packages (see the [levels language package template](https://github.com/lakrme/atom-levels-language-template))
* Fast execution output from spawned child processes no longer freezes Atom
* Added some documentation
* General bug fixing and other adjustments

## 0.2.0 (2015-10-15)

* Execution can now be stopped on all platforms

## 0.1.0 (2015-09-29)

* First release