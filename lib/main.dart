import 'dart:convert';
import 'dart:io';
import 'package:sass_api/sass_api.dart';
import 'package:sass/sass.dart' as Sass;
import 'package:diff_match_patch/diff_match_patch.dart';
import './src/formatter_visitor.dart';

void main(List<String> arguments) async {
  final source = File(arguments[0]);

  String input;
  if (arguments.contains('--stdin')) {
    input = await stdin.transform(utf8.decoder).join();
  } else {
    input = await source.readAsString();
  }

  String? preParsed;
  if (!arguments.contains('--no-verify')) {
    preParsed = (await Sass.compileStringToResultAsync(
      input,
      syntax: Syntax.sass,
      url: 'file://' + source.absolute.path
    )).toString();
  }

  final stylesheet = Stylesheet.parse(input, Syntax.sass, url: source.path);

  final formatter = FormatterVisitor();
  final formatted = formatter.format(stylesheet);

  try {
    if (!arguments.contains('--no-verify')) {
      // validate the conversion by comparing the compiled result
      final postParsed = (await Sass.compileStringToResultAsync(
        formatted,
        syntax: Syntax.scss,
        url: 'file://' + source.absolute.path
      )).toString();
      if (preParsed != postParsed) {
        stderr.writeln('Output mismatch');
        stderr.writeln(diff(preParsed!, postParsed));
        exitCode = 1;
      }
    }
    stdout.write(formatted);
  } on SassFormatException catch (e) {
    stderr.writeln(e);
    exitCode = 1;
  }
}
