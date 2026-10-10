/// A handle returned by listener registrations such as
/// `workspace.onDidSaveTextDocument`.
///
/// Call [dispose] to stop receiving events. Disposing twice is a no-op.
abstract interface class LumideDisposable {
  /// Creates a disposable that runs [onDispose] once.
  factory LumideDisposable(void Function() onDispose) = _CallbackDisposable;

  /// Stops the registration.
  void dispose();
}

class _CallbackDisposable implements LumideDisposable {
  _CallbackDisposable(this._onDispose);

  void Function()? _onDispose;

  @override
  void dispose() {
    final onDispose = _onDispose;
    _onDispose = null;
    onDispose?.call();
  }
}

/// Adds [callback] to [callbacks] and returns a handle that removes it.
LumideDisposable addListener<T>(List<T> callbacks, T callback) {
  callbacks.add(callback);
  return LumideDisposable(() => callbacks.remove(callback));
}
