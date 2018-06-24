'use babel';

import {Emitter} from 'atom';

export default class TerminalBuffer {
  constructor({prompt, commands, commandNotFound} = {}) {
    this.emitter = new Emitter();
    this.history = [];
    this.scopes = [];

    const commandNotFoundFunc = (input) => this.writeLn(`${input}: command not found!`);
    this.enterScope({
      prompt: prompt ? prompt : '',
      commands: commands ? commands : {},
      commandNotFound: commandNotFound ? commandNotFound : commandNotFoundFunc
    });
  }

  destroy() {
    this.emitter.dispose();
  }

  onDidCreateNewLine(callback) {
    return this.emitter.on('did-create-new-line', callback);
  }

  onDidUpdateActiveLine(callback) {
    return this.emitter.on('did-update-active-line', callback);
  }

  onDidEnterInput(callback) {
    return this.emitter.on('did-enter-input', callback);
  }

  onDidEnterScope(callback) {
    return this.emitter.on('did-enter-scope', callback);
  }

  onDidExitScope(callback) {
    return this.emitter.on('did-exit-scope', callback);
  }

  onDidClear(callback) {
    return this.emitter.on('did-clear', callback);
  }

  didCreateNewLine() {
    this.emitter.emit('did-create-new-line');
  }

  didUpdateActiveLine() {
    this.emitter.emit('did-update-active-line', {
      output: this.activeLineOutput,
      input: this.activeLineInput,
      inputCursorPos: this.activeLineInputCursorPos
    });
  }

  didEnterInput(input) {
    this.emitter.emit('did-enter-input', input);
  }

  newLine(prompt = this.prompt) {
    if (this.activeLineOutput || this.activeLineInput) {
      this.history.push(this.activeLineOutput + this.activeLineInput);
    }

    this.resetInputAndOutput();
    this.didCreateNewLine();

    if (prompt) {
      this.addStringToOutput(`${prompt} `);
    }

    this.promptIsActive = true;
  }

  resetInputAndOutput() {
    this.activeLineOutput = '';
    this.activeLineInput = '';
    this.activeLineInputCursorPos = 0;
    this.inputHistoryIndex = -1;
    this.promptIsActive = false;
  }

  addStringToOutput(string) {
    if (this.promptIsActive) {
      this.resetInputAndOutput();
    }
    this.activeLineOutput += string;
    this.didUpdateActiveLine();
  }

  addStringToInput(string) {
    const prefix = this.activeLineInput.slice(0, this.activeLineInputCursorPos);
    const suffix = this.activeLineInput.substr(this.activeLineInputCursorPos);
    this.activeLineInput = prefix + string + suffix;
    this.activeLineInputCursorPos += string.length;
    this.didUpdateActiveLine();
  }

  removeCharFromInput() {
    if (this.activeLineInputCursorPos !== 0) {
      const prefix = this.activeLineInput.slice(0, this.activeLineInputCursorPos - 1);
      const suffix = this.activeLineInput.substr(this.activeLineInputCursorPos);
      this.activeLineInput = prefix + suffix;
      this.activeLineInputCursorPos--;
      this.didUpdateActiveLine();
    }
  }

  showPreviousInput() {
    if (this.inputHistoryIndex < this.inputHistory.length - 1) {
      this.inputHistoryIndex++;
      this.activeLineInput = this.inputHistory[this.inputHistoryIndex];
      this.activeLineInputCursorPos = this.activeLineInput.length;
      this.didUpdateActiveLine();
    }
  }

  showSubsequentInput() {
    if (this.inputHistoryIndex == 0) {
      this.activeLineInput = '';
      this.activeLineInputCursorPos = 0;
      this.inputHistoryIndex--;
      this.didUpdateActiveLine();
    } else if (this.inputHistoryIndex > 0) {
      this.inputHistoryIndex--;
      this.activeLineInput = this.inputHistory[this.inputHistoryIndex];
      this.activeLineInputCursorPos = this.activeLineInput.length;
      this.didUpdateActiveLine();
    }
  }

  moveInputCursorLeft() {
    if (this.activeLineInputCursorPos > 0) {
      this.activeLineInputCursorPos--;
      this.didUpdateActiveLine();
    }
  }

  moveInputCursorRight() {
    if (this.activeLineInputCursorPos < this.activeLineInput.length) {
      this.activeLineInputCursorPos++;
      this.didUpdateActiveLine();
    }
  }

  enterInput() {
    const input = this.activeLineInput.trim();
    this.newLine();
    this.didEnterInput(input);

    if (input) {
      if (this.inputHistory[0] !== input) {
        this.inputHistory.unshift(input);
      }

      if (Object.keys(this.commands).length !== 0) {
        const args = input.split(' ');
        const commandName = args.shift();
        const command = this.commands[commandName];

        if (command) {
          if (args.length === 0) {
            command();
          } else {
            command(args);
          }
        } else {
          this.commandNotFound(commandName);
        }
      }
    }
  }

  getActiveLineOutput() {
    return this.promptIsActive ? '' : this.activeLineOutput;
  }

  getActiveLineInput() {
    return this.activeLineInput;
  }

  write(output) {
    const lines = output.split('\n');
    this.addStringToOutput(lines.shift());

    for (const line of lines) {
      this.newLine('');
      if (line) {
        this.addStringToOutput(line);
      }
    }
  }

  writeLn(output) {
    this.write(output);
    this.newLine();
  }

  clear() {
    this.history = [];
    this.resetInputAndOutput();
    this.emitter.emit('did-clear');

    if (this.prompt) {
      this.addStringToOutput(`${this.prompt} `);
    }

    this.promptIsActive = true;
  }

  enterScope({prompt, commands, commandNotFound} = {}) {
    if (!prompt) {
      prompt = '';
    } else if (prompt === 'inherit') {
      prompt = this.prompt;
    }

    if (!commands) {
      commands = {};
    } else if (commands === 'inherit') {
      commands = this.commands;
    }

    if (!commandNotFound) {
      commandNotFound = this.commandNotFound;
    }

    this.prompt = prompt;
    this.commands = commands;
    this.commandNotFound = commandNotFound;
    this.inputHistory = [];

    this.scopes.push({
      prompt: this.prompt,
      commands: this.commands,
      commandNotFound: this.commandNotFound,
      inputHistory: this.inputHistory
    });

    if (this.promptIsActive) {
      this.addStringToOutput(this.prompt ? `${this.prompt} ` : '');
      this.promptIsActive = true;
    }
  }

  exitScope() {
    if (this.scopes.length > 1) {
      this.scopes.pop();

      const currentScope = this.scopes[this.scopes.length - 1];
      this.prompt = currentScope.prompt;
      this.commands = currentScope.commands;
      this.commandNotFound = currentScope.commandNotFound;
      this.inputHistory = currentScope.inputHistory;

      if (this.promptIsActive) {
        this.addStringToOutput(this.prompt ? `${this.prompt} ` : '');
        this.promptIsActive = true;
      }
    }
  }
}