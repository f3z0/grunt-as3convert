/*
 * grunt-contrib-cssmin
 * http://gruntjs.com/
 *
 * Copyright (c) 2014 Tim Branyen, contributors
 * Licensed under the MIT license.
 */

'use strict';

var chalk = require('chalk');
var p = require('../ecmascript.js');
var printer = require('../print.js')

module.exports = function(grunt) {
  grunt.registerMultiTask('as3convert',  'AS3 Convert', function() {
    var options = this.options({
    });

    this.files.forEach(function(file) {
      var valid = file.src.filter(function(filepath) {
        // Warn on and remove invalid source files (if nonull was set).
        if (!grunt.file.exists(filepath)) {
          grunt.log.warn('Source file ' + chalk.cyan(filepath) + ' not found.');
          return false;
        } else {
          return true;
        }
      });
      console.log(file)

      var as3 = "";

      var js = valid.map(function(file) {
        var src = grunt.file.read(file);
        as3 += src;

        var program = p.parse(src);
        printer.print(p.parser);
        return program.print("", "  ");

      }).join('');
console.log('js ' + js)

      if (as3.length === 0) {
        return grunt.log.warn('Destination not written because converted AS3 was empty.');
      }

      if (options.banner) {
        as3 = options.banner + grunt.util.linefeed + as3;
      }

      grunt.file.write(file.dest, js);

      grunt.log.writeln('File ' + chalk.cyan(file.dest) + ' created.');
    });
  });
};
