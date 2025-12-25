-- =====================================================
-- DYNAMIC TABLE ARCHITECTURE - DATA MIGRATION
-- =====================================================
-- Purpose: Split shared tables into department-specific tables
-- Departments: CSEDS, CSE, ECE, MECH, CIVIL, EEE, etc.
-- =====================================================

SET NOCOUNT ON;
PRINT '========================================';
PRINT 'DYNAMIC TABLE MIGRATION - STARTED';
PRINT 'Time: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '========================================';
PRINT '';

-- =====================================================
-- STEP 1: CREATE TABLES FOR CSEDS DEPARTMENT
-- =====================================================
PRINT 'Step 1: Creating tables for CSEDS department...';

-- Faculty_CSEDS
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Faculty_CSEDS')
BEGIN
    CREATE TABLE [dbo].[Faculty_CSEDS] (
        [FacultyId] INT IDENTITY(1,1) PRIMARY KEY,
        [Name] NVARCHAR(200) NOT NULL,
        [Email] NVARCHAR(200) NOT NULL UNIQUE,
        [PasswordHash] NVARCHAR(500) NOT NULL,
        [Department] NVARCHAR(100) NOT NULL DEFAULT 'CSEDS',
        [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
        INDEX IX_Faculty_CSEDS_Email (Email),
        INDEX IX_Faculty_CSEDS_Department (Department)
    );
    PRINT '  ? Faculty_CSEDS table created';
END
ELSE
    PRINT '  ? Faculty_CSEDS table already exists';

-- Students_CSEDS
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Students_CSEDS')
BEGIN
    CREATE TABLE [dbo].[Students_CSEDS] (
        [RollNumber] NVARCHAR(50) PRIMARY KEY,
        [Name] NVARCHAR(200) NOT NULL,
        [Year] INT NOT NULL,
        [Semester] NVARCHAR(50) NULL,
        [Email] NVARCHAR(200) NOT NULL UNIQUE,
        [PasswordHash] NVARCHAR(500) NOT NULL,
        [Department] NVARCHAR(100) NOT NULL DEFAULT 'CSEDS',
        [TotalSubjectsSelected] INT NOT NULL DEFAULT 0,
        [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
        INDEX IX_Students_CSEDS_Email (Email),
        INDEX IX_Students_CSEDS_Year (Year),
        INDEX IX_Students_CSEDS_Department (Department)
    );
    PRINT '  ? Students_CSEDS table created';
END
ELSE
    PRINT '  ? Students_CSEDS table already exists';

-- Subjects_CSEDS
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Subjects_CSEDS')
BEGIN
    CREATE TABLE [dbo].[Subjects_CSEDS] (
        [SubjectId] INT IDENTITY(1,1) PRIMARY KEY,
        [Name] NVARCHAR(200) NOT NULL,
        [Year] INT NOT NULL,
        [Semester] NVARCHAR(50) NULL,
        [Department] NVARCHAR(100) NOT NULL DEFAULT 'CSEDS',
        [MaxEnrollments] INT NOT NULL DEFAULT 60,
        [IsCore] BIT NOT NULL DEFAULT 0,
        [IsOptional] BIT NOT NULL DEFAULT 1,
        [IsLab] BIT NOT NULL DEFAULT 0,
        [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
        INDEX IX_Subjects_CSEDS_Year (Year),
        INDEX IX_Subjects_CSEDS_Department (Department)
    );
    PRINT '  ? Subjects_CSEDS table created';
END
ELSE
    PRINT '  ? Subjects_CSEDS table already exists';

-- AssignedSubjects_CSEDS
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'AssignedSubjects_CSEDS')
BEGIN
    CREATE TABLE [dbo].[AssignedSubjects_CSEDS] (
        [AssignedSubjectId] INT IDENTITY(1,1) PRIMARY KEY,
        [SubjectId] INT NOT NULL,
        [FacultyId] INT NOT NULL,
        [CurrentEnrollment] INT NOT NULL DEFAULT 0,
        CONSTRAINT FK_AssignedSubjects_CSEDS_Subject FOREIGN KEY ([SubjectId]) 
            REFERENCES [Subjects_CSEDS]([SubjectId]) ON DELETE CASCADE,
        CONSTRAINT FK_AssignedSubjects_CSEDS_Faculty FOREIGN KEY ([FacultyId]) 
            REFERENCES [Faculty_CSEDS]([FacultyId]) ON DELETE CASCADE,
        INDEX IX_AssignedSubjects_CSEDS_Subject (SubjectId),
        INDEX IX_AssignedSubjects_CSEDS_Faculty (FacultyId)
    );
    PRINT '  ? AssignedSubjects_CSEDS table created';
END
ELSE
    PRINT '  ? AssignedSubjects_CSEDS table already exists';

-- StudentEnrollments_CSEDS
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'StudentEnrollments_CSEDS')
BEGIN
    CREATE TABLE [dbo].[StudentEnrollments_CSEDS] (
        [StudentId] NVARCHAR(50) NOT NULL,
        [AssignedSubjectId] INT NOT NULL,
        [EnrollmentTime] DATETIME2 NOT NULL DEFAULT GETDATE(),
        PRIMARY KEY ([StudentId], [AssignedSubjectId]),
        CONSTRAINT FK_StudentEnrollments_CSEDS_Student FOREIGN KEY ([StudentId]) 
            REFERENCES [Students_CSEDS]([RollNumber]) ON DELETE CASCADE,
        CONSTRAINT FK_StudentEnrollments_CSEDS_AssignedSubject FOREIGN KEY ([AssignedSubjectId]) 
            REFERENCES [AssignedSubjects_CSEDS]([AssignedSubjectId]) ON DELETE CASCADE,
        INDEX IX_StudentEnrollments_CSEDS_Student (StudentId),
        INDEX IX_StudentEnrollments_CSEDS_AssignedSubject (AssignedSubjectId)
    );
    PRINT '  ? StudentEnrollments_CSEDS table created';
END
ELSE
    PRINT '  ? StudentEnrollments_CSEDS table already exists';

PRINT '';

-- =====================================================
-- STEP 2: MIGRATE CSEDS DATA
-- =====================================================
PRINT 'Step 2: Migrating CSEDS data from shared tables...';

DECLARE @FacultyCount INT, @StudentCount INT, @SubjectCount INT, @AssignedCount INT, @EnrollmentCount INT;

-- 2.1: Migrate Faculty
BEGIN TRY
    SET IDENTITY_INSERT Faculty_CSEDS ON;
    
    INSERT INTO Faculty_CSEDS (FacultyId, Name, Email, PasswordHash, Department, CreatedAt)
    SELECT FacultyId, Name, Email, PasswordHash, Department, CreatedAt
    FROM Faculties
    WHERE Department IN ('CSEDS', 'CSE(DS)', 'Cse-Ds', 'CSE-DS')
    AND FacultyId NOT IN (SELECT FacultyId FROM Faculty_CSEDS);
    
    SET @FacultyCount = @@ROWCOUNT;
    SET IDENTITY_INSERT Faculty_CSEDS OFF;
    
    PRINT '  ? Migrated ' + CAST(@FacultyCount AS VARCHAR) + ' faculty members';
END TRY
BEGIN CATCH
    PRINT '  ? Error migrating faculty: ' + ERROR_MESSAGE();
END CATCH

-- 2.2: Migrate Students
BEGIN TRY
    INSERT INTO Students_CSEDS (RollNumber, Name, Year, Semester, Email, PasswordHash, Department, TotalSubjectsSelected, CreatedAt)
    SELECT RollNumber, Name, Year, Semester, Email, PasswordHash, Department, TotalSubjectsSelected, CreatedAt
    FROM Students
    WHERE Department IN ('CSEDS', 'CSE(DS)', 'Cse-Ds', 'CSE-DS')
    AND RollNumber NOT IN (SELECT RollNumber FROM Students_CSEDS);
    
    SET @StudentCount = @@ROWCOUNT;
    PRINT '  ? Migrated ' + CAST(@StudentCount AS VARCHAR) + ' students';
END TRY
BEGIN CATCH
    PRINT '  ? Error migrating students: ' + ERROR_MESSAGE();
END CATCH

-- 2.3: Migrate Subjects
BEGIN TRY
    SET IDENTITY_INSERT Subjects_CSEDS ON;
    
    INSERT INTO Subjects_CSEDS (SubjectId, Name, Year, Semester, Department, MaxEnrollments, IsCore, IsOptional, IsLab, CreatedAt)
    SELECT SubjectId, Name, Year, Semester, Department, MaxEnrollments, IsCore, IsOptional, IsLab, CreatedAt
    FROM Subjects
    WHERE Department IN ('CSEDS', 'CSE(DS)', 'Cse-Ds', 'CSE-DS')
    AND SubjectId NOT IN (SELECT SubjectId FROM Subjects_CSEDS);
    
    SET @SubjectCount = @@ROWCOUNT;
    SET IDENTITY_INSERT Subjects_CSEDS OFF;
    
    PRINT '  ? Migrated ' + CAST(@SubjectCount AS VARCHAR) + ' subjects';
END TRY
BEGIN CATCH
    PRINT '  ? Error migrating subjects: ' + ERROR_MESSAGE();
END CATCH

-- 2.4: Migrate AssignedSubjects
BEGIN TRY
    SET IDENTITY_INSERT AssignedSubjects_CSEDS ON;
    
    INSERT INTO AssignedSubjects_CSEDS (AssignedSubjectId, SubjectId, FacultyId, CurrentEnrollment)
    SELECT a.AssignedSubjectId, a.SubjectId, a.FacultyId, a.CurrentEnrollment
    FROM AssignedSubjects a
    INNER JOIN Subjects s ON a.SubjectId = s.SubjectId
    WHERE s.Department IN ('CSEDS', 'CSE(DS)', 'Cse-Ds', 'CSE-DS')
    AND a.AssignedSubjectId NOT IN (SELECT AssignedSubjectId FROM AssignedSubjects_CSEDS);
    
    SET @AssignedCount = @@ROWCOUNT;
    SET IDENTITY_INSERT AssignedSubjects_CSEDS OFF;
    
    PRINT '  ? Migrated ' + CAST(@AssignedCount AS VARCHAR) + ' assigned subjects';
END TRY
BEGIN CATCH
    PRINT '  ? Error migrating assigned subjects: ' + ERROR_MESSAGE();
END CATCH

-- 2.5: Migrate StudentEnrollments
BEGIN TRY
    INSERT INTO StudentEnrollments_CSEDS (StudentId, AssignedSubjectId, EnrollmentTime)
    SELECT se.StudentId, se.AssignedSubjectId, se.EnrollmentTime
    FROM StudentEnrollments se
    INNER JOIN Students s ON se.StudentId = s.RollNumber
    WHERE s.Department IN ('CSEDS', 'CSE(DS)', 'Cse-Ds', 'CSE-DS')
    AND NOT EXISTS (
        SELECT 1 FROM StudentEnrollments_CSEDS
        WHERE StudentId = se.StudentId AND AssignedSubjectId = se.AssignedSubjectId
    );
    
    SET @EnrollmentCount = @@ROWCOUNT;
    PRINT '  ? Migrated ' + CAST(@EnrollmentCount AS VARCHAR) + ' student enrollments';
END TRY
BEGIN CATCH
    PRINT '  ? Error migrating enrollments: ' + ERROR_MESSAGE();
END CATCH

PRINT '';

-- =====================================================
-- STEP 3: VERIFICATION
-- =====================================================
PRINT 'Step 3: Verifying migration...';
PRINT '';

PRINT '  CSEDS Department Tables:';
SELECT 'Faculty_CSEDS' AS TableName, COUNT(*) AS RecordCount FROM Faculty_CSEDS
UNION ALL
SELECT 'Students_CSEDS', COUNT(*) FROM Students_CSEDS
UNION ALL
SELECT 'Subjects_CSEDS', COUNT(*) FROM Subjects_CSEDS
UNION ALL
SELECT 'AssignedSubjects_CSEDS', COUNT(*) FROM AssignedSubjects_CSEDS
UNION ALL
SELECT 'StudentEnrollments_CSEDS', COUNT(*) FROM StudentEnrollments_CSEDS;

PRINT '';
PRINT '========================================';
PRINT 'MIGRATION COMPLETED SUCCESSFULLY';
PRINT 'Time: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '========================================';
PRINT '';
PRINT 'NEXT STEPS:';
PRINT '1. Test CSEDS department with new tables';
PRINT '2. Update controllers to use DynamicDbContextFactory';
PRINT '3. Create tables for other departments as needed';
PRINT '4. Consider archiving old shared tables after verification';

GO
