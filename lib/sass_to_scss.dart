import 'dart:io';
import 'package:sass_api/sass_api.dart';
import 'src/formatter_visitor.dart';

void main(List<String> arguments) async {
  var source = File(arguments[0]);
  var stylesheet = Stylesheet.parse(await source.readAsString(), Syntax.sass, url: source.path);

  var formatter = FormatterVisitor();
  var formatted = formatter.format(stylesheet);
  print(formatted);

  // validate the conversion by trying to parse the result
  try {
    Stylesheet.parse(formatted, Syntax.scss, url: source.path.replaceAll('.sass', '.scss (output)'));
  } on SassFormatException catch (e) {
    print(e);
  }
}
