using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TutorLiveMentor.Models;
using TutorLiveMentor.Helpers;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace TutorLiveMentor.Controllers
{
    /// <summary>
    /// Partial class for AdminController with Dynamic Department Management Methods
    /// Provides CSEDS-equivalent functionality for ALL departments
    /// </summary>
    public partial class AdminController
    {
        #region Dynamic Department Validation

        /// <summary>
        /// Check if admin has access to a specific department
        /// </summary>
        private bool HasDepartmentAccess(string department, string requestedDepartment)
        {
            if (string.IsNullOrEmpty(department) || string.IsNullOrEmpty(requestedDepartment))
                return false;

            var normalizedAdmin = DepartmentNormalizer.Normalize(department);
            var normalizedRequest = DepartmentNormalizer.Normalize(requestedDepartment);

            return normalizedAdmin == normalizedRequest;
        }

        /// <summary>
        /// Get department from session or request
        /// </summary>
        private string GetDepartmentFromRequest(string requestDepartment)
        {
            if (!string.IsNullOrEmpty(requestDepartment))
                return requestDepartment;

            return HttpContext.Session.GetString("AdminDepartment") ?? "";
        }

        #endregion

        #region Dynamic Dashboard

        /// <summary>
        /// Dynamic Dashboard for any department (accessed from Admin login)
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> DynamicDashboard(string department)
        {
            var adminId = HttpContext.Session.GetInt32("AdminId");
            var adminDepartment = HttpContext.Session.GetString("AdminDepartment");

            if (adminId == null)
            {
                TempData["ErrorMessage"] = "Please login to access the dashboard.";
                return RedirectToAction("Login");
            }

            var deptCode = GetDepartmentFromRequest(department);
            if (string.IsNullOrEmpty(deptCode))
            {
                TempData["ErrorMessage"] = "Department not specified.";
                return RedirectToAction("Dashboard");
            }

            var normalizedDept = DepartmentNormalizer.Normalize(deptCode);

            var viewModel = new DepartmentDashboardViewModel
            {
                DepartmentCode = deptCode,
                DepartmentName = deptCode,
                AdminEmail = HttpContext.Session.GetString("AdminEmail") ?? "",
                TotalStudents = await _context.Students.Where(s => s.Department == normalizedDept).CountAsync(),
                TotalFaculty = await _context.Faculties.Where(f => f.Department == normalizedDept).CountAsync(),
                TotalSubjects = await _context.Subjects.Where(s => s.Department == normalizedDept).CountAsync(),
                TotalEnrollments = await _context.StudentEnrollments
                    .Include(se => se.Student)
                    .Where(se => se.Student.Department == normalizedDept)
                    .CountAsync(),
                RecentStudents = await _context.Students
                    .Where(s => s.Department == normalizedDept)
                    .OrderByDescending(s => s.Id)
                    .Take(5)
                    .ToListAsync(),
                RecentFaculty = await _context.Faculties
                    .Where(f => f.Department == normalizedDept)
                    .OrderByDescending(f => f.FacultyId)
                    .Take(5)
                    .ToListAsync(),
                StudentsByYear = await _context.Students
                    .Where(s => s.Department == normalizedDept && !string.IsNullOrEmpty(s.Year))
                    .GroupBy(s => s.Year)
                    .Select(g => new StudentYearStatistic { Year = g.Key, Count = g.Count() })
                    .ToListAsync(),
                SubjectFacultyMappings = await GetDynamicSubjectFacultyMappings(normalizedDept)
            };

            // Get department name from database if available
            var dept = await _context.Departments.FirstOrDefaultAsync(d => d.DepartmentCode == deptCode);
            if (dept != null)
            {
                viewModel.DepartmentName = dept.DepartmentName;
            }

            return View(viewModel);
        }

        #endregion

        #region Dynamic Faculty Management

        /// <summary>
        /// Manage Faculty for any department - View action
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> ManageDynamicFaculty(string department)
        {
            var adminId = HttpContext.Session.GetInt32("AdminId");
            if (adminId == null)
            {
                TempData["ErrorMessage"] = "Please login to access faculty management.";
                return RedirectToAction("Login");
            }

            var deptCode = GetDepartmentFromRequest(department);
            if (string.IsNullOrEmpty(deptCode))
            {
                TempData["ErrorMessage"] = "Department not specified.";
                return RedirectToAction("Dashboard");
            }

            var normalizedDept = DepartmentNormalizer.Normalize(deptCode);

            var viewModel = new FacultyManagementViewModel
            {
                DepartmentFaculty = await GetDynamicFacultyWithAssignments(normalizedDept),
                AvailableSubjects = await _context.Subjects
                    .Where(s => s.Department == normalizedDept)
                    .OrderBy(s => s.Year)
                    .ThenBy(s => s.Name)
                    .ToListAsync()
            };

            // Get department name
            var dept = await _context.Departments.FirstOrDefaultAsync(d => d.DepartmentCode == deptCode);
            ViewBag.DepartmentCode = deptCode;
            ViewBag.DepartmentName = dept?.DepartmentName ?? deptCode;

            return View(viewModel);
        }

        /// <summary>
        /// Add faculty to dynamic department
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> AddDynamicFaculty([FromBody] AddFacultyRequest request, string department)
        {
            var adminId = HttpContext.Session.GetInt32("AdminId");
            if (adminId == null)
                return Json(new { success = false, message = "Session expired" });

            var deptCode = GetDepartmentFromRequest(department);
            if (string.IsNullOrEmpty(deptCode))
                return Json(new { success = false, message = "Department not specified" });

            try
            {
                var normalizedDept = DepartmentNormalizer.Normalize(deptCode);

                // Check if email already exists
                var existingFaculty = await _context.Faculties.FirstOrDefaultAsync(f => f.Email == request.Email);
                if (existingFaculty != null)
                    return Json(new { success = false, message = "Faculty with this email already exists" });

                var faculty = new Faculty
                {
                    Name = request.Name,
                    Email = request.Email,
                    Password = request.Password ?? "TutorLive123",
                    Department = normalizedDept
                };

                _context.Faculties.Add(faculty);
                await _context.SaveChangesAsync();

                await _signalRService.NotifyUserActivity(
                    HttpContext.Session.GetString("AdminEmail") ?? "",
                    "Admin",
                    "Faculty Added",
                    $"New faculty member {faculty.Name} added to {deptCode}"
                );

                return Json(new { success = true, message = "Faculty added successfully", facultyId = faculty.FacultyId });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = $"Error adding faculty: {ex.Message}" });
            }
        }

        /// <summary>
        /// Update faculty in dynamic department
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> UpdateDynamicFaculty([FromBody] UpdateFacultyRequest request, string department)
        {
            var adminId = HttpContext.Session.GetInt32("AdminId");
            if (adminId == null)
                return Json(new { success = false, message = "Session expired" });

            var deptCode = GetDepartmentFromRequest(department);
            if (string.IsNullOrEmpty(deptCode))
                return Json(new { success = false, message = "Department not specified" });

            try
            {
                var normalizedDept = DepartmentNormalizer.Normalize(deptCode);

                var faculty = await _context.Faculties
                    .FirstOrDefaultAsync(f => f.FacultyId == request.FacultyId && f.Department == normalizedDept);

                if (faculty == null)
                    return Json(new { success = false, message = "Faculty not found in your department" });

                // Check if email is changing and already exists
                if (faculty.Email != request.Email)
                {
                    var existingFaculty = await _context.Faculties.FirstOrDefaultAsync(f => f.Email == request.Email);
                    if (existingFaculty != null)
                        return Json(new { success = false, message = "Another faculty already uses this email" });
                }

                faculty.Name = request.Name;
                faculty.Email = request.Email;
                if (!string.IsNullOrEmpty(request.Password))
                    faculty.Password = request.Password;

                await _context.SaveChangesAsync();

                await _signalRService.NotifyUserActivity(
                    HttpContext.Session.GetString("AdminEmail") ?? "",
                    "Admin",
                    "Faculty Updated",
                    $"Faculty {faculty.Name} updated in {deptCode}"
                );

                return Json(new { success = true, message = "Faculty updated successfully" });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = $"Error updating faculty: {ex.Message}" });
            }
        }

        /// <summary>
        /// Delete faculty from dynamic department
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> DeleteDynamicFaculty([FromBody] DeleteFacultyRequest request, string department)
        {
            var adminId = HttpContext.Session.GetInt32("AdminId");
            if (adminId == null)
                return Json(new { success = false, message = "Session expired" });

            var deptCode = GetDepartmentFromRequest(department);
            if (string.IsNullOrEmpty(deptCode))
                return Json(new { success = false, message = "Department not specified" });

            try
            {
                var normalizedDept = DepartmentNormalizer.Normalize(deptCode);

                var faculty = await _context.Faculties
                    .FirstOrDefaultAsync(f => f.FacultyId == request.FacultyId && f.Department == normalizedDept);

                if (faculty == null)
                    return Json(new { success = false, message = "Faculty not found in your department" });

                // Check for enrollments
                var hasEnrollments = await _context.StudentEnrollments
                    .Include(se => se.AssignedSubject)
                    .AnyAsync(se => se.AssignedSubject.FacultyId == request.FacultyId);

                if (hasEnrollments)
                    return Json(new { success = false, message = "Cannot delete faculty with active student enrollments" });

                // Remove assigned subjects first
                var assignments = await _context.AssignedSubjects
                    .Where(a => a.FacultyId == request.FacultyId)
                    .ToListAsync();

                _context.AssignedSubjects.RemoveRange(assignments);
                _context.Faculties.Remove(faculty);
                await _context.SaveChangesAsync();

                await _signalRService.NotifyUserActivity(
                    HttpContext.Session.GetString("AdminEmail") ?? "",
                    "Admin",
                    "Faculty Deleted",
                    $"Faculty {faculty.Name} deleted from {deptCode}"
                );

                return Json(new { success = true, message = "Faculty deleted successfully" });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = $"Error deleting faculty: {ex.Message}" });
            }
        }

        #endregion

        #region Dynamic Subjects Management

        /// <summary>
        /// Manage Subjects for any department - View action
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> ManageDynamicSubjects(string department)
        {
            var adminId = HttpContext.Session.GetInt32("AdminId");
            if (adminId == null)
            {
                TempData["ErrorMessage"] = "Please login to access subject management.";
                return RedirectToAction("Login");
            }

            var deptCode = GetDepartmentFromRequest(department);
            if (string.IsNullOrEmpty(deptCode))
            {
                TempData["ErrorMessage"] = "Department not specified.";
                return RedirectToAction("Dashboard");
            }

            var normalizedDept = DepartmentNormalizer.Normalize(deptCode);

            var subjects = await _context.Subjects
                .Where(s => s.Department == normalizedDept)
                .OrderBy(s => s.Year)
                .ThenBy(s => s.Name)
                .ToListAsync();

            // Get department name
            var dept = await _context.Departments.FirstOrDefaultAsync(d => d.DepartmentCode == deptCode);
            ViewBag.DepartmentCode = deptCode;
            ViewBag.DepartmentName = dept?.DepartmentName ?? deptCode;

            return View(subjects);
        }

        /// <summary>
        /// Add subject to dynamic department
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> AddDynamicSubject([FromBody] AddSubjectRequest request, string department)
        {
            var adminId = HttpContext.Session.GetInt32("AdminId");
            if (adminId == null)
                return Json(new { success = false, message = "Session expired" });

            var deptCode = GetDepartmentFromRequest(department);
            if (string.IsNullOrEmpty(deptCode))
                return Json(new { success = false, message = "Department not specified" });

            try
            {
                var normalizedDept = DepartmentNormalizer.Normalize(deptCode);

                var subject = new Subject
                {
                    Name = request.Name,
                    Department = normalizedDept,
                    Year = request.Year,
                    Semester = request.Semester,
                    SemesterStartDate = request.SemesterStartDate,
                    SemesterEndDate = request.SemesterEndDate,
                    MaxEnrollments = request.MaxEnrollments ?? 60
                };

                _context.Subjects.Add(subject);
                await _context.SaveChangesAsync();

                await _signalRService.NotifyUserActivity(
                    HttpContext.Session.GetString("AdminEmail") ?? "",
                    "Admin",
                    "Subject Added",
                    $"New subject {subject.Name} added to {deptCode}"
                );

                return Json(new { success = true, message = "Subject added successfully", subjectId = subject.SubjectId });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = $"Error adding subject: {ex.Message}" });
            }
        }

        /// <summary>
        /// Update subject in dynamic department
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> UpdateDynamicSubject([FromBody] UpdateSubjectRequest request, string department)
        {
            var adminId = HttpContext.Session.GetInt32("AdminId");
            if (adminId == null)
                return Json(new { success = false, message = "Session expired" });

            var deptCode = GetDepartmentFromRequest(department);
            if (string.IsNullOrEmpty(deptCode))
                return Json(new { success = false, message = "Department not specified" });

            try
            {
                var normalizedDept = DepartmentNormalizer.Normalize(deptCode);

                var subject = await _context.Subjects
                    .FirstOrDefaultAsync(s => s.SubjectId == request.SubjectId && s.Department == normalizedDept);

                if (subject == null)
                    return Json(new { success = false, message = "Subject not found in your department" });

                subject.Name = request.Name;
                subject.Year = request.Year;
                subject.Semester = request.Semester;
                subject.SemesterStartDate = request.SemesterStartDate;
                subject.SemesterEndDate = request.SemesterEndDate;
                if (request.MaxEnrollments.HasValue)
                    subject.MaxEnrollments = request.MaxEnrollments.Value;

                await _context.SaveChangesAsync();

                await _signalRService.NotifyUserActivity(
                    HttpContext.Session.GetString("AdminEmail") ?? "",
                    "Admin",
                    "Subject Updated",
                    $"Subject {subject.Name} updated in {deptCode}"
                );

                return Json(new { success = true, message = "Subject updated successfully" });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = $"Error updating subject: {ex.Message}" });
            }
        }

        /// <summary>
        /// Delete subject from dynamic department
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> DeleteDynamicSubject([FromBody] DeleteSubjectRequest request, string department)
        {
            var adminId = HttpContext.Session.GetInt32("AdminId");
            if (adminId == null)
                return Json(new { success = false, message = "Session expired" });

            var deptCode = GetDepartmentFromRequest(department);
            if (string.IsNullOrEmpty(deptCode))
                return Json(new { success = false, message = "Department not specified" });

            try
            {
                var normalizedDept = DepartmentNormalizer.Normalize(deptCode);

                var subject = await _context.Subjects
                    .FirstOrDefaultAsync(s => s.SubjectId == request.SubjectId && s.Department == normalizedDept);

                if (subject == null)
                    return Json(new { success = false, message = "Subject not found in your department" });

                // Check for enrollments
                var hasEnrollments = await _context.StudentEnrollments
                    .Include(se => se.AssignedSubject)
                    .AnyAsync(se => se.AssignedSubject.SubjectId == request.SubjectId);

                if (hasEnrollments)
                    return Json(new { success = false, message = "Cannot delete subject with active enrollments" });

                // Remove assigned subjects first
                var assignments = await _context.AssignedSubjects
                    .Where(a => a.SubjectId == request.SubjectId)
                    .ToListAsync();

                _context.AssignedSubjects.RemoveRange(assignments);
                _context.Subjects.Remove(subject);
                await _context.SaveChangesAsync();

                await _signalRService.NotifyUserActivity(
                    HttpContext.Session.GetString("AdminEmail") ?? "",
                    "Admin",
                    "Subject Deleted",
                    $"Subject {subject.Name} deleted from {deptCode}"
                );

                return Json(new { success = true, message = "Subject deleted successfully" });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = $"Error deleting subject: {ex.Message}" });
            }
        }

        #endregion

        #region Dynamic Students Management

        /// <summary>
        /// Manage Students for any department - View action
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> ManageDynamicStudents(string department)
        {
            var adminId = HttpContext.Session.GetInt32("AdminId");
            if (adminId == null)
            {
                TempData["ErrorMessage"] = "Please login to access student management.";
                return RedirectToAction("Login");
            }

            var deptCode = GetDepartmentFromRequest(department);
            if (string.IsNullOrEmpty(deptCode))
            {
                TempData["ErrorMessage"] = "Department not specified.";
                return RedirectToAction("Dashboard");
            }

            var normalizedDept = DepartmentNormalizer.Normalize(deptCode);

            // Get all students with their enrollments
            var students = await _context.Students
                .Where(s => s.Department == normalizedDept)
                .ToListAsync();

            var studentDetails = new List<StudentDetailDto>();

            foreach (var student in students)
            {
                var enrollments = await _context.StudentEnrollments
                    .Include(se => se.AssignedSubject)
                        .ThenInclude(a => a.Subject)
                    .Include(se => se.AssignedSubject)
                        .ThenInclude(a => a.Faculty)
                    .Where(se => se.StudentId == student.Id)
                    .ToListAsync();

                var enrolledSubjects = enrollments.Select(e => new EnrolledSubjectInfo
                {
                    SubjectName = e.AssignedSubject.Subject.Name,
                    FacultyName = e.AssignedSubject.Faculty.Name,
                    Semester = e.AssignedSubject.Subject.Semester ?? ""
                }).ToList();

                studentDetails.Add(new StudentDetailDto
                {
                    StudentId = student.Id,
                    FullName = student.FullName,
                    RegdNumber = student.RegdNumber,
                    Email = student.Email,
                    Year = student.Year,
                    Semester = student.Semester ?? "",
                    Department = student.Department,
                    TotalEnrollments = enrollments.Count,
                    EnrolledSubjects = enrolledSubjects
                });
            }

            var viewModel = new StudentManagementViewModel
            {
                DepartmentStudents = studentDetails,
                AvailableYears = new List<string> { "I Year", "II Year", "III Year", "IV Year" }
            };

            // Get department name
            var dept = await _context.Departments.FirstOrDefaultAsync(d => d.DepartmentCode == deptCode);
            ViewBag.DepartmentCode = deptCode;
            ViewBag.DepartmentName = dept?.DepartmentName ?? deptCode;

            return View(viewModel);
        }

        /// <summary>
        /// Add student to dynamic department
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> AddDynamicStudent([FromBody] AddStudentRequest request, string department)
        {
            var adminId = HttpContext.Session.GetInt32("AdminId");
            if (adminId == null)
                return Json(new { success = false, message = "Session expired" });

            var deptCode = GetDepartmentFromRequest(department);
            if (string.IsNullOrEmpty(deptCode))
                return Json(new { success = false, message = "Department not specified" });

            try
            {
                var normalizedDept = DepartmentNormalizer.Normalize(deptCode);

                // Check if student with this registration number already exists
                var existingStudent = await _context.Students.FirstOrDefaultAsync(s => s.RegdNumber == request.RegdNumber);
                if (existingStudent != null)
                    return Json(new { success = false, message = "Student with this registration number already exists" });

                // Check if email already exists
                var existingEmail = await _context.Students.FirstOrDefaultAsync(s => s.Email == request.Email);
                if (existingEmail != null)
                    return Json(new { success = false, message = "Student with this email already exists" });

                var student = new Student
                {
                    Id = request.RegdNumber,
                    FullName = request.FullName,
                    RegdNumber = request.RegdNumber,
                    Email = request.Email,
                    Password = request.Password ?? "TutorLive123",
                    Year = request.Year,
                    Semester = request.Semester ?? "",
                    Department = normalizedDept,
                    SelectedSubject = ""
                };

                _context.Students.Add(student);
                await _context.SaveChangesAsync();

                await _signalRService.NotifyUserActivity(
                    HttpContext.Session.GetString("AdminEmail") ?? "",
                    "Admin",
                    "Student Added",
                    $"New student {student.FullName} added to {deptCode}"
                );

                return Json(new { success = true, message = "Student added successfully", studentId = student.Id });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = $"Error adding student: {ex.Message}" });
            }
        }

        /// <summary>
        /// Add student page for dynamic department
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> AddDynamicStudent(string department)
        {
            var adminId = HttpContext.Session.GetInt32("AdminId");
            if (adminId == null)
            {
                TempData["ErrorMessage"] = "Please login to access this page.";
                return RedirectToAction("Login");
            }

            var deptCode = GetDepartmentFromRequest(department);
            if (string.IsNullOrEmpty(deptCode))
            {
                TempData["ErrorMessage"] = "Department not specified.";
                return RedirectToAction("Dashboard");
            }

            var viewModel = new CSEDSStudentViewModel
            {
                Department = deptCode,
                IsEdit = false,
                AvailableYears = new List<string> { "I Year", "II Year", "III Year", "IV Year" }
            };

            ViewBag.DepartmentCode = deptCode;
            var dept = await _context.Departments.FirstOrDefaultAsync(d => d.DepartmentCode == deptCode);
            ViewBag.DepartmentName = dept?.DepartmentName ?? deptCode;

            return View("AddDynamicStudent", viewModel);
        }

        /// <summary>
        /// Add student POST for dynamic department
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> AddDynamicStudent(CSEDSStudentViewModel model, string department)
        {
            var adminId = HttpContext.Session.GetInt32("AdminId");
            if (adminId == null)
            {
                TempData["ErrorMessage"] = "Please login to access this page.";
                return RedirectToAction("Login");
            }

            var deptCode = GetDepartmentFromRequest(department);
            if (string.IsNullOrEmpty(deptCode))
            {
                TempData["ErrorMessage"] = "Department not specified.";
                return RedirectToAction("Dashboard");
            }

            // Validate model
            if (!ModelState.IsValid)
            {
                model.AvailableYears = new List<string> { "I Year", "II Year", "III Year", "IV Year" };
                ViewBag.DepartmentCode = deptCode;
                var dept = await _context.Departments.FirstOrDefaultAsync(d => d.DepartmentCode == deptCode);
                ViewBag.DepartmentName = dept?.DepartmentName ?? deptCode;
                return View(model);
            }

            try
            {
                var normalizedDept = DepartmentNormalizer.Normalize(deptCode);

                // Check if student with this registration number already exists
                var existingStudent = await _context.Students
                    .FirstOrDefaultAsync(s => s.RegdNumber == model.RegdNumber);

                if (existingStudent != null)
                {
                    ModelState.AddModelError("RegdNumber", "Student with this registration number already exists");
                    model.AvailableYears = new List<string> { "I Year", "II Year", "III Year", "IV Year" };
                    ViewBag.DepartmentCode = deptCode;
                    var dept = await _context.Departments.FirstOrDefaultAsync(d => d.DepartmentCode == deptCode);
                    ViewBag.DepartmentName = dept?.DepartmentName ?? deptCode;
                    return View(model);
                }

                // Check if email already exists
                var existingEmail = await _context.Students
                    .FirstOrDefaultAsync(s => s.Email == model.Email);

                if (existingEmail != null)
                {
                    ModelState.AddModelError("Email", "This email is already registered");
                    model.AvailableYears = new List<string> { "I Year", "II Year", "III Year", "IV Year" };
                    ViewBag.DepartmentCode = deptCode;
                    var dept = await _context.Departments.FirstOrDefaultAsync(d => d.DepartmentCode == deptCode);
                    ViewBag.DepartmentName = dept?.DepartmentName ?? deptCode;
                    return View(model);
                }

                // Create new student with normalized department
                var student = new Student
                {
                    Id = model.RegdNumber, // Use RegdNumber as ID
                    FullName = model.FullName,
                    RegdNumber = model.RegdNumber,
                    Email = model.Email,
                    Password = string.IsNullOrWhiteSpace(model.Password) ? "TutorLive123" : model.Password,
                    Year = model.Year,
                    Semester = model.Semester ?? "I", // Save semester, default to I if not provided
                    Department = normalizedDept, // PERMANENT FIX: Normalize department
                    SelectedSubject = ""
                };

                _context.Students.Add(student);
                await _context.SaveChangesAsync();

                await _signalRService.NotifyUserActivity(
                    HttpContext.Session.GetString("AdminEmail") ?? "",
                    "Admin",
                    "Student Added",
                    $"New student {student.FullName} has been added to {deptCode}"
                );

                // Broadcast dashboard stats update
                await BroadcastDashboardUpdate($"Student '{student.FullName}' added to {deptCode}");

                TempData["SuccessMessage"] = "Student added successfully!";
                return RedirectToAction("ManageDynamicStudents", new { department = deptCode });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error adding student: {ex.Message}");
                ModelState.AddModelError("", $"Error adding student: {ex.Message}");
                model.AvailableYears = new List<string> { "I Year", "II Year", "III Year", "IV Year" };
                ViewBag.DepartmentCode = deptCode;
                var dept = await _context.Departments.FirstOrDefaultAsync(d => d.DepartmentCode == deptCode);
                ViewBag.DepartmentName = dept?.DepartmentName ?? deptCode;
                return View(model);
            }
        }

        /// <summary>
        /// Add student POST for dynamic department (JSON API)
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> AddDynamicStudentPost([FromBody] AddStudentRequest request, string department)
        {
            var adminId = HttpContext.Session.GetInt32("AdminId");
            if (adminId == null)
                return Json(new { success = false, message = "Session expired" });

            var deptCode = GetDepartmentFromRequest(department);
            if (string.IsNullOrEmpty(deptCode))
                return Json(new { success = false, message = "Department not specified" });

            try
            {
                var normalizedDept = DepartmentNormalizer.Normalize(deptCode);

                // Check if student with this registration number already exists
                var existingStudent = await _context.Students.FirstOrDefaultAsync(s => s.RegdNumber == request.RegdNumber);
                if (existingStudent != null)
                    return Json(new { success = false, message = "Student with this registration number already exists" });

                // Check if email already exists
                var existingEmail = await _context.Students.FirstOrDefaultAsync(s => s.Email == request.Email);
                if (existingEmail != null)
                    return Json(new { success = false, message = "Student with this email already exists" });

                var student = new Student
                {
                    Id = request.RegdNumber,
                    FullName = request.FullName,
                    RegdNumber = request.RegdNumber,
                    Email = request.Email,
                    Password = request.Password ?? "TutorLive123",
                    Year = request.Year,
                    Semester = request.Semester ?? "",
                    Department = normalizedDept,
                    SelectedSubject = ""
                };

                _context.Students.Add(student);
                await _context.SaveChangesAsync();

                await _signalRService.NotifyUserActivity(
                    HttpContext.Session.GetString("AdminEmail") ?? "",
                    "Admin",
                    "Student Added",
                    $"New student {student.FullName} added to {deptCode}"
                );

                return Json(new { success = true, message = "Student added successfully", studentId = student.Id });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = $"Error adding student: {ex.Message}" });
            }
        }

        /// <summary>
        /// Edit student page for dynamic department
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> EditDynamicStudent(string id, string department)
        {
            var adminId = HttpContext.Session.GetInt32("AdminId");
            if (adminId == null)
            {
                TempData["ErrorMessage"] = "Please login to access this page.";
                return RedirectToAction("Login");
            }

            var deptCode = GetDepartmentFromRequest(department);
            if (string.IsNullOrEmpty(deptCode))
            {
                TempData["ErrorMessage"] = "Department not specified.";
                return RedirectToAction("Dashboard");
            }

            var normalizedDept = DepartmentNormalizer.Normalize(deptCode);

            var student = await _context.Students
                .FirstOrDefaultAsync(s => s.Id == id && s.Department == normalizedDept);

            if (student == null)
            {
                TempData["ErrorMessage"] = "Student not found.";
                return RedirectToAction("ManageDynamicStudents", new { department = deptCode });
            }

            var viewModel = new CSEDSStudentViewModel
            {
                StudentId = student.Id,
                FullName = student.FullName,
                RegdNumber = student.RegdNumber,
                Email = student.Email,
                Year = student.Year,
                Semester = student.Semester ?? "",
                Department = student.Department,
                IsEdit = true,
                AvailableYears = new List<string> { "I Year", "II Year", "III Year", "IV Year" }
            };

            ViewBag.DepartmentCode = deptCode;
            var dept = await _context.Departments.FirstOrDefaultAsync(d => d.DepartmentCode == deptCode);
            ViewBag.DepartmentName = dept?.DepartmentName ?? deptCode;

            return View("EditDynamicStudent", viewModel);
        }

        /// <summary>
        /// Update student in dynamic department
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> UpdateDynamicStudent([FromBody] UpdateStudentRequest request, string department)
        {
            var adminId = HttpContext.Session.GetInt32("AdminId");
            if (adminId == null)
                return Json(new { success = false, message = "Session expired" });

            var deptCode = GetDepartmentFromRequest(department);
            if (string.IsNullOrEmpty(deptCode))
                return Json(new { success = false, message = "Department not specified" });

            try
            {
                var normalizedDept = DepartmentNormalizer.Normalize(deptCode);

                var student = await _context.Students
                    .FirstOrDefaultAsync(s => s.Id == request.StudentId && s.Department == normalizedDept);

                if (student == null)
                    return Json(new { success = false, message = "Student not found" });

                // Update student properties
                student.FullName = request.FullName;
                student.Email = request.Email;
                student.Year = request.Year;
                student.Semester = request.Semester ?? "";
                
                if (!string.IsNullOrEmpty(request.Password))
                {
                    student.Password = request.Password;
                }

                await _context.SaveChangesAsync();

                await _signalRService.NotifyUserActivity(
                    HttpContext.Session.GetString("AdminEmail") ?? "",
                    "Admin",
                    "Student Updated",
                    $"Student {student.FullName} updated in {deptCode}"
                );

                return Json(new { success = true, message = "Student updated successfully" });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = $"Error updating student: {ex.Message}" });
            }
        }

        /// <summary>
        /// Delete student from dynamic department
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> DeleteDynamicStudent([FromBody] DeleteStudentRequest request, string department)
        {
            var adminId = HttpContext.Session.GetInt32("AdminId");
            if (adminId == null)
                return Json(new { success = false, message = "Session expired" });

            var deptCode = GetDepartmentFromRequest(department);
            if (string.IsNullOrEmpty(deptCode))
                return Json(new { success = false, message = "Department not specified" });

            try
            {
                var normalizedDept = DepartmentNormalizer.Normalize(deptCode);

                var student = await _context.Students
                    .FirstOrDefaultAsync(s => s.Id == request.StudentId && s.Department == normalizedDept);

                if (student == null)
                    return Json(new { success = false, message = "Student not found" });

                // Remove all enrollments first
                var enrollments = await _context.StudentEnrollments
                    .Where(se => se.StudentId == student.Id)
                    .ToListAsync();

                _context.StudentEnrollments.RemoveRange(enrollments);
                _context.Students.Remove(student);
                await _context.SaveChangesAsync();

                await _signalRService.NotifyUserActivity(
                    HttpContext.Session.GetString("AdminEmail") ?? "",
                    "Admin",
                    "Student Deleted",
                    $"Student {student.FullName} deleted from {deptCode}"
                );

                return Json(new { success = true, message = "Student deleted successfully" });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = $"Error deleting student: {ex.Message}" });
            }
        }

        /// <summary>
        /// Download Excel template for bulk student upload (Dynamic Department)
        /// </summary>
        [HttpGet]
        public IActionResult DownloadDynamicStudentTemplate(string department)
        {
            var adminId = HttpContext.Session.GetInt32("AdminId");
            if (adminId == null)
                return RedirectToAction("Login");

            var deptCode = GetDepartmentFromRequest(department);
            if (string.IsNullOrEmpty(deptCode))
            {
                TempData["ErrorMessage"] = "Department not specified.";
                return RedirectToAction("DynamicDashboard", new { department });
            }

            try
            {
                OfficeOpenXml.ExcelPackage.LicenseContext = OfficeOpenXml.LicenseContext.NonCommercial;

                using (var package = new OfficeOpenXml.ExcelPackage())
                {
                    var worksheet = package.Workbook.Worksheets.Add("Students Template");

                    // Set header style
                    var headerCells = worksheet.Cells["A1:G1"];
                    headerCells.Style.Font.Bold = true;
                    headerCells.Style.Fill.PatternType = OfficeOpenXml.Style.ExcelFillStyle.Solid;
                    headerCells.Style.Fill.BackgroundColor.SetColor(System.Drawing.Color.FromArgb(52, 152, 219));
                    headerCells.Style.Font.Color.SetColor(System.Drawing.Color.White);
                    headerCells.Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;

                    // Add headers
                    worksheet.Cells[1, 1].Value = "StudentID";
                    worksheet.Cells[1, 2].Value = "FullName";
                    worksheet.Cells[1, 3].Value = "Email";
                    worksheet.Cells[1, 4].Value = "DepartmentCode";
                    worksheet.Cells[1, 5].Value = "Year";
                    worksheet.Cells[1, 6].Value = "Semester";
                    worksheet.Cells[1, 7].Value = "Password";

                    // Add sample data with department code
                    worksheet.Cells[2, 1].Value = "23091A0001";
                    worksheet.Cells[2, 2].Value = "John Doe";
                    worksheet.Cells[2, 3].Value = "john.doe@example.com";
                    worksheet.Cells[2, 4].Value = deptCode.ToUpper();
                    worksheet.Cells[2, 5].Value = "2";
                    worksheet.Cells[2, 6].Value = "I";
                    worksheet.Cells[2, 7].Value = "Password123";

                    // Add instructions specific to department
                    worksheet.Cells[4, 1].Value = "Instructions:";
                    worksheet.Cells[4, 1].Style.Font.Bold = true;
                    worksheet.Cells[5, 1].Value = "1. StudentID must be unique (e.g., 23091A0001)";
                    worksheet.Cells[6, 1].Value = $"2. DepartmentCode should be '{deptCode.ToUpper()}' (your department)";
                    worksheet.Cells[7, 1].Value = "3. Year should be 1, 2, 3, or 4";
                    worksheet.Cells[8, 1].Value = "4. Semester should be I or II (or 1 or 2)";
                    worksheet.Cells[9, 1].Value = "5. Password is optional (default: rgmcet123 if blank)";
                    worksheet.Cells[10, 1].Value = "6. Delete this sample row and instructions before uploading";

                    // Auto-fit columns
                    worksheet.Cells[worksheet.Dimension.Address].AutoFitColumns();

                    var stream = new System.IO.MemoryStream();
                    package.SaveAs(stream);
                    stream.Position = 0;

                    var fileName = $"{deptCode}_Students_Template_{DateTime.Now:yyyyMMdd_HHmmss}.xlsx";
                    return File(stream, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", fileName);
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error generating template: {ex.Message}");
                TempData["ErrorMessage"] = $"Error generating template: {ex.Message}";
                return RedirectToAction("ManageDynamicStudents", new { department });
            }
        }

        /// <summary>
        /// Bulk upload students from Excel file (Dynamic Department)
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> BulkUploadDynamicStudents(IFormFile excelFile, string department)
        {
            var adminId = HttpContext.Session.GetInt32("AdminId");
            if (adminId == null)
                return RedirectToAction("Login");

            var deptCode = GetDepartmentFromRequest(department);
            if (string.IsNullOrEmpty(deptCode))
            {
                TempData["ErrorMessage"] = "Department not specified.";
                return RedirectToAction("DynamicDashboard", new { department });
            }

            if (excelFile == null || excelFile.Length == 0)
            {
                TempData["ErrorMessage"] = "Please select an Excel file to upload.";
                return RedirectToAction("ManageDynamicStudents", new { department });
            }

            if (!excelFile.FileName.EndsWith(".xlsx", StringComparison.OrdinalIgnoreCase))
            {
                TempData["ErrorMessage"] = "Only .xlsx files are supported.";
                return RedirectToAction("ManageDynamicStudents", new { department });
            }

            try
            {
                OfficeOpenXml.ExcelPackage.LicenseContext = OfficeOpenXml.LicenseContext.NonCommercial;

                var normalizedDept = DepartmentNormalizer.Normalize(deptCode);
                var successCount = 0;
                var errorCount = 0;
                var errors = new List<string>();

                using (var stream = new System.IO.MemoryStream())
                {
                    await excelFile.CopyToAsync(stream);
                    using (var package = new OfficeOpenXml.ExcelPackage(stream))
                    {
                        var worksheet = package.Workbook.Worksheets[0];
                        var rowCount = worksheet.Dimension?.Rows ?? 0;

                        if (rowCount < 2)
                        {
                            TempData["ErrorMessage"] = "The Excel file is empty or has no data rows.";
                            return RedirectToAction("ManageDynamicStudents", new { department });
                        }

                        // Start from row 2 (skip header)
                        for (int row = 2; row <= rowCount; row++)
                        {
                            try
                            {
                                // Read data from Excel
                                var studentId = worksheet.Cells[row, 1].Value?.ToString()?.Trim();
                                var fullName = worksheet.Cells[row, 2].Value?.ToString()?.Trim();
                                var email = worksheet.Cells[row, 3].Value?.ToString()?.Trim();
                                var deptCodeFromExcel = worksheet.Cells[row, 4].Value?.ToString()?.Trim();
                                var yearStr = worksheet.Cells[row, 5].Value?.ToString()?.Trim();
                                var semesterStr = worksheet.Cells[row, 6].Value?.ToString()?.Trim();
                                var password = worksheet.Cells[row, 7].Value?.ToString()?.Trim();

                                // Validate required fields
                                if (string.IsNullOrWhiteSpace(studentId) ||
                                    string.IsNullOrWhiteSpace(fullName) ||
                                    string.IsNullOrWhiteSpace(email) ||
                                    string.IsNullOrWhiteSpace(deptCodeFromExcel) ||
                                    string.IsNullOrWhiteSpace(yearStr))
                                {
                                    errors.Add($"Row {row}: Missing required fields");
                                    errorCount++;
                                    continue;
                                }

                                // Validate department code matches admin's department
                                var normalizedExcelDept = DepartmentNormalizer.Normalize(deptCodeFromExcel);
                                if (normalizedExcelDept != normalizedDept)
                                {
                                    errors.Add($"Row {row}: Department code mismatch (expected {deptCode}, got {deptCodeFromExcel})");
                                    errorCount++;
                                    continue;
                                }

                                // Check if student already exists
                                var existingStudent = await _context.Students
                                    .FirstOrDefaultAsync(s => s.Id == studentId || s.RegdNumber == studentId);

                                if (existingStudent != null)
                                {
                                    errors.Add($"Row {row}: Student ID {studentId} already exists");
                                    errorCount++;
                                    continue;
                                }

                                // Parse year
                                if (!int.TryParse(yearStr, out int year) || year < 1 || year > 4)
                                {
                                    errors.Add($"Row {row}: Invalid Year value (must be 1-4)");
                                    errorCount++;
                                    continue;
                                }

                                // Parse semester (optional, default to I)
                                var semester = "I";
                                if (!string.IsNullOrWhiteSpace(semesterStr))
                                {
                                    var semesterUpper = semesterStr.ToUpper().Trim();
                                    if (semesterUpper == "I" || semesterUpper == "1")
                                    {
                                        semester = "I";
                                    }
                                    else if (semesterUpper == "II" || semesterUpper == "2")
                                    {
                                        semester = "II";
                                    }
                                    else
                                    {
                                        errors.Add($"Row {row}: Invalid Semester value (must be I, II, 1, or 2)");
                                        errorCount++;
                                        continue;
                                    }
                                }

                                // Create student
                                var student = new Student
                                {
                                    Id = studentId,
                                    RegdNumber = studentId,
                                    FullName = fullName,
                                    Email = email,
                                    Password = string.IsNullOrWhiteSpace(password) ? "rgmcet123" : password,
                                    Department = normalizedDept,
                                    Year = year.ToString(),
                                    Semester = semester,
                                    SelectedSubject = ""
                                };

                                _context.Students.Add(student);
                                successCount++;
                            }
                            catch (Exception ex)
                            {
                                errors.Add($"Row {row}: {ex.Message}");
                                errorCount++;
                            }
                        }

                        // Save all students
                        if (successCount > 0)
                        {
                            await _context.SaveChangesAsync();

                            await _signalRService.NotifyUserActivity(
                                HttpContext.Session.GetString("AdminEmail") ?? "",
                                "Admin",
                                "Bulk Upload",
                                $"{successCount} students uploaded to {deptCode}"
                            );
                        }
                    }
                }

                // Prepare result message
                var resultMessage = $"Upload completed: {successCount} students added successfully";
                if (errorCount > 0)
                {
                    resultMessage += $", {errorCount} errors occurred";
                    if (errors.Count > 0)
                    {
                        // Show ALL errors, not just first 5
                        var errorDetails = string.Join("; ", errors);
                        TempData["ErrorDetails"] = errorDetails;
                    }
                }

                if (successCount > 0)
                    TempData["SuccessMessage"] = resultMessage;
                else
                    TempData["ErrorMessage"] = "No students were added. " + resultMessage;

                return RedirectToAction("ManageDynamicStudents", new { department });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error processing Excel file: {ex.Message}");
                TempData["ErrorMessage"] = $"Error processing file: {ex.Message}";
                return RedirectToAction("ManageDynamicStudents", new { department });
            }
        }

        /// <summary>
        /// Download Excel template for bulk faculty upload (Dynamic Department)
        /// </summary>
        [HttpGet]
        public IActionResult DownloadDynamicFacultyTemplate(string department)
        {
            var adminId = HttpContext.Session.GetInt32("AdminId");
            if (adminId == null)
                return RedirectToAction("Login");

            var deptCode = GetDepartmentFromRequest(department);
            if (string.IsNullOrEmpty(deptCode))
            {
                TempData["ErrorMessage"] = "Department not specified.";
                return RedirectToAction("DynamicDashboard", new { department });
            }

            try
            {
                OfficeOpenXml.ExcelPackage.LicenseContext = OfficeOpenXml.LicenseContext.NonCommercial;

                using (var package = new OfficeOpenXml.ExcelPackage())
                {
                    var worksheet = package.Workbook.Worksheets.Add("Faculty Template");

                    // Set header style
                    var headerCells = worksheet.Cells["A1:D1"];
                    headerCells.Style.Font.Bold = true;
                    headerCells.Style.Fill.PatternType = OfficeOpenXml.Style.ExcelFillStyle.Solid;
                    headerCells.Style.Fill.BackgroundColor.SetColor(System.Drawing.Color.FromArgb(52, 152, 219));
                    headerCells.Style.Font.Color.SetColor(System.Drawing.Color.White);
                    headerCells.Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;

                    // Add headers
                    worksheet.Cells[1, 1].Value = "FacultyName";
                    worksheet.Cells[1, 2].Value = "Email";
                    worksheet.Cells[1, 3].Value = "DepartmentCode";
                    worksheet.Cells[1, 4].Value = "Password";

                    // Add sample data with department code
                    worksheet.Cells[2, 1].Value = "Dr. John Doe";
                    worksheet.Cells[2, 2].Value = "john.doe@rgmcet.edu.in";
                    worksheet.Cells[2, 3].Value = deptCode.ToUpper();
                    worksheet.Cells[2, 4].Value = "Faculty@123";

                    // Add instructions specific to department
                    worksheet.Cells[4, 1].Value = "Instructions:";
                    worksheet.Cells[4, 1].Style.Font.Bold = true;
                    worksheet.Cells[5, 1].Value = "1. FacultyName is required (e.g., Dr. John Doe)";
                    worksheet.Cells[6, 1].Value = "2. Email must be unique and valid";
                    worksheet.Cells[7, 1].Value = $"3. DepartmentCode should be '{deptCode.ToUpper()}' (your department)";
                    worksheet.Cells[8, 1].Value = "4. Password is optional (default: rgmcet123 if blank)";
                    worksheet.Cells[9, 1].Value = "5. Delete this sample row and instructions before uploading";

                    // Auto-fit columns
                    worksheet.Cells[worksheet.Dimension.Address].AutoFitColumns();

                    var stream = new System.IO.MemoryStream();
                    package.SaveAs(stream);
                    stream.Position = 0;

                    var fileName = $"{deptCode}_Faculty_Template_{DateTime.Now:yyyyMMdd_HHmmss}.xlsx";
                    return File(stream, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", fileName);
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error generating faculty template: {ex.Message}");
                TempData["ErrorMessage"] = $"Error generating template: {ex.Message}";
                return RedirectToAction("ManageDynamicFaculty", new { department });
            }
        }

        /// <summary>
        /// Bulk upload faculty from Excel file (Dynamic Department)
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> BulkUploadDynamicFaculty(IFormFile excelFile, string department)
        {
            var adminId = HttpContext.Session.GetInt32("AdminId");
            if (adminId == null)
                return RedirectToAction("Login");

            var deptCode = GetDepartmentFromRequest(department);
            if (string.IsNullOrEmpty(deptCode))
            {
                TempData["ErrorMessage"] = "Department not specified.";
                return RedirectToAction("DynamicDashboard", new { department });
            }

            if (excelFile == null || excelFile.Length == 0)
            {
                TempData["ErrorMessage"] = "Please select an Excel file to upload.";
                return RedirectToAction("ManageDynamicFaculty", new { department });
            }

            if (!excelFile.FileName.EndsWith(".xlsx", StringComparison.OrdinalIgnoreCase))
            {
                TempData["ErrorMessage"] = "Only .xlsx files are supported.";
                return RedirectToAction("ManageDynamicFaculty", new { department });
            }

            try
            {
                OfficeOpenXml.ExcelPackage.LicenseContext = OfficeOpenXml.LicenseContext.NonCommercial;

                var normalizedDept = DepartmentNormalizer.Normalize(deptCode);
                var successCount = 0;
                var errorCount = 0;
                var errors = new List<string>();

                using (var stream = new System.IO.MemoryStream())
                {
                    await excelFile.CopyToAsync(stream);
                    using (var package = new OfficeOpenXml.ExcelPackage(stream))
                    {
                        var worksheet = package.Workbook.Worksheets[0];
                        var rowCount = worksheet.Dimension?.Rows ?? 0;

                        if (rowCount < 2)
                        {
                            TempData["ErrorMessage"] = "The Excel file is empty or has no data rows.";
                            return RedirectToAction("ManageDynamicFaculty", new { department });
                        }

                        // Start from row 2 (skip header)
                        for (int row = 2; row <= rowCount; row++)
                        {
                            try
                            {
                                // Read data from Excel
                                var facultyName = worksheet.Cells[row, 1].Value?.ToString()?.Trim();
                                var email = worksheet.Cells[row, 2].Value?.ToString()?.Trim();
                                var deptCodeFromExcel = worksheet.Cells[row, 3].Value?.ToString()?.Trim();
                                var password = worksheet.Cells[row, 4].Value?.ToString()?.Trim();

                                // Validate required fields
                                if (string.IsNullOrWhiteSpace(facultyName) ||
                                    string.IsNullOrWhiteSpace(email) ||
                                    string.IsNullOrWhiteSpace(deptCodeFromExcel))
                                {
                                    errors.Add($"Row {row}: Missing required fields");
                                    errorCount++;
                                    continue;
                                }

                                // Validate department code matches admin's department
                                var normalizedExcelDept = DepartmentNormalizer.Normalize(deptCodeFromExcel);
                                if (normalizedExcelDept != normalizedDept)
                                {
                                    errors.Add($"Row {row}: Department code mismatch (expected {deptCode}, got {deptCodeFromExcel})");
                                    errorCount++;
                                    continue;
                                }

                                // Check if faculty with this email already exists
                                var existingFaculty = await _context.Faculties
                                    .FirstOrDefaultAsync(f => f.Email == email);

                                if (existingFaculty != null)
                                {
                                    errors.Add($"Row {row}: Faculty with email {email} already exists");
                                    errorCount++;
                                    continue;
                                }

                                // Create faculty
                                var faculty = new Faculty
                                {
                                    Name = facultyName,
                                    Email = email,
                                    Password = string.IsNullOrWhiteSpace(password) ? "rgmcet123" : password,
                                    Department = normalizedDept
                                };

                                _context.Faculties.Add(faculty);
                                successCount++;
                            }
                            catch (Exception ex)
                            {
                                errors.Add($"Row {row}: {ex.Message}");
                                errorCount++;
                            }
                        }

                        // Save all faculty
                        if (successCount > 0)
                        {
                            await _context.SaveChangesAsync();

                            await _signalRService.NotifyUserActivity(
                                HttpContext.Session.GetString("AdminEmail") ?? "",
                                "Admin",
                                "Bulk Upload",
                                $"{successCount} faculty members uploaded to {deptCode}"
                            );
                        }
                    }
                }

                // Prepare result message
                var resultMessage = $"Upload completed: {successCount} faculty members added successfully";
                if (errorCount > 0)
                {
                    resultMessage += $", {errorCount} errors occurred";
                    if (errors.Count > 0)
                    {
                        // Show ALL errors, not just first 5
                        var errorDetails = string.Join("; ", errors);
                        TempData["ErrorDetails"] = errorDetails;
                    }
                }

                if (successCount > 0)
                    TempData["SuccessMessage"] = resultMessage;
                else
                    TempData["ErrorMessage"] = "No faculty members were added. " + resultMessage;

                return RedirectToAction("ManageDynamicFaculty", new { department });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error processing Excel file: {ex.Message}");
                TempData["ErrorMessage"] = $"Error processing file: {ex.Message}";
                return RedirectToAction("ManageDynamicFaculty", new { department });
            }
        }

        #endregion

        #region Dynamic Schedule Management

        /// <summary>
        /// Manage Faculty Selection Schedule for any department - View action
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> ManageDynamicSchedule(string department)
        {
            var adminId = HttpContext.Session.GetInt32("AdminId");
            if (adminId == null)
            {
                TempData["ErrorMessage"] = "Please login to access schedule management.";
                return RedirectToAction("Login");
            }

            var deptCode = GetDepartmentFromRequest(department);
            if (string.IsNullOrEmpty(deptCode))
            {
                TempData["ErrorMessage"] = "Department not specified.";
                return RedirectToAction("Dashboard");
            }

            var normalizedDept = DepartmentNormalizer.Normalize(deptCode);

            // Get or create schedule for this department
            var schedule = await _context.FacultySelectionSchedules
                .FirstOrDefaultAsync(fs => fs.Department == deptCode || fs.Department == normalizedDept);

            if (schedule == null)
            {
                schedule = new FacultySelectionSchedule
                {
                    Department = normalizedDept,
                    IsEnabled = false,
                    UseSchedule = false,
                    StartDateTime = DateTime.Now.AddDays(7),
                    EndDateTime = DateTime.Now.AddDays(30),
                    DisabledMessage = $"Faculty selection for {deptCode} is currently disabled.",
                    CreatedAt = DateTime.Now
                };
                _context.FacultySelectionSchedules.Add(schedule);
                await _context.SaveChangesAsync();
            }

            // Count affected students
            var affectedStudentsCount = await _context.Students
                .Where(s => s.Department == normalizedDept)
                .CountAsync();

            var viewModel = new FacultySelectionScheduleViewModel
            {
                ScheduleId = schedule.ScheduleId,
                Department = deptCode,
                IsEnabled = schedule.IsEnabled,
                UseSchedule = schedule.UseSchedule,
                StartDateTime = schedule.StartDateTime,
                EndDateTime = schedule.EndDateTime,
                DisabledMessage = schedule.DisabledMessage,
                AffectedStudents = affectedStudentsCount,
                AffectedSubjects = 0,  // Can be populated if needed
                TotalEnrollments = 0,  // Can be populated if needed
                IsCurrentlyAvailable = schedule.IsCurrentlyAvailable,
                StatusDescription = schedule.StatusDescription,
                UpdatedAt = schedule.UpdatedAt,
                UpdatedBy = schedule.UpdatedBy
            };

            // Get department name
            var dept = await _context.Departments.FirstOrDefaultAsync(d => d.DepartmentCode == deptCode);
            ViewBag.DepartmentCode = deptCode;
            ViewBag.DepartmentName = dept?.DepartmentName ?? deptCode;

            return View("ManageDynamicSchedule_YEAR_BASED", viewModel);
        }

        /// <summary>
        /// Get year-based schedules for dynamic department (API endpoint)
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> GetDynamicYearSchedules(string department)
        {
            var adminId = HttpContext.Session.GetInt32("AdminId");
            if (adminId == null)
                return Json(new { success = false, message = "Unauthorized" });

            var deptCode = GetDepartmentFromRequest(department);
            if (string.IsNullOrEmpty(deptCode))
                return Json(new { success = false, message = "Department not specified" });

            try
            {
                var normalizedDept = DepartmentNormalizer.Normalize(deptCode);

                // Get year-based schedules for this department
                var schedules = await _context.FacultySelectionSchedules
                    .Where(fs => fs.Department == normalizedDept && fs.Year != null)
                    .Select(fs => new
                    {
                        year = fs.Year,
                        isEnabled = fs.IsEnabled,
                        useSchedule = fs.UseSchedule,
                        startDateTime = fs.StartDateTime,
                        endDateTime = fs.EndDateTime
                    })
                    .ToListAsync();

                // Ensure all 4 years exist (create default if missing)
                var existingYears = schedules.Select(s => s.year).Where(y => y.HasValue).Select(y => y.Value).ToList();
                var missingYears = new[] { 1, 2, 3, 4 }.Except(existingYears).ToList();

                if (missingYears.Any())
                {
                    foreach (var year in missingYears)
                    {
                        var newSchedule = new FacultySelectionSchedule
                        {
                            Department = normalizedDept,
                            Year = year,
                            IsEnabled = false,
                            UseSchedule = false,
                            StartDateTime = DateTime.Now.AddDays(7),
                            EndDateTime = DateTime.Now.AddDays(30),
                            DisabledMessage = $"Year {year} faculty selection is currently disabled.",
                            CreatedAt = DateTime.Now
                        };
                        _context.FacultySelectionSchedules.Add(newSchedule);
                    }
                    await _context.SaveChangesAsync();

                    // Re-fetch schedules
                    schedules = await _context.FacultySelectionSchedules
                        .Where(fs => fs.Department == normalizedDept && fs.Year != null)
                        .Select(fs => new
                        {
                            year = fs.Year,
                            isEnabled = fs.IsEnabled,
                            useSchedule = fs.UseSchedule,
                            startDateTime = fs.StartDateTime,
                            endDateTime = fs.EndDateTime
                        })
                        .ToListAsync();
                }

                return Json(new { success = true, schedules });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = $"Error loading schedules: {ex.Message}" });
            }
        }

        /// <summary>
        /// Get year-specific statistics for dynamic department (API endpoint)
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> GetDynamicYearStatistics(string department, int year)
        {
            var adminId = HttpContext.Session.GetInt32("AdminId");
            if (adminId == null)
                return Json(new { success = false, message = "Unauthorized" });

            var deptCode = GetDepartmentFromRequest(department);
            if (string.IsNullOrEmpty(deptCode))
                return Json(new { success = false, message = "Department not specified" });

            try
            {
                var normalizedDept = DepartmentNormalizer.Normalize(deptCode);
                var yearString = year.ToString();

                // Count students for this year
                var studentsCount = await _context.Students
                    .Where(s => s.Department == normalizedDept && s.Year == yearString)
                    .CountAsync();

                // Count subjects for this year
                var subjectsCount = await _context.Subjects
                    .Where(s => s.Department == normalizedDept && s.Year == year)
                    .CountAsync();

                // Count enrollments for this year
                var enrollmentsCount = await _context.StudentEnrollments
                    .Include(se => se.Student)
                    .Where(se => se.Student.Department == normalizedDept && se.Student.Year == yearString)
                    .CountAsync();

                return Json(new
                {
                    success = true,
                    studentsCount,
                    subjectsCount,
                    enrollmentsCount
                });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = $"Error loading statistics: {ex.Message}" });
            }
        }

        /// <summary>
        /// Update year-specific schedule for dynamic department (API endpoint)
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> UpdateDynamicYearSchedule([FromBody] YearScheduleUpdateRequest request)
        {
            var adminId = HttpContext.Session.GetInt32("AdminId");
            var adminEmail = HttpContext.Session.GetString("AdminEmail");

            if (adminId == null)
                return Json(new { success = false, message = "Unauthorized" });

            // Get department from request body (the view sends it in the JSON)
            var deptCode = request.Department;
            if (string.IsNullOrEmpty(deptCode))
            {
                // Fallback to session if not in request
                deptCode = HttpContext.Session.GetString("AdminDepartment");
            }

            if (string.IsNullOrEmpty(deptCode))
                return Json(new { success = false, message = "Department not specified" });

            try
            {
                var normalizedDept = DepartmentNormalizer.Normalize(deptCode);

                // Find or create year-specific schedule
                var schedule = await _context.FacultySelectionSchedules
                    .FirstOrDefaultAsync(fs => fs.Department == normalizedDept && fs.Year == request.Year);

                if (schedule == null)
                {
                    schedule = new FacultySelectionSchedule
                    {
                        Department = normalizedDept,
                        Year = request.Year,
                        IsEnabled = request.IsEnabled,
                        UseSchedule = false,
                        StartDateTime = DateTime.Now.AddDays(7),
                        EndDateTime = DateTime.Now.AddDays(30),
                        DisabledMessage = $"Year {request.Year} faculty selection is currently disabled.",
                        CreatedAt = DateTime.Now,
                        UpdatedAt = DateTime.Now,
                        UpdatedBy = adminEmail ?? "Admin"
                    };
                    _context.FacultySelectionSchedules.Add(schedule);
                }
                else
                {
                    schedule.IsEnabled = request.IsEnabled;
                    schedule.UpdatedAt = DateTime.Now;
                    schedule.UpdatedBy = adminEmail ?? "Admin";
                }

                await _context.SaveChangesAsync();

                await _signalRService.NotifyUserActivity(
                    adminEmail ?? "",
                    "Admin",
                    "Schedule Updated",
                    $"Year {request.Year} faculty selection {(request.IsEnabled ? "ENABLED" : "DISABLED")} for {deptCode}"
                );

                return Json(new
                {
                    success = true,
                    message = $"Year {request.Year} faculty selection {(request.IsEnabled ? "enabled" : "disabled")} successfully"
                });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = $"Error updating schedule: {ex.Message}" });
            }
        }

        #endregion

        #region Dynamic Reports and Analytics

        /// <summary>
        /// Dynamic Reports & Analytics page for any department
        /// Shows enrollment data, statistics, and allows exporting
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> DynamicReports(string department)
        {
            var adminId = HttpContext.Session.GetInt32("AdminId");
            var adminDepartment = HttpContext.Session.GetString("AdminDepartment");

            if (adminId == null)
            {
                TempData["ErrorMessage"] = "Please login to access reports.";
                return RedirectToAction("Login");
            }

            var deptCode = GetDepartmentFromRequest(department);
            if (string.IsNullOrEmpty(deptCode))
            {
                TempData["ErrorMessage"] = "Department not specified.";
                return RedirectToAction("Dashboard");
            }

            var normalizedDept = DepartmentNormalizer.Normalize(deptCode);

            // Get data for report filters
            var viewModel = new CSEDSReportsViewModel
            {
                AvailableYears = await _context.Subjects
                    .Where(s => s.Department == normalizedDept)
                    .Select(s => s.Year)
                    .Distinct()
                    .OrderBy(y => y)
                    .ToListAsync(),

                AvailableSemesters = new List<SemesterOption>
                {
                    new SemesterOption { Value = "I", Text = "Semester I (1)", NumericValue = 1 },
                    new SemesterOption { Value = "II", Text = "Semester II (2)", NumericValue = 2 }
                },

                AvailableSubjects = await _context.Subjects
                    .Where(s => s.Department == normalizedDept)
                    .OrderBy(s => s.Year)
                    .ThenBy(s => s.Name)
                    .ToListAsync(),

                AvailableFaculty = await _context.Faculties
                    .Where(f => f.Department == normalizedDept)
                    .OrderBy(f => f.Name)
                    .ToListAsync()
            };

            // Get department name for display
            var dept = await _context.Departments.FirstOrDefaultAsync(d => d.DepartmentCode == deptCode);
            ViewBag.DepartmentCode = deptCode;
            ViewBag.DepartmentName = dept?.DepartmentName ?? deptCode;

            return View(viewModel);
        }

        /// <summary>
        /// Generate report data for dynamic department
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> GenerateDynamicReport([FromBody] CSEDSReportsViewModel filters, string department)
        {
            var adminId = HttpContext.Session.GetInt32("AdminId");
            if (adminId == null)
            {
                return Json(new { success = false, message = "Session expired. Please log in again.", unauthorized = true });
            }

            var deptCode = GetDepartmentFromRequest(department);
            if (string.IsNullOrEmpty(deptCode))
            {
                return Json(new { success = false, message = "Department not specified", unauthorized = true });
            }

            try
            {
                var normalizedDept = DepartmentNormalizer.Normalize(deptCode);

                // Start with base query for department enrollments
                var query = _context.StudentEnrollments
                    .Include(se => se.Student)
                    .Include(se => se.AssignedSubject)
                        .ThenInclude(a => a.Subject)
                    .Include(se => se.AssignedSubject)
                        .ThenInclude(a => a.Faculty)
                    .Where(se => se.Student.Department == normalizedDept);

                // Apply filters
                if (filters.SelectedSubjectId.HasValue)
                    query = query.Where(se => se.AssignedSubject.SubjectId == filters.SelectedSubjectId.Value);

                if (filters.SelectedFacultyId.HasValue)
                    query = query.Where(se => se.AssignedSubject.FacultyId == filters.SelectedFacultyId.Value);

                if (filters.SelectedYear.HasValue)
                    query = query.Where(se => se.AssignedSubject.Subject.Year == filters.SelectedYear.Value);

                if (!string.IsNullOrEmpty(filters.SelectedSemester))
                    query = query.Where(se => se.AssignedSubject.Subject.Semester == filters.SelectedSemester);

                var reportData = await query
                    .OrderBy(se => se.Student.FullName)
                    .ThenBy(se => se.AssignedSubject.Subject.Name)
                    .Select(se => new StudentEnrollmentReportItem
                    {
                        StudentName = se.Student.FullName,
                        StudentRegdNumber = se.Student.RegdNumber,
                        StudentEmail = se.Student.Email,
                        StudentYear = se.Student.Year,
                        SubjectName = se.AssignedSubject.Subject.Name,
                        SubjectYear = se.AssignedSubject.Subject.Year.ToString(),
                        Semester = se.AssignedSubject.Subject.Semester ?? "",
                        FacultyName = se.AssignedSubject.Faculty.Name,
                        FacultyEmail = se.AssignedSubject.Faculty.Email,
                        EnrolledAt = se.EnrolledAt,
                        EnrolledAtFormatted = se.EnrolledAt.ToString("MM/dd/yyyy hh:mm:ss tt")
                    })
                    .ToListAsync();

                return Json(new { success = true, data = reportData, count = reportData.Count });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Report generation error: {ex}");
                return Json(new { success = false, message = $"Error generating report: {ex.Message}" });
            }
        }

        #endregion

        #region Dynamic Helper Methods

        /// <summary>
        /// Get faculty with their assignments for dynamic department
        /// </summary>
        private async Task<List<FacultyDetailDto>> GetDynamicFacultyWithAssignments(string normalizedDept)
        {
            var faculty = await _context.Faculties
                .Where(f => f.Department == normalizedDept)
                .ToListAsync();

            var result = new List<FacultyDetailDto>();

            foreach (var f in faculty)
            {
                var assignedSubjects = await _context.AssignedSubjects
                    .Include(a => a.Subject)
                    .Where(a => a.FacultyId == f.FacultyId && a.Subject.Department == normalizedDept)
                    .ToListAsync();

                var enrollmentCount = 0;
                var subjectInfos = new List<AssignedSubjectInfo>();

                foreach (var assignment in assignedSubjects)
                {
                    var enrollments = await _context.StudentEnrollments
                        .CountAsync(se => se.AssignedSubjectId == assignment.AssignedSubjectId);

                    enrollmentCount += enrollments;

                    subjectInfos.Add(new AssignedSubjectInfo
                    {
                        AssignedSubjectId = assignment.AssignedSubjectId,
                        SubjectId = assignment.SubjectId,
                        SubjectName = assignment.Subject.Name,
                        Year = assignment.Subject.Year,
                        Semester = assignment.Subject.Semester ?? "",
                        EnrollmentCount = enrollments
                    });
                }

                result.Add(new FacultyDetailDto
                {
                    FacultyId = f.FacultyId,
                    Name = f.Name,
                    Email = f.Email,
                    Department = f.Department,
                    AssignedSubjects = subjectInfos,
                    TotalEnrollments = enrollmentCount
                });
            }

            return result.OrderBy(f => f.Name).ToList();
        }

        /// <summary>
        /// Get subject-faculty mappings for dynamic department
        /// </summary>
        private async Task<List<SubjectFacultyMappingDto>> GetDynamicSubjectFacultyMappings(string normalizedDept)
        {
            var subjects = await _context.Subjects
                .Where(s => s.Department == normalizedDept)
                .ToListAsync();

            var result = new List<SubjectFacultyMappingDto>();

            foreach (var s in subjects)
            {
                var assignedFaculty = await _context.AssignedSubjects
                    .Include(a => a.Faculty)
                    .Where(a => a.SubjectId == s.SubjectId && a.Faculty.Department == normalizedDept)
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

        #endregion
    }

    #region Dynamic Department DTOs (moved to end)

    /// <summary>
    /// Data Transfer Object for student enrollment report
    /// </summary>
    public class StudentEnrollmentReportItem
    {
        public string StudentName { get; set; }
        public string StudentRegdNumber { get; set; }
        public string StudentEmail { get; set; }
        public string StudentYear { get; set; }
        public string SubjectName { get; set; }
        public string SubjectYear { get; set; }
        public string Semester { get; set; }
        public string FacultyName { get; set; }
        public string FacultyEmail { get; set; }
        public DateTime EnrolledAt { get; set; }
        public string EnrolledAtFormatted { get; set; }
    }

    #endregion
}
