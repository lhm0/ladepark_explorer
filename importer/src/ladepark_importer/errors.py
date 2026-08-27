class ImporterError(Exception):
    """Base class for controlled importer failures."""


class SourceFormatError(ImporterError):
    """The source file cannot be parsed."""


class SchemaError(ImporterError):
    """The source schema violates the documented contract."""


class DataValidationError(ImporterError):
    """A source row contains an invalid required value."""
