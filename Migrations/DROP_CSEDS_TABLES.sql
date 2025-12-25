-- Drop existing CSEDS tables to start fresh
PRINT 'Dropping existing CSEDS tables...';

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_StudentEnrollments_CSEDS_AssignedSubject')
    ALTER TABLE StudentEnrollments_CSEDS DROP CONSTRAINT FK_StudentEnrollments_CSEDS_AssignedSubject;

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_StudentEnrollments_CSEDS_Student')
    ALTER TABLE StudentEnrollments_CSEDS DROP CONSTRAINT FK_StudentEnrollments_CSEDS_Student;

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_AssignedSubjects_CSEDS_Faculty')
    ALTER TABLE AssignedSubjects_CSEDS DROP CONSTRAINT FK_AssignedSubjects_CSEDS_Faculty;

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_AssignedSubjects_CSEDS_Subject')
    ALTER TABLE AssignedSubjects_CSEDS DROP CONSTRAINT FK_AssignedSubjects_CSEDS_Subject;

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'StudentEnrollments_CSEDS')
    DROP TABLE StudentEnrollments_CSEDS;

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'AssignedSubjects_CSEDS')
    DROP TABLE AssignedSubjects_CSEDS;

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Subjects_CSEDS')
    DROP TABLE Subjects_CSEDS;

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Students_CSEDS')
    DROP TABLE Students_CSEDS;

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Faculty_CSEDS')
    DROP TABLE Faculty_CSEDS;

PRINT 'All CSEDS tables dropped successfully!';
