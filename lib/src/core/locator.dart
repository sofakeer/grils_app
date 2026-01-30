class ServiceLocator {
  ServiceLocator._();
  static final ServiceLocator instance = ServiceLocator._();

  final Map<Type, Object> _singletons = {};

  T get<T extends Object>() {
    final obj = _singletons[T];
    if (obj == null) throw StateError('Service of type $T not found');
    return obj as T;
  }

  void register<T extends Object>(T instance) {
    if (_singletons.containsKey(T)) {
      throw StateError('Service of type $T already registered');
    }
    _singletons[T] = instance;
  }
}

