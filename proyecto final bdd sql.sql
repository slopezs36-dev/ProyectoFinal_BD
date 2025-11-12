-- =============================================
-- PROYECTO FINAL - BASE DE DATOS DEMO_ACADEMIA
-- SCRIPT CORREGIDO PARA SQL SERVER MANAGEMENT
-- =============================================

-- 🔹 Usar la base de datos
USE Demo_Academia;
GO

-- =============================================
-- 🔹 VISTAS CON SCHEMABINDING CORREGIDAS
-- =============================================

-- Vista: Resumen de alumnos y sus promedios
IF OBJECT_ID('Academia.vw_ResumenAlumno','V') IS NOT NULL
    DROP VIEW Academia.vw_ResumenAlumno;
GO
CREATE VIEW Academia.vw_ResumenAlumno
WITH SCHEMABINDING
AS
SELECT
    a.AlumnoID,
    a.Nombre,
    a.Apellido,
    COUNT_BIG(*) AS TotalCalificaciones,
    AVG(CONVERT(DECIMAL(10,2), c.Nota)) AS PromedioNotas,
    SUM(CONVERT(BIGINT, a.Creditos)) AS SumaCreditos
FROM Academia.Alumnos AS a
LEFT JOIN Academia.Calificaciones AS c
    ON a.AlumnoID = c.AlumnoID
GROUP BY a.AlumnoID, a.Nombre, a.Apellido;
GO


-- Vista: Promedio por curso y periodo
IF OBJECT_ID('Academia.vw_PromedioCursoPeriodo','V') IS NOT NULL
    DROP VIEW Academia.vw_PromedioCursoPeriodo;
GO
CREATE VIEW Academia.vw_PromedioCursoPeriodo
WITH SCHEMABINDING
AS
SELECT
    c.Curso,
    c.Periodo,
    COUNT_BIG(*) AS CantNotas,
    AVG(CONVERT(DECIMAL(10,2), c.Nota)) AS PromedioNota
FROM Academia.Calificaciones AS c
GROUP BY c.Curso, c.Periodo;
GO


-- Vista: Notas en formato PIVOT
IF OBJECT_ID('Academia.vw_NotasPivotExample','V') IS NOT NULL
    DROP VIEW Academia.vw_NotasPivotExample;
GO
CREATE VIEW Academia.vw_NotasPivotExample
WITH SCHEMABINDING
AS
SELECT p.AlumnoID, p.[Matematica I], p.[Programacion I], p.[Economia], p.[Matematica II]
FROM
(
    SELECT AlumnoID, Curso, Nota
    FROM Academia.Calificaciones
) AS src
PIVOT
(
    MAX(Nota) FOR Curso IN ([Matematica I], [Programacion I], [Economia], [Matematica II])
) AS p;
GO


-- Vista: Ranking de promedio por carrera
IF OBJECT_ID('Academia.vw_RankPromedioPorCarrera','V') IS NOT NULL
    DROP VIEW Academia.vw_RankPromedioPorCarrera;
GO
CREATE VIEW Academia.vw_RankPromedioPorCarrera
WITH SCHEMABINDING
AS
SELECT
    a.AlumnoID,
    a.Nombre,
    a.Apellido,
    a.Carrera,
    AVG(CONVERT(DECIMAL(10,2), c.Nota)) OVER (PARTITION BY a.AlumnoID) AS Promedio,
    ROW_NUMBER() OVER (PARTITION BY a.Carrera ORDER BY AVG(CONVERT(DECIMAL(10,2), c.Nota)) DESC) AS RankEnCarrera
FROM Academia.Alumnos AS a
LEFT JOIN Academia.Calificaciones AS c
    ON a.AlumnoID = c.AlumnoID
GROUP BY a.AlumnoID, a.Nombre, a.Apellido, a.Carrera;
GO


-- =============================================
-- 🔹 FUNCIÓN PARA RLS (SEGURIDAD)
-- =============================================
IF OBJECT_ID('Seguridad.fn_predicado_alumno','FN') IS NOT NULL
    DROP FUNCTION Seguridad.fn_predicado_alumno;
GO
CREATE FUNCTION Seguridad.fn_predicado_alumno(@AlumnoID INT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
(
    SELECT 1 AS fn_result
    FROM Academia.Alumnos AS a
    JOIN Seguridad.AlumnoUsuarios AS au ON a.AlumnoID = au.AlumnoID
    WHERE a.AlumnoID = @AlumnoID
      AND au.DbUserName = USER_NAME()
);
GO


-- =============================================
-- 🔹 CONSULTAS DE PRUEBA
-- =============================================

-- Vistas
SELECT * FROM Academia.vw_ResumenAlumno;
SELECT * FROM Academia.vw_PromedioCursoPeriodo;
SELECT * FROM Academia.vw_NotasPivotExample;
SELECT * FROM Academia.vw_RankPromedioPorCarrera;

-- Función de seguridad y SP
EXEC Seguridad.sp_IniciarSesionAlumno @AlumnoID = 1000;
EXEC Seguridad.sp_CerrarSesionAlumno @AlumnoID = 1000;

-- Auditorías y backups
SELECT * FROM Seguridad.AuditoriaAccesos;
SELECT TOP(50) * FROM Seguridad.RegistroBackups ORDER BY FechaHora DESC;
GO
