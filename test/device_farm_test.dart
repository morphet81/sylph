import 'package:fake_process_manager/fake_process_manager.dart';
import 'package:process/process.dart';
import 'package:sylph/src/device_farm.dart';
import 'package:test/test.dart';
import 'package:tool_base/tool_base.dart';
import 'package:tool_base_test/tool_base_test.dart';

main() {
  group('device farm', () {
    FakeProcessManager fakeProcessManager;

    setUp(() async {
      fakeProcessManager = FakeProcessManager();
    });

    testUsingContext('setup project', () {
      final projectName = 'project name';
      final jobTimeoutMinutes = 10;
      final projectArn =
          'arn:aws:devicefarm:us-west-2:122621792560:project:9796b48e-ad3d-4b3c-97a6-94d4e50b1792';
      fakeProcessManager.calls = [
        Call('aws devicefarm list-projects',
            ProcessResult(0, 0, '{"projects":[]}', '')),
        Call(
            'aws devicefarm create-project --name $projectName --default-job-timeout-minutes $jobTimeoutMinutes',
            ProcessResult(
                0,
                0,
                '{"project": {"arn": "$projectArn","name": "$projectName","defaultJobTimeoutMinutes": $jobTimeoutMinutes,"created": 1567902055.614}}',
                '')),
      ];
      final result = setupProject(projectName, jobTimeoutMinutes);
      expect(result, equals(projectArn));
      fakeProcessManager.verifyCalls();
    }, overrides: <Type, Generator>{
      ProcessManager: () => fakeProcessManager,
//      Logger: () => VerboseLogger(StdoutLogger()),
    });

    testUsingContext('setup device pool', () {
      final projectName = 'project name';
      final jobTimeoutMinutes = 10;
      final projectArn =
          'arn:aws:devicefarm:us-west-2:122621792560:project:9796b48e-ad3d-4b3c-97a6-94d4e50b1792';
      fakeProcessManager.calls = [
        Call('aws devicefarm list-projects',
            ProcessResult(0, 0, '{"projects":[]}', '')),
        Call(
            'aws devicefarm create-project --name $projectName --default-job-timeout-minutes $jobTimeoutMinutes',
            ProcessResult(
                0,
                0,
                jsonEncode({
                  "project": {
                    "arn": "$projectArn",
                    "name": "$projectName",
                    "defaultJobTimeoutMinutes": jobTimeoutMinutes,
                    "created": 1567902055.614
                  }
                }),
                '')),
      ];
      final devicePoolInfo = {};
//      final result = setupDevicePool(devicePoolInfo, projectArn);
//      expect(result, equals(projectArn));
//      fakeProcessManager.verifyCalls();
    }, skip: true, overrides: <Type, Generator>{
      ProcessManager: () => fakeProcessManager,
//      Logger: () => VerboseLogger(StdoutLogger()),
    });
  });
}
