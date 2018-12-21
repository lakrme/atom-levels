'use babel';

import {CompositeDisposable, Emitter} from 'atom';
import TerminalBuffer                 from './terminal-buffer';
import * as terminalUtils             from './terminal-utils';

let typedMessageIdCounter = 0;

function getTypedMessageId() {
  const id = typedMessageIdCounter;
  typedMessageIdCounter++;

  return id;
}

export default class Terminal {
  constructor() {
    this.emitter = new Emitter();

    this.visible = !atom.config.get('levels.terminalSettings.defaultTerminalIsHidden');
    this.size = atom.config.get('levels.terminalSettings.defaultTerminalSize');
    this.fontSize = atom.config.get('levels.terminalSettings.defaultTerminalFontSize');

    this.buffer = new TerminalBuffer({
      prompt: 'Levels>',
      commands: {
        clear: () => this.clearCommand(),
        help: () => this.helpCommand(),
        run: () => this.runCommand(),
        set: (args) => this.setCommand(args),
        topkek: () => this.topkekCommand(),
        unset: (args) => this.unsetCommand(args)
      }
    });

    this.focused = false;
    this.refCount = 0;
    this.executing = false;

    this.typedMessageBuffer = null;
    this.typedMessageCurrentLineBuffer = null;

    this.bufferSubscriptions = new CompositeDisposable();
    this.bufferSubscriptions.add(this.buffer.onDidCreateNewLine(() => this.updateTypedMessageBufferOnDidCreateNewLine()));
    this.bufferSubscriptions.add(this.buffer.onDidUpdateActiveLine((state) => this.updateTypedMessageBufferOnDidUpdateActiveLine(state)));
  }

  destroy() {
    this.bufferSubscriptions.dispose();
    this.buffer.destroy();
    this.emitter.emit('did-destroy');
    this.emitter.dispose();
  }

  onDidDestroy(callback) {
    return this.emitter.on('did-destroy', callback);
  }

  observeIsVisible(callback) {
    callback(this.visible);

    return this.onDidChangeIsVisible(callback);
  }

  onDidChangeIsVisible(callback) {
    return this.emitter.on('did-change-is-visible', callback);
  }

  onDidShow(callback) {
    return this.emitter.on('did-show', callback);
  }

  onDidHide(callback) {
    return this.emitter.on('did-hide', callback);
  }

  observeSize(callback) {
    callback(this.size);

    return this.onDidChangeSize(callback);
  }

  onDidChangeSize(callback) {
    return this.emitter.on('did-change-size', callback);
  }

  observeFontSize(callback) {
    callback(this.fontSize);

    return this.onDidChangeFontSize(callback);
  }

  onDidChangeFontSize(callback) {
    return this.emitter.on('did-change-font-size', callback);
  }

  onDidFocus(callback) {
    return this.emitter.on('did-focus', callback);
  }

  onDidBlur(callback) {
    return this.emitter.on('did-blur', callback);
  }

  onDidScrollToTop(callback) {
    return this.emitter.on('did-scroll-to-top', callback);
  }

  onDidScrollToBottom(callback) {
    return this.emitter.on('did-scroll-to-bottom', callback);
  }

  observeIsExecuting(callback) {
    callback(this.executing);

    return this.onDidChangeIsExecuting(callback);
  }

  onDidChangeIsExecuting(callback) {
    return this.emitter.on('did-change-is-executing', callback);
  }

  onDidStartExecution(callback) {
    return this.emitter.on('did-start-execution', callback);
  }

  onDidStopExecution(callback) {
    return this.emitter.on('did-stop-execution', callback);
  }

  onDidCreateNewLine(callback) {
    return this.buffer.onDidCreateNewLine(callback);
  }

  onDidUpdateActiveLine(callback) {
    return this.buffer.onDidUpdateActiveLine(callback);
  }

  onDidEnterInput(callback) {
    return this.buffer.onDidEnterInput(callback);
  }

  onDidClear(callback) {
    return this.buffer.onDidClear(callback);
  }

  onDidStartReadingTypedMessage(callback) {
    return this.emitter.on('did-start-reading-typed-message', callback);
  }

  onDidStopReadingTypedMessage(callback) {
    return this.emitter.on('did-stop-reading-typed-message', callback);
  }

  onDidReadTypedMessage(callback) {
    return this.emitter.on('did-read-typed-message', callback);
  }

  isRetained() {
    return this.refCount > 0;
  }

  acquire() {
    return this.refCount++;
  }

  release() {
    if (this.isRetained()) {
      this.refCount--;
      if (!this.isRetained()) {
        this.destroy();
      }
    }
  }

  getSize() {
    return this.size;
  }

  setSize(size) {
    if (size !== this.size) {
      const minSize = terminalUtils.MIN_SIZE;
      if (size >= minSize) {
        this.size = size;
      } else {
        this.size = minSize;
      }
      this.emitter.emit('did-change-size', this.size);
    }
  }

  getFontSize() {
    return this.fontSize;
  }

  setFontSize(fontSize) {
    if (fontSize !== this.fontSize) {
      if (terminalUtils.FONT_SIZES.includes(fontSize)) {
        this.fontSize = fontSize;
        this.emitter.emit('did-change-font-size', this.fontSize);
      }
    }
  }

  increaseFontSize() {
    const fontSizes = terminalUtils.FONT_SIZES;
    const fontSizeIndex = fontSizes.indexOf(this.fontSize);
    if (fontSizeIndex < fontSizes.length - 1) {
      this.setFontSize(fontSizes[fontSizeIndex + 1]);
    }
  }

  decreaseFontSize() {
    const fontSizes = terminalUtils.FONT_SIZES;
    const fontSizeIndex = fontSizes.indexOf(this.fontSize);
    if (fontSizeIndex > 0) {
      this.setFontSize(fontSizes[fontSizeIndex - 1]);
    }
  }

  getLineHeight() {
    return this.fontSize + 4;
  }

  getCharWidth() {
    const canvas = document.createElement('canvas');
    const context = canvas.getContext('2d');
    context.font = `${this.fontSize}px Courier`;

    return context.measureText('_').width;
  }

  hasFocus() {
    return this.focused;
  }

  focus() {
    this.emitter.emit('did-focus');
    this.didFocus();
  }

  didFocus() {
    this.focused = true;
  }

  blur() {
    this.emitter.emit('did-blur');
    this.didBlur();
  }

  didBlur() {
    this.focused = false;
  }

  scrollToTop() {
    this.emitter.emit('did-scroll-to-top');
  }

  scrollToBottom() {
    this.emitter.emit('did-scroll-to-bottom');
  }

  getBuffer() {
    return this.buffer;
  }

  newLine() {
    this.buffer.newLine();
  }

  write(output) {
    this.buffer.write(output);
  }

  writeLn(output) {
    this.buffer.writeLn(output);
  }

  enterScope(options) {
    this.buffer.enterScope(options);
  }

  exitScope() {
    this.buffer.exitScope();
  }

  clear() {
    this.buffer.clear();
  }

  writeSubtle(message) {
    this.writeTypedMessage({type: 'subtle', body: message});
  }

  writeInfo(message) {
    this.writeTypedMessage({type: 'info', body: message});
  }

  writeSuccess(message) {
    this.writeTypedMessage({type: 'success', body: message});
  }

  writeWarning(message) {
    this.writeTypedMessage({type: 'warning', body: message});
  }

  writeError(message) {
    this.writeTypedMessage({type: 'error', body: message});
  }

  writeTypedMessage({type, head, body, data} = {}) {
    if (head || body) {
      let startTag = `<message type="${type}"`;
      for (const key in data) {
        startTag += ` data-${key}="${data[key]}"`;
      }
      startTag += '>\n';
      const headElem = head ? `<head>\n${head}\n</head>\n` : '';
      const bodyElem = body ? `<body>\n${body}\n</body>\n` : '';
      const endTag = '</message>';
      const typedMessage = startTag + headElem + bodyElem + endTag;
      if (this.buffer.getActiveLineOutput()) {
        this.newLine();
      }
      this.writeLn(typedMessage);
    }
  }

  updateTypedMessageBufferOnDidCreateNewLine() {
    if (this.typedMessageBuffer != null) {
      if (!(this.typedMessageCurrentLineBuffer.match(/^<message\s+.*type=.*>/)
           || this.typedMessageCurrentLineBuffer.match(/^<head>/)
           || this.typedMessageCurrentLineBuffer.match(/^<\/head>/)
           || this.typedMessageCurrentLineBuffer.match(/^<body>/)
           || this.typedMessageCurrentLineBuffer.match(/^<\/body>/)
           || this.typedMessageCurrentLineBuffer.match(/^<\/message>/))) {
        this.typedMessageCurrentLineBuffer = this.typedMessageCurrentLineBuffer
          .replace(/&/g, '&amp;')
          .replace(/"/g, '&quot;')
          .replace(/'/g, '&apos;')
          .replace(/</g, '&lt;')
          .replace(/>/g, '&gt;');
      }

      this.typedMessageBuffer += `${this.typedMessageCurrentLineBuffer}\n`;
      if (this.typedMessageCurrentLineBuffer.match(/^<\/message>/)) {
        const typedMessage = this.readTypedMessage(this.typedMessageBuffer);
        if (typedMessage) {
          this.emitter.emit('did-read-typed-message', typedMessage);
        }
        this.emitter.emit('did-stop-reading-typed-message');
        this.typedMessageBuffer = null;
      }
      this.typedMessageCurrentLineBuffer = null;
    }
  }

  updateTypedMessageBufferOnDidUpdateActiveLine({output}) {
    if (this.typedMessageBuffer == null) {
      this.typedMessageBuffer = '';
    }
    this.typedMessageCurrentLineBuffer = output;
    if (this.typedMessageCurrentLineBuffer.match(/^<message\s+.*type=.*>/)) {
      this.typedMessageBuffer = this.typedMessageCurrentLineBuffer;
      this.emitter.emit('did-start-reading-typed-message');
    }
  }

  readTypedMessage(buffer) {
    const parser = new DOMParser();
    const xml = parser.parseFromString(buffer, 'text/xml');
    const message = xml.querySelector('message');

    if (!message) {
      return null;
    }

    const typedMessage = {id: getTypedMessageId()};
    typedMessage.data = {};

    for (const attr of message.attributes) {
      if (attr.name.startsWith('data-')) {
        const dataKey = attr.name.substr(5);
        typedMessage.data[dataKey] = attr.value;
      } else {
        typedMessage[attr.name] = attr.value;
      }
    }

    const head = message.getElementsByTagName('head')[0];
    typedMessage.head = head ? head.textContent : '';
    const body = message.getElementsByTagName('body')[0];
    typedMessage.body = body ? body.textContent : '';

    return typedMessage;
  }

  clearCommand() {
    const workspaceView = atom.views.getView(atom.workspace);
    atom.commands.dispatch(workspaceView, 'levels:clear-terminal');
  }

  helpCommand() {
    this.writeInfo('The following commands are available:');
    this.writeSubtle('clear                         Clears the terminal.');
    this.writeSubtle('help                          Shows this help message.');
    this.writeSubtle('run                           Starts the execution of the program.');
    this.writeSubtle('set <size|fontSize> <number>  Sets the size or font size to the given number.');
    this.writeSubtle('topkek                        Prints the topkek banner to the terminal.');
    this.writeSubtle('unset <size|fontSize>         Resets the size or font size to the default value.');
  }

  runCommand() {
    const workspaceView = atom.views.getView(atom.workspace);
    atom.commands.dispatch(workspaceView, 'levels:start-execution');
  }

  setCommand(args) {
    if (!args || args.length !== 2) {
      this.writeWarning('set: wrong number of arguments!');
    } else {
      const propertyStr = args[0];
      const valueStr = args[1];
      switch (propertyStr) {
        case 'fontSize': {
          const value = parseInt(valueStr);
          if (!isNaN(value)) {
            this.setFontSize(value);
          } else {
            this.writeWarning(`set: ${valueStr}: invalid argument!`);
          }
          break;
        }
        case 'size': {
          const value = parseInt(valueStr);
          if (!isNaN(value)) {
            this.setSize(value);
          } else {
            this.writeWarning(`set: ${valueStr}: invalid argument!`);
          }
          break;
        }
        default:
          this.writeWarning(`set: ${propertyStr}: unknown property!`);
      }
    }
  }

  topkekCommand() {
    this.writeLn(terminalUtils.TOPKEK);
  }

  unsetCommand(args) {
    if (!args || args.length !== 1) {
      this.writeWarning('unset: wrong number of arguments!');
    } else {
      const propertyStr = args[0];
      switch (propertyStr) {
        case 'fontSize':
          this.setFontSize(terminalUtils.DEFAULT_FONT_SIZE);
          break;
        case 'size':
          this.setSize(terminalUtils.DEFAULT_SIZE);
          break;
        default:
          this.writeWarning(`unset: ${propertyStr}: unknown property!`);
      }
    }
  }

  isExecuting() {
    return this.executing;
  }

  didStartExecution() {
    if (!this.executing) {
      this.executing = true;
      this.emitter.emit('did-start-execution');
      this.emitter.emit('did-change-is-executing', this.executing);
    }
  }

  didStopExecution() {
    if (this.executing) {
      this.typedMessageBuffer = null;
      this.typedMessageCurrentLineBuffer = null;
      this.emitter.emit('did-stop-reading-typed-message');

      this.executing = false;
      this.emitter.emit('did-stop-execution');
      this.emitter.emit('did-change-is-executing', this.executing);
    }
  }

  isVisible() {
    return this.visible;
  }

  toggle() {
    if (this.visible) {
      this.hide();
    } else {
      this.show();
    }
  }

  show() {
    if (!this.visible) {
      this.visible = true;
      this.emitter.emit('did-show');
      this.emitter.emit('did-change-is-visible', this.visible);
    }
  }

  hide() {
    if (this.visible) {
      this.visible = false;
      this.emitter.emit('did-hide');
      this.emitter.emit('did-change-is-visible', this.visible);
    }
  }
}