USE [Olive3_Live]
GO
CREATE LOGIN walkerd WITH PASSWORD = '<password>';
GO
CREATE USER [walkerd] FOR LOGIN [walkerd] WITH DEFAULT_SCHEMA=[dbo];
GO
EXEC sp_addrolemember N'db_datareader', N'walkerd'
GO
USE [Olive3_Live]
GO
EXEC sp_addrolemember N'db_datawriter', N'walkerd'
GO
USE [Olive3_Live]
GO
EXEC sp_addrolemember N'db_ddladmin', N'walkerd'
GO
GRANT SELECT ON SCHEMA :: dbo TO walkerd;