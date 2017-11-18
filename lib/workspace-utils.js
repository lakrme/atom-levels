'use babel';

import {Point}          from 'atom';
import path             from 'path';
import languageRegistry from './language-registry';

export const DEFAULT_WHEN_TO_WRITE_FILE_HEADER = 'before saving the buffer';
export const DEFAULT_CLEAR_TERMINAL_ON_EXECUTION = true;
export const FILE_HEADER_PATTERN = 'Language: <languageName>, Level: <levelName>';
export const FILE_HEADER_REG_EXP = /Language:\s+(.+),\s+Level:\s+(.+)/;

export function writeLanguageInformationFileHeader(textEditor, language, level) {
  let fileHeader = FILE_HEADER_PATTERN.replace(/<languageName>/, language.getName()).replace(/<levelName>/, level.getName());

  const lineCommentPattern = language.getLineCommentPattern();
  if (lineCommentPattern && lineCommentPattern.includes('<comment>')) {
    fileHeader = lineCommentPattern.replace(/<comment>/, fileHeader);
    textEditor.getBuffer().insert(new Point(0, 0), `${fileHeader}\n`);
  }
}

export function deleteLanguageInformationFileHeader(textEditor) {
  const textBuffer = textEditor.getBuffer();
  if (FILE_HEADER_REG_EXP.exec(textBuffer.lineForRow(0))) {
    textBuffer.deleteRow(0);
  }
}

export function readLanguageInformationFromTextEditor(textEditor) {
  const result = readLanguageInformationFromFileHeader(textEditor);
  let language = result ? result.language : undefined;
  const level = result ? result.level : undefined;

  if (!language) {
    language = readLanguageFromFileExtension(textEditor);
    if (!language) {
      language = languageRegistry.getLanguageForGrammar(textEditor.getGrammar());
    }
  }

  if (language) {
    return {language, level};
  }
}

export function readLanguageInformationFromFileHeader(textEditor) {
  const match = FILE_HEADER_REG_EXP.exec(textEditor.getBuffer().lineForRow(0));
  if (match) {
    const languageName = match[1];
    const levelName = match[2];

    const language = languageRegistry.getLanguageForName(languageName);
    if (language) {
      const result = {language};
      const level = language.getLevelForName(levelName);
      if (level) {
        result.level = level;
      }
      return result;
    }
  }
}

export function readLanguageFromFileExtension(textEditor) {
  const filePath = textEditor.getPath();
  if (filePath) {
    const fileType = path.extname(filePath).substr(1);
    return languageRegistry.getLanguagesForFileType(fileType)[0];
  }
}