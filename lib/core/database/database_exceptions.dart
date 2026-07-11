const String databaseAlreadyOpenMessage =
    'Zenno is already open in another tab. Close that tab, then reload.';

bool isDatabaseAlreadyOpenError(Object error) =>
    error is StateError && error.message == databaseAlreadyOpenMessage;
