using System;
using System.Collections.Generic;

namespace TutorLiveMentor.Models
{
    /// <summary>
    /// Configuration for dynamic department-specific tables
    /// Defines naming conventions and table structures
    /// </summary>
    public class DynamicTableConfiguration
    {
        /// <summary>
        /// Get normalized department code for table naming
        /// Removes special characters: CSE(DS) -> CSEDS
        /// </summary>
        public static string NormalizeDepartmentCode(string departmentCode)
        {
            if (string.IsNullOrWhiteSpace(departmentCode))
                return string.Empty;

            return departmentCode
                .Replace("(", "")
                .Replace(")", "")
                .Replace(" ", "")
                .Replace("-", "")
                .Replace("&", "AND")
                .ToUpper();
        }

        /// <summary>
        /// Get all table names for a department
        /// </summary>
        public static List<string> GetTableNames(string departmentCode)
        {
            var normalized = NormalizeDepartmentCode(departmentCode);
            return new List<string>
            {
                $"Faculty_{normalized}",
                $"Students_{normalized}",
                $"Subjects_{normalized}",
                $"AssignedSubjects_{normalized}",
                $"StudentEnrollments_{normalized}"
            };
        }

        /// <summary>
        /// Get faculty table name for department
        /// </summary>
        public static string GetFacultyTable(string departmentCode)
            => $"Faculty_{NormalizeDepartmentCode(departmentCode)}";

        /// <summary>
        /// Get students table name for department
        /// </summary>
        public static string GetStudentsTable(string departmentCode)
            => $"Students_{NormalizeDepartmentCode(departmentCode)}";

        /// <summary>
        /// Get subjects table name for department
        /// </summary>
        public static string GetSubjectsTable(string departmentCode)
            => $"Subjects_{NormalizeDepartmentCode(departmentCode)}";

        /// <summary>
        /// Get assigned subjects table name for department
        /// </summary>
        public static string GetAssignedSubjectsTable(string departmentCode)
            => $"AssignedSubjects_{NormalizeDepartmentCode(departmentCode)}";

        /// <summary>
        /// Get student enrollments table name for department
        /// </summary>
        public static string GetStudentEnrollmentsTable(string departmentCode)
            => $"StudentEnrollments_{NormalizeDepartmentCode(departmentCode)}";

        /// <summary>
        /// Check if a department uses dynamic tables
        /// Currently all departments use dynamic tables
        /// </summary>
        public static bool UsesDynamicTables(string departmentCode)
        {
            // All departments use dynamic tables
            return !string.IsNullOrWhiteSpace(departmentCode);
        }

        /// <summary>
        /// Get database schema information for a department
        /// </summary>
        public static DepartmentSchemaInfo GetSchemaInfo(string departmentCode)
        {
            var normalized = NormalizeDepartmentCode(departmentCode);
            return new DepartmentSchemaInfo
            {
                DepartmentCode = departmentCode,
                NormalizedCode = normalized,
                TableNames = GetTableNames(departmentCode),
                UsesDynamicTables = true
            };
        }
    }

    /// <summary>
    /// Information about a department's database schema
    /// </summary>
    public class DepartmentSchemaInfo
    {
        public string DepartmentCode { get; set; } = string.Empty;
        public string NormalizedCode { get; set; } = string.Empty;
        public List<string> TableNames { get; set; } = new();
        public bool UsesDynamicTables { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.Now;
    }

    /// <summary>
    /// Result of table creation operation
    /// </summary>
    public class TableCreationResult
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;
        public List<string> CreatedTables { get; set; } = new();
        public List<string> Errors { get; set; } = new();
        public TimeSpan Duration { get; set; }
    }

    /// <summary>
    /// Result of data migration operation
    /// </summary>
    public class DataMigrationResult
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;
        public int FacultyMigrated { get; set; }
        public int StudentsMigrated { get; set; }
        public int SubjectsMigrated { get; set; }
        public int AssignmentsMigrated { get; set; }
        public int EnrollmentsMigrated { get; set; }
        public List<string> Errors { get; set; } = new();
        public TimeSpan Duration { get; set; }
    }
}
