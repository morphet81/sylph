import 'dart:async';
import 'dart:convert';

//import 'dart:io';

import 'package:tool_base/tool_base.dart';
import 'package:yaml/yaml.dart';

import 'devices.dart';

/// Parses a named yaml file.
/// Returns as [Map].
Map parseYamlFile(String yamlPath) =>
    jsonDecode(jsonEncode(loadYaml(fs.file(yamlPath).readAsStringSync())));

/// Parse a yaml string.
/// Returns as [Map].
Map parseYamlStr(String yamlString) =>
    jsonDecode(jsonEncode(loadYaml(yamlString)));

/// Clears a named directory.
/// Creates directory if none exists.
void clearDirectory(String dir) {
  if (fs.directory(dir).existsSync()) {
    fs.directory(dir).deleteSync(recursive: true);
  }
  fs.directory(dir).createSync(recursive: true);
}

/// Writes a file image to a path on disk.
Future<void> writeFileImage(List<int> fileImage, String path) async {
  final file = await fs.file(path).create(recursive: true);
  await file.writeAsBytes(fileImage, flush: true);
}

/// Executes a command with arguments in a separate process.
/// If [silent] is false, outputs to stdout when command completes.
/// Returns stdout as [String].
String cmd(List<String> cmd,
    {String workingDirectory = '.', bool silent = true}) {
  final result = processManager.runSync(cmd,
      workingDirectory: workingDirectory, runInShell: true);
  traceCommand(cmd, workingDirectory: workingDirectory);
  if (!silent) printStatus(result.stdout);
  if (result.exitCode != 0) {
    printError(result.stderr);
    throw 'command failed: exitcode=${result.exitCode}, cmd=\'${cmd.join(" ")}\', workingDir=$workingDirectory';
  }
  return result.stdout;
}

/// Execute command [cmd] with arguments [arguments] in a separate process
/// and stream stdout/stderr.
Future<void> streamCmd(
  List<String> cmd, {
  String workingDirectory = '.',
  ProcessStartMode mode = ProcessStartMode.normal,
}) async {
  if (mode == ProcessStartMode.normal) {
    int exitCode = await runCommandAndStreamOutput(cmd,
        workingDirectory: workingDirectory);
    if (exitCode != 0 && mode == ProcessStartMode.normal) {
      throw 'command failed: exitcode=$exitCode, cmd=\'${cmd.join(" ")}\', workingDirectory=$workingDirectory, mode=$mode';
    }
  } else {
//    final process = await runDetached(cmd);
//    exitCode = await process.exitCode;
    unawaited(runDetached(cmd));
  }
}

/// Trace a command.
void traceCommand(List<String> args, {String workingDirectory}) {
  final String argsText = args.join(' ');
  if (workingDirectory == null) {
    printTrace('executing: $argsText');
  } else {
    printTrace('executing: [$workingDirectory${fs.path.separator}] $argsText');
  }
}

/// Runs a device farm command.
/// Returns as [Map].
Map deviceFarmCmd(List<String> arguments, [String workingDir = '.']) {
  return jsonDecode(cmd(['aws', 'devicefarm']..addAll(arguments),
      workingDirectory: workingDir));
}

/// Gets device pool from config file.
/// Returns as [Map].
Map getDevicePoolInfo(List devicePools, String poolName) {
  return devicePools.firstWhere((pool) => pool['pool_name'] == poolName,
      orElse: () => throw 'Error: device pool $poolName not found');
}

/// Converts [enum] value to [String].
String enumToStr(dynamic _enum) => _enum.toString().split('.').last;

/// Converts [String] to [enum].
T stringToEnum<T>(List<T> values, String value) {
  return values.firstWhere((type) => enumToStr(type) == value,
      orElse: () =>
          throw 'Fatal: \'$value\' not found in ${values.toString()}');
}

/// generates a download directory path for each Device Farm run's artifacts
String runArtifactsDirPath(String downloadDirPrefix, String sylphRunName,
    String projectName, String poolName) {
  final downloadDir = '$downloadDirPrefix/' +
      '$sylphRunName/$projectName/$poolName'.replaceAll(' ', '_');
  return downloadDir;
}

/// generates a download directory path for each Device Farm run job's artifacts
String jobArtifactsDirPath(String runArtifactDir, SylphDevice sylphDevice) {
  final downloadDir = '$runArtifactDir/' +
      '${sylphDevice.name}-${sylphDevice.model}-${sylphDevice.os}'
          .replaceAll(' ', '_');
  return downloadDir;
}

/// Formats a list of ARNs for Device Farm API
/// Returns a formatted [String]
String formatArns(List arns) {
  String formatted = '';
  for (final arn in arns) {
    formatted += '\\"$arn\\",';
  }
  // remove last char
  return formatted.substring(0, formatted.length - 1);
}
