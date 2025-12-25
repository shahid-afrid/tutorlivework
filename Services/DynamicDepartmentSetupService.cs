using Microsoft.EntityFrameworkCore;
using TutorLiveMentor.Models;
using TutorLiveMentor.Helpers;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace TutorLiveMentor.Services
{
    /// <summary>
    /// Automatic Department Setup Service
    /// Creates complete admin interface for new departments automatically
    /// Uses CSEDS as reference template
    /// </summary>
    public class DynamicDepartmentSetupService
    {
        private readonly AppDbContext _context;
        private readonly DynamicTableService _dynamicTableService;

        public DynamicDepartmentSetupService(AppDbContext context, DynamicTableService dynamicTableService)
        {
            _context = context;
            _dynamicTableService = dynamicTableService;
        }

        /// <summary>
        /// Complete automatic setup when a new department is created
        /// This creates all necessary configurations AND database tables for the admin to manage the department
        /// </summary>
        public async Task<bool> SetupNewDepartment(int departmentId, int createdBySuperAdminId)
        {
            try
            {
                var department = await _context.Departments
                    .FirstOrDefaultAsync(d => d.DepartmentId == departmentId);

                if (department == null)
                    return false;

                // 0. CREATE DEPARTMENT-SPECIFIC TABLES FIRST
                Console.WriteLine($"[DYNAMIC SETUP] Creating tables for {department.DepartmentCode}...");
                var tableResult = await _dynamicTableService.CreateDepartmentTables(department.DepartmentCode);
                
                if (tableResult.Success)
                {
                    Console.WriteLine($"[DYNAMIC SETUP] ? Tables created: {tableResult.Message}");
                }
                else
                {
                    Console.WriteLine($"[DYNAMIC SETUP] ? Table creation: {tableResult.Message}");
                    // Continue even if tables exist - might be a re-setup
                }

                // 1. Initialize Department Settings
                await InitializeDepartmentSettings(department);

                // 2. Create Default Faculty Selection Schedule (disabled by default)
                await CreateDefaultSchedule(department);

                // 3. Setup Department Permissions
                await SetupDefaultPermissions(department);

                // 4. Log the setup
                await LogDepartmentSetup(department, createdBySuperAdminId);

                await _context.SaveChangesAsync();
                
                Console.WriteLine($"[DYNAMIC SETUP] ? Complete setup finished for {department.DepartmentCode}");
                return true;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error in SetupNewDepartment: {ex.Message}");
                return false;
            }
        }

        /// <summary>
        /// Initialize department with default settings
        /// </summary>
        private async Task InitializeDepartmentSettings(Department department)
        {
            // Set default feature flags (same as CSEDS)
            department.AllowStudentRegistration = true;
            department.AllowFacultyAssignment = true;
            department.AllowSubjectSelection = true;
            department.IsActive = true;

            _context.Departments.Update(department);
        }

        /// <summary>
        /// Create a default (disabled) faculty selection schedule
        /// Admin can enable and configure this later
        /// </summary>
        private async Task CreateDefaultSchedule(Department department)
        {
            var existingSchedule = await _context.FacultySelectionSchedules
                .FirstOrDefaultAsync(fs => fs.Department == department.DepartmentCode);

            if (existingSchedule == null)
            {
                var defaultSchedule = new FacultySelectionSchedule
                {
                    Department = department.DepartmentCode,
                    IsEnabled = false, // Disabled by default - admin must enable
                    UseSchedule = false, // No time restriction by default
                    StartDateTime = DateTime.Now.AddDays(7), // Start in 7 days (optional)
                    EndDateTime = DateTime.Now.AddDays(30), // End in 30 days (optional)
                    DisabledMessage = $"Faculty selection for {department.DepartmentName} is currently disabled. Please contact your administrator.",
                    CreatedAt = DateTime.Now
                };

                _context.FacultySelectionSchedules.Add(defaultSchedule);
            }
        }

        /// <summary>
        /// Setup default permissions for department admin
        /// Grants full access by default (similar to CSEDS admin)
        /// </summary>
        private async Task SetupDefaultPermissions(Department department)
        {
            // Get all admins assigned to this department
            var departmentAdmins = await _context.DepartmentAdmins
                .Where(da => da.DepartmentId == department.DepartmentId)
                .ToListAsync();

            foreach (var deptAdmin in departmentAdmins)
            {
                // Grant full permissions (same as CSEDS)
                deptAdmin.CanManageStudents = true;
                deptAdmin.CanManageFaculty = true;
                deptAdmin.CanManageSubjects = true;
                deptAdmin.CanViewReports = true;
                deptAdmin.CanManageSchedules = true;

                _context.DepartmentAdmins.Update(deptAdmin);
            }
        }

        /// <summary>
        /// Log the department setup in audit logs
        /// </summary>
        private async Task LogDepartmentSetup(Department department, int superAdminId)
        {
            try
            {
                var superAdmin = await _context.SuperAdmins.FindAsync(superAdminId);

                var auditLog = new AuditLog
                {
                    SuperAdminId = superAdminId,
                    ActionPerformedBy = superAdmin?.Email ?? "System",
                    ActionType = "Setup",
                    EntityType = "Department",
                    EntityId = department.DepartmentId,
                    ActionDescription = $"Automatic setup completed for department {department.DepartmentName} ({department.DepartmentCode})",
                    IpAddress = "127.0.0.1",
                    ActionDate = DateTime.Now,
                    Status = "Success"
                };

                _context.AuditLogs.Add(auditLog);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error logging department setup: {ex.Message}");
                // Don't fail the entire operation if logging fails
            }
        }

        /// <summary>
        /// Setup admin account with full department access
        /// Called when admin is created for a department
        /// </summary>
        public async Task<bool> SetupAdminAccess(int adminId, int departmentId)
        {
            try
            {
                var deptAdmin = await _context.DepartmentAdmins
                    .FirstOrDefaultAsync(da => da.AdminId == adminId && da.DepartmentId == departmentId);

                if (deptAdmin != null)
                {
                    // Grant full permissions (same as CSEDS admin)
                    deptAdmin.CanManageStudents = true;
                    deptAdmin.CanManageFaculty = true;
                    deptAdmin.CanManageSubjects = true;
                    deptAdmin.CanViewReports = true;
                    deptAdmin.CanManageSchedules = true;

                    _context.DepartmentAdmins.Update(deptAdmin);
                    await _context.SaveChangesAsync();
                }

                return true;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error in SetupAdminAccess: {ex.Message}");
                return false;
            }
        }

        /// <summary>
        /// Get department configuration for dynamic routing
        /// This allows the system to know what interface to show
        /// </summary>
        public async Task<DepartmentConfiguration> GetDepartmentConfiguration(string departmentCode)
        {
            var department = await _context.Departments
                .FirstOrDefaultAsync(d => d.DepartmentCode == departmentCode);

            if (department == null)
                return null;

            return new DepartmentConfiguration
            {
                DepartmentId = department.DepartmentId,
                DepartmentCode = department.DepartmentCode,
                DepartmentName = department.DepartmentName,
                IsActive = department.IsActive,
                AllowStudentRegistration = department.AllowStudentRegistration,
                AllowFacultyAssignment = department.AllowFacultyAssignment,
                AllowSubjectSelection = department.AllowSubjectSelection,
                UseDynamicInterface = true // All new departments use dynamic interface
            };
        }
    }

    /// <summary>
    /// Department configuration model
    /// </summary>
    public class DepartmentConfiguration
    {
        public int DepartmentId { get; set; }
        public string DepartmentCode { get; set; }
        public string DepartmentName { get; set; }
        public bool IsActive { get; set; }
        public bool AllowStudentRegistration { get; set; }
        public bool AllowFacultyAssignment { get; set; }
        public bool AllowSubjectSelection { get; set; }
        public bool UseDynamicInterface { get; set; }
    }
}
