-- ============================================
-- MIGRATE DATA FOR ALL DEPARTMENTS - FIXED VERSION
-- ============================================
-- This script migrates data from shared tables to department-specific tables
-- Run this AFTER tables have been created
-- ============================================

USE [TutorLiveV1];
GO

PRINT '========================================';
PRINT 'DATA MIGRATION FOR ALL DEPARTMENTS';
PRINT 'Started at: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '========================================';
PRINT '';

-- ============================================
-- MIGRATE DES DEPARTMENT
-- ============================================
PRINT '=== Migrating DES Department ===';
PRINT '';

-- 1. Migrate Faculty
BEGIN TRY
    SET IDENTITY_INSERT Faculty_DES ON;
    
    INSERT INTO Faculty_DES 
    (FacultyId, Name, Email, Password, Department, Specialization, Qualification, 
     ExperienceYears, PhoneNumber, IsActive, CreatedDate, LastLogin, ProfileImageUrl)
    SELECT 
        FacultyId, Name, Email, Password, Department, Specialization, Qualification,
        ExperienceYears, PhoneNumber, IsActive, CreatedDate, LastLogin, ProfileImageUrl
    FROM Faculties
    WHERE Department = 'DES'
    AND FacultyId NOT IN (SELECT FacultyId FROM Faculty_DES);
    
    SET IDENTITY_INSERT Faculty_DES OFF;
    
    PRINT '  ? Migrated ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' faculty records';
END TRY
BEGIN CATCH
    SET IDENTITY_INSERT Faculty_DES OFF;
    PRINT '  ? Faculty migration: ' + ERROR_MESSAGE();
END CATCH

-- 2. Migrate Students
BEGIN TRY
    INSERT INTO Students_DES 
    (Id, FullName, RegdNumber, Department, Year, Semester, Email, PhoneNumber, 
     Password, IsActive, CreatedDate, LastLogin)
    SELECT 
        Id, FullName, RegdNumber, Department, Year, Semester, Email, PhoneNumber,
        Password, IsActive, CreatedDate, LastLogin
    FROM Students
    WHERE Department = 'DES'
    AND Id NOT IN (SELECT Id FROM Students_DES);
    
    PRINT '  ? Migrated ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' student records';
END TRY
BEGIN CATCH
    PRINT '  ? Student migration: ' + ERROR_MESSAGE();
END CATCH

-- 3. Migrate Subjects
BEGIN TRY
    SET IDENTITY_INSERT Subjects_DES ON;
    
    INSERT INTO Subjects_DES 
    (SubjectId, Name, SubjectCode, Department, SubjectType, Year, Semester, Credits, IsActive, CreatedDate)
    SELECT 
        SubjectId, Name, SubjectCode, Department, SubjectType, Year, Semester, Credits, IsActive, CreatedDate
    FROM Subjects
    WHERE Department = 'DES'
    AND SubjectId NOT IN (SELECT SubjectId FROM Subjects_DES);
    
    SET IDENTITY_INSERT Subjects_DES OFF;
    
    PRINT '  ? Migrated ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' subject records';
END TRY
BEGIN CATCH
    SET IDENTITY_INSERT Subjects_DES OFF;
    PRINT '  ? Subject migration: ' + ERROR_MESSAGE();
END CATCH

-- 4. Migrate AssignedSubjects
BEGIN TRY
    SET IDENTITY_INSERT AssignedSubjects_DES ON;
    
    INSERT INTO AssignedSubjects_DES 
    (AssignmentId, SubjectId, FacultyId, Department, Year, Semester, MaxEnrollments, CurrentEnrollments, IsActive, AssignedDate)
    SELECT 
        AssignmentId, SubjectId, FacultyId, Department, Year, Semester, MaxEnrollments, CurrentEnrollments, IsActive, AssignedDate
    FROM AssignedSubjects
    WHERE Department = 'DES'
    AND AssignmentId NOT IN (SELECT AssignmentId FROM AssignedSubjects_DES);
    
    SET IDENTITY_INSERT AssignedSubjects_DES OFF;
    
    PRINT '  ? Migrated ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' assigned subject records';
END TRY
BEGIN CATCH
    SET IDENTITY_INSERT AssignedSubjects_DES OFF;
    PRINT '  ? AssignedSubjects migration: ' + ERROR_MESSAGE();
END CATCH

-- 5. Migrate StudentEnrollments
BEGIN TRY
    SET IDENTITY_INSERT StudentEnrollments_DES ON;
    
    INSERT INTO StudentEnrollments_DES 
    (EnrollmentId, StudentId, AssignmentId, SubjectId, FacultyId, EnrollmentDate, IsActive)
    SELECT 
        e.EnrollmentId, e.StudentId, e.AssignmentId, e.SubjectId, e.FacultyId, e.EnrollmentDate, e.IsActive
    FROM StudentEnrollments e
    INNER JOIN Students s ON e.StudentId = s.Id
    WHERE s.Department = 'DES'
    AND e.EnrollmentId NOT IN (SELECT EnrollmentId FROM StudentEnrollments_DES);
    
    SET IDENTITY_INSERT StudentEnrollments_DES OFF;
    
    PRINT '  ? Migrated ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' enrollment records';
END TRY
BEGIN CATCH
    SET IDENTITY_INSERT StudentEnrollments_DES OFF;
    PRINT '  ? Enrollment migration: ' + ERROR_MESSAGE();
END CATCH

PRINT '';
PRINT '? DES Department migration complete';
PRINT '';

-- ============================================
-- MIGRATE IT DEPARTMENT
-- ============================================
PRINT '=== Migrating IT Department ===';
PRINT '';

-- 1. Migrate Faculty
BEGIN TRY
    SET IDENTITY_INSERT Faculty_IT ON;
    
    INSERT INTO Faculty_IT 
    (FacultyId, Name, Email, Password, Department, Specialization, Qualification, 
     ExperienceYears, PhoneNumber, IsActive, CreatedDate, LastLogin, ProfileImageUrl)
    SELECT 
        FacultyId, Name, Email, Password, Department, Specialization, Qualification,
        ExperienceYears, PhoneNumber, IsActive, CreatedDate, LastLogin, ProfileImageUrl
    FROM Faculties
    WHERE Department = 'IT'
    AND FacultyId NOT IN (SELECT FacultyId FROM Faculty_IT);
    
    SET IDENTITY_INSERT Faculty_IT OFF;
    
    PRINT '  ? Migrated ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' faculty records';
END TRY
BEGIN CATCH
    SET IDENTITY_INSERT Faculty_IT OFF;
    PRINT '  ? Faculty migration: ' + ERROR_MESSAGE();
END CATCH

-- 2. Migrate Students
BEGIN TRY
    INSERT INTO Students_IT 
    (Id, FullName, RegdNumber, Department, Year, Semester, Email, PhoneNumber, 
     Password, IsActive, CreatedDate, LastLogin)
    SELECT 
        Id, FullName, RegdNumber, Department, Year, Semester, Email, PhoneNumber,
        Password, IsActive, CreatedDate, LastLogin
    FROM Students
    WHERE Department = 'IT'
    AND Id NOT IN (SELECT Id FROM Students_IT);
    
    PRINT '  ? Migrated ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' student records';
END TRY
BEGIN CATCH
    PRINT '  ? Student migration: ' + ERROR_MESSAGE();
END CATCH

-- 3. Migrate Subjects
BEGIN TRY
    SET IDENTITY_INSERT Subjects_IT ON;
    
    INSERT INTO Subjects_IT 
    (SubjectId, Name, SubjectCode, Department, SubjectType, Year, Semester, Credits, IsActive, CreatedDate)
    SELECT 
        SubjectId, Name, SubjectCode, Department, SubjectType, Year, Semester, Credits, IsActive, CreatedDate
    FROM Subjects
    WHERE Department = 'IT'
    AND SubjectId NOT IN (SELECT SubjectId FROM Subjects_IT);
    
    SET IDENTITY_INSERT Subjects_IT OFF;
    
    PRINT '  ? Migrated ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' subject records';
END TRY
BEGIN CATCH
    SET IDENTITY_INSERT Subjects_IT OFF;
    PRINT '  ? Subject migration: ' + ERROR_MESSAGE();
END CATCH

-- 4. Migrate AssignedSubjects
BEGIN TRY
    SET IDENTITY_INSERT AssignedSubjects_IT ON;
    
    INSERT INTO AssignedSubjects_IT 
    (AssignmentId, SubjectId, FacultyId, Department, Year, Semester, MaxEnrollments, CurrentEnrollments, IsActive, AssignedDate)
    SELECT 
        AssignmentId, SubjectId, FacultyId, Department, Year, Semester, MaxEnrollments, CurrentEnrollments, IsActive, AssignedDate
    FROM AssignedSubjects
    WHERE Department = 'IT'
    AND AssignmentId NOT IN (SELECT AssignmentId FROM AssignedSubjects_IT);
    
    SET IDENTITY_INSERT AssignedSubjects_IT OFF;
    
    PRINT '  ? Migrated ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' assigned subject records';
END TRY
BEGIN CATCH
    SET IDENTITY_INSERT AssignedSubjects_IT OFF;
    PRINT '  ? AssignedSubjects migration: ' + ERROR_MESSAGE();
END CATCH

-- 5. Migrate StudentEnrollments
BEGIN TRY
    SET IDENTITY_INSERT StudentEnrollments_IT ON;
    
    INSERT INTO StudentEnrollments_IT 
    (EnrollmentId, StudentId, AssignmentId, SubjectId, FacultyId, EnrollmentDate, IsActive)
    SELECT 
        e.EnrollmentId, e.StudentId, e.AssignmentId, e.SubjectId, e.FacultyId, e.EnrollmentDate, e.IsActive
    FROM StudentEnrollments e
    INNER JOIN Students s ON e.StudentId = s.Id
    WHERE s.Department = 'IT'
    AND e.EnrollmentId NOT IN (SELECT EnrollmentId FROM StudentEnrollments_IT);
    
    SET IDENTITY_INSERT StudentEnrollments_IT OFF;
    
    PRINT '  ? Migrated ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' enrollment records';
END TRY
BEGIN CATCH
    SET IDENTITY_INSERT StudentEnrollments_IT OFF;
    PRINT '  ? Enrollment migration: ' + ERROR_MESSAGE();
END CATCH

PRINT '';
PRINT '? IT Department migration complete';
PRINT '';

-- ============================================
-- MIGRATE ECE DEPARTMENT
-- ============================================
PRINT '=== Migrating ECE Department ===';
PRINT '';

-- 1. Migrate Faculty
BEGIN TRY
    SET IDENTITY_INSERT Faculty_ECE ON;
    
    INSERT INTO Faculty_ECE 
    (FacultyId, Name, Email, Password, Department, Specialization, Qualification, 
     ExperienceYears, PhoneNumber, IsActive, CreatedDate, LastLogin, ProfileImageUrl)
    SELECT 
        FacultyId, Name, Email, Password, Department, Specialization, Qualification,
        ExperienceYears, PhoneNumber, IsActive, CreatedDate, LastLogin, ProfileImageUrl
    FROM Faculties
    WHERE Department = 'ECE'
    AND FacultyId NOT IN (SELECT FacultyId FROM Faculty_ECE);
    
    SET IDENTITY_INSERT Faculty_ECE OFF;
    
    PRINT '  ? Migrated ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' faculty records';
END TRY
BEGIN CATCH
    SET IDENTITY_INSERT Faculty_ECE OFF;
    PRINT '  ? Faculty migration: ' + ERROR_MESSAGE();
END CATCH

-- 2. Migrate Students
BEGIN TRY
    INSERT INTO Students_ECE 
    (Id, FullName, RegdNumber, Department, Year, Semester, Email, PhoneNumber, 
     Password, IsActive, CreatedDate, LastLogin)
    SELECT 
        Id, FullName, RegdNumber, Department, Year, Semester, Email, PhoneNumber,
        Password, IsActive, CreatedDate, LastLogin
    FROM Students
    WHERE Department = 'ECE'
    AND Id NOT IN (SELECT Id FROM Students_ECE);
    
    PRINT '  ? Migrated ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' student records';
END TRY
BEGIN CATCH
    PRINT '  ? Student migration: ' + ERROR_MESSAGE();
END CATCH

-- 3. Migrate Subjects
BEGIN TRY
    SET IDENTITY_INSERT Subjects_ECE ON;
    
    INSERT INTO Subjects_ECE 
    (SubjectId, Name, SubjectCode, Department, SubjectType, Year, Semester, Credits, IsActive, CreatedDate)
    SELECT 
        SubjectId, Name, SubjectCode, Department, SubjectType, Year, Semester, Credits, IsActive, CreatedDate
    FROM Subjects
    WHERE Department = 'ECE'
    AND SubjectId NOT IN (SELECT SubjectId FROM Subjects_ECE);
    
    SET IDENTITY_INSERT Subjects_ECE OFF;
    
    PRINT '  ? Migrated ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' subject records';
END TRY
BEGIN CATCH
    SET IDENTITY_INSERT Subjects_ECE OFF;
    PRINT '  ? Subject migration: ' + ERROR_MESSAGE();
END CATCH

-- 4. Migrate AssignedSubjects
BEGIN TRY
    SET IDENTITY_INSERT AssignedSubjects_ECE ON;
    
    INSERT INTO AssignedSubjects_ECE 
    (AssignmentId, SubjectId, FacultyId, Department, Year, Semester, MaxEnrollments, CurrentEnrollments, IsActive, AssignedDate)
    SELECT 
        AssignmentId, SubjectId, FacultyId, Department, Year, Semester, MaxEnrollments, CurrentEnrollments, IsActive, AssignedDate
    FROM AssignedSubjects
    WHERE Department = 'ECE'
    AND AssignmentId NOT IN (SELECT AssignmentId FROM AssignedSubjects_ECE);
    
    SET IDENTITY_INSERT AssignedSubjects_ECE OFF;
    
    PRINT '  ? Migrated ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' assigned subject records';
END TRY
BEGIN CATCH
    SET IDENTITY_INSERT AssignedSubjects_ECE OFF;
    PRINT '  ? AssignedSubjects migration: ' + ERROR_MESSAGE();
END CATCH

-- 5. Migrate StudentEnrollments
BEGIN TRY
    SET IDENTITY_INSERT StudentEnrollments_ECE ON;
    
    INSERT INTO StudentEnrollments_ECE 
    (EnrollmentId, StudentId, AssignmentId, SubjectId, FacultyId, EnrollmentDate, IsActive)
    SELECT 
        e.EnrollmentId, e.StudentId, e.AssignmentId, e.SubjectId, e.FacultyId, e.EnrollmentDate, e.IsActive
    FROM StudentEnrollments e
    INNER JOIN Students s ON e.StudentId = s.Id
    WHERE s.Department = 'ECE'
    AND e.EnrollmentId NOT IN (SELECT EnrollmentId FROM StudentEnrollments_ECE);
    
    SET IDENTITY_INSERT StudentEnrollments_ECE OFF;
    
    PRINT '  ? Migrated ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' enrollment records';
END TRY
BEGIN CATCH
    SET IDENTITY_INSERT StudentEnrollments_ECE OFF;
    PRINT '  ? Enrollment migration: ' + ERROR_MESSAGE();
END CATCH

PRINT '';
PRINT '? ECE Department migration complete';
PRINT '';

-- ============================================
-- MIGRATE MECH DEPARTMENT
-- ============================================
PRINT '=== Migrating MECH Department ===';
PRINT '';

-- 1. Migrate Faculty
BEGIN TRY
    SET IDENTITY_INSERT Faculty_MECH ON;
    
    INSERT INTO Faculty_MECH 
    (FacultyId, Name, Email, Password, Department, Specialization, Qualification, 
     ExperienceYears, PhoneNumber, IsActive, CreatedDate, LastLogin, ProfileImageUrl)
    SELECT 
        FacultyId, Name, Email, Password, Department, Specialization, Qualification,
        ExperienceYears, PhoneNumber, IsActive, CreatedDate, LastLogin, ProfileImageUrl
    FROM Faculties
    WHERE Department = 'MECH'
    AND FacultyId NOT IN (SELECT FacultyId FROM Faculty_MECH);
    
    SET IDENTITY_INSERT Faculty_MECH OFF;
    
    PRINT '  ? Migrated ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' faculty records';
END TRY
BEGIN CATCH
    SET IDENTITY_INSERT Faculty_MECH OFF;
    PRINT '  ? Faculty migration: ' + ERROR_MESSAGE();
END CATCH

-- 2. Migrate Students
BEGIN TRY
    INSERT INTO Students_MECH 
    (Id, FullName, RegdNumber, Department, Year, Semester, Email, PhoneNumber, 
     Password, IsActive, CreatedDate, LastLogin)
    SELECT 
        Id, FullName, RegdNumber, Department, Year, Semester, Email, PhoneNumber,
        Password, IsActive, CreatedDate, LastLogin
    FROM Students
    WHERE Department = 'MECH'
    AND Id NOT IN (SELECT Id FROM Students_MECH);
    
    PRINT '  ? Migrated ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' student records';
END TRY
BEGIN CATCH
    PRINT '  ? Student migration: ' + ERROR_MESSAGE();
END CATCH

-- 3. Migrate Subjects
BEGIN TRY
    SET IDENTITY_INSERT Subjects_MECH ON;
    
    INSERT INTO Subjects_MECH 
    (SubjectId, Name, SubjectCode, Department, SubjectType, Year, Semester, Credits, IsActive, CreatedDate)
    SELECT 
        SubjectId, Name, SubjectCode, Department, SubjectType, Year, Semester, Credits, IsActive, CreatedDate
    FROM Subjects
    WHERE Department = 'MECH'
    AND SubjectId NOT IN (SELECT SubjectId FROM Subjects_MECH);
    
    SET IDENTITY_INSERT Subjects_MECH OFF;
    
    PRINT '  ? Migrated ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' subject records';
END TRY
BEGIN CATCH
    SET IDENTITY_INSERT Subjects_MECH OFF;
    PRINT '  ? Subject migration: ' + ERROR_MESSAGE();
END CATCH

-- 4. Migrate AssignedSubjects
BEGIN TRY
    SET IDENTITY_INSERT AssignedSubjects_MECH ON;
    
    INSERT INTO AssignedSubjects_MECH 
    (AssignmentId, SubjectId, FacultyId, Department, Year, Semester, MaxEnrollments, CurrentEnrollments, IsActive, AssignedDate)
    SELECT 
        AssignmentId, SubjectId, FacultyId, Department, Year, Semester, MaxEnrollments, CurrentEnrollments, IsActive, AssignedDate
    FROM AssignedSubjects
    WHERE Department = 'MECH'
    AND AssignmentId NOT IN (SELECT AssignmentId FROM AssignedSubjects_MECH);
    
    SET IDENTITY_INSERT AssignedSubjects_MECH OFF;
    
    PRINT '  ? Migrated ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' assigned subject records';
END TRY
BEGIN CATCH
    SET IDENTITY_INSERT AssignedSubjects_MECH OFF;
    PRINT '  ? AssignedSubjects migration: ' + ERROR_MESSAGE();
END CATCH

-- 5. Migrate StudentEnrollments
BEGIN TRY
    SET IDENTITY_INSERT StudentEnrollments_MECH ON;
    
    INSERT INTO StudentEnrollments_MECH 
    (EnrollmentId, StudentId, AssignmentId, SubjectId, FacultyId, EnrollmentDate, IsActive)
    SELECT 
        e.EnrollmentId, e.StudentId, e.AssignmentId, e.SubjectId, e.FacultyId, e.EnrollmentDate, e.IsActive
    FROM StudentEnrollments e
    INNER JOIN Students s ON e.StudentId = s.Id
    WHERE s.Department = 'MECH'
    AND e.EnrollmentId NOT IN (SELECT EnrollmentId FROM StudentEnrollments_MECH);
    
    SET IDENTITY_INSERT StudentEnrollments_MECH OFF;
    
    PRINT '  ? Migrated ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' enrollment records';
END TRY
BEGIN CATCH
    SET IDENTITY_INSERT StudentEnrollments_MECH OFF;
    PRINT '  ? Enrollment migration: ' + ERROR_MESSAGE();
END CATCH

PRINT '';
PRINT '? MECH Department migration complete';
PRINT '';

-- ============================================
-- VERIFICATION
-- ============================================
PRINT '========================================';
PRINT 'VERIFICATION SUMMARY';
PRINT '========================================';
PRINT '';

PRINT '--- DES Department ---';
SELECT 
    'Faculty' AS TableType, 
    COUNT(*) AS RecordCount 
FROM Faculty_DES
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
SELECT 
    'Faculty' AS TableType, 
    COUNT(*) AS RecordCount 
FROM Faculty_IT
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
SELECT 
    'Faculty' AS TableType, 
    COUNT(*) AS RecordCount 
FROM Faculty_ECE
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
SELECT 
    'Faculty' AS TableType, 
    COUNT(*) AS RecordCount 
FROM Faculty_MECH
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
PRINT '? DATA MIGRATION COMPLETE!';
PRINT 'Completed at: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '========================================';
PRINT '';
PRINT '?? SUMMARY:';
PRINT '- Migrated data for 4 departments: DES, IT, ECE, MECH';
PRINT '- All existing data copied from shared tables';
PRINT '- Shared tables remain intact (backward compatibility)';
PRINT '';
PRINT '?? NEXT STEPS:';
PRINT '1. Review verification results above';
PRINT '2. Run: .\VERIFY_ALL_DEPARTMENTS_MIGRATION.ps1';
PRINT '3. Test admin login for each department';
PRINT '';
