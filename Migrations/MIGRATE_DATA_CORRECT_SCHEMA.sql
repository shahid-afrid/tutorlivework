-- ============================================
-- MIGRATE DATA - SCHEMA-CORRECT VERSION
-- ============================================
-- This migration matches the ACTUAL database schema
-- ============================================

USE [Working5Db];
GO

PRINT '========================================';
PRINT 'DATA MIGRATION (SCHEMA-MATCHED)';
PRINT 'Started at: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '========================================';
PRINT '';

-- Check what data exists in shared tables by department
PRINT '=== Current Data in Shared Tables ===';
PRINT '';

SELECT 'Faculty' AS TableType, Department, COUNT(*) AS Count
FROM Faculties
WHERE Department IN ('DES', 'IT', 'ECE', 'MECH')
GROUP BY Department

UNION ALL

SELECT 'Students', Department, COUNT(*)
FROM Students  
WHERE Department IN ('DES', 'IT', 'ECE', 'MECH')
GROUP BY Department

UNION ALL

SELECT 'Subjects', Department, COUNT(*)
FROM Subjects
WHERE Department IN ('DES', 'IT', 'ECE', 'MECH')
GROUP BY Department

UNION ALL

SELECT 'AssignedSubjects', Department, COUNT(*)
FROM AssignedSubjects
WHERE Department IN ('DES', 'IT', 'ECE', 'MECH')
GROUP BY Department;

PRINT '';
PRINT '========================================';
PRINT '';

-- ============================================
-- MIGRATE DES DEPARTMENT
-- ============================================
PRINT '=== Migrating DES Department ===';

-- Faculty
BEGIN TRY
    SET IDENTITY_INSERT Faculty_DES ON;
    
    INSERT INTO Faculty_DES (FacultyId, Name, Email, Password, Department)
    SELECT FacultyId, Name, Email, Password, Department
    FROM Faculties
    WHERE Department = 'DES'
    AND FacultyId NOT IN (SELECT FacultyId FROM Faculty_DES);
    
    SET IDENTITY_INSERT Faculty_DES OFF;
    PRINT '  ? Faculty: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' records';
END TRY
BEGIN CATCH
    SET IDENTITY_INSERT Faculty_DES OFF;
    PRINT '  ? Faculty error: ' + ERROR_MESSAGE();
END CATCH

-- Students  
BEGIN TRY
    INSERT INTO Students_DES (Id, FullName, RegdNumber, Department, Year, Semester, Email, Password)
    SELECT Id, FullName, RegdNumber, Department, 
           CAST(Year AS INT), 
           Semester, Email, Password
    FROM Students
    WHERE Department = 'DES'
    AND Id NOT IN (SELECT Id FROM Students_DES);
    
    PRINT '  ? Students: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' records';
END TRY
BEGIN CATCH
    PRINT '  ? Students error: ' + ERROR_MESSAGE();
END CATCH

-- Subjects
BEGIN TRY
    SET IDENTITY_INSERT Subjects_DES ON;
    
    INSERT INTO Subjects_DES (SubjectId, Name, Department, SubjectType, Year, Semester)
    SELECT SubjectId, Name, Department, SubjectType, Year, Semester
    FROM Subjects
    WHERE Department = 'DES'
    AND SubjectId NOT IN (SELECT SubjectId FROM Subjects_DES);
    
    SET IDENTITY_INSERT Subjects_DES OFF;
    PRINT '  ? Subjects: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' records';
END TRY
BEGIN CATCH
    SET IDENTITY_INSERT Subjects_DES OFF;
    PRINT '  ? Subjects error: ' + ERROR_MESSAGE();
END CATCH

-- AssignedSubjects
BEGIN TRY
    SET IDENTITY_INSERT AssignedSubjects_DES ON;
    
    INSERT INTO AssignedSubjects_DES (AssignmentId, SubjectId, FacultyId, Department, Year)
    SELECT AssignedSubjectId, SubjectId, FacultyId, Department, Year
    FROM AssignedSubjects
    WHERE Department = 'DES'
    AND AssignedSubjectId NOT IN (SELECT AssignmentId FROM AssignedSubjects_DES);
    
    SET IDENTITY_INSERT AssignedSubjects_DES OFF;
    PRINT '  ? AssignedSubjects: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' records';
END TRY
BEGIN CATCH
    SET IDENTITY_INSERT AssignedSubjects_DES OFF;
    PRINT '  ? AssignedSubjects error: ' + ERROR_MESSAGE();
END CATCH

-- StudentEnrollments
BEGIN TRY
    SET IDENTITY_INSERT StudentEnrollments_DES ON;
    
    INSERT INTO StudentEnrollments_DES (EnrollmentId, StudentId, AssignmentId, SubjectId, FacultyId)
    SELECT 
        ROW_NUMBER() OVER (ORDER BY se.StudentId) AS EnrollmentId,
        se.StudentId,
        se.AssignedSubjectId,
        asub.SubjectId,
        asub.FacultyId
    FROM StudentEnrollments se
    INNER JOIN Students s ON se.StudentId = s.Id
    INNER JOIN AssignedSubjects asub ON se.AssignedSubjectId = asub.AssignedSubjectId
    WHERE s.Department = 'DES';
    
    SET IDENTITY_INSERT StudentEnrollments_DES OFF;
    PRINT '  ? StudentEnrollments: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' records';
END TRY
BEGIN CATCH
    SET IDENTITY_INSERT StudentEnrollments_DES OFF;
    PRINT '  ? StudentEnrollments error: ' + ERROR_MESSAGE();
END CATCH

PRINT '? DES complete';
PRINT '';

-- ============================================
-- MIGRATE IT DEPARTMENT
-- ============================================
PRINT '=== Migrating IT Department ===';

-- Faculty
BEGIN TRY
    SET IDENTITY_INSERT Faculty_IT ON;
    
    INSERT INTO Faculty_IT (FacultyId, Name, Email, Password, Department)
    SELECT FacultyId, Name, Email, Password, Department
    FROM Faculties
    WHERE Department = 'IT'
    AND FacultyId NOT IN (SELECT FacultyId FROM Faculty_IT);
    
    SET IDENTITY_INSERT Faculty_IT OFF;
    PRINT '  ? Faculty: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' records';
END TRY
BEGIN CATCH
    SET IDENTITY_INSERT Faculty_IT OFF;
    PRINT '  ? Faculty error: ' + ERROR_MESSAGE();
END CATCH

-- Students
BEGIN TRY
    INSERT INTO Students_IT (Id, FullName, RegdNumber, Department, Year, Semester, Email, Password)
    SELECT Id, FullName, RegdNumber, Department, 
           CAST(Year AS INT), 
           Semester, Email, Password
    FROM Students
    WHERE Department = 'IT'
    AND Id NOT IN (SELECT Id FROM Students_IT);
    
    PRINT '  ? Students: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' records';
END TRY
BEGIN CATCH
    PRINT '  ? Students error: ' + ERROR_MESSAGE();
END CATCH

-- Subjects
BEGIN TRY
    SET IDENTITY_INSERT Subjects_IT ON;
    
    INSERT INTO Subjects_IT (SubjectId, Name, Department, SubjectType, Year, Semester)
    SELECT SubjectId, Name, Department, SubjectType, Year, Semester
    FROM Subjects
    WHERE Department = 'IT'
    AND SubjectId NOT IN (SELECT SubjectId FROM Subjects_IT);
    
    SET IDENTITY_INSERT Subjects_IT OFF;
    PRINT '  ? Subjects: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' records';
END TRY
BEGIN CATCH
    SET IDENTITY_INSERT Subjects_IT OFF;
    PRINT '  ? Subjects error: ' + ERROR_MESSAGE();
END CATCH

-- AssignedSubjects
BEGIN TRY
    SET IDENTITY_INSERT AssignedSubjects_IT ON;
    
    INSERT INTO AssignedSubjects_IT (AssignmentId, SubjectId, FacultyId, Department, Year)
    SELECT AssignedSubjectId, SubjectId, FacultyId, Department, Year
    FROM AssignedSubjects
    WHERE Department = 'IT'
    AND AssignedSubjectId NOT IN (SELECT AssignmentId FROM AssignedSubjects_IT);
    
    SET IDENTITY_INSERT AssignedSubjects_IT OFF;
    PRINT '  ? AssignedSubjects: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' records';
END TRY
BEGIN CATCH
    SET IDENTITY_INSERT AssignedSubjects_IT OFF;
    PRINT '  ? AssignedSubjects error: ' + ERROR_MESSAGE();
END CATCH

-- StudentEnrollments
BEGIN TRY
    SET IDENTITY_INSERT StudentEnrollments_IT ON;
    
    INSERT INTO StudentEnrollments_IT (EnrollmentId, StudentId, AssignmentId, SubjectId, FacultyId)
    SELECT 
        ROW_NUMBER() OVER (ORDER BY se.StudentId) AS EnrollmentId,
        se.StudentId,
        se.AssignedSubjectId,
        asub.SubjectId,
        asub.FacultyId
    FROM StudentEnrollments se
    INNER JOIN Students s ON se.StudentId = s.Id
    INNER JOIN AssignedSubjects asub ON se.AssignedSubjectId = asub.AssignedSubjectId
    WHERE s.Department = 'IT';
    
    SET IDENTITY_INSERT StudentEnrollments_IT OFF;
    PRINT '  ? StudentEnrollments: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' records';
END TRY
BEGIN CATCH
    SET IDENTITY_INSERT StudentEnrollments_IT OFF;
    PRINT '  ? StudentEnrollments error: ' + ERROR_MESSAGE();
END CATCH

PRINT '? IT complete';
PRINT '';

-- ============================================
-- MIGRATE ECE DEPARTMENT
-- ============================================
PRINT '=== Migrating ECE Department ===';

-- Faculty
BEGIN TRY
    SET IDENTITY_INSERT Faculty_ECE ON;
    
    INSERT INTO Faculty_ECE (FacultyId, Name, Email, Password, Department)
    SELECT FacultyId, Name, Email, Password, Department
    FROM Faculties
    WHERE Department = 'ECE'
    AND FacultyId NOT IN (SELECT FacultyId FROM Faculty_ECE);
    
    SET IDENTITY_INSERT Faculty_ECE OFF;
    PRINT '  ? Faculty: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' records';
END TRY
BEGIN CATCH
    SET IDENTITY_INSERT Faculty_ECE OFF;
    PRINT '  ? Faculty error: ' + ERROR_MESSAGE();
END CATCH

-- Students
BEGIN TRY
    INSERT INTO Students_ECE (Id, FullName, RegdNumber, Department, Year, Semester, Email, Password)
    SELECT Id, FullName, RegdNumber, Department, 
           CAST(Year AS INT), 
           Semester, Email, Password
    FROM Students
    WHERE Department = 'ECE'
    AND Id NOT IN (SELECT Id FROM Students_ECE);
    
    PRINT '  ? Students: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' records';
END TRY
BEGIN CATCH
    PRINT '  ? Students error: ' + ERROR_MESSAGE();
END CATCH

-- Subjects
BEGIN TRY
    SET IDENTITY_INSERT Subjects_ECE ON;
    
    INSERT INTO Subjects_ECE (SubjectId, Name, Department, SubjectType, Year, Semester)
    SELECT SubjectId, Name, Department, SubjectType, Year, Semester
    FROM Subjects
    WHERE Department = 'ECE'
    AND SubjectId NOT IN (SELECT SubjectId FROM Subjects_ECE);
    
    SET IDENTITY_INSERT Subjects_ECE OFF;
    PRINT '  ? Subjects: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' records';
END TRY
BEGIN CATCH
    SET IDENTITY_INSERT Subjects_ECE OFF;
    PRINT '  ? Subjects error: ' + ERROR_MESSAGE();
END CATCH

-- AssignedSubjects
BEGIN TRY
    SET IDENTITY_INSERT AssignedSubjects_ECE ON;
    
    INSERT INTO AssignedSubjects_ECE (AssignmentId, SubjectId, FacultyId, Department, Year)
    SELECT AssignedSubjectId, SubjectId, FacultyId, Department, Year
    FROM AssignedSubjects
    WHERE Department = 'ECE'
    AND AssignedSubjectId NOT IN (SELECT AssignmentId FROM AssignedSubjects_ECE);
    
    SET IDENTITY_INSERT AssignedSubjects_ECE OFF;
    PRINT '  ? AssignedSubjects: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' records';
END TRY
BEGIN CATCH
    SET IDENTITY_INSERT AssignedSubjects_ECE OFF;
    PRINT '  ? AssignedSubjects error: ' + ERROR_MESSAGE();
END CATCH

-- StudentEnrollments
BEGIN TRY
    SET IDENTITY_INSERT StudentEnrollments_ECE ON;
    
    INSERT INTO StudentEnrollments_ECE (EnrollmentId, StudentId, AssignmentId, SubjectId, FacultyId)
    SELECT 
        ROW_NUMBER() OVER (ORDER BY se.StudentId) AS EnrollmentId,
        se.StudentId,
        se.AssignedSubjectId,
        asub.SubjectId,
        asub.FacultyId
    FROM StudentEnrollments se
    INNER JOIN Students s ON se.StudentId = s.Id
    INNER JOIN AssignedSubjects asub ON se.AssignedSubjectId = asub.AssignedSubjectId
    WHERE s.Department = 'ECE';
    
    SET IDENTITY_INSERT StudentEnrollments_ECE OFF;
    PRINT '  ? StudentEnrollments: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' records';
END TRY
BEGIN CATCH
    SET IDENTITY_INSERT StudentEnrollments_ECE OFF;
    PRINT '  ? StudentEnrollments error: ' + ERROR_MESSAGE();
END CATCH

PRINT '? ECE complete';
PRINT '';

-- ============================================
-- MIGRATE MECH DEPARTMENT
-- ============================================
PRINT '=== Migrating MECH Department ===';

-- Faculty
BEGIN TRY
    SET IDENTITY_INSERT Faculty_MECH ON;
    
    INSERT INTO Faculty_MECH (FacultyId, Name, Email, Password, Department)
    SELECT FacultyId, Name, Email, Password, Department
    FROM Faculties
    WHERE Department = 'MECH'
    AND FacultyId NOT IN (SELECT FacultyId FROM Faculty_MECH);
    
    SET IDENTITY_INSERT Faculty_MECH OFF;
    PRINT '  ? Faculty: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' records';
END TRY
BEGIN CATCH
    SET IDENTITY_INSERT Faculty_MECH OFF;
    PRINT '  ? Faculty error: ' + ERROR_MESSAGE();
END CATCH

-- Students
BEGIN TRY
    INSERT INTO Students_MECH (Id, FullName, RegdNumber, Department, Year, Semester, Email, Password)
    SELECT Id, FullName, RegdNumber, Department, 
           CAST(Year AS INT), 
           Semester, Email, Password
    FROM Students
    WHERE Department = 'MECH'
    AND Id NOT IN (SELECT Id FROM Students_MECH);
    
    PRINT '  ? Students: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' records';
END TRY
BEGIN CATCH
    PRINT '  ? Students error: ' + ERROR_MESSAGE();
END CATCH

-- Subjects
BEGIN TRY
    SET IDENTITY_INSERT Subjects_MECH ON;
    
    INSERT INTO Subjects_MECH (SubjectId, Name, Department, SubjectType, Year, Semester)
    SELECT SubjectId, Name, Department, SubjectType, Year, Semester
    FROM Subjects
    WHERE Department = 'MECH'
    AND SubjectId NOT IN (SELECT SubjectId FROM Subjects_MECH);
    
    SET IDENTITY_INSERT Subjects_MECH OFF;
    PRINT '  ? Subjects: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' records';
END TRY
BEGIN CATCH
    SET IDENTITY_INSERT Subjects_MECH OFF;
    PRINT '  ? Subjects error: ' + ERROR_MESSAGE();
END CATCH

-- AssignedSubjects
BEGIN TRY
    SET IDENTITY_INSERT AssignedSubjects_MECH ON;
    
    INSERT INTO AssignedSubjects_MECH (AssignmentId, SubjectId, FacultyId, Department, Year)
    SELECT AssignedSubjectId, SubjectId, FacultyId, Department, Year
    FROM AssignedSubjects
    WHERE Department = 'MECH'
    AND AssignedSubjectId NOT IN (SELECT AssignmentId FROM AssignedSubjects_MECH);
    
    SET IDENTITY_INSERT AssignedSubjects_MECH OFF;
    PRINT '  ? AssignedSubjects: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' records';
END TRY
BEGIN CATCH
    SET IDENTITY_INSERT AssignedSubjects_MECH OFF;
    PRINT '  ? AssignedSubjects error: ' + ERROR_MESSAGE();
END CATCH

-- StudentEnrollments
BEGIN TRY
    SET IDENTITY_INSERT StudentEnrollments_MECH ON;
    
    INSERT INTO StudentEnrollments_MECH (EnrollmentId, StudentId, AssignmentId, SubjectId, FacultyId)
    SELECT 
        ROW_NUMBER() OVER (ORDER BY se.StudentId) AS EnrollmentId,
        se.StudentId,
        se.AssignedSubjectId,
        asub.SubjectId,
        asub.FacultyId
    FROM StudentEnrollments se
    INNER JOIN Students s ON se.StudentId = s.Id
    INNER JOIN AssignedSubjects asub ON se.AssignedSubjectId = asub.AssignedSubjectId
    WHERE s.Department = 'MECH';
    
    SET IDENTITY_INSERT StudentEnrollments_MECH OFF;
    PRINT '  ? StudentEnrollments: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' records';
END TRY
BEGIN CATCH
    SET IDENTITY_INSERT StudentEnrollments_MECH OFF;
    PRINT '  ? StudentEnrollments error: ' + ERROR_MESSAGE();
END CATCH

PRINT '? MECH complete';
PRINT '';

-- ============================================
-- VERIFICATION
-- ============================================
PRINT '========================================';
PRINT 'FINAL VERIFICATION';
PRINT '========================================';
PRINT '';

SELECT 'DES' AS Dept, 'Faculty' AS Type, COUNT(*) AS Count FROM Faculty_DES
UNION ALL SELECT 'DES', 'Students', COUNT(*) FROM Students_DES
UNION ALL SELECT 'DES', 'Subjects', COUNT(*) FROM Subjects_DES
UNION ALL SELECT 'DES', 'Assignments', COUNT(*) FROM AssignedSubjects_DES
UNION ALL SELECT 'DES', 'Enrollments', COUNT(*) FROM StudentEnrollments_DES

UNION ALL SELECT 'IT', 'Faculty', COUNT(*) FROM Faculty_IT
UNION ALL SELECT 'IT', 'Students', COUNT(*) FROM Students_IT
UNION ALL SELECT 'IT', 'Subjects', COUNT(*) FROM Subjects_IT
UNION ALL SELECT 'IT', 'Assignments', COUNT(*) FROM AssignedSubjects_IT
UNION ALL SELECT 'IT', 'Enrollments', COUNT(*) FROM StudentEnrollments_IT

UNION ALL SELECT 'ECE', 'Faculty', COUNT(*) FROM Faculty_ECE
UNION ALL SELECT 'ECE', 'Students', COUNT(*) FROM Students_ECE
UNION ALL SELECT 'ECE', 'Subjects', COUNT(*) FROM Subjects_ECE
UNION ALL SELECT 'ECE', 'Assignments', COUNT(*) FROM AssignedSubjects_ECE
UNION ALL SELECT 'ECE', 'Enrollments', COUNT(*) FROM StudentEnrollments_ECE

UNION ALL SELECT 'MECH', 'Faculty', COUNT(*) FROM Faculty_MECH
UNION ALL SELECT 'MECH', 'Students', COUNT(*) FROM Students_MECH
UNION ALL SELECT 'MECH', 'Subjects', COUNT(*) FROM Subjects_MECH
UNION ALL SELECT 'MECH', 'Assignments', COUNT(*) FROM AssignedSubjects_MECH
UNION ALL SELECT 'MECH', 'Enrollments', COUNT(*) FROM StudentEnrollments_MECH
ORDER BY Dept, Type;

PRINT '';
PRINT '========================================';
PRINT '? MIGRATION COMPLETE!';
PRINT 'Completed at: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '========================================';
