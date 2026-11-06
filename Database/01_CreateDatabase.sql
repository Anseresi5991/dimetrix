/* =====================================================================
   DistriMax - 01 Creación de la base de datos
   Ejecutar conectado a (localdb)\MSSQLLocalDB o .\SQLEXPRESS
   ¡OJO! Borra la base si ya existe.
   ===================================================================== */
USE master;
GO

IF DB_ID('DistriMaxDB') IS NOT NULL
BEGIN
    ALTER DATABASE DistriMaxDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DistriMaxDB;
END
GO

CREATE DATABASE DistriMaxDB COLLATE Modern_Spanish_CI_AS;
GO

PRINT 'Base de datos DistriMaxDB creada';
GO
