-- =====================================================
-- CSEDS DYNAMIC TABLES - PHASE 1 MIGRATION
-- =====================================================
-- Purpose: Create CSEDS-specific tables ONLY
-- Other departments will continue using shared tables
-- =====================================================

SET NOCOUNT ON;
PRINT '========================================';
PRINT 'CSEDS DYNAMIC TABLE MIGRATION';
PRINT 'Time: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '========================================';
PRINT '';

-- =====================================================
-- STEP 1: CREATE CSEDS-SPECIFIC TABLES
-- =====================================================
PRINT 'Step 1: Creating CSEDS-specific tables...';
PRINT '';

-- 1.1: Faculty_CSEDS
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Faculty_CSEDS')
BEGIN
    PRINT '  Creating Faculty_CSEDS...';
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
    PRINT '  ? Faculty_CSEDS created';
END
ELSE
    PRINT '  ? Faculty_CSEDS already exists';

-- 1.2: Students_CSEDS
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Students_CSEDS')
BEGIN
    PRINT '  Creating Students_CSEDS...';
    CREATE TABLE [dbo].[Students_CSEDS] (
        [Id] NVARCHAR(50) PRIMARY KEY,
        [FullName] NVARCHAR(200) NOT NULL,
        [RegdNumber] NVARCHAR(10) NOT NULL,
        [Year] NVARCHAR(50) NOT NULL,
        [Department] NVARCHAR(100) NOT NULL DEFAULT 'CSEDS',
        [Semester] NVARCHAR(50) NULL,
        [Email] NVARCHAR(200) NOT NULL UNIQUE,
        [Password] NVARCHAR(500) NOT NULL,
        [SelectedSubject] NVARCHAR(MAX) NULL,
        INDEX IX_Students_CSEDS_Email (Email),
        INDEX IX_Students_CSEDS_RegdNumber (RegdNumber),
        INDEX IX_Students_CSEDS_Year (Year),
        INDEX IX_Students_CSEDS_Department (Department)
    );
    PRINT '  ? Students_CSEDS created';
END
ELSE
    PRINT '  ? Students_CSEDS already exists';

-- 1.3: Subjects_CSEDS
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Subjects_CSEDS')
BEGIN
    PRINT '  Creating Subjects_CSEDS...';
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
    PRINT '  ? Subjects_CSEDS created';
END
ELSE
    PRINT '  ? Subjects_CSEDS already exists';

-- 1.4: AssignedSubjects_CSEDS
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'AssignedSubjects_CSEDS')
BEGIN
    PRINT '  Creating AssignedSubjects_CSEDS...';
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
    PRINT '  ? AssignedSubjects_CSEDS created';
END
ELSE
    PRINT '  ? AssignedSubjects_CSEDS already exists';

-- 1.5: StudentEnrollments_CSEDS
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'StudentEnrollments_CSEDS')
BEGIN
    PRINT '  Creating StudentEnrollments_CSEDS...';
    CREATE TABLE [dbo].[StudentEnrollments_CSEDS] (
        [StudentId] NVARCHAR(50) NOT NULL,
        [AssignedSubjectId] INT NOT NULL,
        [EnrollmentTime] DATETIME2 NOT NULL DEFAULT GETDATE(),
        PRIMARY KEY ([StudentId], [AssignedSubjectId]),
        CONSTRAINT FK_StudentEnrollments_CSEDS_Student FOREIGN KEY ([StudentId]) 
            REFERENCES [Students_CSEDS]([Id]) ON DELETE CASCADE,
        CONSTRAINT FK_StudentEnrollments_CSEDS_AssignedSubject FOREIGN KEY ([AssignedSubjectId]) 
            REFERENCES [AssignedSubjects_CSEDS]([AssignedSubjectId]) ON DELETE CASCADE,
        INDEX IX_StudentEnrollments_CSEDS_Student (StudentId),
        INDEX IX_StudentEnrollments_CSEDS_AssignedSubject (AssignedSubjectId)
    );
    PRINT '  ? StudentEnrollments_CSEDS created';
END
ELSE
    PRINT '  ? StudentEnrollments_CSEDS already exists';

PRINT '';
PRINT '========================================';
PRINT 'Step 1 Complete: All CSEDS tables created';
PRINT '========================================';
PRINT '';

-- =====================================================
-- STEP 2: MIGRATE CSEDS DATA FROM SHARED TABLES
-- =====================================================
PRINT 'Step 2: Migrating CSEDS data...';
PRINT '';

DECLARE @FacultyCount INT, @StudentCount INT, @SubjectCount INT, @AssignedCount INT, @EnrollmentCount INT;

-- 2.1: Migrate Faculty (with IDENTITY_INSERT)
BEGIN TRY
    SET IDENTITY_INSERT Faculty_CSEDS ON;
    
    INSERT INTO Faculty_CSEDS (FacultyId, Name, Email, PasswordHash, Department, CreatedAt)
    SELECT FacultyId, Name, Email, PasswordHash, Department, CreatedAt
    FROM Faculties
    WHERE Department = 'CSEDS'
    AND FacultyId NOT IN (SELECT FacultyId FROM Faculty_CSEDS);
    
    SET @FacultyCount = @@ROWCOUNT;
    SET IDENTITY_INSERT Faculty_CSEDS OFF;
    
    PRINT '  ? Migrated ' + CAST(@FacultyCount AS VARCHAR) + ' faculty members';
END TRY
BEGIN CATCH
    PRINT '  ? Error migrating faculty: ' + ERROR_MESSAGE();
    IF @@TRANCOUNT > 0 ROLLBACK;
END CATCH

-- 2.2: Migrate Students
BEGIN TRY
    INSERT INTO Students_CSEDS (Id, FullName, RegdNumber, Year, Department, Semester, Email, Password, SelectedSubject)
    SELECT Id, FullName, RegdNumber, Year, Department, Semester, Email, Password, SelectedSubject
    FROM Students
    WHERE Department = 'CSEDS'
    AND Id NOT IN (SELECT Id FROM Students_CSEDS);
    
    SET @StudentCount = @@ROWCOUNT;
    PRINT '  ? Migrated ' + CAST(@StudentCount AS VARCHAR) + ' students';
END TRY
BEGIN CATCH
    PRINT '  ? Error migrating students: ' + ERROR_MESSAGE();
END CATCH

-- 2.3: Migrate Subjects (with IDENTITY_INSERT)
BEGIN TRY
    SET IDENTITY_INSERT Subjects_CSEDS ON;
    
    INSERT INTO Subjects_CSEDS (SubjectId, Name, Year, Semester, Department, MaxEnrollments, IsCore, IsOptional, IsLab, CreatedAt)
    SELECT SubjectId, Name, Year, Semester, Department, MaxEnrollments, IsCore, IsOptional, IsLab, CreatedAt
    FROM Subjects
    WHERE Department = 'CSEDS'
    AND SubjectId NOT IN (SELECT SubjectId FROM Subjects_CSEDS);
    
    SET @SubjectCount = @@ROWCOUNT;
    SET IDENTITY_INSERT Subjects_CSEDS OFF;
    
    PRINT '  ? Migrated ' + CAST(@SubjectCount AS VARCHAR) + ' subjects';
END TRY
BEGIN CATCH
    PRINT '  ? Error migrating subjects: ' + ERROR_MESSAGE();
    IF @@TRANCOUNT > 0 ROLLBACK;
END CATCH

-- 2.4: Migrate AssignedSubjects (with IDENTITY_INSERT)
BEGIN TRY
    SET IDENTITY_INSERT AssignedSubjects_CSEDS ON;
    
    INSERT INTO AssignedSubjects_CSEDS (AssignedSubjectId, SubjectId, FacultyId, CurrentEnrollment)
    SELECT a.AssignedSubjectId, a.SubjectId, a.FacultyId, a.CurrentEnrollment
    FROM AssignedSubjects a
    INNER JOIN Subjects s ON a.SubjectId = s.SubjectId
    WHERE s.Department = 'CSEDS'
    AND a.AssignedSubjectId NOT IN (SELECT AssignedSubjectId FROM AssignedSubjects_CSEDS);
    
    SET @AssignedCount = @@ROWCOUNT;
    SET IDENTITY_INSERT AssignedSubjects_CSEDS OFF;
    
    PRINT '  ? Migrated ' + CAST(@AssignedCount AS VARCHAR) + ' assigned subjects';
END TRY
BEGIN CATCH
    PRINT '  ? Error migrating assigned subjects: ' + ERROR_MESSAGE();
    IF @@TRANCOUNT > 0 ROLLBACK;
END CATCH

-- 2.5: Migrate StudentEnrollments
BEGIN TRY
    INSERT INTO StudentEnrollments_CSEDS (StudentId, AssignedSubjectId, EnrollmentTime)
    SELECT se.StudentId, se.AssignedSubjectId, se.EnrollmentTime
    FROM StudentEnrollments se
    INNER JOIN Students s ON se.StudentId = s.Id
    WHERE s.Department = 'CSEDS'
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
PRINT '========================================';
PRINT 'Step 2 Complete: Data migration finished';
PRINT '========================================';
PRINT '';

-- =====================================================
-- STEP 3: VERIFICATION
-- =====================================================
PRINT 'Step 3: Verifying migration...';
PRINT '';

PRINT '  CSEDS Table Record Counts:';
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
PRINT '  Comparing with Shared Tables:';
SELECT 'Faculties (CSEDS)' AS TableName, COUNT(*) AS RecordCount FROM Faculties WHERE Department = 'CSEDS'
UNION ALL
SELECT 'Students (CSEDS)', COUNT(*) FROM Students WHERE Department = 'CSEDS'
UNION ALL
SELECT 'Subjects (CSEDS)', COUNT(*) FROM Subjects WHERE Department = 'CSEDS';

PRINT '';
PRINT '========================================';
PRINT 'CSEDS MIGRATION COMPLETED SUCCESSFULLY';
PRINT 'Time: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '========================================';
PRINT '';
PRINT 'NEXT STEPS:';
PRINT '1. Update AdminController to use DynamicDbContextFactory for CSEDS';
PRINT '2. Test CSEDS admin functionality';
PRINT '3. Verify CSEDS data isolation';
PRINT '4. Other departments (DES, IT, etc.) continue using shared tables';
PRINT '';

GO
