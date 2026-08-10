CREATE OR ALTER PROCEDURE dbo.usp_Auth_GetUserContext
    @UserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        u.UserId,
        u.UserName,
        u.Email,
        CONCAT(u.FirstName,
               CASE WHEN u.LastName IS NULL THEN '' ELSE ' ' + u.LastName END) AS FullName,
        ur.RoleId,
        r.RoleName
    FROM dbo.Users u
    INNER JOIN dbo.UserRoles ur
        ON u.UserId = ur.UserId
    INNER JOIN dbo.Roles r
        ON ur.RoleId = r.RoleId
    WHERE u.UserId = @UserId
      AND u.IsActive = 1;
END;