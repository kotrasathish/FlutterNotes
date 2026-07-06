class CloudStorageException implements Exception {
  const CloudStorageException();
}

class CouldNotUpdateNoteException extends CloudStorageException {}
class CouldNotGetAllNotesException extends CloudStorageException {}
class CloudNotUpdatedException extends CloudStorageException {}
class CouldNotDeleteNoteException extends CloudStorageException {}