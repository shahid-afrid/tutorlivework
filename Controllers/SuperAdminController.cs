using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TutorLiveMentor.Models;
using TutorLiveMentor.Services;
using System;
using System.Linq;
using System.Threading.Tasks;
using System.Collections.Generic;

namespace TutorLiveMentor.Controllers
{
    /// <summary>
    /// Super Admin Controller - Manages all super admin operations
    /// </summary>
    public class SuperAdminController : Controller
    {
        private readonly SuperAdminService _superAdminService;
        private readonly AppDbContext _context;

        public SuperAdminController(SuperAdminService superAdminService, AppDbContext context)
        {
            _superAdminService = superAdminService;
            _context = context;
        }

        #region Authentication

        /// <summary>
        /// Super Admin Login Page
        /// </summary>
        [HttpGet]
        public IActionResult Login()
        {
            // If already logged in, redirect to dashboard
            if (HttpContext.Session.GetInt32("SuperAdminId") != null)
            {
                return RedirectToAction("Dashboard");
            }

            return View();
        }

        /// <summary>
        /// Super Admin Login POST
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> Login(SuperAdminLoginViewModel model)
        {
            if (!ModelState.IsValid)
            {
                return View(model);
            }

            var superAdmin = await _superAdminService.AuthenticateSuperAdmin(model.Email, model.Password);

            if (superAdmin == null)
            {
                ViewBag.ErrorMessage = "Invalid email or password.";
                return View(model);
            }

            // Set session
            HttpContext.Session.SetInt32("SuperAdminId", superAdmin.SuperAdminId);
            HttpContext.Session.SetString("SuperAdminEmail", superAdmin.Email);
            HttpContext.Session.SetString("SuperAdminName", superAdmin.Name);
            HttpContext.Session.SetString("UserRole", "SuperAdmin");

            return RedirectToAction("Dashboard");
        }

        /// <summary>
        /// Super Admin Logout
        /// </summary>
        [HttpGet]
        public IActionResult Logout()
        {
            HttpContext.Session.Clear();
            return RedirectToAction("Login");
        }

        #endregion

        #region Dashboard

        /// <summary>
        /// Super Admin Dashboard
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> Dashboard()
        {
            if (!CheckSuperAdminSession())
            {
                return RedirectToAction("Login");
            }

            var dashboardData = await _superAdminService.GetDashboardData();
            var superAdminId = HttpContext.Session.GetInt32("SuperAdminId").Value;
            dashboardData.CurrentSuperAdmin = await _superAdminService.GetSuperAdminById(superAdminId);

            // Get department statistics for management cards
            var departmentStats = new List<SuperAdminDepartmentStats>();
            foreach (var dept in dashboardData.Departments)
            {
                var stats = await _superAdminService.GetDepartmentStatistics(dept.DepartmentId);
                if (stats != null)
                {
                    departmentStats.Add(stats);
                }
            }

            var enhancedModel = new SuperAdminEnhancedDashboardViewModel
            {
                CurrentSuperAdmin = dashboardData.CurrentSuperAdmin,
                Departments = dashboardData.Departments,
                DepartmentStatistics = departmentStats,
                SystemStats = dashboardData.SystemStats,
                RecentActivities = dashboardData.RecentActivities
            };

            return View(enhancedModel);
        }

        #endregion

        #region Department Management

        /// <summary>
        /// Manage Departments Page
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> ManageDepartments()
        {
            if (!CheckSuperAdminSession())
            {
                return RedirectToAction("Login");
            }

            var departments = await _superAdminService.GetAllDepartmentsDetailed();
            return View(departments);
        }

        /// <summary>
        /// Create Department - GET
        /// </summary>
        [HttpGet]
        public IActionResult CreateDepartment()
        {
            if (!CheckSuperAdminSession())
            {
                return RedirectToAction("Login");
            }

            return View(new DepartmentDetailViewModel { IsActive = true, AllowStudentRegistration = true, AllowFacultyAssignment = true, AllowSubjectSelection = true });
        }

        /// <summary>
        /// Create Department - POST
        /// </summary>
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> CreateDepartment(DepartmentDetailViewModel model)
        {
            if (!CheckSuperAdminSession())
            {
                return RedirectToAction("Login");
            }

            // Custom validation for admin account creation
            if (model.CreateAdminAccount)
            {
                if (string.IsNullOrWhiteSpace(model.AdminName))
                {
                    ModelState.AddModelError("AdminName", "Admin name is required when creating admin account");
                }
                if (string.IsNullOrWhiteSpace(model.AdminEmail))
                {
                    ModelState.AddModelError("AdminEmail", "Admin email is required when creating admin account");
                }
                if (string.IsNullOrWhiteSpace(model.AdminPassword))
                {
                    ModelState.AddModelError("AdminPassword", "Admin password is required when creating admin account");
                }
                else if (model.AdminPassword.Length < 6)
                {
                    ModelState.AddModelError("AdminPassword", "Password must be at least 6 characters");
                }
                if (model.AdminPassword != model.ConfirmAdminPassword)
                {
                    ModelState.AddModelError("ConfirmAdminPassword", "Passwords do not match");
                }
            }

            if (!ModelState.IsValid)
            {
                var errors = ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage);
                TempData["ErrorMessage"] = "Validation failed: " + string.Join(", ", errors);
                return View(model);
            }

            try
            {
                // Check if department code already exists
                var existingDept = await _context.Departments
                    .FirstOrDefaultAsync(d => d.DepartmentCode == model.DepartmentCode.ToUpper());
                
                if (existingDept != null)
                {
                    TempData["ErrorMessage"] = $"Department with code '{model.DepartmentCode}' already exists.";
                    return View(model);
                }

                // Check if admin email already exists (when creating admin)
                if (model.CreateAdminAccount)
                {
                    var existingAdmin = await _context.Admins
                        .FirstOrDefaultAsync(a => a.Email == model.AdminEmail);
                    
                    if (existingAdmin != null)
                    {
                        TempData["ErrorMessage"] = $"Admin with email '{model.AdminEmail}' already exists.";
                        return View(model);
                    }
                }

                var superAdminId = HttpContext.Session.GetInt32("SuperAdminId").Value;
                var result = await _superAdminService.CreateDepartment(model, superAdminId);
                
                if (result != null)
                {
                    string successMsg = $"Department '{model.DepartmentName}' (Code: {model.DepartmentCode}) created successfully!";
                    if (model.CreateAdminAccount)
                    {
                        successMsg += $" Admin account created: {model.AdminEmail}";
                    }
                    TempData["SuccessMessage"] = successMsg;
                    return RedirectToAction("ManageDepartments");
                }
                else
                {
                    TempData["ErrorMessage"] = "Failed to create department. Please try again.";
                    return View(model);
                }
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error creating department: {ex.Message}";
                return View(model);
            }
        }

        /// <summary>
        /// Edit Department - GET
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> EditDepartment(int id)
        {
            if (!CheckSuperAdminSession())
            {
                return RedirectToAction("Login");
            }

            var departments = await _superAdminService.GetAllDepartmentsDetailed();
            var department = departments.FirstOrDefault(d => d.DepartmentId == id);

            if (department == null)
            {
                return NotFound();
            }

            return View(department);
        }

        /// <summary>
        /// Edit Department - POST
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> EditDepartment(DepartmentDetailViewModel model)
        {
            if (!CheckSuperAdminSession())
            {
                return RedirectToAction("Login");
            }

            if (!ModelState.IsValid)
            {
                return View(model);
            }

            var superAdminId = HttpContext.Session.GetInt32("SuperAdminId").Value;
            var success = await _superAdminService.UpdateDepartment(model, superAdminId);

            if (!success)
            {
                TempData["ErrorMessage"] = "Failed to update department.";
                return View(model);
            }

            TempData["SuccessMessage"] = "Department updated successfully!";
            return RedirectToAction("ManageDepartments");
        }

        /// <summary>
        /// Delete Department
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> DeleteDepartment(int id)
        {
            if (!CheckSuperAdminSession())
            {
                return RedirectToAction("Login");
            }

            var superAdminId = HttpContext.Session.GetInt32("SuperAdminId").Value;
            var success = await _superAdminService.DeleteDepartment(id, superAdminId);

            if (success)
            {
                TempData["SuccessMessage"] = "Department deleted successfully!";
            }
            else
            {
                TempData["ErrorMessage"] = "Failed to delete department.";
            }

            return RedirectToAction("ManageDepartments");
        }

        #endregion

        #region Admin Management

        /// <summary>
        /// Manage Admins Page
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> ManageAdmins()
        {
            if (!CheckSuperAdminSession())
            {
                return RedirectToAction("Login");
            }

            var admins = await _superAdminService.GetAllAdmins();
            var departments = await _superAdminService.GetSimpleDepartmentList();

            var model = new AdminManagementViewModel
            {
                Admins = admins,
                AvailableDepartments = departments
            };

            return View(model);
        }

        /// <summary>
        /// Create Admin - POST (AJAX)
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> CreateAdmin([FromBody] AdminUserDetailViewModel model)
        {
            if (!CheckSuperAdminSession())
            {
                return Json(new { success = false, message = "Unauthorized" });
            }

            if (!ModelState.IsValid)
            {
                return Json(new { success = false, message = "Invalid data provided" });
            }

            try
            {
                var superAdminId = HttpContext.Session.GetInt32("SuperAdminId").Value;
                await _superAdminService.CreateAdmin(model, superAdminId);

                return Json(new { success = true, message = "Admin created successfully" });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = ex.Message });
            }
        }

        /// <summary>
        /// Delete Admin - POST (AJAX)
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> DeleteAdmin([FromBody] dynamic data)
        {
            if (!CheckSuperAdminSession())
            {
                return Json(new { success = false, message = "Unauthorized" });
            }

            try
            {
                int adminId = (int)data.AdminId;
                var superAdminId = HttpContext.Session.GetInt32("SuperAdminId").Value;
                var success = await _superAdminService.DeleteAdmin(adminId, superAdminId);

                if (success)
                {
                    return Json(new { success = true, message = "Admin deleted successfully" });
                }

                return Json(new { success = false, message = "Failed to delete admin" });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = ex.Message });
            }
        }

        #endregion

        #region Reports & Analytics

        /// <summary>
        /// Cross-Department Reports
        /// </summary>
        [HttpGet]
        public IActionResult CrossDepartmentReports()
        {
            if (!CheckSuperAdminSession())
            {
                return RedirectToAction("Login");
            }

            // This will be implemented in Phase 3
            return View();
        }

        /// <summary>
        /// System Configuration
        /// </summary>
        [HttpGet]
        public IActionResult SystemConfiguration()
        {
            if (!CheckSuperAdminSession())
            {
                return RedirectToAction("Login");
            }

            // This will be implemented in Phase 3
            return View();
        }

        /// <summary>
        /// Audit Logs
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> AuditLogs(int count = 100)
        {
            if (!CheckSuperAdminSession())
            {
                return RedirectToAction("Login");
            }

            var logs = await _superAdminService.GetRecentActivities(count);
            return View(logs);
        }

        #endregion

        #region Cross-Department Management Routes

        /// <summary>
        /// Manage Students for specific department
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> ManageStudents(int departmentId)
        {
            if (!CheckSuperAdminSession())
            {
                return RedirectToAction("Login");
            }

            var department = await _superAdminService.GetDepartmentById(departmentId);
            if (department == null)
            {
                TempData["ErrorMessage"] = "Department not found.";
                return RedirectToAction("Dashboard");
            }

            // Store department context in session for the admin view
            HttpContext.Session.SetString("ViewingDepartment", department.DepartmentCode);
            HttpContext.Session.SetString("ViewingDepartmentName", department.DepartmentName);
            HttpContext.Session.SetInt32("ViewingDepartmentId", department.DepartmentId);
            
            // Also set AdminDepartment so admin views recognize the context
            HttpContext.Session.SetString("AdminDepartment", department.DepartmentCode);
            
            // Set a temporary AdminId flag (using SuperAdminId) so admin views don't reject
            var superAdminId = HttpContext.Session.GetInt32("SuperAdminId").Value;
            HttpContext.Session.SetInt32("AdminId", superAdminId);
            HttpContext.Session.SetString("AdminEmail", HttpContext.Session.GetString("SuperAdminEmail"));

            // Redirect to appropriate admin management page based on department
            if (department.DepartmentCode.Equals("CSE", StringComparison.OrdinalIgnoreCase))
            {
                return RedirectToAction("ManageStudents", "Admin");
            }
            else if (department.DepartmentCode.Equals("CSEDS", StringComparison.OrdinalIgnoreCase) || 
                     department.DepartmentCode.Equals("CSE(DS)", StringComparison.OrdinalIgnoreCase))
            {
                return RedirectToAction("ManageCSEDSStudents", "Admin");
            }
            else
            {
                // All other departments use generic dynamic interface - pass department parameter
                return RedirectToAction("ManageDynamicStudents", "Admin", new { department = department.DepartmentCode });
            }
        }

        /// <summary>
        /// Manage Faculty for specific department
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> ManageFaculty(int departmentId)
        {
            if (!CheckSuperAdminSession())
            {
                return RedirectToAction("Login");
            }

            var department = await _superAdminService.GetDepartmentById(departmentId);
            if (department == null)
            {
                TempData["ErrorMessage"] = "Department not found.";
                return RedirectToAction("Dashboard");
            }

            HttpContext.Session.SetString("ViewingDepartment", department.DepartmentCode);
            HttpContext.Session.SetString("ViewingDepartmentName", department.DepartmentName);
            HttpContext.Session.SetInt32("ViewingDepartmentId", department.DepartmentId);
            HttpContext.Session.SetString("AdminDepartment", department.DepartmentCode);
            
            var superAdminId = HttpContext.Session.GetInt32("SuperAdminId").Value;
            HttpContext.Session.SetInt32("AdminId", superAdminId);
            HttpContext.Session.SetString("AdminEmail", HttpContext.Session.GetString("SuperAdminEmail"));

            if (department.DepartmentCode.Equals("CSE", StringComparison.OrdinalIgnoreCase))
            {
                return RedirectToAction("ManageFaculty", "Admin");
            }
            else if (department.DepartmentCode.Equals("CSEDS", StringComparison.OrdinalIgnoreCase) || 
                     department.DepartmentCode.Equals("CSE(DS)", StringComparison.OrdinalIgnoreCase))
            {
                return RedirectToAction("ManageCSEDSFaculty", "Admin");
            }
            else
            {
                // All other departments use generic dynamic interface - pass department parameter
                return RedirectToAction("ManageDynamicFaculty", "Admin", new { department = department.DepartmentCode });
            }
        }

        /// <summary>
        /// Manage Subjects for specific department
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> ManageSubjects(int departmentId)
        {
            if (!CheckSuperAdminSession())
            {
                return RedirectToAction("Login");
            }

            var department = await _superAdminService.GetDepartmentById(departmentId);
            if (department == null)
            {
                TempData["ErrorMessage"] = "Department not found.";
                return RedirectToAction("Dashboard");
            }

            HttpContext.Session.SetString("ViewingDepartment", department.DepartmentCode);
            HttpContext.Session.SetString("ViewingDepartmentName", department.DepartmentName);
            HttpContext.Session.SetInt32("ViewingDepartmentId", department.DepartmentId);
            HttpContext.Session.SetString("AdminDepartment", department.DepartmentCode);
            
            var superAdminId = HttpContext.Session.GetInt32("SuperAdminId").Value;
            HttpContext.Session.SetInt32("AdminId", superAdminId);
            HttpContext.Session.SetString("AdminEmail", HttpContext.Session.GetString("SuperAdminEmail"));

            if (department.DepartmentCode.Equals("CSE", StringComparison.OrdinalIgnoreCase))
            {
                return RedirectToAction("ManageSubjects", "Admin");
            }
            else if (department.DepartmentCode.Equals("CSEDS", StringComparison.OrdinalIgnoreCase) || 
                     department.DepartmentCode.Equals("CSE(DS)", StringComparison.OrdinalIgnoreCase))
            {
                return RedirectToAction("ManageCSEDSSubjects", "Admin");
            }
            else
            {
                // All other departments use generic dynamic interface - pass department parameter
                return RedirectToAction("ManageDynamicSubjects", "Admin", new { department = department.DepartmentCode });
            }
        }

        /// <summary>
        /// Manage Subject Assignments for specific department
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> ManageSubjectAssignments(int departmentId)
        {
            if (!CheckSuperAdminSession())
            {
                return RedirectToAction("Login");
            }

            var department = await _superAdminService.GetDepartmentById(departmentId);
            if (department == null)
            {
                TempData["ErrorMessage"] = "Department not found.";
                return RedirectToAction("Dashboard");
            }

            HttpContext.Session.SetString("ViewingDepartment", department.DepartmentCode);
            HttpContext.Session.SetString("ViewingDepartmentName", department.DepartmentName);
            HttpContext.Session.SetInt32("ViewingDepartmentId", department.DepartmentId);
            HttpContext.Session.SetString("AdminDepartment", department.DepartmentCode);
            
            var superAdminId = HttpContext.Session.GetInt32("SuperAdminId").Value;
            HttpContext.Session.SetInt32("AdminId", superAdminId);
            HttpContext.Session.SetString("AdminEmail", HttpContext.Session.GetString("SuperAdminEmail"));

            // Pass department parameter for subject assignments
            return RedirectToAction("ManageSubjectAssignments", "Admin", new { department = department.DepartmentCode });
        }

        /// <summary>
        /// Toggle Department Feature - AJAX Endpoint
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> ToggleDepartmentFeature([FromBody] dynamic data)
        {
            if (!CheckSuperAdminSession())
            {
                return Json(new { success = false, message = "Unauthorized" });
            }

            try
            {
                int departmentId = (int)data.departmentId;
                string featureName = (string)data.featureName;
                bool enabled = (bool)data.enabled;

                var superAdminId = HttpContext.Session.GetInt32("SuperAdminId").Value;
                var success = await _superAdminService.ToggleDepartmentFeature(departmentId, featureName, enabled, superAdminId);

                if (success)
                {
                    return Json(new { success = true, message = $"Feature {featureName} toggled successfully" });
                }

                return Json(new { success = false, message = "Failed to toggle feature" });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = ex.Message });
            }
        }

        #endregion

        #region Dynamic Department Dashboard

        /// <summary>
        /// Dynamic Department Dashboard - Works for ANY department
        /// Provides CSEDS-like functionality for all departments
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> DynamicDashboard(string departmentId)
        {
            if (!CheckSuperAdminSession())
            {
                return RedirectToAction("Login");
            }

            if (string.IsNullOrEmpty(departmentId))
            {
                TempData["ErrorMessage"] = "Department ID is required.";
                return RedirectToAction("Dashboard");
            }

            // Parse department ID
            if (!int.TryParse(departmentId, out int deptId))
            {
                TempData["ErrorMessage"] = "Invalid department ID.";
                return RedirectToAction("Dashboard");
            }

            // Get department details
            var department = await _superAdminService.GetDepartmentById(deptId);
            if (department == null)
            {
                TempData["ErrorMessage"] = "Department not found.";
                return RedirectToAction("Dashboard");
            }

            // Build dashboard view model
            var students = await _context.Students
                .Where(s => s.Department == department.DepartmentCode)
                .ToListAsync();

            var faculties = await _context.Faculties
                .Where(f => f.Department == department.DepartmentCode)
                .ToListAsync();

            var subjects = await _context.Subjects
                .Where(s => s.Department == department.DepartmentCode)
                .ToListAsync();

            var enrollments = await _context.StudentEnrollments
                .Include(se => se.Student)
                .Include(se => se.AssignedSubject)
                    .ThenInclude(a => a.Subject)
                .Where(se => se.Student.Department == department.DepartmentCode)
                .ToListAsync();

            // Get subject-faculty mappings (matching CSEDS functionality)
            var subjectFacultyMappings = await GetSubjectFacultyMappingsForDepartment(department.DepartmentCode);

            var viewModel = new DepartmentDashboardViewModel
            {
                DepartmentCode = department.DepartmentCode,
                DepartmentName = department.DepartmentName,
                AdminEmail = HttpContext.Session.GetString("SuperAdminEmail") ?? "",
                TotalStudents = students.Count,
                TotalFaculty = faculties.Count,
                TotalSubjects = subjects.Count,
                TotalEnrollments = enrollments.Count,
                TotalAssignments = 0,
                StudentsByYear = students
                    .Where(s => !string.IsNullOrEmpty(s.Year))
                    .GroupBy(s => s.Year)
                    .Select(g => new StudentYearStatistic 
                    { 
                        Year = g.Key,  // Keep as string, no need to extract
                        Count = g.Count() 
                    })
                    .OrderBy(ys => ys.Year)
                    .ToList(),
                SubjectsByYear = subjects.GroupBy(s => s.Year)
                    .Select(g => new YearStatistic { Year = g.Key, Count = g.Count() })
                    .OrderBy(ys => ys.Year)
                    .ToList(),
                RecentStudents = students.OrderByDescending(s => s.Id).Take(5).ToList(),
                RecentFaculty = faculties.OrderByDescending(f => f.FacultyId).Take(5).ToList(),
                SubjectFacultyMappings = subjectFacultyMappings
            };

            Console.WriteLine($"DynamicDashboard loaded for: {department.DepartmentName} ({department.DepartmentCode})");
            Console.WriteLine($"Students: {viewModel.TotalStudents}, Faculty: {viewModel.TotalFaculty}, Subjects: {viewModel.TotalSubjects}");

            return View(viewModel);
        }

        /// <summary>
        /// Helper method to get subject-faculty mappings for any department
        /// </summary>
        private async Task<List<SubjectFacultyMappingDto>> GetSubjectFacultyMappingsForDepartment(string departmentCode)
        {
            // Get all subjects for this department
            var subjects = await _context.Subjects
                .Where(s => s.Department == departmentCode)
                .ToListAsync();

            var result = new List<SubjectFacultyMappingDto>();

            foreach (var s in subjects)
            {
                var assignedFaculty = await _context.AssignedSubjects
                    .Include(a => a.Faculty)
                    .Where(a => a.SubjectId == s.SubjectId && a.Faculty.Department == departmentCode)
                    .ToListAsync();

                var enrollmentCount = 0;
                var facultyInfos = new List<FacultyInfo>();

                foreach (var assignment in assignedFaculty)
                {
                    var enrollments = await _context.StudentEnrollments
                        .CountAsync(se => se.AssignedSubjectId == assignment.AssignedSubjectId);

                    enrollmentCount += enrollments;

                    facultyInfos.Add(new FacultyInfo
                    {
                        FacultyId = assignment.FacultyId,
                        Name = assignment.Faculty.Name,
                        Email = assignment.Faculty.Email,
                        AssignedSubjectId = assignment.AssignedSubjectId
                    });
                }

                result.Add(new SubjectFacultyMappingDto
                {
                    SubjectId = s.SubjectId,
                    SubjectName = s.Name,
                    Year = s.Year,
                    Semester = s.Semester ?? "",
                    SemesterStartDate = s.SemesterStartDate,
                    SemesterEndDate = s.SemesterEndDate,
                    AssignedFaculty = facultyInfos,
                    EnrollmentCount = enrollmentCount
                });
            }

            return result.OrderBy(s => s.Year).ThenBy(s => s.SubjectName).ToList();
        }

        /// <summary>
        /// Extract numeric year from year string (e.g., "II Year" -> 2, "III Year" -> 3)
        /// </summary>
        private int ExtractYear(string yearString)
        {
            if (string.IsNullOrEmpty(yearString)) return 0;
            
            yearString = yearString.ToUpper().Replace(" ", "").Replace("YEAR", "");
            
            if (yearString.Contains("IV") || yearString.Contains("4")) return 4;
            if (yearString.Contains("III") || yearString.Contains("3")) return 3;
            if (yearString.Contains("II") || yearString.Contains("2")) return 2;
            if (yearString.Contains("I") || yearString.Contains("1")) return 1;
            
            return 0;
        }

        #endregion

        #region Helper Methods

        /// <summary>
        /// Check if super admin is logged in
        /// </summary>
        private bool CheckSuperAdminSession()
        {
            var superAdminId = HttpContext.Session.GetInt32("SuperAdminId");
            var userRole = HttpContext.Session.GetString("UserRole");

            return superAdminId.HasValue && userRole == "SuperAdmin";
        }

        #endregion
    }
}
