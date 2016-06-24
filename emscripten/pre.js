(function (root, factory) {
  if (typeof define === 'function' && define.amd) {
    define('was-cli', ['exports'], factory);
  } else if (typeof exports !== 'undefined') {
    factory(exports);
  } else {
    factory((root.wasCLI = {}));
  }
}(this, function (exports) {

  function runWAS(text) {
    var Module = {
      arguments: ['--print', '--infer-types', 't.was', '--output', 't.wast'],
      preRun: [
        function () {
          FS.writeFile('t.was', text)
        }
      ],
      print: function (text) { },
      printErr: function (text) {
        errorLog.push(text);
      },
    };
    var errorLog = [];
