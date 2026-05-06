import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

class PythonEngine {
  PythonEngine({this.pythonBinary = 'python3'});

  final String pythonBinary;

  Future<Map<String, dynamic>> call(String command, Map<String, dynamic> payload) async {
    final script = _resolveCliPath();

    // Process.run() is non-interactive and does not accept a `stdin:` named
    // parameter in Dart. Process.start() gives us a live Process object, so we
    // can write the JSON payload to stdin, close it, then read stdout/stderr.
    final process = await Process.start(
      pythonBinary,
      [script, command],
      runInShell: false,
    );

    process.stdin.write(jsonEncode(payload));
    await process.stdin.flush();
    await process.stdin.close();

    final stdoutFuture = utf8.decoder.bind(process.stdout).join();
    final stderrFuture = utf8.decoder.bind(process.stderr).join();

    final exitCode = await process.exitCode;
    final stdoutText = await stdoutFuture;
    final stderrText = await stderrFuture;

    if (exitCode != 0) {
      throw PythonEngineException(
        'Python engine failed ($exitCode): $stderrText',
      );
    }

    try {
      final decoded = jsonDecode(stdoutText);
      if (decoded is! Map<String, dynamic>) {
        throw const PythonEngineException('Python engine returned a non-object JSON payload.');
      }
      return decoded;
    } on FormatException catch (error) {
      throw PythonEngineException(
        'Python engine returned invalid JSON: ${error.message}\nRaw output: $stdoutText',
      );
    }
  }

  String _resolveCliPath() {
    final executableDir = p.dirname(Platform.resolvedExecutable);
    final candidates = <String>[
      p.join(Directory.current.path, 'backend', 'cli.py'),
      p.join(executableDir, 'backend', 'cli.py'),
      p.join(executableDir, '..', 'backend', 'cli.py'),
    ];

    for (final candidate in candidates) {
      if (File(candidate).existsSync()) return candidate;
    }

    // Development fallback. This gives a readable error if the project is run from an unexpected directory.
    return p.join(Directory.current.path, 'backend', 'cli.py');
  }
}

class PythonEngineException implements Exception {
  const PythonEngineException(this.message);
  final String message;

  @override
  String toString() => message;
}
