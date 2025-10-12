part of '../_parsing.dart';

class _ExpressionParser {
  _ExpressionParser({
    required this.input,
    required _LiteralResolver literalResolver,
  })  : _tokens = _tokenizeExpression(input),
        _literalResolver = literalResolver;

  final String input;
  final List<_Token> _tokens;
  final _LiteralResolver _literalResolver;
  int _current = 0;

  _ExprValue parse() {
    final value = _expression();
    _consume(_TokenType.eof, 'Unexpected trailing tokens');
    return value;
  }

  _ExprValue _expression() {
    var value = _term();
    while (true) {
      if (_match(_TokenType.plus)) {
        final op = _previous;
        final right = _term();
        value = _combineAdd(value, right, op, true);
        continue;
      }
      if (_match(_TokenType.minus)) {
        final op = _previous;
        final right = _term();
        value = _combineAdd(value, right, op, false);
        continue;
      }
      break;
    }
    return value;
  }

  _ExprValue _term() {
    var value = _factor();
    while (true) {
      if (_match(_TokenType.star)) {
        final op = _previous;
        final right = _factor();
        value = _combineMultiply(value, right, op);
        continue;
      }
      if (_match(_TokenType.slash)) {
        final op = _previous;
        final right = _factor();
        value = _combineDivide(value, right, op);
        continue;
      }
      break;
    }
    return value;
  }

  _ExprValue _factor() {
    if (_match(_TokenType.plus)) {
      return _factor();
    }
    if (_match(_TokenType.minus)) {
      final value = _factor();
      return _ExprValue(-value.value, value.sizePower, value.timePower);
    }
    if (_match(_TokenType.leftParen)) {
      final expr = _expression();
      _consume(_TokenType.rightParen, 'Missing closing parenthesis');
      return expr;
    }
    if (_match(_TokenType.literal)) {
      return _literalResolver(_previous);
    }
    final token = _currentToken;
    throw FormatException('Unexpected token in expression', input, token.start);
  }

  bool _match(_TokenType type) {
    if (_check(type)) {
      _advance();
      return true;
    }
    return false;
  }

  bool _check(_TokenType type) {
    if (_current >= _tokens.length) return false;
    return _tokens[_current].type == type;
  }

  _Token _advance() {
    if (_current < _tokens.length) {
      _current++;
    }
    return _previous;
  }

  _Token get _previous => _tokens[_current - 1];

  _Token get _currentToken => _tokens[_current];

  _Token _consume(_TokenType type, String message) {
    if (_check(type)) return _advance();
    final token = _currentToken;
    throw FormatException(message, input, token.start);
  }

  _ExprValue _combineAdd(
    _ExprValue left,
    _ExprValue right,
    _Token op,
    bool isAddition,
  ) {
    if (left.sizePower != right.sizePower ||
        left.timePower != right.timePower) {
      final opName = isAddition ? 'add' : 'subtract';
      throw FormatException(
        'Cannot $opName values with incompatible units',
        input,
        op.start,
      );
    }
    final resultValue =
        isAddition ? left.value + right.value : left.value - right.value;
    if (resultValue.isNaN || resultValue.isInfinite) {
      throw FormatException(
          'Expression produced a non-finite result', input, op.start);
    }
    return _ExprValue(resultValue, left.sizePower, left.timePower);
  }

  _ExprValue _combineMultiply(
    _ExprValue left,
    _ExprValue right,
    _Token op,
  ) {
    final resultValue = left.value * right.value;
    if (resultValue.isNaN || resultValue.isInfinite) {
      throw FormatException(
          'Expression produced a non-finite result', input, op.start);
    }
    return _ExprValue(
      resultValue,
      left.sizePower + right.sizePower,
      left.timePower + right.timePower,
    );
  }

  _ExprValue _combineDivide(
    _ExprValue left,
    _ExprValue right,
    _Token op,
  ) {
    if (right.value == 0) {
      throw FormatException('Division by zero in expression', input, op.start);
    }
    final resultValue = left.value / right.value;
    if (resultValue.isNaN || resultValue.isInfinite) {
      throw FormatException(
          'Expression produced a non-finite result', input, op.start);
    }
    return _ExprValue(
      resultValue,
      left.sizePower - right.sizePower,
      left.timePower - right.timePower,
    );
  }
}

enum _TokenType {
  literal,
  plus,
  minus,
  star,
  slash,
  leftParen,
  rightParen,
  eof
}

class _Token {
  const _Token(this.type, this.lexeme, this.start);

  final _TokenType type;
  final String lexeme;
  final int start;
}

class _ExprValue {
  const _ExprValue(this.value, this.sizePower, this.timePower);

  final double value;
  final int sizePower;
  final int timePower;
}

List<_Token> _tokenizeExpression(String input) {
  final tokens = <_Token>[];
  var index = 0;
  while (index < input.length) {
    final ch = input[index];
    if (ch.trim().isEmpty) {
      index++;
      continue;
    }
    if (_isOperatorOrParen(ch)) {
      final type = switch (ch) {
        '+' => _TokenType.plus,
        '-' => _TokenType.minus,
        '*' => _TokenType.star,
        '/' => _TokenType.slash,
        '(' => _TokenType.leftParen,
        ')' => _TokenType.rightParen,
        _ => _TokenType.literal,
      };
      tokens.add(_Token(type, ch, index));
      index++;
      continue;
    }
    final start = index;
    while (index < input.length && !_isOperatorOrParen(input[index])) {
      index++;
    }
    final lexeme = input.substring(start, index);
    tokens.add(_Token(_TokenType.literal, lexeme, start));
  }
  tokens.add(_Token(_TokenType.eof, '', input.length));
  return tokens;
}

bool _isOperatorOrParen(String ch) {
  return ch == '+' ||
      ch == '-' ||
      ch == '*' ||
      ch == '/' ||
      ch == '(' ||
      ch == ')';
}
