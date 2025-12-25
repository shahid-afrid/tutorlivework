-- =====================================================
-- CSEDS DYNAMIC TABLES - SIMPLE MIGRATION (NO GO)
-- =====================================================

SET NOCOUNT ON;
PRINT 'Starting CSEDS Dynamic Table Migration...';

-- 1. Faculty_CSEDS
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Faculty_CSEDS')
BEGIN
    CREATE TABLE [dbo].[Faculty_CSEDS] (
        [FacultyId] INT IDENTITY(1,1) PRIMARY KEY,
        [Name] NVARCHAR(200) NOT NULL,
        [Email] NVARCHAR(200) NOT NULL UNIQUE,
        [PasswordHash] NVARCHAR(500) NOT NULL,
        [Department] NVARCHAR(100) NOT NULL DEFAULT 'CSEDS',
        [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE()
    );
    CREATE INDEX IX_Faculty_CSEDS_Email ON Faculty_CSEDS(Email);
    CREATE INDEX IX_Faculty_CSEDS_Department ON Faculty_CSEDS(Department);
    PRINT 'Faculty_CSEDS created';
END;

-- 2. Students_CSEDS
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Students_CSEDS')
BEGIN
    CREATE TABLE [dbo].[Students_CSEDS] (
        [Id] NVARCHAR(50) PRIMARY KEY,
        [FullName] NVARCHAR(200) NOT NULL,
        [RegdNumber] NVARCHAR(10) NOT NULL,
        [Year] NVARCHAR(50) NOT NULL,
        [Department] NVARCHAR(100) NOT NULL DEFAULT 'CSEDS',
        [Semester] NVARCHAR(50) NULL,
        [Email] NVARCHAR(200) NOT NULL UNIQUE,
        [Password] NVARCHAR(500) NOT NULL,
        [SelectedSubject] NVARCHAR(MAX) NULL
    );
    CREATE INDEX IX_Students_CSEDS_Email ON Students_CSEDS(Email);
    CREATE INDEX IX_Students_CSEDS_RegdNumber ON Students_CSEDS(RegdNumber);
    CREATE INDEX IX_Students_CSEDS_Year ON Students_CSEDS(Year);
    CREATE INDEX IX_Students_CSEDS_Department ON Students_CSEDS(Department);
    PRINT 'Students_CSEDS created';
END;

-- 3. Subjects_CSEDS
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
        [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE()
    );
    CREATE INDEX IX_Subjects_CSEDS_Year ON Subjects_CSEDS(Year);
    CREATE INDEX IX_Subjects_CSEDS_Department ON Subjects_CSEDS(Department);
    PRINT 'Subjects_CSEDS created';
END;

-- 4. AssignedSubjects_CSEDS
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'AssignedSubjects_CSEDS')
BEGIN
    CREATE TABLE [dbo].[AssignedSubjects_CSEDS] (
        [AssignedSubjectId] INT IDENTITY(1,1) PRIMARY KEY,
        [SubjectId] INT NOT NULL,
        [FacultyId] INT NOT NULL,
        [CurrentEnrollment] INT NOT NULL DEFAULT 0
    );
    CREATE INDEX IX_AssignedSubjects_CSEDS_Subject ON AssignedSubjects_CSEDS(SubjectId);
    CREATE INDEX IX_AssignedSubjects_CSEDS_Faculty ON AssignedSubjects_CSEDS(FacultyId);
    PRINT 'AssignedSubjects_CSEDS created';
END;

-- 5. StudentEnrollments_CSEDS
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'StudentEnrollments_CSEDS')
BEGIN
    CREATE TABLE [dbo].[StudentEnrollments_CSEDS] (
        [StudentId] NVARCHAR(50) NOT NULL,
        [AssignedSubjectId] INT NOT NULL,
        [EnrolledAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
        PRIMARY KEY ([StudentId], [AssignedSubjectId])
    );
    CREATE INDEX IX_StudentEnrollments_CSEDS_Student ON StudentEnrollments_CSEDS(StudentId);
    CREATE INDEX IX_StudentEnrollments_CSEDS_AssignedSubject ON StudentEnrollments_CSEDS(AssignedSubjectId);
    PRINT 'StudentEnrollments_CSEDS created';
END;

-- Add foreign keys AFTER all tables are created
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_AssignedSubjects_CSEDS_Subject')
BEGIN
    ALTER TABLE AssignedSubjects_CSEDS
    ADD CONSTRAINT FK_AssignedSubjects_CSEDS_Subject 
    FOREIGN KEY ([SubjectId]) REFERENCES Subjects_CSEDS([SubjectId]) ON DELETE CASCADE;
END;

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_AssignedSubjects_CSEDS_Faculty')
BEGIN
    ALTER TABLE AssignedSubjects_CSEDS
    ADD CONSTRAINT FK_AssignedSubjects_CSEDS_Faculty 
    FOREIGN KEY ([FacultyId]) REFERENCES Faculty_CSEDS([FacultyId]) ON DELETE CASCADE;
END;

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_StudentEnrollments_CSEDS_Student')
BEGIN
    ALTER TABLE StudentEnrollments_CSEDS
    ADD CONSTRAINT FK_StudentEnrollments_CSEDS_Student 
    FOREIGN KEY ([StudentId]) REFERENCES Students_CSEDS([Id]) ON DELETE CASCADE;
END;

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_StudentEnrollments_CSEDS_AssignedSubject')
BEGIN
    ALTER TABLE StudentEnrollments_CSEDS
    ADD CONSTRAINT FK_StudentEnrollments_CSEDS_AssignedSubject 
    FOREIGN KEY ([AssignedSubjectId]) REFERENCES AssignedSubjects_CSEDS([AssignedSubjectId]) ON DELETE CASCADE;
END;

PRINT 'Tables and constraints created successfully!';

-- MIGRATE DATA
PRINT 'Starting data migration...';

-- Migrate Faculty
SET IDENTITY_INSERT Faculty_CSEDS ON;
INSERT INTO Faculty_CSEDS (FacultyId, Name, Email, PasswordHash, Department, CreatedAt)
SELECT FacultyId, Name, Email, Password, Department, GETDATE()
FROM Faculties
WHERE Department = 'CSEDS'
AND FacultyId NOT IN (SELECT FacultyId FROM Faculty_CSEDS);
SET IDENTITY_INSERT Faculty_CSEDS OFF;
PRINT 'Faculty migrated: ' + CAST(@@ROWCOUNT AS VARCHAR);

-- Migrate Students
INSERT INTO Students_CSEDS (Id, FullName, RegdNumber, Year, Department, Semester, Email, Password, SelectedSubject)
SELECT Id, FullName, RegdNumber, Year, Department, Semester, Email, Password, SelectedSubject
FROM Students
WHERE Department = 'CSEDS'
AND Id NOT IN (SELECT Id FROM Students_CSEDS);
PRINT 'Students migrated: ' + CAST(@@ROWCOUNT AS VARCHAR);

-- Migrate Subjects
SET IDENTITY_INSERT Subjects_CSEDS ON;
INSERT INTO Subjects_CSEDS (SubjectId, Name, Year, Semester, Department, MaxEnrollments, IsCore, IsOptional, IsLab, CreatedAt)
SELECT SubjectId, Name, Year, ISNULL(Semester, ''), Department, ISNULL(MaxEnrollments, 60), 
       CASE WHEN SubjectType = 'Core' THEN 1 ELSE 0 END,
       CASE WHEN SubjectType != 'Core' THEN 1 ELSE 0 END,
       0, GETDATE()
FROM Subjects
WHERE Department = 'CSEDS'
AND SubjectId NOT IN (SELECT SubjectId FROM Subjects_CSEDS);
SET IDENTITY_INSERT Subjects_CSEDS OFF;
PRINT 'Subjects migrated: ' + CAST(@@ROWCOUNT AS VARCHAR);

-- Migrate AssignedSubjects
SET IDENTITY_INSERT AssignedSubjects_CSEDS ON;
INSERT INTO AssignedSubjects_CSEDS (AssignedSubjectId, SubjectId, FacultyId, CurrentEnrollment)
SELECT a.AssignedSubjectId, a.SubjectId, a.FacultyId, a.CurrentEnrollment
FROM AssignedSubjects a
INNER JOIN Subjects s ON a.SubjectId = s.SubjectId
WHERE s.Department = 'CSEDS'
AND a.AssignedSubjectId NOT IN (SELECT AssignedSubjectId FROM AssignedSubjects_CSEDS);
SET IDENTITY_INSERT AssignedSubjects_CSEDS OFF;
PRINT 'AssignedSubjects migrated: ' + CAST(@@ROWCOUNT AS VARCHAR);

-- Migrate StudentEnrollments
INSERT INTO StudentEnrollments_CSEDS (StudentId, AssignedSubjectId, EnrolledAt)
SELECT se.StudentId, se.AssignedSubjectId, se.EnrolledAt
FROM StudentEnrollments se
INNER JOIN Students s ON se.StudentId = s.Id
WHERE s.Department = 'CSEDS'
AND NOT EXISTS (
    SELECT 1 FROM StudentEnrollments_CSEDS
    WHERE StudentId = se.StudentId AND AssignedSubjectId = se.AssignedSubjectId
);
PRINT 'StudentEnrollments migrated: ' + CAST(@@ROWCOUNT AS VARCHAR);

PRINT 'CSEDS migration completed successfully!';

-- VERIFICATION
SELECT 'Faculty_CSEDS' AS TableName, COUNT(*) AS RecordCount FROM Faculty_CSEDS
UNION ALL
SELECT 'Students_CSEDS', COUNT(*) FROM Students_CSEDS
UNION ALL
SELECT 'Subjects_CSEDS', COUNT(*) FROM Subjects_CSEDS
UNION ALL
SELECT 'AssignedSubjects_CSEDS', COUNT(*) FROM AssignedSubjects_CSEDS
UNION ALL
SELECT 'StudentEnrollments_CSEDS', COUNT(*) FROM StudentEnrollments_CSEDS;
