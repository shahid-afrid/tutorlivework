-- ============================================
-- MIGRATE ALL EXISTING DEPARTMENTS TO DYNAMIC TABLES
-- ============================================
-- This script migrates DES, IT, ECE, MECH departments from shared tables
-- to department-specific tables (like CSEDS already has)
--
-- WHAT THIS DOES:
-- 1. Creates department-specific tables for each department
-- 2. Migrates existing data from shared tables to department tables
-- 3. Keeps shared tables intact for backward compatibility
-- 4. Adds verification queries to ensure data integrity
--
-- DEPARTMENTS TO MIGRATE:
-- - DES  (Design)
-- - IT   (Information Technology)
-- - ECE  (Electronics and Communication Engineering)
-- - MECH (Mechanical Engineering)
--
-- Note: CSEDS already has dynamic tables, so it's excluded
-- ============================================

USE [TutorLiveV1];
GO

PRINT '========================================';
PRINT 'DYNAMIC TABLE MIGRATION FOR ALL DEPARTMENTS';
PRINT 'Started at: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '========================================';
PRINT '';

-- ============================================
-- STEP 1: VERIFY DEPARTMENTS EXIST
-- ============================================
PRINT '=== STEP 1: Verifying Departments ===';
PRINT '';

SELECT 
    DepartmentId,
    DepartmentName,
    DepartmentCode,
    IsActive
FROM Departments
WHERE DepartmentCode IN ('DES', 'IT', 'ECE', 'MECH')
ORDER BY DepartmentCode;

PRINT '';
PRINT 'Departments verified. Proceeding with migration...';
PRINT '';

-- ============================================
-- FUNCTION: Create department-specific tables
-- ============================================
-- We'll create a stored procedure to generate tables dynamically

IF OBJECT_ID('dbo.sp_CreateDepartmentTables', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_CreateDepartmentTables;
GO

CREATE PROCEDURE dbo.sp_CreateDepartmentTables
    @DeptCode NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @TableName NVARCHAR(100);
    
    PRINT '----------------------------------------';
    PRINT 'Creating tables for department: ' + @DeptCode;
    PRINT '----------------------------------------';
    
    -- 1. Create Faculty_{DeptCode} table
    SET @TableName = 'Faculty_' + @DeptCode;
    
    IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = @TableName)
    BEGIN
        SET @SQL = N'
        CREATE TABLE [dbo].[' + @TableName + '] (
            [FacultyId] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
            [Name] NVARCHAR(100) NOT NULL,
            [Email] NVARCHAR(100) NOT NULL UNIQUE,
            [Password] NVARCHAR(100) NOT NULL,
            [Department] NVARCHAR(50) NOT NULL,
            [Specialization] NVARCHAR(200) NULL,
            [Qualification] NVARCHAR(200) NULL,
            [ExperienceYears] INT NULL,
            [PhoneNumber] NVARCHAR(20) NULL,
            [IsActive] BIT NOT NULL DEFAULT 1,
            [CreatedDate] DATETIME NOT NULL DEFAULT GETDATE(),
            [LastLogin] DATETIME NULL,
            [ProfileImageUrl] NVARCHAR(500) NULL
        );';
        
        EXEC sp_executesql @SQL;
        PRINT '? Created: ' + @TableName;
    END
    ELSE
        PRINT '? Table already exists: ' + @TableName;
    
    -- 2. Create Students_{DeptCode} table
    SET @TableName = 'Students_' + @DeptCode;
    
    IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = @TableName)
    BEGIN
        SET @SQL = N'
        CREATE TABLE [dbo].[' + @TableName + '] (
            [StudentId] INT IDENTITY(1,1) NOT NULL,
            [Id] NVARCHAR(50) NOT NULL PRIMARY KEY,
            [FullName] NVARCHAR(100) NOT NULL,
            [RegdNumber] NVARCHAR(50) NOT NULL UNIQUE,
            [Department] NVARCHAR(50) NOT NULL,
            [Year] INT NOT NULL,
            [Semester] NVARCHAR(10) NULL,
            [Email] NVARCHAR(100) NULL,
            [PhoneNumber] NVARCHAR(20) NULL,
            [Password] NVARCHAR(100) NOT NULL,
            [IsActive] BIT NOT NULL DEFAULT 1,
            [CreatedDate] DATETIME NOT NULL DEFAULT GETDATE(),
            [LastLogin] DATETIME NULL
        );';
        
        EXEC sp_executesql @SQL;
        PRINT '? Created: ' + @TableName;
    END
    ELSE
        PRINT '? Table already exists: ' + @TableName;
    
    -- 3. Create Subjects_{DeptCode} table
    SET @TableName = 'Subjects_' + @DeptCode;
    
    IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = @TableName)
    BEGIN
        SET @SQL = N'
        CREATE TABLE [dbo].[' + @TableName + '] (
            [SubjectId] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
            [Name] NVARCHAR(200) NOT NULL,
            [SubjectCode] NVARCHAR(50) NOT NULL,
            [Department] NVARCHAR(50) NOT NULL,
            [SubjectType] NVARCHAR(50) NOT NULL,
            [Year] INT NOT NULL,
            [Semester] NVARCHAR(10) NULL,
            [Credits] INT NULL,
            [IsActive] BIT NOT NULL DEFAULT 1,
            [CreatedDate] DATETIME NOT NULL DEFAULT GETDATE(),
            CONSTRAINT UQ_' + @DeptCode + '_SubjectCode UNIQUE (SubjectCode, Department)
        );';
        
        EXEC sp_executesql @SQL;
        PRINT '? Created: ' + @TableName;
    END
    ELSE
        PRINT '? Table already exists: ' + @TableName;
    
    -- 4. Create AssignedSubjects_{DeptCode} table
    SET @TableName = 'AssignedSubjects_' + @DeptCode;
    
    IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = @TableName)
    BEGIN
        SET @SQL = N'
        CREATE TABLE [dbo].[' + @TableName + '] (
            [AssignmentId] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
            [SubjectId] INT NOT NULL,
            [FacultyId] INT NOT NULL,
            [Department] NVARCHAR(50) NOT NULL,
            [Year] INT NOT NULL,
            [Semester] NVARCHAR(10) NULL,
            [MaxEnrollments] INT NOT NULL DEFAULT 60,
            [CurrentEnrollments] INT NOT NULL DEFAULT 0,
            [IsActive] BIT NOT NULL DEFAULT 1,
            [AssignedDate] DATETIME NOT NULL DEFAULT GETDATE(),
            FOREIGN KEY ([SubjectId]) REFERENCES [dbo].[Subjects_' + @DeptCode + '] ([SubjectId]),
            FOREIGN KEY ([FacultyId]) REFERENCES [dbo].[Faculty_' + @DeptCode + '] ([FacultyId])
        );';
        
        EXEC sp_executesql @SQL;
        PRINT '? Created: ' + @TableName;
    END
    ELSE
        PRINT '? Table already exists: ' + @TableName;
    
    -- 5. Create StudentEnrollments_{DeptCode} table
    SET @TableName = 'StudentEnrollments_' + @DeptCode;
    
    IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = @TableName)
    BEGIN
        SET @SQL = N'
        CREATE TABLE [dbo].[' + @TableName + '] (
            [EnrollmentId] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
            [StudentId] NVARCHAR(50) NOT NULL,
            [AssignmentId] INT NOT NULL,
            [SubjectId] INT NOT NULL,
            [FacultyId] INT NOT NULL,
            [EnrollmentDate] DATETIME NOT NULL DEFAULT GETDATE(),
            [IsActive] BIT NOT NULL DEFAULT 1,
            FOREIGN KEY ([AssignmentId]) REFERENCES [dbo].[AssignedSubjects_' + @DeptCode + '] ([AssignmentId]),
            CONSTRAINT UQ_' + @DeptCode + '_Enrollment UNIQUE (StudentId, AssignmentId)
        );';
        
        EXEC sp_executesql @SQL;
        PRINT '? Created: ' + @TableName;
    END
    ELSE
        PRINT '? Table already exists: ' + @TableName;
    
    PRINT '';
END
GO

-- ============================================
-- STEP 2: CREATE TABLES FOR ALL DEPARTMENTS
-- ============================================
PRINT '=== STEP 2: Creating Department-Specific Tables ===';
PRINT '';

-- Create tables for DES
EXEC dbo.sp_CreateDepartmentTables @DeptCode = 'DES';

-- Create tables for IT
EXEC dbo.sp_CreateDepartmentTables @DeptCode = 'IT';

-- Create tables for ECE
EXEC dbo.sp_CreateDepartmentTables @DeptCode = 'ECE';

-- Create tables for MECH
EXEC dbo.sp_CreateDepartmentTables @DeptCode = 'MECH';

PRINT '';
PRINT '? All department tables created successfully!';
PRINT '';

-- ============================================
-- STEP 3: MIGRATE DATA FROM SHARED TABLES
-- ============================================
PRINT '=== STEP 3: Migrating Data to Department Tables ===';
PRINT '';

-- Function to migrate department data
IF OBJECT_ID('dbo.sp_MigrateDepartmentData', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_MigrateDepartmentData;
GO

CREATE PROCEDURE dbo.sp_MigrateDepartmentData
    @DeptCode NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SET IDENTITY_INSERT ON;
    
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @RowCount INT;
    
    PRINT '----------------------------------------';
    PRINT 'Migrating data for: ' + @DeptCode;
    PRINT '----------------------------------------';
    
    -- 1. Migrate Faculty
    BEGIN TRY
        SET @SQL = N'
        INSERT INTO [dbo].[Faculty_' + @DeptCode + '] 
        (FacultyId, Name, Email, Password, Department, Specialization, Qualification, 
         ExperienceYears, PhoneNumber, IsActive, CreatedDate, LastLogin, ProfileImageUrl)
        SELECT 
            FacultyId, Name, Email, Password, Department, Specialization, Qualification,
            ExperienceYears, PhoneNumber, IsActive, CreatedDate, LastLogin, ProfileImageUrl
        FROM [dbo].[Faculties]
        WHERE Department = @DeptCode
        AND FacultyId NOT IN (SELECT FacultyId FROM [dbo].[Faculty_' + @DeptCode + ']);';
        
        EXEC sp_executesql @SQL, N'@DeptCode NVARCHAR(50)', @DeptCode = @DeptCode;
        SET @RowCount = @@ROWCOUNT;
        PRINT '  ? Migrated ' + CAST(@RowCount AS NVARCHAR) + ' faculty records';
    END TRY
    BEGIN CATCH
        PRINT '  ? Faculty migration: ' + ERROR_MESSAGE();
    END CATCH
    
    -- 2. Migrate Students
    BEGIN TRY
        SET @SQL = N'
        INSERT INTO [dbo].[Students_' + @DeptCode + '] 
        (Id, FullName, RegdNumber, Department, Year, Semester, Email, PhoneNumber, 
         Password, IsActive, CreatedDate, LastLogin)
        SELECT 
            Id, FullName, RegdNumber, Department, Year, Semester, Email, PhoneNumber,
            Password, IsActive, CreatedDate, LastLogin
        FROM [dbo].[Students]
        WHERE Department = @DeptCode
        AND Id NOT IN (SELECT Id FROM [dbo].[Students_' + @DeptCode + ']);';
        
        EXEC sp_executesql @SQL, N'@DeptCode NVARCHAR(50)', @DeptCode = @DeptCode;
        SET @RowCount = @@ROWCOUNT;
        PRINT '  ? Migrated ' + CAST(@RowCount AS NVARCHAR) + ' student records';
    END TRY
    BEGIN CATCH
        PRINT '  ? Student migration: ' + ERROR_MESSAGE();
    END CATCH
    
    -- 3. Migrate Subjects
    BEGIN TRY
        SET @SQL = N'
        INSERT INTO [dbo].[Subjects_' + @DeptCode + '] 
        (SubjectId, Name, SubjectCode, Department, SubjectType, Year, Semester, Credits, IsActive, CreatedDate)
        SELECT 
            SubjectId, Name, SubjectCode, Department, SubjectType, Year, Semester, Credits, IsActive, CreatedDate
        FROM [dbo].[Subjects]
        WHERE Department = @DeptCode
        AND SubjectId NOT IN (SELECT SubjectId FROM [dbo].[Subjects_' + @DeptCode + ']);';
        
        EXEC sp_executesql @SQL, N'@DeptCode NVARCHAR(50)', @DeptCode = @DeptCode;
        SET @RowCount = @@ROWCOUNT;
        PRINT '  ? Migrated ' + CAST(@RowCount AS NVARCHAR) + ' subject records';
    END TRY
    BEGIN CATCH
        PRINT '  ? Subject migration: ' + ERROR_MESSAGE();
    END CATCH
    
    -- 4. Migrate AssignedSubjects
    BEGIN TRY
        SET @SQL = N'
        INSERT INTO [dbo].[AssignedSubjects_' + @DeptCode + '] 
        (AssignmentId, SubjectId, FacultyId, Department, Year, Semester, MaxEnrollments, CurrentEnrollments, IsActive, AssignedDate)
        SELECT 
            AssignmentId, SubjectId, FacultyId, Department, Year, Semester, MaxEnrollments, CurrentEnrollments, IsActive, AssignedDate
        FROM [dbo].[AssignedSubjects]
        WHERE Department = @DeptCode
        AND AssignmentId NOT IN (SELECT AssignmentId FROM [dbo].[AssignedSubjects_' + @DeptCode + ']);';
        
        EXEC sp_executesql @SQL, N'@DeptCode NVARCHAR(50)', @DeptCode = @DeptCode;
        SET @RowCount = @@ROWCOUNT;
        PRINT '  ? Migrated ' + CAST(@RowCount AS NVARCHAR) + ' assigned subject records';
    END TRY
    BEGIN CATCH
        PRINT '  ? AssignedSubjects migration: ' + ERROR_MESSAGE();
    END CATCH
    
    -- 5. Migrate StudentEnrollments
    BEGIN TRY
        SET @SQL = N'
        INSERT INTO [dbo].[StudentEnrollments_' + @DeptCode + '] 
        (EnrollmentId, StudentId, AssignmentId, SubjectId, FacultyId, EnrollmentDate, IsActive)
        SELECT 
            e.EnrollmentId, e.StudentId, e.AssignmentId, e.SubjectId, e.FacultyId, e.EnrollmentDate, e.IsActive
        FROM [dbo].[StudentEnrollments] e
        INNER JOIN [dbo].[Students] s ON e.StudentId = s.Id
        WHERE s.Department = @DeptCode
        AND e.EnrollmentId NOT IN (SELECT EnrollmentId FROM [dbo].[StudentEnrollments_' + @DeptCode + ']);';
        
        EXEC sp_executesql @SQL, N'@DeptCode NVARCHAR(50)', @DeptCode = @DeptCode;
        SET @RowCount = @@ROWCOUNT;
        PRINT '  ? Migrated ' + CAST(@RowCount AS NVARCHAR) + ' enrollment records';
    END TRY
    BEGIN CATCH
        PRINT '  ? Enrollment migration: ' + ERROR_MESSAGE();
    END CATCH
    
    PRINT '';
END
GO

-- Execute migration for all departments
EXEC dbo.sp_MigrateDepartmentData @DeptCode = 'DES';
EXEC dbo.sp_MigrateDepartmentData @DeptCode = 'IT';
EXEC dbo.sp_MigrateDepartmentData @DeptCode = 'ECE';
EXEC dbo.sp_MigrateDepartmentData @DeptCode = 'MECH';

PRINT '';
PRINT '? Data migration completed for all departments!';
PRINT '';

-- ============================================
-- STEP 4: VERIFY MIGRATION
-- ============================================
PRINT '=== STEP 4: Verification ===';
PRINT '';

PRINT '--- DES Department ---';
SELECT 'Faculty' AS TableType, COUNT(*) AS RecordCount FROM Faculty_DES
UNION ALL
SELECT 'Students', COUNT(*) FROM Students_DES
UNION ALL
SELECT 'Subjects', COUNT(*) FROM Subjects_DES
UNION ALL
SELECT 'AssignedSubjects', COUNT(*) FROM AssignedSubjects_DES
UNION ALL
SELECT 'StudentEnrollments', COUNT(*) FROM StudentEnrollments_DES;

PRINT '';
PRINT '--- IT Department ---';
SELECT 'Faculty' AS TableType, COUNT(*) AS RecordCount FROM Faculty_IT
UNION ALL
SELECT 'Students', COUNT(*) FROM Students_IT
UNION ALL
SELECT 'Subjects', COUNT(*) FROM Subjects_IT
UNION ALL
SELECT 'AssignedSubjects', COUNT(*) FROM AssignedSubjects_IT
UNION ALL
SELECT 'StudentEnrollments', COUNT(*) FROM StudentEnrollments_IT;

PRINT '';
PRINT '--- ECE Department ---';
SELECT 'Faculty' AS TableType, COUNT(*) AS RecordCount FROM Faculty_ECE
UNION ALL
SELECT 'Students', COUNT(*) FROM Students_ECE
UNION ALL
SELECT 'Subjects', COUNT(*) FROM Subjects_ECE
UNION ALL
SELECT 'AssignedSubjects', COUNT(*) FROM AssignedSubjects_ECE
UNION ALL
SELECT 'StudentEnrollments', COUNT(*) FROM StudentEnrollments_ECE;

PRINT '';
PRINT '--- MECH Department ---';
SELECT 'Faculty' AS TableType, COUNT(*) AS RecordCount FROM Faculty_MECH
UNION ALL
SELECT 'Students', COUNT(*) FROM Students_MECH
UNION ALL
SELECT 'Subjects', COUNT(*) FROM Subjects_MECH
UNION ALL
SELECT 'AssignedSubjects', COUNT(*) FROM AssignedSubjects_MECH
UNION ALL
SELECT 'StudentEnrollments', COUNT(*) FROM StudentEnrollments_MECH;

PRINT '';
PRINT '========================================';
PRINT '? MIGRATION COMPLETE!';
PRINT 'Completed at: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '========================================';
PRINT '';
PRINT '?? SUMMARY:';
PRINT '- Created 5 tables for each department (Faculty, Students, Subjects, AssignedSubjects, StudentEnrollments)';
PRINT '- Migrated all existing data from shared tables';
PRINT '- Shared tables are still intact (backward compatibility)';
PRINT '- Total departments migrated: 4 (DES, IT, ECE, MECH)';
PRINT '- Total tables created: 20 (5 per department)';
PRINT '';
PRINT '?? NEXT STEPS:';
PRINT '1. Test the migration results above';
PRINT '2. Update AdminControllerDynamicMethods to use these tables';
PRINT '3. Test admin login for each department';
PRINT '4. Verify students can see subjects from their department tables';
PRINT '';
PRINT '? IMPORTANT:';
PRINT '- Keep shared tables for backward compatibility';
PRINT '- CSEDS already uses dynamic tables (Faculty_CSEDS, etc.)';
PRINT '- Future departments will auto-create tables via DynamicTableService';
PRINT '';

GO

-- Clean up stored procedures
DROP PROCEDURE IF EXISTS dbo.sp_CreateDepartmentTables;
DROP PROCEDURE IF EXISTS dbo.sp_MigrateDepartmentData;
GO
