import 'package:sass_api/sass_api.dart';

class FormatterVisitor with RecursiveStatementVisitor {
  final StringBuffer _buffer = StringBuffer();
  int _indent = 0;
  int _lastLine = 0;

  String _indentStr() => '  ' * _indent;

  String format(Statement root) {
    root.accept(this);
    return _buffer.toString();
  }

  // Re-insert empty lines from the source file
  // Should be called at the top of each visitor method
  void _checkBlankLine(SassNode node) {
    if (_lastLine == 0) {
      _lastLine = node.span.start.line;
      return;
    }

    final linesBetween = node.span.start.line - _lastLine - 1;
    if (linesBetween > 0) {
      _buffer.write('\n' * linesBetween);
    }
    _lastLine = node.span.end.line;
  }

  // lastLine may be incorrect after visiting children,
  // call this at the end of each visitor method to clean up
  void _resetLastLine(SassNode node) {
    _lastLine = node.span.end.line;
  }

  void _extractComment(SassNode node) {
    var firstLine = node.span.text.split('\n').first;
    if (firstLine.contains('//')) {
      var comment = firstLine.split('//').last.trimRight();
      _buffer.writeln(' //$comment');
    }
  }

  String _excludeComment(String text) {
    if (text.contains('//')) {
      return text.split('//').first.trimRight();
    }
    return text;
  }

  // VISITOR METHODS

  // use super
  // void visitContentBlock(ContentBlock node) {}
  // void visitStylesheet(Stylesheet node) {}

  void visitAtRootRule(AtRootRule node) {
    _checkBlankLine(node);
    _buffer.write(_indentStr());
    _buffer.write('@at-root');
    if (node.query != null) {
      _buffer.write(' ');
      _buffer.write(node.query!.span.text);
    }
    if (
      node.query == null &&
      node.children.length == 1 &&
      node.children[0] is StyleRule &&
      node.children[0].span.start.line == node.span.start.line
    ) {
      // single inline selector
      _buffer.write(' ');
      visitStyleRule(node.children[0] as StyleRule, true);
    } else {
      _buffer.writeln(' {');

      _indent++;
      visitChildren(node.children);
      _indent--;

      _buffer.write(_indentStr());
      _buffer.writeln('}');
    }
    _resetLastLine(node);
  }

  void visitAtRule(AtRule node) {
    _checkBlankLine(node);
    _buffer.write(_indentStr());
    _buffer.write('@');
    _buffer.write(node.name);
    if (node.value != null) {
      _buffer.write(' ${node.value}');
    }
    if (node.children != null) {
      _buffer.write(' {');
      _extractComment(node);
      _indent++;
      super.visitAtRule(node);
      _indent--;
      _buffer.write(_indentStr());
      _buffer.writeln('}');
    } else {
      _buffer.write(';');
      _extractComment(node);
    }
    _resetLastLine(node);
  }

  void visitContentRule(ContentRule node) {
    _checkBlankLine(node);
    _buffer.write(_indentStr());
    _buffer.write('@content');
    if (node.arguments.isEmpty) {
      _buffer.write(';');
    } else {
      _buffer.write('(');
      _buffer.write(node.arguments.span.text);
      _buffer.write(');');
    }
    _extractComment(node);
    _resetLastLine(node);
  }

  void visitDebugRule(DebugRule node) {
    throw UnimplementedError('visitDebugRule');
    // _checkBlankLine(node);
    // _resetLastLine(node);
  }

  void visitDeclaration(Declaration node) {
    _checkBlankLine(node);
    _buffer.write(_indentStr());
    _buffer.write(node.name.span.text);
    if (node.value != null) {
      _buffer.write(': ');
      _buffer.write(node.value!.span.text.trim());
    }

    _buffer.write(';');
    _extractComment(node);

    _resetLastLine(node);
  }

  void visitEachRule(EachRule node) {
    _checkBlankLine(node);

    _buffer.write(_indentStr());
    _buffer.write('@each ${node.variables.map((variable) => '\$' + variable).join(', ')} in ');
    _buffer.write(node.list.span.text);
    _buffer.write(' {');
    _extractComment(node);
    _indent++;
    super.visitEachRule(node);
    _indent--;
    _buffer.write(_indentStr());
    _buffer.writeln('}');

    _resetLastLine(node);
  }

  void visitErrorRule(ErrorRule node) {
    throw UnimplementedError('visitErrorRule');
    // _checkBlankLine(node);
    // _resetLastLine(node);
  }

  void visitExtendRule(ExtendRule node) {
    _checkBlankLine(node);
    _buffer.write(_indentStr());
    _buffer.write(_excludeComment(node.span.text));
    _buffer.write(';');
    _extractComment(node);
    _resetLastLine(node);
  }

  void visitForRule(ForRule node) {
    _checkBlankLine(node);
    _buffer.write(_indentStr());
    _buffer.write('@for \$${node.variable} from ${node.from} ');
    _buffer.write(node.isExclusive ? 'to' : 'through');
    _buffer.write(' ${node.to} {');
    _extractComment(node);
    _indent++;
    super.visitForRule(node);
    _indent--;
    _buffer.write(_indentStr());
    _buffer.writeln('}');
    _resetLastLine(node);
  }

  void visitForwardRule(ForwardRule node) {
    throw UnimplementedError('visitForwardRule');
    // _checkBlankLine(node);
    // _resetLastLine(node);
  }

  void visitFunctionRule(FunctionRule node) {
    throw UnimplementedError('visitFunctionRule');
    // _checkBlankLine(node);
    // _resetLastLine(node);
  }

  void visitIfRule(IfRule node) {
    _checkBlankLine(node);
    for (var (index, clause) in node.clauses.indexed) {
      _checkBlankLine(clause.expression);
      _buffer.write(_indentStr());
      if (index == 0) {
        _buffer.write('@if ');
      } else {
        _buffer.write('@else if ');
      }
      _buffer.write(clause.expression.span.text);
      _buffer.writeln(' {');
      _indent++;
      visitChildren(clause.children);
      _indent--;
      _buffer.write(_indentStr());
      _buffer.writeln('}');
    }

    if (node.lastClause case var clause?) {
      _lastLine++;
      _buffer.write(_indentStr());
      _buffer.write('@else');
      _buffer.writeln(' {');
      _indent++;
      visitChildren(clause.children);
      _indent--;
      _buffer.write(_indentStr());
      _buffer.writeln('}');
    }
    _resetLastLine(node);
  }

  void visitImportRule(ImportRule node) {
    throw UnimplementedError('visitImportRule');
    // _checkBlankLine(node);
    // _resetLastLine(node);
  }

  void visitIncludeRule(IncludeRule node) {
    _checkBlankLine(node);
    _buffer.write(_indentStr());
    _buffer.write('@include ');
    if (node.namespace != null) {
      _buffer.write(node.namespace);
      _buffer.write('.');
    }
    _buffer.write(node.name);
    if (!node.arguments.isEmpty) {
      _buffer.write(node.arguments.span.text);
    }
    if (node.content == null) {
      _buffer.writeln(';');
    } else {
      if (!node.content!.parameters.isEmpty) {
        _buffer.write(' using ');
        _buffer.write(node.content!.parameters.span.text);
      }
      _buffer.writeln(' {');

      _indent++;
      super.visitIncludeRule(node);
      _indent--;

      _buffer.write(_indentStr());
      _buffer.writeln('}');
    }
    _resetLastLine(node);
  }

  void visitLoudComment(LoudComment node) {
    throw UnimplementedError('visitLoudComment');
    // _checkBlankLine(node);
    // _resetLastLine(node);
  }

  void visitMediaRule(MediaRule node) {
    _checkBlankLine(node);
    _buffer.write(_indentStr());
    _buffer.write('@media ');
    _buffer.write(node.query.span.text);
    _buffer.writeln(' {');

    _indent++;
    visitChildren(node.children);
    _indent--;

    _buffer.write(_indentStr());
    _buffer.writeln('}');
    _resetLastLine(node);
  }

  void visitMixinRule(MixinRule node) {
    _checkBlankLine(node);
    _buffer.write(_indentStr());
    _buffer.write('@mixin ${node.name}');
    if (!node.parameters.isEmpty) {
      _buffer.write(node.parameters.span.text);
    }
    if (!node.children.isEmpty) {
      _buffer.writeln(' {');
      _indent++;
      super.visitMixinRule(node);
      _indent--;
      _buffer.write(_indentStr());
      _buffer.writeln('}');
    }
    _resetLastLine(node);
  }

  void visitReturnRule(ReturnRule node) {
    throw UnimplementedError('visitReturnRule');
    // _checkBlankLine(node);
    // _resetLastLine(node);
  }

  void visitSilentComment(SilentComment node) {
    _checkBlankLine(node);
    _buffer.write(_indentStr());
    _buffer.writeln(node.span.text);
    _resetLastLine(node);
  }

  void visitStyleRule(StyleRule node, [bool? skipIndent]) {
    _checkBlankLine(node);

    if (skipIndent == null || !skipIndent) {
      _buffer.write(_indentStr());
    }
    if (node.selector.isPlain) {
      _buffer.write(node.selector.span.text.split('//').first.trimRight());
    } else {
      for (var item in node.selector.contents) {
        if (item is String) {
          _buffer.write(item.trimRight());
        } else if (item is Expression) {
          _buffer.write('#{');
          _buffer.write(item.span.text);
          _buffer.write('}');
        } else {
          throw UnimplementedError('Unknown selector interpolation type');
        }
      }
    }
    _buffer.write(' {');
    _extractComment(node.selector);

    _indent++;
    visitChildren(node.children);
    _indent--;

    _buffer.write(_indentStr());
    _buffer.writeln('}');
    _resetLastLine(node);
  }

  void visitSupportsRule(SupportsRule node) {
    _checkBlankLine(node);
    _buffer.write(_indentStr());
    _buffer.write('@supports ');
    _buffer.write(node.condition.span.text);
    _buffer.writeln(' {');
    _indent++;
    visitChildren(node.children);
    _indent--;
    _buffer.write(_indentStr());
    _buffer.writeln('}');
    _resetLastLine(node);
  }

  void visitUseRule(UseRule node) {
    _checkBlankLine(node);
    _buffer.write(_indentStr());
    _buffer.write(_excludeComment(node.span.text));
    _buffer.write(';');
    _extractComment(node);
    _resetLastLine(node);
  }

  void visitVariableDeclaration(VariableDeclaration node) {
    _checkBlankLine(node);
    _buffer.write(_indentStr());
    _buffer.write(_excludeComment(node.span.text));
    _buffer.write(';');
    _extractComment(node);
    _resetLastLine(node);
  }

  void visitWarnRule(WarnRule node) {
    throw UnimplementedError('visitWarnRule');
    // _checkBlankLine(node);
    // _resetLastLine(node);
  }

  void visitWhileRule(WhileRule node) {
    throw UnimplementedError('visitWhileRule');
    // _checkBlankLine(node);
    // _resetLastLine(node);
  }
}
