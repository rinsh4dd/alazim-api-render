CREATE OR ALTER PROCEDURE dbo.usp_Auth_CreateUser
    @Username NVARCHAR(100),
    @Email NVARCHAR(255),
    @PasswordHash NVARCHAR(MAX),
    @FirstName NVARCHAR(100),
    @LastName NVARCHAR(100) = NULL,
    @PhoneNumber NVARCHAR(20) = NULL,
    @RoleId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @NewUserId UNIQUEIDENTIFIER = NEWID();

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO dbo.Users
        (
            UserId,
            UserName,
            Email,
            PasswordHash,
            FirstName,
            LastName,
            PhoneNumber,
            IsActive,
            IsLocked,
            FailedLoginAttempts,
            CreatedOn
        )
        VALUES
        (
            @NewUserId,
            @Username,
            @Email,
            @PasswordHash,
            @FirstName,
            @LastName,
            @PhoneNumber,
            1,
            0,
            0,
            SYSUTCDATETIME()
        );

        INSERT INTO dbo.UserRoles
        (
            UserId,
            RoleId
        )
        VALUES
        (
            @NewUserId,
            @RoleId
        );

        COMMIT TRANSACTION;

        SELECT @NewUserId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END;
