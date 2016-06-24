
    var result = FS.readFile('t.wast', {encoding: 'utf8'});
    if (!result)
      throw new Error('WAS conversion error:\n' + errorLog.join('\n'));
    return result;
  }

  exports.runWAS = runWAS;
}));
