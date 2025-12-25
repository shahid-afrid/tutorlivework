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
    /// Super Admin Service - Business logic for super admin operations
    /// </summary>
    public class SuperAdminService
    {
        private readonly AppDbContext _context;
        private readonly DynamicDepartmentSetupService _setupService;

        public SuperAdminService(AppDbContext context, DynamicDepartmentSetupService setupService)
        {
            _context = context;
            _setupService = setupService;
        }

        #region Authentication

        /// <summary>
        /// Authenticate super admin user
        /// </summary>
        public async Task<SuperAdmin> AuthenticateSuperAdmin(string email, string password)
        {
            var superAdmin = await _context.SuperAdmins
                .FirstOrDefaultAsync(sa => sa.Email == email && sa.Password == password && sa.IsActive);

            if (superAdmin != null)
            {
                superAdmin.LastLogin = DateTime.Now;
                await _context.SaveChangesAsync();

                // Note: Audit logging temporarily disabled for stability
                // await LogAuditAction(
                //     superAdmin.SuperAdminId,
                //     "Login",
                //     "SuperAdmin",
                //     superAdmin.SuperAdminId,
                //     $"Super admin {email} logged in successfully"
                // );
            }

            return superAdmin;
        }

        #endregion

        #region Dashboard

        /// <summary>
        /// Get dashboard data for super admin
        /// </summary>
        public async Task<SuperAdminDashboardViewModel> GetDashboardData()
        {
            var departments = await GetAllDepartmentsWithStats();
            var systemStats = await GetSystemStatistics();
            var recentActivities = await GetRecentActivities(20);
            var departmentAdmins = await _context.DepartmentAdmins
                .Include(da => da.Admin)
                .Include(da => da.Department)
                .OrderByDescending(da => da.AssignedDate)
                .Take(10)
                .ToListAsync();

            return new SuperAdminDashboardViewModel
            {
                Departments = departments,
                SystemStats = systemStats,
                RecentActivities = recentActivities,
                DepartmentAdmins = departmentAdmins
            };
        }

        /// <summary>
        /// Get all departments with statistics
        /// </summary>
        public async Task<List<DepartmentOverview>> GetAllDepartmentsWithStats()
        {
            var departments = await _context.Departments
                .OrderBy(d => d.DepartmentName)
                .ToListAsync();

            var departmentOverviews = new List<DepartmentOverview>();

            foreach (var dept in departments)
            {
                var adminCount = await _context.DepartmentAdmins
                    .CountAsync(da => da.DepartmentId == dept.DepartmentId);

                var studentCount = await _context.Students
                    .CountAsync(s => s.Department == dept.DepartmentCode);

                var facultyCount = await _context.Faculties
                    .CountAsync(f => f.Department == dept.DepartmentCode);

                var subjectCount = await _context.Subjects
                    .CountAsync(s => s.Department == dept.DepartmentCode);

                var enrollmentCount = await _context.StudentEnrollments
                    .CountAsync(se => _context.AssignedSubjects
                        .Any(asub => asub.AssignedSubjectId == se.AssignedSubjectId &&
                             _context.Subjects.Any(subj => subj.SubjectId == asub.SubjectId && subj.Department == dept.DepartmentCode)));

                departmentOverviews.Add(new DepartmentOverview
                {
                    DepartmentId = dept.DepartmentId,
                    DepartmentName = dept.DepartmentName,
                    DepartmentCode = dept.DepartmentCode,
                    IsActive = dept.IsActive,
                    TotalStudents = studentCount,
                    TotalFaculty = facultyCount,
                    TotalSubjects = subjectCount,
                    TotalEnrollments = enrollmentCount,
                    AdminCount = adminCount,
                    CreatedDate = dept.CreatedDate
                });
            }

            return departmentOverviews;
        }

        /// <summary>
        /// Get system-wide statistics
        /// </summary>
        public async Task<SystemStatistics> GetSystemStatistics()
        {
            var totalDepartments = await _context.Departments.CountAsync();
            var activeDepartments = await _context.Departments.CountAsync(d => d.IsActive);
            var totalStudents = await _context.Students.CountAsync();
            var totalFaculty = await _context.Faculties.CountAsync();
            var totalSubjects = await _context.Subjects.CountAsync();
            var totalAdmins = await _context.Admins.CountAsync();
            var totalEnrollments = await _context.StudentEnrollments.CountAsync();
            var todayEnrollments = await _context.StudentEnrollments
                .CountAsync(se => se.EnrolledAt.Date == DateTime.Today);
            var activeSchedules = await _context.FacultySelectionSchedules
                .CountAsync(fs => fs.IsEnabled);

            return new SystemStatistics
            {
                TotalDepartments = totalDepartments,
                ActiveDepartments = activeDepartments,
                TotalStudents = totalStudents,
                TotalFaculty = totalFaculty,
                TotalSubjects = totalSubjects,
                TotalAdmins = totalAdmins,
                TotalEnrollments = totalEnrollments,
                TodayEnrollments = todayEnrollments,
                ActiveSchedules = activeSchedules
            };
        }

        #endregion

        #region Department Management

        /// <summary>
        /// Get all departments for management
        /// </summary>
        public async Task<List<DepartmentDetailViewModel>> GetAllDepartmentsDetailed()
        {
            var departments = await _context.Departments
                .Include(d => d.DepartmentAdmins)
                .ThenInclude(da => da.Admin)
                .OrderBy(d => d.DepartmentName)
                .ToListAsync();

            var departmentDetails = new List<DepartmentDetailViewModel>();

            foreach (var d in departments)
            {
                // Use the ACTUAL department code from database for queries
                // This ensures we find existing students/faculty/subjects
                var deptCodeInDb = d.DepartmentCode;
                
                // Calculate real-time statistics from actual data using DB code
                var studentCount = await _context.Students
                    .CountAsync(s => s.Department == deptCodeInDb);

                var facultyCount = await _context.Faculties
                    .CountAsync(f => f.Department == deptCodeInDb);

                var subjectCount = await _context.Subjects
                    .CountAsync(s => s.Department == deptCodeInDb);

                // Normalize for DISPLAY and consistency, but use DB code for queries
                var normalizedDeptCode = DepartmentNormalizer.Normalize(deptCodeInDb);

                departmentDetails.Add(new DepartmentDetailViewModel
                {
                    DepartmentId = d.DepartmentId,
                    DepartmentName = d.DepartmentName,
                    DepartmentCode = deptCodeInDb,  // Keep original code from DB
                    Description = d.Description,
                    IsActive = d.IsActive,
                    AllowStudentRegistration = d.AllowStudentRegistration,
                    AllowFacultyAssignment = d.AllowFacultyAssignment,
                    AllowSubjectSelection = d.AllowSubjectSelection,
                    TotalStudents = studentCount,
                    TotalFaculty = facultyCount,
                    TotalSubjects = subjectCount,
                    TotalAdmins = d.DepartmentAdmins.Count,
                    CreatedDate = d.CreatedDate,
                    LastModifiedDate = d.LastModifiedDate,
                    AssignedAdmins = d.DepartmentAdmins.Select(da => new AdminUserSummary
                    {
                        AdminId = da.AdminId,
                        Email = da.Admin.Email,
                        Department = da.Admin.Department,
                        LastLogin = da.Admin.LastLogin,
                        CanManageStudents = da.CanManageStudents,
                        CanManageFaculty = da.CanManageFaculty,
                        CanManageSubjects = da.CanManageSubjects,
                        CanViewReports = da.CanViewReports,
                        CanManageSchedules = da.CanManageSchedules
                    }).ToList()
                });
            }

            return departmentDetails;
        }

        /// <summary>
        /// Create new department
        /// </summary>
        public async Task<Department> CreateDepartment(DepartmentDetailViewModel model, int superAdminId)
        {
            // Normalize the department code to ensure consistency (e.g., CSE(DS) -> CSEDS)
            var normalizedDeptCode = DepartmentNormalizer.Normalize(model.DepartmentCode.ToUpper());
            
            var department = new Department
            {
                DepartmentName = model.DepartmentName,
                DepartmentCode = normalizedDeptCode,
                Description = model.Description,
                IsActive = model.IsActive,
                AllowStudentRegistration = model.AllowStudentRegistration,
                AllowFacultyAssignment = model.AllowFacultyAssignment,
                AllowSubjectSelection = model.AllowSubjectSelection,
                CreatedDate = DateTime.Now
            };

            _context.Departments.Add(department);
            await _context.SaveChangesAsync();

            // Create department admin if requested
            if (model.CreateAdminAccount && !string.IsNullOrEmpty(model.AdminEmail))
            {
                // Create admin account with normalized department code
                var admin = new Admin
                {
                    Email = model.AdminEmail,
                    Password = model.AdminPassword, // In production, this should be hashed
                    Department = normalizedDeptCode,
                    CreatedDate = DateTime.Now
                };

                _context.Admins.Add(admin);
                await _context.SaveChangesAsync();

                // Link admin to department with full permissions
                var deptAdmin = new DepartmentAdmin
                {
                    AdminId = admin.AdminId,
                    DepartmentId = department.DepartmentId,
                    AssignedDate = DateTime.Now,
                    CanManageStudents = true,
                    CanManageFaculty = true,
                    CanManageSubjects = true,
                    CanViewReports = true,
                    CanManageSchedules = true
                };

                _context.DepartmentAdmins.Add(deptAdmin);
                await _context.SaveChangesAsync();

                Console.WriteLine($"? Created admin account for {model.DepartmentName}: {model.AdminEmail} with department: {normalizedDeptCode}");
            }

            // AUTOMATIC SETUP: Initialize department with all necessary configurations
            await _setupService.SetupNewDepartment(department.DepartmentId, superAdminId);
            Console.WriteLine($"? Automatic setup completed for department: {department.DepartmentName}");

            // Audit logging temporarily disabled
            // await LogAuditAction(
            //     superAdminId,
            //     "Create",
            //     "Department",
            //     department.DepartmentId,
            //     $"Created new department: {department.DepartmentName} ({department.DepartmentCode})"
            // );

            return department;
        }

        /// <summary>
        /// Update existing department
        /// </summary>
        public async Task<bool> UpdateDepartment(DepartmentDetailViewModel model, int superAdminId)
        {
            var department = await _context.Departments.FindAsync(model.DepartmentId);
            if (department == null) return false;

            var oldValue = $"{department.DepartmentName} - Active: {department.IsActive}";

            // Normalize the department code to ensure consistency (e.g., CSE(DS) -> CSEDS)
            var normalizedDeptCode = DepartmentNormalizer.Normalize(model.DepartmentCode.ToUpper());
            
            department.DepartmentName = model.DepartmentName;
            department.DepartmentCode = normalizedDeptCode;
            department.Description = model.Description;
            department.IsActive = model.IsActive;
            department.AllowStudentRegistration = model.AllowStudentRegistration;
            department.AllowFacultyAssignment = model.AllowFacultyAssignment;
            department.AllowSubjectSelection = model.AllowSubjectSelection;
            department.LastModifiedDate = DateTime.Now;

            await _context.SaveChangesAsync();

            var newValue = $"{department.DepartmentName} - Active: {department.IsActive}";

            // Audit logging temporarily disabled
            // await LogAuditAction(
            //     superAdminId,
            //     "Update",
            //     "Department",
            //     department.DepartmentId,
            //     $"Updated department: {department.DepartmentName}",
            //     oldValue,
            //     newValue
            // );

            return true;
        }

        /// <summary>
        /// Delete department
        /// </summary>
        public async Task<bool> DeleteDepartment(int departmentId, int superAdminId)
        {
            var department = await _context.Departments.FindAsync(departmentId);
            if (department == null) return false;

            _context.Departments.Remove(department);
            await _context.SaveChangesAsync();

            // Audit logging temporarily disabled
            // await LogAuditAction(
            //     superAdminId,
            //     "Delete",
            //     "Department",
            //     departmentId,
            //     $"Deleted department: {department.DepartmentName} ({department.DepartmentCode})"
            // );

            return true;
        }

        #endregion

        #region Admin Management

        /// <summary>
        /// Get all admins with department assignments
        /// </summary>
        public async Task<List<AdminUserDetailViewModel>> GetAllAdmins()
        {
            var admins = await _context.Admins
                .OrderBy(a => a.Email)
                .ToListAsync();

            var adminDetails = new List<AdminUserDetailViewModel>();

            foreach (var admin in admins)
            {
                var deptAdmin = await _context.DepartmentAdmins
                    .Include(da => da.Department)
                    .FirstOrDefaultAsync(da => da.AdminId == admin.AdminId);

                var studentCount = await _context.Students.CountAsync(s => s.Department == admin.Department);
                var facultyCount = await _context.Faculties.CountAsync(f => f.Department == admin.Department);
                var subjectCount = await _context.Subjects.CountAsync(s => s.Department == admin.Department);

                adminDetails.Add(new AdminUserDetailViewModel
                {
                    AdminId = admin.AdminId,
                    Email = admin.Email,
                    Password = admin.Password,
                    Department = admin.Department,
                    CreatedDate = admin.CreatedDate,
                    LastLogin = admin.LastLogin,
                    DepartmentId = deptAdmin?.DepartmentId,
                    DepartmentName = deptAdmin?.Department?.DepartmentName,
                    CanManageStudents = deptAdmin?.CanManageStudents ?? false,
                    CanManageFaculty = deptAdmin?.CanManageFaculty ?? false,
                    CanManageSubjects = deptAdmin?.CanManageSubjects ?? false,
                    CanViewReports = deptAdmin?.CanViewReports ?? false,
                    CanManageSchedules = deptAdmin?.CanManageSchedules ?? false,
                    TotalStudentsManaged = studentCount,
                    TotalFacultyManaged = facultyCount,
                    TotalSubjectsManaged = subjectCount
                });
            }

            return adminDetails;
        }

        /// <summary>
        /// Create new admin and assign to department
        /// </summary>
        public async Task<Admin> CreateAdmin(AdminUserDetailViewModel model, int superAdminId)
        {
            var admin = new Admin
            {
                Email = model.Email,
                Password = model.Password,
                Department = model.Department,
                CreatedDate = DateTime.Now
            };

            _context.Admins.Add(admin);
            await _context.SaveChangesAsync();

            // Assign to department if specified
            if (model.DepartmentId.HasValue)
            {
                var deptAdmin = new DepartmentAdmin
                {
                    AdminId = admin.AdminId,
                    DepartmentId = model.DepartmentId.Value,
                    AssignedDate = DateTime.Now,
                    CanManageStudents = model.CanManageStudents,
                    CanManageFaculty = model.CanManageFaculty,
                    CanManageSubjects = model.CanManageSubjects,
                    CanViewReports = model.CanViewReports,
                    CanManageSchedules = model.CanManageSchedules
                };

                _context.DepartmentAdmins.Add(deptAdmin);
                await _context.SaveChangesAsync();

                // AUTOMATIC SETUP: Grant admin full access to department interface
                await _setupService.SetupAdminAccess(admin.AdminId, model.DepartmentId.Value);
                Console.WriteLine($"? Admin access configured for {admin.Email} to department ID: {model.DepartmentId.Value}");
            }

            // Audit logging temporarily disabled
            // await LogAuditAction(
            //     superAdminId,
            //     "Create",
            //     "Admin",
            //     admin.AdminId,
            //     $"Created new admin: {admin.Email} for department {admin.Department}"
            // );

            return admin;
        }

        /// <summary>
        /// Delete admin user
        /// </summary>
        public async Task<bool> DeleteAdmin(int adminId, int superAdminId)
        {
            var admin = await _context.Admins.FindAsync(adminId);
            if (admin == null) return false;

            _context.Admins.Remove(admin);
            await _context.SaveChangesAsync();

            // Audit logging temporarily disabled
            // await LogAuditAction(
            //     superAdminId,
            //     "Delete",
            //     "Admin",
            //     adminId,
            //     $"Deleted admin: {admin.Email}"
            // );

            return true;
        }

        #endregion

        #region Audit Logging

        /// <summary>
        /// Get recent activities
        /// </summary>
        public async Task<List<RecentActivity>> GetRecentActivities(int count = 50)
        {
            return await _context.AuditLogs
                .OrderByDescending(al => al.ActionDate)
                .Take(count)
                .Select(al => new RecentActivity
                {
                    AuditLogId = al.AuditLogId,
                    ActionPerformedBy = al.ActionPerformedBy,
                    ActionType = al.ActionType,
                    ActionDescription = al.ActionDescription,
                    ActionDate = al.ActionDate,
                    Status = al.Status
                })
                .ToListAsync();
        }

        /// <summary>
        /// Log audit action
        /// </summary>
        public async Task LogAuditAction(int? superAdminId, string actionType, string entityType, 
            int? entityId, string description, string oldValue = null, string newValue = null)
        {
            var superAdmin = superAdminId.HasValue 
                ? await _context.SuperAdmins.FindAsync(superAdminId.Value) 
                : null;

            var auditLog = new AuditLog
            {
                SuperAdminId = superAdminId,
                ActionPerformedBy = superAdmin?.Email ?? "System",
                ActionType = actionType,
                EntityType = entityType,
                EntityId = entityId,
                ActionDescription = description,
                OldValue = oldValue,
                NewValue = newValue,
                IpAddress = "127.0.0.1", // Default for now, can be enhanced to get actual IP
                ActionDate = DateTime.Now,
                Status = "Success"
            };

            _context.AuditLogs.Add(auditLog);
            await _context.SaveChangesAsync();
        }

        #endregion

        #region Cross-Department Management

        /// <summary>
        /// Get all students for a specific department
        /// </summary>
        public async Task<List<Student>> GetStudentsForDepartment(string departmentCode)
        {
            return await _context.Students
                .Where(s => s.Department == departmentCode)
                .OrderBy(s => s.FullName)
                .ToListAsync();
        }

        /// <summary>
        /// Get all faculty for a specific department
        /// </summary>
        public async Task<List<Faculty>> GetFacultyForDepartment(string departmentCode)
        {
            return await _context.Faculties
                .Where(f => f.Department == departmentCode)
                .OrderBy(f => f.Name)
                .ToListAsync();
        }

        /// <summary>
        /// Get all subjects for a specific department
        /// </summary>
        public async Task<List<Subject>> GetSubjectsForDepartment(string departmentCode)
        {
            return await _context.Subjects
                .Where(s => s.Department == departmentCode)
                .OrderBy(s => s.Name)
                .ToListAsync();
        }

        /// <summary>
        /// Get all subject assignments for a specific department
        /// </summary>
        public async Task<List<AssignedSubject>> GetSubjectAssignmentsForDepartment(string departmentCode)
        {
            return await _context.AssignedSubjects
                .Include(asub => asub.Faculty)
                .Include(asub => asub.Subject)
                .Where(asub => asub.Subject.Department == departmentCode)
                .OrderBy(asub => asub.Subject.Name)
                .ToListAsync();
        }

        /// <summary>
        /// Toggle department feature (AllowStudentRegistration, AllowFacultyAssignment, AllowSubjectSelection)
        /// </summary>
        public async Task<bool> ToggleDepartmentFeature(int departmentId, string featureName, bool enabled, int superAdminId)
        {
            var department = await _context.Departments.FindAsync(departmentId);
            if (department == null) return false;

            var oldValue = "";
            var newValue = "";

            switch (featureName.ToLower())
            {
                case "allowstudentregistration":
                    oldValue = department.AllowStudentRegistration.ToString();
                    department.AllowStudentRegistration = enabled;
                    newValue = enabled.ToString();
                    break;
                case "allowfacultyassignment":
                    oldValue = department.AllowFacultyAssignment.ToString();
                    department.AllowFacultyAssignment = enabled;
                    newValue = enabled.ToString();
                    break;
                case "allowsubjectselection":
                    oldValue = department.AllowSubjectSelection.ToString();
                    department.AllowSubjectSelection = enabled;
                    newValue = enabled.ToString();
                    break;
                case "isactive":
                    oldValue = department.IsActive.ToString();
                    department.IsActive = enabled;
                    newValue = enabled.ToString();
                    break;
                default:
                    return false;
            }

            department.LastModifiedDate = DateTime.Now;
            await _context.SaveChangesAsync();

            // Audit logging temporarily disabled
            // await LogAuditAction(
            //     superAdminId,
            //     "Toggle",
            //     "Department",
            //     departmentId,
            //     $"Toggled {featureName} for {department.DepartmentName}",
            //     oldValue,
            //     newValue
            // );

            return true;
        }

        /// <summary>
        /// Get department statistics for Super Admin dashboard
        /// </summary>
        public async Task<SuperAdminDepartmentStats> GetDepartmentStatistics(int departmentId)
        {
            var department = await _context.Departments.FindAsync(departmentId);
            if (department == null) return null;

            var studentCount = await _context.Students.CountAsync(s => s.Department == department.DepartmentCode);
            var facultyCount = await _context.Faculties.CountAsync(f => f.Department == department.DepartmentCode);
            var subjectCount = await _context.Subjects.CountAsync(s => s.Department == department.DepartmentCode);
            var assignmentCount = await _context.AssignedSubjects
                .CountAsync(asub => asub.Subject.Department == department.DepartmentCode);

            return new SuperAdminDepartmentStats
            {
                DepartmentId = departmentId,
                DepartmentName = department.DepartmentName,
                DepartmentCode = department.DepartmentCode,
                TotalStudents = studentCount,
                TotalFaculty = facultyCount,
                TotalSubjects = subjectCount,
                TotalAssignments = assignmentCount,
                IsActive = department.IsActive,
                AllowStudentRegistration = department.AllowStudentRegistration,
                AllowFacultyAssignment = department.AllowFacultyAssignment,
                AllowSubjectSelection = department.AllowSubjectSelection
            };
        }

        #endregion

        #region Utility Methods

        /// <summary>
        /// Get super admin by ID
        /// </summary>
        public async Task<SuperAdmin> GetSuperAdminById(int superAdminId)
        {
            return await _context.SuperAdmins.FindAsync(superAdminId);
        }

        /// <summary>
        /// Get department by ID
        /// </summary>
        public async Task<Department> GetDepartmentById(int departmentId)
        {
            return await _context.Departments.FindAsync(departmentId);
        }

        /// <summary>
        /// Get simple department list
        /// </summary>
        public async Task<List<DepartmentSimple>> GetSimpleDepartmentList()
        {
            return await _context.Departments
                .Where(d => d.IsActive)
                .OrderBy(d => d.DepartmentName)
                .Select(d => new DepartmentSimple
                {
                    DepartmentId = d.DepartmentId,
                    DepartmentName = d.DepartmentName,
                    DepartmentCode = d.DepartmentCode,
                    IsActive = d.IsActive
                })
                .ToListAsync();
        }

        #endregion
    }
}
