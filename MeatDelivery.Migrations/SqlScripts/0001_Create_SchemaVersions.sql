IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'SchemaVersions')
BEGIN
    CREATE TABLE dbo.SchemaVersions
    (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        ScriptName NVARCHAR(255) NOT NULL UNIQUE,
        AppliedOn DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        AppliedBy NVARCHAR(100) NULL,
        Remarks NVARCHAR(500) NULL
    );
END