CREATE OR ALTER PROCEDURE dbo.usp_Logs_InsertActivityLog
    @UserId UNIQUEIDENTIFIER = NULL,
    @ActivityType NVARCHAR(100),
    @Description NVARCHAR(1000),
    @Source NVARCHAR(100) = NULL,
    @ReferenceId NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.ActivityLogs
    (
        UserId,
        ActivityType,
        Description,
        Source,
        ReferenceId,
        CreatedOn
    )
    VALUES
    (
        @UserId,
        @ActivityType,
        @Description,
        @Source,
        @ReferenceId,
        SYSUTCDATETIME()
    );
END;
