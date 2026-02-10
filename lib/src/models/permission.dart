/// Permission model for plugin security.
library;

/// A permission that a plugin requests.
sealed class Permission {
  const Permission();

  /// Network access permission.
  const factory Permission.network(String domain) = NetworkPermission;

  /// File system access permission.
  const factory Permission.fileSystem(String path) = FileSystemPermission;

  /// Shell command execution permission.
  const factory Permission.shell(String command) = ShellPermission;
}

/// Permission to access a network domain.
class NetworkPermission extends Permission {
  const NetworkPermission(this.domain);

  /// Allowed domain (e.g., 'api.github.com').
  final String domain;

  @override
  String toString() => 'NetworkPermission($domain)';
}

/// Permission to access a file system path.
class FileSystemPermission extends Permission {
  const FileSystemPermission(this.path);

  /// Allowed path (supports ${workspace} variable).
  final String path;

  @override
  String toString() => 'FileSystemPermission($path)';
}

/// Permission to execute a shell command.
class ShellPermission extends Permission {
  const ShellPermission(this.command);

  /// Allowed command (e.g., 'git', 'npm').
  final String command;

  @override
  String toString() => 'ShellPermission($command)';
}
