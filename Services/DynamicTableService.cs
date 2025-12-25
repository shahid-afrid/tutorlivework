using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using TutorLiveMentor.Models;

namespace TutorLiveMentor.Services
{
    /// <summary>
    /// Dynamic Table Service - Creates department-specific database tables
    /// Each department gets isolated tables using CSEDS STANDARD SCHEMA:
    ///   - Faculty_{DEPT}: FacultyId, Name, Email, Password, Department
    ///   - Students_{DEPT}: Id, FullName, RegdNumber, Year, Department, Semester, Email, Password, SelectedSubject
    ///   - Subjects_{DEPT}: SubjectId, Name, Department, Year, Semester, SemesterStartDate, SemesterEndDate, SubjectType, MaxEnrollments
    ///   - AssignedSubjects_{DEPT}: AssignedSubjectId, FacultyId, SubjectId, Department, Year, SelectedCount
    ///   - StudentEnrollments_{DEPT}: StudentId, AssignedSubjectId, EnrolledAt
    /// This ensures complete data isolation and scalability
    /// </summary>
    public class DynamicTableService
    {
        private readonly AppDbContext _context;
        private readonly string _connectionString;

        public DynamicTableService(AppDbContext context, IConfiguration configuration)
        {
            _context = context;
            _connectionString = configuration.GetConnectionString("DefaultConnection") ?? string.Empty;
        }

        /// <summary>
        /// Creates all necessary tables for a new department using CSEDS standard schema
        /// Returns true if successful, false otherwise
        /// </summary>
        public async Task<(bool Success, string Message)> CreateDepartmentTables(string departmentCode)
        {
            try
            {
                var normalizedCode = departmentCode.Replace("(", "").Replace(")", "").Replace(" ", "");

                // Check if tables already exist
                if (await TableExists($"Faculty_{normalizedCode}"))
                {
                    return (false, $"Tables for department {departmentCode} already exist.");
                }

                // Create all tables in a transaction
                using (var connection = new SqlConnection(_connectionString))
                {
                    await connection.OpenAsync();
                    using (var transaction = connection.BeginTransaction())
                    {
                        try
                        {
                            Console.WriteLine($"[DYNAMIC TABLES] Creating tables for {normalizedCode} with CSEDS standard schema...");

                            // 1. Create Faculty table (CSEDS STANDARD)
                            await ExecuteNonQuery(connection, transaction, CreateFacultyTableSql(normalizedCode));
                            Console.WriteLine($"[DYNAMIC TABLES] ? Faculty_{normalizedCode} created");

                            // 2. Create Students table (CSEDS STANDARD)
                            await ExecuteNonQuery(connection, transaction, CreateStudentsTableSql(normalizedCode));
                            Console.WriteLine($"[DYNAMIC TABLES] ? Students_{normalizedCode} created");

                            // 3. Create Subjects table (CSEDS STANDARD)
                            await ExecuteNonQuery(connection, transaction, CreateSubjectsTableSql(normalizedCode));
                            Console.WriteLine($"[DYNAMIC TABLES] ? Subjects_{normalizedCode} created");

                            // 4. Create AssignedSubjects table (CSEDS STANDARD)
                            await ExecuteNonQuery(connection, transaction, CreateAssignedSubjectsTableSql(normalizedCode));
                            Console.WriteLine($"[DYNAMIC TABLES] ? AssignedSubjects_{normalizedCode} created");

                            // 5. Create StudentEnrollments table (CSEDS STANDARD)
                            await ExecuteNonQuery(connection, transaction, CreateStudentEnrollmentsTableSql(normalizedCode));
                            Console.WriteLine($"[DYNAMIC TABLES] ? StudentEnrollments_{normalizedCode} created");

                            transaction.Commit();
                            Console.WriteLine($"[DYNAMIC TABLES] ? All tables created successfully for {normalizedCode}");
                            return (true, $"Successfully created all tables for department {departmentCode} with CSEDS schema");
                        }
                        catch (Exception ex)
                        {
                            transaction.Rollback();
                            Console.WriteLine($"[DYNAMIC TABLES] ? Error creating tables: {ex.Message}");
                            return (false, $"Error creating tables: {ex.Message}");
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[DYNAMIC TABLES] ? Database connection error: {ex.Message}");
                return (false, $"Database connection error: {ex.Message}");
            }
        }

        /// <summary>
        /// Check if a table exists in the database
        /// </summary>
        public async Task<bool> TableExists(string tableName)
        {
            try
            {
                using (var connection = new SqlConnection(_connectionString))
                {
                    await connection.OpenAsync();
                    var sql = @"
                        SELECT COUNT(*) 
                        FROM INFORMATION_SCHEMA.TABLES 
                        WHERE TABLE_NAME = @TableName";

                    using (var command = new SqlCommand(sql, connection))
                    {
                        command.Parameters.AddWithValue("@TableName", tableName);
                        var result = await command.ExecuteScalarAsync();
                        return Convert.ToInt32(result) > 0;
                    }
                }
            }
            catch
            {
                return false;
            }
        }

        /// <summary>
        /// Get all department-specific table names
        /// </summary>
        public async Task<List<string>> GetDepartmentTables(string departmentCode)
        {
            var normalizedCode = departmentCode.Replace("(", "").Replace(")", "").Replace(" ", "");
            return new List<string>
            {
                $"Faculty_{normalizedCode}",
                $"Students_{normalizedCode}",
                $"Subjects_{normalizedCode}",
                $"AssignedSubjects_{normalizedCode}",
                $"StudentEnrollments_{normalizedCode}"
            };
        }

        #region SQL Generation Methods - CSEDS STANDARD SCHEMA

        /// <summary>
        /// CSEDS STANDARD SCHEMA - Faculty Table
        /// Columns: FacultyId, Name, Email, Password, Department
        /// </summary>
        private string CreateFacultyTableSql(string deptCode) => $@"
            CREATE TABLE [dbo].[Faculty_{deptCode}] (
                [FacultyId] INT IDENTITY(1,1) PRIMARY KEY,
                [Name] NVARCHAR(100) NOT NULL,
                [Email] NVARCHAR(100) NOT NULL UNIQUE,
                [Password] NVARCHAR(255) NOT NULL,
                [Department] NVARCHAR(50) NOT NULL DEFAULT '{deptCode}'
            );
            CREATE INDEX IX_Faculty_{deptCode}_Email ON Faculty_{deptCode}(Email);
            CREATE INDEX IX_Faculty_{deptCode}_Department ON Faculty_{deptCode}(Department);
        ";

        /// <summary>
        /// CSEDS STANDARD SCHEMA - Students Table
        /// Columns: Id, FullName, RegdNumber, Year, Department, Semester, Email, Password, SelectedSubject
        /// </summary>
        private string CreateStudentsTableSql(string deptCode) => $@"
            CREATE TABLE [dbo].[Students_{deptCode}] (
                [Id] NVARCHAR(50) PRIMARY KEY,
                [FullName] NVARCHAR(200) NOT NULL,
                [RegdNumber] NVARCHAR(10) NOT NULL,
                [Year] NVARCHAR(50) NOT NULL,
                [Department] NVARCHAR(50) NOT NULL DEFAULT '{deptCode}',
                [Semester] NVARCHAR(50) NULL,
                [Email] NVARCHAR(200) NOT NULL UNIQUE,
                [Password] NVARCHAR(500) NOT NULL,
                [SelectedSubject] NVARCHAR(MAX) NULL
            );
            CREATE INDEX IX_Students_{deptCode}_Email ON Students_{deptCode}(Email);
            CREATE INDEX IX_Students_{deptCode}_RegdNumber ON Students_{deptCode}(RegdNumber);
            CREATE INDEX IX_Students_{deptCode}_Year ON Students_{deptCode}(Year);
            CREATE INDEX IX_Students_{deptCode}_Department ON Students_{deptCode}(Department);
        ";

        /// <summary>
        /// CSEDS STANDARD SCHEMA - Subjects Table
        /// Columns: SubjectId, Name, Department, Year, Semester, SemesterStartDate, SemesterEndDate, SubjectType, MaxEnrollments
        /// </summary>
        private string CreateSubjectsTableSql(string deptCode) => $@"
            CREATE TABLE [dbo].[Subjects_{deptCode}] (
                [SubjectId] INT IDENTITY(1,1) PRIMARY KEY,
                [Name] NVARCHAR(200) NOT NULL,
                [Department] NVARCHAR(50) NOT NULL DEFAULT '{deptCode}',
                [Year] INT NOT NULL DEFAULT 1,
                [Semester] NVARCHAR(50) NULL,
                [SemesterStartDate] DATETIME2 NULL,
                [SemesterEndDate] DATETIME2 NULL,
                [SubjectType] NVARCHAR(50) NOT NULL DEFAULT 'Core',
                [MaxEnrollments] INT NULL
            );
            CREATE INDEX IX_Subjects_{deptCode}_Year ON Subjects_{deptCode}(Year);
            CREATE INDEX IX_Subjects_{deptCode}_Department ON Subjects_{deptCode}(Department);
        ";

        /// <summary>
        /// CSEDS STANDARD SCHEMA - AssignedSubjects Table
        /// Columns: AssignedSubjectId, FacultyId, SubjectId, Department, Year, SelectedCount
        /// </summary>
        private string CreateAssignedSubjectsTableSql(string deptCode) => $@"
            CREATE TABLE [dbo].[AssignedSubjects_{deptCode}] (
                [AssignedSubjectId] INT IDENTITY(1,1) PRIMARY KEY,
                [FacultyId] INT NOT NULL,
                [SubjectId] INT NOT NULL,
                [Department] NVARCHAR(50) NOT NULL,
                [Year] INT NOT NULL,
                [SelectedCount] INT NOT NULL DEFAULT 0,
                CONSTRAINT FK_AssignedSubjects_{deptCode}_Subject 
                    FOREIGN KEY ([SubjectId]) REFERENCES [Subjects_{deptCode}]([SubjectId]) ON DELETE CASCADE,
                CONSTRAINT FK_AssignedSubjects_{deptCode}_Faculty 
                    FOREIGN KEY ([FacultyId]) REFERENCES [Faculty_{deptCode}]([FacultyId]) ON DELETE CASCADE
            );
            CREATE INDEX IX_AssignedSubjects_{deptCode}_Faculty ON AssignedSubjects_{deptCode}(FacultyId);
            CREATE INDEX IX_AssignedSubjects_{deptCode}_Subject ON AssignedSubjects_{deptCode}(SubjectId);
        ";

        /// <summary>
        /// CSEDS STANDARD SCHEMA - StudentEnrollments Table
        /// Columns: StudentId, AssignedSubjectId, EnrolledAt
        /// </summary>
        private string CreateStudentEnrollmentsTableSql(string deptCode) => $@"
            CREATE TABLE [dbo].[StudentEnrollments_{deptCode}] (
                [StudentId] NVARCHAR(50) NOT NULL,
                [AssignedSubjectId] INT NOT NULL,
                [EnrolledAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
                PRIMARY KEY ([StudentId], [AssignedSubjectId]),
                CONSTRAINT FK_StudentEnrollments_{deptCode}_Student 
                    FOREIGN KEY ([StudentId]) REFERENCES [Students_{deptCode}]([Id]) ON DELETE CASCADE,
                CONSTRAINT FK_StudentEnrollments_{deptCode}_AssignedSubject 
                    FOREIGN KEY ([AssignedSubjectId]) REFERENCES [AssignedSubjects_{deptCode}]([AssignedSubjectId]) ON DELETE CASCADE
            );
            CREATE INDEX IX_StudentEnrollments_{deptCode}_Student ON StudentEnrollments_{deptCode}(StudentId);
            CREATE INDEX IX_StudentEnrollments_{deptCode}_AssignedSubject ON StudentEnrollments_{deptCode}(AssignedSubjectId);
        ";

        #endregion

        #region Helper Methods

        private async Task ExecuteNonQuery(SqlConnection connection, SqlTransaction transaction, string sql)
        {
            using (var command = new SqlCommand(sql, connection, transaction))
            {
                command.CommandTimeout = 120; // 2 minutes timeout
                await command.ExecuteNonQueryAsync();
            }
        }

        #endregion
    }
}
