using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TutorLiveMentor.Models
{
    /// <summary>
    /// Super Admin user with cross-department access
    /// </summary>
    public class SuperAdmin
    {
        [Key]
        public int SuperAdminId { get; set; }

        [Required(ErrorMessage = "Name is required")]
        [StringLength(100)]
        public string Name { get; set; }

        [Required(ErrorMessage = "Email is required")]
        [EmailAddress(ErrorMessage = "Invalid email format")]
        [StringLength(100)]
        public string Email { get; set; }

        [Required(ErrorMessage = "Password is required")]
        [StringLength(255)]
        public string Password { get; set; }

        [StringLength(15)]
        public string PhoneNumber { get; set; }

        public bool IsActive { get; set; } = true;

        public DateTime CreatedDate { get; set; } = DateTime.Now;

        public DateTime? LastLogin { get; set; }

        [StringLength(50)]
        public string Role { get; set; } = "SuperAdmin";

        // Navigation properties
        public virtual ICollection<AuditLog> AuditLogs { get; set; }
    }

    /// <summary>
    /// Department entity for multi-department management
    /// </summary>
    public class Department
    {
        [Key]
        public int DepartmentId { get; set; }

        [Required(ErrorMessage = "Department name is required")]
        [StringLength(100)]
        public string DepartmentName { get; set; }

        [Required(ErrorMessage = "Department code is required")]
        [StringLength(20)]
        public string DepartmentCode { get; set; }

        [StringLength(200)]
        public string Description { get; set; }

        public bool IsActive { get; set; } = true;

        public DateTime CreatedDate { get; set; } = DateTime.Now;

        public DateTime? LastModifiedDate { get; set; }

        // Configuration
        public bool AllowStudentRegistration { get; set; } = true;
        public bool AllowFacultyAssignment { get; set; } = true;
        public bool AllowSubjectSelection { get; set; } = true;

        // Statistics
        public int TotalStudents { get; set; } = 0;
        public int TotalFaculty { get; set; } = 0;
        public int TotalSubjects { get; set; } = 0;

        // Navigation properties
        public virtual ICollection<DepartmentAdmin> DepartmentAdmins { get; set; }
    }

    /// <summary>
    /// Junction table mapping admins to departments
    /// </summary>
    public class DepartmentAdmin
    {
        [Key]
        public int DepartmentAdminId { get; set; }

        [Required]
        public int AdminId { get; set; }

        [Required]
        public int DepartmentId { get; set; }

        public DateTime AssignedDate { get; set; } = DateTime.Now;

        public bool CanManageStudents { get; set; } = true;
        public bool CanManageFaculty { get; set; } = true;
        public bool CanManageSubjects { get; set; } = true;
        public bool CanViewReports { get; set; } = true;
        public bool CanManageSchedules { get; set; } = true;

        // Navigation properties
        [ForeignKey("AdminId")]
        public virtual Admin Admin { get; set; }

        [ForeignKey("DepartmentId")]
        public virtual Department Department { get; set; }
    }

    /// <summary>
    /// System-wide configuration settings
    /// </summary>
    public class SystemConfiguration
    {
        [Key]
        public int ConfigId { get; set; }

        [Required]
        [StringLength(100)]
        public string ConfigKey { get; set; }

        [Required]
        [StringLength(500)]
        public string ConfigValue { get; set; }

        [StringLength(200)]
        public string Description { get; set; }

        [StringLength(50)]
        public string Category { get; set; }

        public bool IsActive { get; set; } = true;

        public DateTime CreatedDate { get; set; } = DateTime.Now;

        public DateTime? LastModifiedDate { get; set; }

        public int? ModifiedBySuperAdminId { get; set; }
    }

    /// <summary>
    /// Audit log for tracking super admin actions
    /// </summary>
    public class AuditLog
    {
        [Key]
        public int AuditLogId { get; set; }

        public int? SuperAdminId { get; set; }

        [StringLength(100)]
        public string ActionPerformedBy { get; set; } = "System";

        [Required]
        [StringLength(100)]
        public string ActionType { get; set; }

        [StringLength(100)]
        public string EntityType { get; set; } = "";

        public int? EntityId { get; set; }

        [StringLength(500)]
        public string ActionDescription { get; set; } = "";

        public string OldValue { get; set; } = "";

        public string NewValue { get; set; } = "";

        [StringLength(50)]
        public string IpAddress { get; set; } = "127.0.0.1";

        public DateTime ActionDate { get; set; } = DateTime.Now;

        [StringLength(50)]
        public string Status { get; set; } = "Success";

        // Navigation properties
        [ForeignKey("SuperAdminId")]
        public virtual SuperAdmin SuperAdmin { get; set; }
    }
}
