using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace TutorLiveMentor.Models
{
    /// <summary>
    /// Super Admin Login View Model
    /// </summary>
    public class SuperAdminLoginViewModel
    {
        [Required(ErrorMessage = "Email is required")]
        [EmailAddress(ErrorMessage = "Invalid email format")]
        public string Email { get; set; }

        [Required(ErrorMessage = "Password is required")]
        [DataType(DataType.Password)]
        public string Password { get; set; }

        public bool RememberMe { get; set; }
    }

    /// <summary>
    /// Super Admin Dashboard View Model
    /// </summary>
    public class SuperAdminDashboardViewModel
    {
        public SuperAdmin CurrentSuperAdmin { get; set; }
        public List<DepartmentOverview> Departments { get; set; }
        public SystemStatistics SystemStats { get; set; }
        public List<RecentActivity> RecentActivities { get; set; }
        public List<DepartmentAdmin> DepartmentAdmins { get; set; }
    }

    /// <summary>
    /// Department Overview for Dashboard
    /// </summary>
    public class DepartmentOverview
    {
        public int DepartmentId { get; set; }
        public string DepartmentName { get; set; }
        public string DepartmentCode { get; set; }
        public bool IsActive { get; set; }
        public int TotalStudents { get; set; }
        public int TotalFaculty { get; set; }
        public int TotalSubjects { get; set; }
        public int TotalEnrollments { get; set; }
        public int AdminCount { get; set; }
        public DateTime CreatedDate { get; set; }
    }

    /// <summary>
    /// System-wide Statistics
    /// </summary>
    public class SystemStatistics
    {
        public int TotalDepartments { get; set; }
        public int ActiveDepartments { get; set; }
        public int TotalStudents { get; set; }
        public int TotalFaculty { get; set; }
        public int TotalSubjects { get; set; }
        public int TotalAdmins { get; set; }
        public int TotalEnrollments { get; set; }
        public int TodayEnrollments { get; set; }
        public int ActiveSchedules { get; set; }
    }

    /// <summary>
    /// Recent Activity Log Item
    /// </summary>
    public class RecentActivity
    {
        public int AuditLogId { get; set; }
        public string ActionPerformedBy { get; set; }
        public string ActionType { get; set; }
        public string ActionDescription { get; set; }
        public DateTime ActionDate { get; set; }
        public string Status { get; set; }
    }

    /// <summary>
    /// Department Management View Model
    /// </summary>
    public class DepartmentManagementViewModel
    {
        public List<DepartmentDetailViewModel> Departments { get; set; }
        public DepartmentDetailViewModel CurrentDepartment { get; set; }
    }

    /// <summary>
    /// Department Detail View Model
    /// </summary>
    public class DepartmentDetailViewModel
    {
        public int DepartmentId { get; set; }

        [Required(ErrorMessage = "Department name is required")]
        [StringLength(100)]
        public string DepartmentName { get; set; }

        [Required(ErrorMessage = "Department code is required")]
        [StringLength(20)]
        public string DepartmentCode { get; set; }

        [StringLength(200)]
        public string Description { get; set; }

        public bool IsActive { get; set; }
        public bool AllowStudentRegistration { get; set; }
        public bool AllowFacultyAssignment { get; set; }
        public bool AllowSubjectSelection { get; set; }

        public int TotalStudents { get; set; }
        public int TotalFaculty { get; set; }
        public int TotalSubjects { get; set; }
        public int TotalAdmins { get; set; }

        public DateTime CreatedDate { get; set; }
        public DateTime? LastModifiedDate { get; set; }

        public List<AdminUserSummary> AssignedAdmins { get; set; } = new List<AdminUserSummary>();

        // Admin Auto-Creation Fields
        public bool CreateAdminAccount { get; set; } = true;

        [StringLength(100)]
        public string AdminName { get; set; }

        [EmailAddress(ErrorMessage = "Invalid admin email format")]
        [StringLength(50)]
        public string AdminEmail { get; set; }

        [StringLength(100, MinimumLength = 6, ErrorMessage = "Password must be at least 6 characters")]
        public string AdminPassword { get; set; }

        [Compare("AdminPassword", ErrorMessage = "Passwords do not match")]
        public string ConfirmAdminPassword { get; set; }
    }

    /// <summary>
    /// Admin User Management View Model
    /// </summary>
    public class AdminManagementViewModel
    {
        public List<AdminUserDetailViewModel> Admins { get; set; }
        public List<DepartmentSimple> AvailableDepartments { get; set; }
        public AdminUserDetailViewModel CurrentAdmin { get; set; }
    }

    /// <summary>
    /// Admin User Detail View Model
    /// </summary>
    public class AdminUserDetailViewModel
    {
        public int AdminId { get; set; }

        [Required(ErrorMessage = "Email is required")]
        [EmailAddress(ErrorMessage = "Invalid email format")]
        public string Email { get; set; }

        [Required(ErrorMessage = "Password is required")]
        [StringLength(255, MinimumLength = 6)]
        public string Password { get; set; }

        [Required(ErrorMessage = "Department is required")]
        public string Department { get; set; }

        public DateTime CreatedDate { get; set; }
        public DateTime? LastLogin { get; set; }

        // Department Assignment Info
        public int? DepartmentId { get; set; }
        public string DepartmentName { get; set; }
        public bool CanManageStudents { get; set; }
        public bool CanManageFaculty { get; set; }
        public bool CanManageSubjects { get; set; }
        public bool CanViewReports { get; set; }
        public bool CanManageSchedules { get; set; }

        // Statistics
        public int TotalStudentsManaged { get; set; }
        public int TotalFacultyManaged { get; set; }
        public int TotalSubjectsManaged { get; set; }
    }

    /// <summary>
    /// Admin User Summary
    /// </summary>
    public class AdminUserSummary
    {
        public int AdminId { get; set; }
        public string Email { get; set; }
        public string Department { get; set; }
        public DateTime? LastLogin { get; set; }
        public bool CanManageStudents { get; set; }
        public bool CanManageFaculty { get; set; }
        public bool CanManageSubjects { get; set; }
        public bool CanViewReports { get; set; }
        public bool CanManageSchedules { get; set; }
    }

    /// <summary>
    /// Simple Department Info
    /// </summary>
    public class DepartmentSimple
    {
        public int DepartmentId { get; set; }
        public string DepartmentName { get; set; }
        public string DepartmentCode { get; set; }
        public bool IsActive { get; set; }
    }

    /// <summary>
    /// Super Admin Enhanced Dashboard View Model with Management Cards
    /// </summary>
    public class SuperAdminEnhancedDashboardViewModel
    {
        public SuperAdmin CurrentSuperAdmin { get; set; }
        public List<DepartmentOverview> Departments { get; set; }
        public List<SuperAdminDepartmentStats> DepartmentStatistics { get; set; }
        public SystemStatistics SystemStats { get; set; }
        public List<RecentActivity> RecentActivities { get; set; }
    }

    /// <summary>
    /// Super Admin specific Department Statistics (different from CSEDSViewModels.DepartmentStatistics)
    /// </summary>
    public class SuperAdminDepartmentStats
    {
        public int DepartmentId { get; set; }
        public string DepartmentName { get; set; }
        public string DepartmentCode { get; set; }
        public int TotalStudents { get; set; }
        public int TotalFaculty { get; set; }
        public int TotalSubjects { get; set; }
        public int TotalAssignments { get; set; }
        public bool IsActive { get; set; }
        public bool AllowStudentRegistration { get; set; }
        public bool AllowFacultyAssignment { get; set; }
        public bool AllowSubjectSelection { get; set; }
    }

    /// <summary>
    /// Cross-Department Reports View Model
    /// </summary>
    public class CrossDepartmentReportsViewModel
    {
        public List<DepartmentReportData> DepartmentReports { get; set; }
        public EnrollmentTrendsData EnrollmentTrends { get; set; }
        public FacultyWorkloadData FacultyWorkload { get; set; }
        public SubjectPopularityData SubjectPopularity { get; set; }
    }

    /// <summary>
    /// Department Report Data
    /// </summary>
    public class DepartmentReportData
    {
        public string DepartmentName { get; set; }
        public string DepartmentCode { get; set; }
        public int TotalStudents { get; set; }
        public int TotalFaculty { get; set; }
        public int TotalSubjects { get; set; }
        public int TotalEnrollments { get; set; }
        public decimal AverageEnrollmentsPerSubject { get; set; }
        public decimal StudentFacultyRatio { get; set; }
    }

    /// <summary>
    /// Enrollment Trends Data
    /// </summary>
    public class EnrollmentTrendsData
    {
        public List<string> Departments { get; set; }
        public List<int> EnrollmentCounts { get; set; }
        public List<string> TrendLabels { get; set; }
    }

    /// <summary>
    /// Faculty Workload Data
    /// </summary>
    public class FacultyWorkloadData
    {
        public List<FacultyWorkloadItem> WorkloadItems { get; set; }
    }

    public class FacultyWorkloadItem
    {
        public string FacultyName { get; set; }
        public string Department { get; set; }
        public int SubjectsAssigned { get; set; }
        public int TotalStudents { get; set; }
        public string WorkloadStatus { get; set; }
    }

    /// <summary>
    /// Subject Popularity Data
    /// </summary>
    public class SubjectPopularityData
    {
        public List<SubjectPopularityItem> PopularSubjects { get; set; }
    }

    public class SubjectPopularityItem
    {
        public string SubjectName { get; set; }
        public string Department { get; set; }
        public int EnrollmentCount { get; set; }
        public int Year { get; set; }
        public string Semester { get; set; }
    }

    /// <summary>
    /// System Configuration View Model
    /// </summary>
    public class SystemConfigurationViewModel
    {
        public List<SystemConfiguration> Configurations { get; set; }
        public SystemConfiguration CurrentConfig { get; set; }
        public List<string> Categories { get; set; }
    }

    /// <summary>
    /// Assign Admin to Department View Model
    /// </summary>
    public class AssignAdminToDepartmentViewModel
    {
        [Required]
        public int AdminId { get; set; }

        [Required]
        public int DepartmentId { get; set; }

        public bool CanManageStudents { get; set; } = true;
        public bool CanManageFaculty { get; set; } = true;
        public bool CanManageSubjects { get; set; } = true;
        public bool CanViewReports { get; set; } = true;
        public bool CanManageSchedules { get; set; } = true;
    }
}
