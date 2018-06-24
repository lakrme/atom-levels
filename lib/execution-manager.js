'use babel';

import childProcess from 'child_process';
import path         from 'path';

export default class ExecutionManager {
  constructor(levelCodeEditor) {
    this.levelCodeEditor = levelCodeEditor;
    this.executing = false;
    this.handleProcessData = this.handleProcessData.bind(this);
    this.handleProcessExit = this.handleProcessExit.bind(this);
    this.handleProcessClose = this.handleProcessClose.bind(this);
  }

  isExecuting() {
    return this.executing;
  }

  startExecution({runExecArgs} = {}) {
    this.terminal = this.levelCodeEditor.getTerminal();

    if (this.executing || this.terminal.isExecuting()) {
      return;
    }

    this.textEditor = this.levelCodeEditor.getTextEditor();
    this.language = this.levelCodeEditor.getLanguage();
    this.level = this.levelCodeEditor.getLevel();

    if (atom.config.get('levels.workspaceSettings.clearTerminalOnExecution')) {
      this.terminal.clear();
    }

    this.terminal.writeSubtle('Running level code …');

    const runExecPath = this.language.getExecutablePath();
    const configFilePath = this.language.getConfigFilePath();
    const levelNumber = this.level.getNumber() - 1;
    const filePath = this.textEditor.getPath();

    const cmd = [
      `"${runExecPath}"`,
      '-l', `"${configFilePath}"`
    ].concat(runExecArgs).concat([
      `${levelNumber}`,
      `"${filePath}"`,
      '2>&1'
    ]).join(' ');

    this.processExited = false;
    this.processClosed = false;

    this.process = childProcess.exec(cmd, {cwd: path.dirname(runExecPath), env: process.env});
    this.terminalSubscription = this.terminal.onDidEnterInput((input) => this.process.stdin.write(`${input}\n`));
    this.executionStarted();

    this.process.stdout.on('data', this.handleProcessData);
    this.process.on('exit', this.handleProcessExit);
    this.process.on('close', this.handleProcessClose);
  }

  stopExecution() {
    if (!this.executing) {
      return;
    }

    this.executionStoppedByUser = true;
    this.process.stdout.removeListener('data', this.handleProcessData);

    if (!this.processExited) {
      this.killProcess(this.process.pid);
    }
    if (!this.processClosed) {
      this.process.stdout.read();
      this.process.stdout.destroy();
    }
  }

  executionStarted() {
    this.executing = true;
    this.terminal.enterScope();
    this.terminal.didStartExecution();
    this.levelCodeEditor.didStartExecution();
  }

  executionStopped() {
    this.executing = false;
    this.terminal.exitScope();
    this.terminal.didStopExecution();
    this.levelCodeEditor.didStopExecution();

    if (this.executionStoppedByUser) {
      this.executionStoppedByUser = false;
      this.terminal.writeLn('…');
      this.terminal.writeSubtle('Execution stopped!');
    }
  }

  handleProcessData(data) {
    this.process.stdout.pause();
    const lines = data.split('\n');
    this.writeDataLines(lines);
    this.process.stdout.resume();
  }

  handleProcessExit() {
    this.processExited = true;
  }

  handleProcessClose() {
    this.terminalSubscription.dispose();
    this.process.stdin.end();
    this.processClosed = true;
    this.executionStopped();
  }

  writeDataLines(lines) {
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      if (i === lines.length - 1) {
        if (line) {
          this.terminal.write(line);
        }
      } else {
        this.terminal.writeLn(line);
      }
    }
  }

  killProcess(pid) {
    switch (process.platform) {
      case 'darwin':
      case 'linux':
        this.killProcessOnDarwinAndLinux(pid);
        break;
      case 'win32':
        this.killProcessOnWin32(pid);
        break;
      default:
    }
  }

  killProcessOnDarwinAndLinux(parentPid) {
    let childPids = null;
    try {
      const out = childProcess.execSync(`pgrep -P ${parentPid}`, {env: process.env});
      childPids = out.toString().split('\n').map((pid) => parseInt(pid)).filter((pid) => !isNaN(pid));
    } catch (error) {
      childPids = [];
    }

    for (const childPid of childPids) {
      this.killProcessOnDarwinAndLinux(childPid);
    }
    try {
      process.kill(parentPid, 'SIGINT');
    } catch (error) { /* EMPTY */ }
  }

  killProcessOnWin32(parentPid) {
    try {
      const wmicProcess = childProcess.spawn('wmic', [
        'process', 'where', `(ParentProcessId=${parentPid})`, 'get', 'processid'
      ]);

      let out = '';
      wmicProcess.stdout.on('data', (data) => {
        out += data;
      });
      wmicProcess.stdout.on('close', () => {
        const childPids = out.split(/\s+/)
          .filter((pid) => /^\d+$/.test(pid))
          .map((pid) => parseInt(pid))
          .filter((pid) => pid !== parentPid && pid > 0 && pid < Infinity);
        for (const childPid of childPids) {
          this.killProcessOnWin32(childPid);
        }
        try {
          process.kill(parentPid, 'SIGINT');
        } catch (error) { /* EMPTY */ }
      });
    } catch (error) { /* EMPTY */ }
  }
}