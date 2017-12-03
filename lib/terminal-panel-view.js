'use babel';

import {CompositeDisposable} from 'atom';
import * as terminalUtils    from './terminal-utils';
import workspace             from './workspace';

export default class TerminalPanelView {
  constructor() {
    this.element = document.createElement('div');
    this.element.className = 'levels-view terminal-panel';
    this.element.tabIndex = 0;

    this.resizeHandle = document.createElement('div');
    this.resizeHandle.className = 'resize-handle';
    this.element.appendChild(this.resizeHandle);

    this.controlBar = document.createElement('div');
    this.controlBar.className = 'control-bar';
    this.element.appendChild(this.controlBar);

    this.terminalContainer = document.createElement('div');
    this.terminalContainer.className = 'terminal-container';
    this.element.appendChild(this.terminalContainer);

    this.terminalInfo = document.createElement('div');
    this.terminalInfo.className = 'terminal-info';
    this.element.appendChild(this.terminalInfo);

    const cbl = document.createElement('div');
    cbl.className = 'control-bar-left';
    this.controlBar.appendChild(cbl);

    const cbr = document.createElement('div');
    cbr.className = 'control-bar-right';
    this.controlBar.appendChild(cbr);

    const executionControls = document.createElement('div');
    executionControls.className = 'control-group execution-controls';
    cbr.appendChild(executionControls);

    this.startExecutionLink = document.createElement('a');
    this.startExecutionLink.addEventListener('click', () => this.doStartExecution());
    const startExecutionLinkSpan = document.createElement('span');
    startExecutionLinkSpan.className = 'text-success icon icon-playback-play';
    startExecutionLinkSpan.textContent = 'Run';
    this.startExecutionLink.appendChild(startExecutionLinkSpan);
    executionControls.appendChild(this.startExecutionLink);

    this.stopExecutionLink = document.createElement('a');
    this.stopExecutionLink.addEventListener('click', () => this.doStopExecution());
    const stopExecutionLinkSpan = document.createElement('span');
    stopExecutionLinkSpan.className = 'text-error icon icon-primitive-square';
    stopExecutionLinkSpan.textContent = 'Stop';
    this.stopExecutionLink.appendChild(stopExecutionLinkSpan);
    executionControls.appendChild(this.stopExecutionLink);

    const cg = document.createElement('div');
    cg.className = 'control-group';
    cbl.appendChild(cg);

    let ce = document.createElement('div');
    ce.className = 'control-element';
    cg.appendChild(ce);

    this.showTerminalLink = document.createElement('a');
    this.showTerminalLink.addEventListener('click', () => this.doToggleTerminal());
    const showTerminalLinkSpan = document.createElement('span');
    showTerminalLinkSpan.className = 'icon icon-triangle-up';
    showTerminalLinkSpan.textContent = 'Show Terminal';
    this.showTerminalLink.appendChild(showTerminalLinkSpan);
    ce.appendChild(this.showTerminalLink);

    ce = document.createElement('div');
    ce.className = 'control-element';
    cg.appendChild(ce);

    this.hideTerminalLink = document.createElement('a');
    this.hideTerminalLink.addEventListener('click', () => this.doToggleTerminal());
    const hideTerminalLinkSpan = document.createElement('span');
    hideTerminalLinkSpan.className = 'icon icon-triangle-down';
    hideTerminalLinkSpan.textContent = 'Hide Terminal';
    this.hideTerminalLink.appendChild(hideTerminalLinkSpan);
    ce.appendChild(this.hideTerminalLink);

    this.terminalControls = document.createElement('div');
    this.terminalControls.className = 'control-group terminal-controls';
    cbl.appendChild(this.terminalControls);

    let cbs = document.createElement('div');
    cbs.className = 'control-bar-separator';
    this.terminalControls.appendChild(cbs);

    ce = document.createElement('div');
    ce.className = 'control-element';
    this.terminalControls.appendChild(ce);

    const clearTerminalLink = document.createElement('a');
    clearTerminalLink.addEventListener('click', () => this.doClearTerminal());
    const clearTerminalLinkSpan = document.createElement('span');
    clearTerminalLinkSpan.className = 'icon icon-x';
    clearTerminalLinkSpan.textContent = 'Clear';
    clearTerminalLink.appendChild(clearTerminalLinkSpan);
    ce.appendChild(clearTerminalLink);

    ce = document.createElement('div');
    ce.className = 'control-element';
    this.terminalControls.appendChild(ce);

    const scrollTopLink = document.createElement('a');
    scrollTopLink.addEventListener('click', () => this.activeTerminal.scrollToTop());
    const scrollTopLinkSpan = document.createElement('span');
    scrollTopLinkSpan.className = 'icon icon-move-up';
    scrollTopLinkSpan.textContent = 'Scroll To Top';
    scrollTopLink.appendChild(scrollTopLinkSpan);
    ce.appendChild(scrollTopLink);

    ce = document.createElement('div');
    ce.className = 'control-element';
    this.terminalControls.appendChild(ce);

    const scrollBottomLink = document.createElement('a');
    scrollBottomLink.addEventListener('click', () => this.activeTerminal.scrollToBottom());
    const scrollBottomLinkSpan = document.createElement('span');
    scrollBottomLinkSpan.className = 'icon icon-move-down';
    scrollBottomLinkSpan.textContent = 'Scroll To Bottom';
    scrollBottomLink.appendChild(scrollBottomLinkSpan);
    ce.appendChild(scrollBottomLink);

    cbs = document.createElement('div');
    cbs.className = 'control-bar-separator';
    this.terminalControls.appendChild(cbs);

    ce = document.createElement('div');
    ce.className = 'control-element';
    this.terminalControls.appendChild(ce);

    const fontSizeLinkSpan = document.createElement('span');
    fontSizeLinkSpan.className = 'icon icon-text-size';
    fontSizeLinkSpan.textContent = 'Font Size:';
    ce.appendChild(fontSizeLinkSpan);

    this.fontSizeSelect = document.createElement('select');
    for (const fontSize of terminalUtils.FONT_SIZES) {
      const option = document.createElement('option');
      option.value = fontSize;
      option.textContent = fontSize;
      this.fontSizeSelect.appendChild(option);
    }
    ce.appendChild(this.fontSizeSelect);

    this.workspaceSubscriptions = new CompositeDisposable();
    this.workspaceSubscriptions.add(workspace.onDidEnterWorkspace(activeLevelCodeEditor => this.updateOnDidEnterWorkspace(activeLevelCodeEditor)));
    this.workspaceSubscriptions.add(workspace.onDidExitWorkspace(() => this.updateOnDidExitWorkspace()));
    this.workspaceSubscriptions.add(workspace.onDidChangeActiveLanguage(({activeLanguage}) => this.updateOnDidChangeActiveLanguage(activeLanguage)));
    this.workspaceSubscriptions.add(workspace.onDidChangeActiveTerminal(activeTerminal => this.updateOnDidChangeActiveTerminal(activeTerminal)));

    this.resizeStarted = this.resizeStarted.bind(this);
    this.resizeStopped = this.resizeStopped.bind(this);
    this.resize = this.resize.bind(this);
    this.resizeToMinSize = this.resizeToMinSize.bind(this);
    this.changeFontSize = this.changeFontSize.bind(this);
    this.focusTerminal = this.focusTerminal.bind(this);
    this.blurTerminal = this.blurTerminal.bind(this);
    this.dispatchKeyEvent = this.dispatchKeyEvent.bind(this);
  }

  destroy() {
    this.workspaceSubscriptions.dispose();
    this.hide();
  }

  resizeStarted() {
    document.addEventListener('mousemove', this.resize);
    document.addEventListener('mouseup', this.resizeStopped);
  }

  resizeStopped() {
    document.removeEventListener('mousemove', this.resize);
    document.removeEventListener('mouseup', this.resizeStopped);
  }

  resize({pageY, which}) {
    if (which !== 1) {
      this.resizeStopped();
    }

    const controlBarHeight = this.controlBar.offsetHeight;
    const newHeight = document.body.clientHeight - pageY - controlBarHeight;
    const heightDiff = newHeight - this.element.clientHeight;
    const lineHeight = this.activeTerminal.getLineHeight();
    const sizeDiff = (heightDiff - (heightDiff % lineHeight)) / lineHeight;

    if (sizeDiff !== 0) {
      this.activeTerminal.setSize(this.activeTerminal.getSize() + sizeDiff);
    }
  }

  resizeToMinSize() {
    this.activeTerminal.setSize(terminalUtils.MIN_SIZE);
  }

  doToggleTerminal() {
    const workspaceView = atom.views.getView(atom.workspace);
    atom.commands.dispatch(workspaceView, 'levels:toggle-terminal');
  }

  doClearTerminal() {
    const workspaceView = atom.views.getView(atom.workspace);
    atom.commands.dispatch(workspaceView, 'levels:clear-terminal');
  }

  doStartExecution() {
    const workspaceView = atom.views.getView(atom.workspace);
    atom.commands.dispatch(workspaceView, 'levels:start-execution');
  }

  doStopExecution() {
    const workspaceView = atom.views.getView(atom.workspace);
    atom.commands.dispatch(workspaceView, 'levels:stop-execution');
  }

  updateOnDidEnterWorkspace(activeLevelCodeEditor) {
    this.activeLanguage = activeLevelCodeEditor.getLanguage();
    this.activeTerminal = activeLevelCodeEditor.getTerminal();
    this.show();
    this.updateOnDidChangeActiveLanguage(this.activeLanguage);
    this.updateOnDidChangeActiveTerminal(this.activeTerminal);
  }

  updateOnDidExitWorkspace() {
    this.hide();

    if (this.activeTerminalSubscriptions) {
      this.activeTerminalSubscriptions.dispose();
    }
    if (this.activeLanguageSubscription) {
      this.activeLanguageSubscription.dispose();
    }

    this.activeTerminal = null;
    this.activeLanguage = null;

    this.removeEventListeners();
  }

  updateOnDidChangeActiveLanguage(activeLanguage) {
    this.activeLanguage = activeLanguage;
    if (this.activeLanguageSubscription) {
      this.activeLanguageSubscription.dispose();
    }
    this.activeLanguageSubscription = this.activeLanguage.observe(() => this.enableDisableExecutionControls());
  }

  updateOnDidChangeActiveTerminal(activeTerminal) {
    this.activeTerminal = activeTerminal;
    if (this.activeTerminalSubscriptions) {
      this.activeTerminalSubscriptions.dispose();
    }
    this.activeTerminalSubscriptions = new CompositeDisposable();
    this.activeTerminalSubscriptions.add(this.activeTerminal.observeIsVisible(isVisible => this.updateOnDidChangeIsVisible(isVisible)));
    this.activeTerminalSubscriptions.add(this.activeTerminal.onDidChangeSize(size => this.updateOnDidChangeTerminalSize(size)));
    this.activeTerminalSubscriptions.add(this.activeTerminal.observeFontSize(fontSize => this.updateOnDidChangeTerminalFontSize(fontSize)));
    this.activeTerminalSubscriptions.add(this.activeTerminal.observeIsExecuting(isExecuting => this.updateOnDidChangeIsExecuting(isExecuting)));

    this.terminalContainer.innerHTML = '';
    this.terminalContainer.appendChild(atom.views.getView(this.activeTerminal));
  }

  enableDisableExecutionControls() {
    if (!this.activeTerminal.isExecuting()) {
      if (this.activeLanguage.isExecutable()) {
        this.startExecutionLink.style.display = '';
        this.stopExecutionLink.style.display = 'none';
      } else {
        this.startExecutionLink.style.display = 'none';
        this.stopExecutionLink.style.display = 'none';
      }
    }
  }

  changeFontSize() {
    this.activeTerminal.setFontSize(parseInt(this.fontSizeSelect.value));
  }

  focusTerminal() {
    this.activeTerminal.didFocus();
  }

  blurTerminal() {
    this.activeTerminal.didBlur();
  }

  updateOnDidChangeIsVisible(isVisible) {
    if (isVisible) {
      this.resizeHandle.style.display = '';
      this.showTerminalLink.style.display = 'none';
      this.hideTerminalLink.style.display = '';
      this.terminalControls.style.display = 'inline';

      this.removeEventListeners();
      this.fontSizeSelect.addEventListener('change', this.changeFontSize);
      this.resizeHandle.addEventListener('mousedown', this.resizeStarted);
      this.resizeHandle.addEventListener('dblclick', this.resizeToMinSize);
      this.element.addEventListener('keydown', this.dispatchKeyEvent);
      this.element.addEventListener('focusin', this.focusTerminal);
      this.element.addEventListener('focusout', this.blurTerminal);
    } else {
      this.resizeHandle.style.display = 'none';
      this.showTerminalLink.style.display = '';
      this.hideTerminalLink.style.display = 'none';
      this.terminalControls.style.display = 'none';

      this.removeEventListeners();
    }
  }

  updateOnDidChangeTerminalSize(size) {
    this.terminalInfo.innerHTML = `Lines: ${size}`;
    this.terminalInfo.style.display = 'flex';

    if (this.terminalInfo.style.opacity > 0) {
      clearInterval(this.terminalInfoInterval);
      this.terminalInfoInterval = null;
    }
    this.terminalInfo.style.opacity = 1;

    if (!this.terminalInfoInterval) {
      this.terminalInfoInterval = setInterval(() => {
        if (this.terminalInfo.style.opacity > 0) {
          this.terminalInfo.style.opacity -= 0.01;
        } else {
          clearInterval(this.terminalInfoInterval);
          this.terminalInfoInterval = null;
          this.terminalInfo.style.display = 'none';
        }
      }, 14);
    }
  }

  updateOnDidChangeTerminalFontSize(currentFontSize) {
    this.fontSizeSelect.value = currentFontSize;
  }

  updateOnDidChangeIsExecuting(isExecuting) {
    if (isExecuting) {
      this.startExecutionLink.style.display = 'none';
      this.stopExecutionLink.style.display = '';
    } else {
      this.stopExecutionLink.style.display = 'none';
      if (this.activeLanguage.isExecutable()) {
        this.startExecutionLink.style.display = '';
      } else {
        this.startExecutionLink.style.display = 'none';
      }
    }
  }

  show() {
    if (!this.bottomPanel) {
      this.bottomPanel = atom.workspace.addBottomPanel({item: this});
    }
  }

  hide() {
    if (this.bottomPanel) {
      this.bottomPanel.destroy();
      this.bottomPanel = null;
    }
  }

  removeEventListeners() {
    this.fontSizeSelect.removeEventListener('change', this.changeFontSize);
    this.resizeHandle.removeEventListener('mousedown', this.resizeStarted);
    this.resizeHandle.removeEventListener('dblclick', this.resizeToMinSize);
    this.element.removeEventListener('keydown', this.dispatchKeyEvent);
    this.element.removeEventListener('focusin', this.focusTerminal);
    this.element.removeEventListener('focusout', this.blurTerminal);
  }

  dispatchKeyEvent(event) {
    const buffer = this.activeTerminal.getBuffer();
    const keystroke = atom.keymaps.keystrokeForKeyboardEvent(event);
    const keystrokeParts = keystroke === '-' ? ['-'] : keystroke.split('-');

    switch (keystrokeParts.length) {
      case 1: {
        const firstPart = keystrokeParts[0];
        switch (firstPart) {
          case 'enter':
            buffer.enterInput();
            break;
          case 'backspace':
            buffer.removeCharFromInput();
            break;
          case 'up':
            buffer.showPreviousInput();
            break;
          case 'left':
            buffer.moveInputCursorLeft();
            break;
          case 'down':
            buffer.showSubsequentInput();
            break;
          case 'right':
            buffer.moveInputCursorRight();
            break;
          case 'space':
            buffer.addStringToInput(' ');
            break;
          default:
            if (firstPart.length === 1) {
              buffer.addStringToInput(firstPart);
            }
        }
        break;
      }
      case 2:
        if (keystrokeParts[0] === 'shift') {
          const secondPart = keystrokeParts[1];
          if (secondPart.length === 1) {
            buffer.addStringToInput(secondPart);
          }
        }
        break;
      default:
    }
  }
}