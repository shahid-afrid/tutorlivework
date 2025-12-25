-- STANDARDIZE ALL DEPARTMENT SCHEMAS TO MATCH CSEDS
-- =====================================================
-- This script ensures ALL departments (DES, IT, ECE, MECH) have 
-- the EXACT SAME SCHEMA as CSEDS for consistency
--
-- CSEDS Schema (STANDARD):
-- 1. Faculty_{DEPT}        - FacultyId, Name, Email, Password, Department
-- 2. Students_{DEPT}       - Id, FullName, RegdNumber, Year, Department, Semester, Email, Password, SelectedSubject
-- 3. Subjects_{DEPT}       - SubjectId, Name, Department, Year, Semester, SemesterStartDate, SemesterEndDate, SubjectType, MaxEnrollments
-- 4. AssignedSubjects_{DEPT} - AssignedSubjectId, FacultyId, SubjectId, Department, Year, SelectedCount
-- 5. StudentEnrollments_{DEPT} - StudentId, AssignedSubjectId, EnrolledAt
-- =====================================================

USE [Working5Db];
GO

SET NOCOUNT ON;

PRINT '========================================';
PRINT 'STANDARDIZING ALL DEPARTMENT SCHEMAS';
PRINT 'Started at: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '========================================';
PRINT '';

-- Define departments to process
DECLARE @Departments TABLE (DeptCode NVARCHAR(10));
INSERT INTO @Departments VALUES ('DES'), ('IT'), ('ECE'), ('MECH');

DECLARE @DeptCode NVARCHAR(10);
DECLARE @SQL NVARCHAR(MAX);

-- Loop through each department
DECLARE dept_cursor CURSOR FOR SELECT DeptCode FROM @Departments;
OPEN dept_cursor;
FETCH NEXT FROM dept_cursor INTO @DeptCode;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT '';
    PRINT '========================================';
    PRINT 'Processing Department: ' + @DeptCode;
    PRINT '========================================';
    
    -- =====================================================
    -- 1. DROP EXISTING TABLES IF THEY HAVE WRONG SCHEMA
    -- =====================================================
    PRINT 'Dropping existing tables (if any)...';
    
    -- Drop in reverse order due to foreign keys
    SET @SQL = N'
    IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = ''StudentEnrollments_' + @DeptCode + ''')
        DROP TABLE [dbo].[StudentEnrollments_' + @DeptCode + '];
    
    IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = ''AssignedSubjects_' + @DeptCode + ''')
        DROP TABLE [dbo].[AssignedSubjects_' + @DeptCode + '];
    
    IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = ''Subjects_' + @DeptCode + ''')
        DROP TABLE [dbo].[Subjects_' + @DeptCode + '];
    
    IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = ''Students_' + @DeptCode + ''')
        DROP TABLE [dbo].[Students_' + @DeptCode + '];
    
    IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = ''Faculty_' + @DeptCode + ''')
        DROP TABLE [dbo].[Faculty_' + @DeptCode + '];
    ';
    
    EXEC sp_executesql @SQL;
    PRINT 'Old tables dropped (if existed)';
    
    -- =====================================================
    -- 2. CREATE FACULTY TABLE (EXACT CSEDS SCHEMA)
    -- =====================================================
    PRINT 'Creating Faculty_' + @DeptCode + '...';
    
    SET @SQL = N'
    CREATE TABLE [dbo].[Faculty_' + @DeptCode + '] (
        [FacultyId] INT IDENTITY(1,1) PRIMARY KEY,
        [Name] NVARCHAR(100) NOT NULL,
        [Email] NVARCHAR(100) NOT NULL UNIQUE,
        [Password] NVARCHAR(255) NOT NULL,
        [Department] NVARCHAR(50) NOT NULL DEFAULT ''' + @DeptCode + '''
    );
    CREATE INDEX IX_Faculty_' + @DeptCode + '_Email ON Faculty_' + @DeptCode + '(Email);
    CREATE INDEX IX_Faculty_' + @DeptCode + '_Department ON Faculty_' + @DeptCode + '(Department);
    ';
    
    EXEC sp_executesql @SQL;
    PRINT '? Faculty_' + @DeptCode + ' created';
    
    -- =====================================================
    -- 3. CREATE STUDENTS TABLE (EXACT CSEDS SCHEMA)
    -- =====================================================
    PRINT 'Creating Students_' + @DeptCode + '...';
    
    SET @SQL = N'
    CREATE TABLE [dbo].[Students_' + @DeptCode + '] (
        [Id] NVARCHAR(50) PRIMARY KEY,
        [FullName] NVARCHAR(200) NOT NULL,
        [RegdNumber] NVARCHAR(10) NOT NULL,
        [Year] NVARCHAR(50) NOT NULL,
        [Department] NVARCHAR(50) NOT NULL DEFAULT ''' + @DeptCode + ''',
        [Semester] NVARCHAR(50) NULL,
        [Email] NVARCHAR(200) NOT NULL UNIQUE,
        [Password] NVARCHAR(500) NOT NULL,
        [SelectedSubject] NVARCHAR(MAX) NULL
    );
    CREATE INDEX IX_Students_' + @DeptCode + '_Email ON Students_' + @DeptCode + '(Email);
    CREATE INDEX IX_Students_' + @DeptCode + '_RegdNumber ON Students_' + @DeptCode + '(RegdNumber);
    CREATE INDEX IX_Students_' + @DeptCode + '_Year ON Students_' + @DeptCode + '(Year);
    CREATE INDEX IX_Students_' + @DeptCode + '_Department ON Students_' + @DeptCode + '(Department);
    ';
    
    EXEC sp_executesql @SQL;
    PRINT '? Students_' + @DeptCode + ' created';
    
    -- =====================================================
    -- 4. CREATE SUBJECTS TABLE (EXACT CSEDS SCHEMA)
    -- =====================================================
    PRINT 'Creating Subjects_' + @DeptCode + '...';
    
    SET @SQL = N'
    CREATE TABLE [dbo].[Subjects_' + @DeptCode + '] (
        [SubjectId] INT IDENTITY(1,1) PRIMARY KEY,
        [Name] NVARCHAR(200) NOT NULL,
        [Department] NVARCHAR(50) NOT NULL DEFAULT ''' + @DeptCode + ''',
        [Year] INT NOT NULL DEFAULT 1,
        [Semester] NVARCHAR(50) NULL,
        [SemesterStartDate] DATETIME2 NULL,
        [SemesterEndDate] DATETIME2 NULL,
        [SubjectType] NVARCHAR(50) NOT NULL DEFAULT ''Core'',
        [MaxEnrollments] INT NULL
    );
    CREATE INDEX IX_Subjects_' + @DeptCode + '_Year ON Subjects_' + @DeptCode + '(Year);
    CREATE INDEX IX_Subjects_' + @DeptCode + '_Department ON Subjects_' + @DeptCode + '(Department);
    ';
    
    EXEC sp_executesql @SQL;
    PRINT '? Subjects_' + @DeptCode + ' created';
    
    -- =====================================================
    -- 5. CREATE ASSIGNEDSUBJECTS TABLE (EXACT CSEDS SCHEMA)
    -- =====================================================
    PRINT 'Creating AssignedSubjects_' + @DeptCode + '...';
    
    SET @SQL = N'
    CREATE TABLE [dbo].[AssignedSubjects_' + @DeptCode + '] (
        [AssignedSubjectId] INT IDENTITY(1,1) PRIMARY KEY,
        [FacultyId] INT NOT NULL,
        [SubjectId] INT NOT NULL,
        [Department] NVARCHAR(50) NOT NULL,
        [Year] INT NOT NULL,
        [SelectedCount] INT NOT NULL DEFAULT 0
    );
    CREATE INDEX IX_AssignedSubjects_' + @DeptCode + '_Faculty ON AssignedSubjects_' + @DeptCode + '(FacultyId);
    CREATE INDEX IX_AssignedSubjects_' + @DeptCode + '_Subject ON AssignedSubjects_' + @DeptCode + '(SubjectId);
    ';
    
    EXEC sp_executesql @SQL;
    PRINT '? AssignedSubjects_' + @DeptCode + ' created';
    
    -- =====================================================
    -- 6. CREATE STUDENTENROLLMENTS TABLE (EXACT CSEDS SCHEMA)
    -- =====================================================
    PRINT 'Creating StudentEnrollments_' + @DeptCode + '...';
    
    SET @SQL = N'
    CREATE TABLE [dbo].[StudentEnrollments_' + @DeptCode + '] (
        [StudentId] NVARCHAR(50) NOT NULL,
        [AssignedSubjectId] INT NOT NULL,
        [EnrolledAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
        PRIMARY KEY ([StudentId], [AssignedSubjectId])
    );
    CREATE INDEX IX_StudentEnrollments_' + @DeptCode + '_Student ON StudentEnrollments_' + @DeptCode + '(StudentId);
    CREATE INDEX IX_StudentEnrollments_' + @DeptCode + '_AssignedSubject ON StudentEnrollments_' + @DeptCode + '(AssignedSubjectId);
    ';
    
    EXEC sp_executesql @SQL;
    PRINT '? StudentEnrollments_' + @DeptCode + ' created';
    
    -- =====================================================
    -- 7. ADD FOREIGN KEYS (EXACT CSEDS SCHEMA)
    -- =====================================================
    PRINT 'Adding foreign key constraints...';
    
    SET @SQL = N'
    ALTER TABLE AssignedSubjects_' + @DeptCode + '
    ADD CONSTRAINT FK_AssignedSubjects_' + @DeptCode + '_Subject 
    FOREIGN KEY ([SubjectId]) REFERENCES Subjects_' + @DeptCode + '([SubjectId]) ON DELETE CASCADE;
    
    ALTER TABLE AssignedSubjects_' + @DeptCode + '
    ADD CONSTRAINT FK_AssignedSubjects_' + @DeptCode + '_Faculty 
    FOREIGN KEY ([FacultyId]) REFERENCES Faculty_' + @DeptCode + '([FacultyId]) ON DELETE CASCADE;
    
    ALTER TABLE StudentEnrollments_' + @DeptCode + '
    ADD CONSTRAINT FK_StudentEnrollments_' + @DeptCode + '_Student 
    FOREIGN KEY ([StudentId]) REFERENCES Students_' + @DeptCode + '([Id]) ON DELETE CASCADE;
    
    ALTER TABLE StudentEnrollments_' + @DeptCode + '
    ADD CONSTRAINT FK_StudentEnrollments_' + @DeptCode + '_AssignedSubject 
    FOREIGN KEY ([AssignedSubjectId]) REFERENCES AssignedSubjects_' + @DeptCode + '([AssignedSubjectId]) ON DELETE CASCADE;
    ';
    
    EXEC sp_executesql @SQL;
    PRINT '? Foreign keys added';
    
    PRINT '';
    PRINT '??? ' + @DeptCode + ' tables created successfully with CSEDS schema ???';
    
    FETCH NEXT FROM dept_cursor INTO @DeptCode;
END

CLOSE dept_cursor;
DEALLOCATE dept_cursor;

PRINT '';
PRINT '========================================';
PRINT 'SCHEMA STANDARDIZATION COMPLETE';
PRINT 'All departments now have identical schema to CSEDS';
PRINT 'Completed at: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '========================================';

-- =====================================================
-- VERIFICATION: Check all tables exist with correct schema
-- =====================================================
PRINT '';
PRINT '=== VERIFICATION ===';
PRINT '';

SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN (
    'Faculty_DES', 'Faculty_IT', 'Faculty_ECE', 'Faculty_MECH', 'Faculty_CSEDS',
    'Students_DES', 'Students_IT', 'Students_ECE', 'Students_MECH', 'Students_CSEDS',
    'Subjects_DES', 'Subjects_IT', 'Subjects_ECE', 'Subjects_MECH', 'Subjects_CSEDS',
    'AssignedSubjects_DES', 'AssignedSubjects_IT', 'AssignedSubjects_ECE', 'AssignedSubjects_MECH', 'AssignedSubjects_CSEDS',
    'StudentEnrollments_DES', 'StudentEnrollments_IT', 'StudentEnrollments_ECE', 'StudentEnrollments_MECH', 'StudentEnrollments_CSEDS'
)
ORDER BY TABLE_NAME, ORDINAL_POSITION;

PRINT '';
PRINT 'All department tables now use the same schema structure!';
GO
