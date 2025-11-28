using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TutorLiveMentor.Models;
using TutorLiveMentor.Services;

namespace TutorLiveMentor.Controllers
{
    /// <summary>
    /// Partial class extension for AdminController with missing action methods
    /// </summary>
    public partial class AdminController
    {
        /// <summary>
        /// CSEDS Reports page
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> CSEDSReports()
        {
            var adminId = HttpContext.Session.GetInt32("AdminId");
            var department = HttpContext.Session.GetString("AdminDepartment");

            if (adminId == null)
            {
                TempData["ErrorMessage"] = "Please login to access the reports.";
                return RedirectToAction("Login");
            }

            if (!IsCSEDSDepartment(department))
            {
                TempData["ErrorMessage"] = "Access denied. CSEDS department access only.";
                return RedirectToAction("Login");
            }

            // Get data for report filters
            var viewModel = new CSEDSReportsViewModel
            {
                AvailableYears = await _context.Subjects
                    .Where(s => s.Department == "CSEDS" || s.Department == "CSE(DS)")
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
                    .Where(s => s.Department == "CSEDS" || s.Department == "CSE(DS)")
                    .OrderBy(s => s.Year)
                    .ThenBy(s => s.Name)
                    .ToListAsync()
            };

            return View(viewModel);
        }

        /// <summary>
        /// Manage CSEDS Students page
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> ManageCSEDSStudents()
        {
            var adminId = HttpContext.Session.GetInt32("AdminId");
            var department = HttpContext.Session.GetString("AdminDepartment");

            if (adminId == null)
            {
                TempData["ErrorMessage"] = "Please login to access student management.";
                return RedirectToAction("Login");
            }

            if (!IsCSEDSDepartment(department))
            {
                TempData["ErrorMessage"] = "Access denied. CSEDS department access only.";
                return RedirectToAction("Login");
            }

            // Get all CSEDS students with their enrollments
            var students = await _context.Students
                .Where(s => s.Department == "CSEDS" || s.Department == "CSE(DS)")
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
                    Department = student.Department,
                    TotalEnrollments = enrollments.Count,
                    EnrolledSubjects = enrolledSubjects
                });
            }

            var viewModel = new StudentManagementViewModel
            {
                DepartmentStudents = studentDetails,
                AvailableYears = new List<int> { 1, 2, 3, 4 },
                AvailableSemesters = new List<SemesterOption>
                {
                    new SemesterOption { Value = "I", Text = "Semester I (1)", NumericValue = 1 },
                    new SemesterOption { Value = "II", Text = "Semester II (2)", NumericValue = 2 }
                }
            };

            return View(viewModel);
        }

        /// <summary>
        /// Filter students based on criteria
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> GetFilteredStudents([FromBody] StudentFilterRequest filters)
        {
            var department = HttpContext.Session.GetString("AdminDepartment");
            if (!IsCSEDSDepartment(department))
                return Unauthorized();

            try
            {
                var query = _context.Students
                    .Where(s => s.Department == "CSEDS" || s.Department == "CSE(DS)")
                    .AsQueryable();

                // Apply search filter
                if (!string.IsNullOrEmpty(filters.SearchText))
                {
                    var searchLower = filters.SearchText.ToLower();
                    query = query.Where(s => 
                        s.FullName.ToLower().Contains(searchLower) ||
                        s.Email.ToLower().Contains(searchLower) ||
                        s.RegdNumber.ToLower().Contains(searchLower));
                }

                // Apply year filter
                if (!string.IsNullOrEmpty(filters.Year))
                {
                    query = query.Where(s => s.Year == filters.Year);
                }

                var students = await query.ToListAsync();
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

                    // Apply semester filter if needed
                    if (!string.IsNullOrEmpty(filters.Semester))
                    {
                        enrollments = enrollments
                            .Where(e => e.AssignedSubject.Subject.Semester == filters.Semester)
                            .ToList();
                    }

                    // Apply enrollment filter
                    if (filters.HasEnrollments.HasValue)
                    {
                        bool hasEnrollments = enrollments.Any();
                        if (filters.HasEnrollments.Value != hasEnrollments)
                            continue;
                    }

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
                        Department = student.Department,
                        TotalEnrollments = enrollments.Count,
                        EnrolledSubjects = enrolledSubjects
                    });
                }

                return Json(new { success = true, data = studentDetails });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = $"Error filtering students: {ex.Message}" });
            }
        }

        /// <summary>
        /// Delete CSEDS student
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> DeleteCSEDSStudent(string id)
        {
            var department = HttpContext.Session.GetString("AdminDepartment");
            if (!IsCSEDSDepartment(department))
                return Json(new { success = false, message = "Unauthorized access" });

            try
            {
                var student = await _context.Students
                    .FirstOrDefaultAsync(s => s.Id == id && 
                                            (s.Department == "CSEDS" || s.Department == "CSE(DS)"));

                if (student == null)
                    return Json(new { success = false, message = "Student not found" });

                // Delete enrollments first
                var enrollments = await _context.StudentEnrollments
                    .Where(se => se.StudentId == id)
                    .ToListAsync();

                if (enrollments.Any())
                {
                    _context.StudentEnrollments.RemoveRange(enrollments);
                }

                // Delete student
                _context.Students.Remove(student);
                await _context.SaveChangesAsync();

                await _signalRService.NotifyUserActivity(
                    HttpContext.Session.GetString("AdminEmail") ?? "",
                    "Admin",
                    "Student Deleted",
                    $"CSEDS student {student.FullName} has been deleted"
                );

                return Json(new { success = true, message = "Student deleted successfully" });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error deleting student: {ex.Message}");
                return Json(new { success = false, message = $"Error deleting student: {ex.Message}" });
            }
        }

        /// <summary>
        /// Add CSEDS student page
        /// </summary>
        [HttpGet]
        public IActionResult AddCSEDSStudent()
        {
            var department = HttpContext.Session.GetString("AdminDepartment");
            if (!IsCSEDSDepartment(department))
                return RedirectToAction("Login");

            var viewModel = new CSEDSStudentViewModel
            {
                Department = "CSEDS",
                IsEdit = false,
                AvailableYears = new List<string> { "I Year", "II Year", "III Year", "IV Year" }
            };

            return View(viewModel);
        }

        /// <summary>
        /// Add CSEDS student POST action
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> AddCSEDSStudent(CSEDSStudentViewModel model)
        {
            var department = HttpContext.Session.GetString("AdminDepartment");
            if (!IsCSEDSDepartment(department))
                return RedirectToAction("Login");

            // Validate model
            if (!ModelState.IsValid)
            {
                model.AvailableYears = new List<string> { "I Year", "II Year", "III Year", "IV Year" };
                return View(model);
            }

            try
            {
                // Check if student with this registration number already exists
                var existingStudent = await _context.Students
                    .FirstOrDefaultAsync(s => s.RegdNumber == model.RegdNumber);

                if (existingStudent != null)
                {
                    ModelState.AddModelError("RegdNumber", "A student with this registration number already exists");
                    model.AvailableYears = new List<string> { "I Year", "II Year", "III Year", "IV Year" };
                    return View(model);
                }

                // Check if email is already used
                var existingEmail = await _context.Students
                    .FirstOrDefaultAsync(s => s.Email == model.Email);

                if (existingEmail != null)
                {
                    ModelState.AddModelError("Email", "This email is already registered");
                    model.AvailableYears = new List<string> { "I Year", "II Year", "III Year", "IV Year" };
                    return View(model);
                }

                // Create new student
                var student = new Student
                {
                    Id = model.RegdNumber, // Use RegdNumber as ID
                    FullName = model.FullName,
                    RegdNumber = model.RegdNumber,
                    Email = model.Email,
                    Password = string.IsNullOrWhiteSpace(model.Password) ? "TutorLive123" : model.Password,
                    Year = model.Year,
                    Department = "CSEDS",
                    SelectedSubject = ""
                };

                _context.Students.Add(student);
                await _context.SaveChangesAsync();

                await _signalRService.NotifyUserActivity(
                    HttpContext.Session.GetString("AdminEmail") ?? "",
                    "Admin",
                    "Student Added",
                    $"New CSEDS student {student.FullName} has been added to the system"
                );

                TempData["SuccessMessage"] = "Student added successfully!";
                return RedirectToAction("ManageCSEDSStudents");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error adding student: {ex.Message}");
                ModelState.AddModelError("", $"Error adding student: {ex.Message}");
                model.AvailableYears = new List<string> { "I Year", "II Year", "III Year", "IV Year" };
                return View(model);
            }
        }

        /// <summary>
        /// Edit CSEDS student page
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> EditCSEDSStudent(string id)
        {
            var department = HttpContext.Session.GetString("AdminDepartment");
            if (!IsCSEDSDepartment(department))
                return RedirectToAction("Login");

            var student = await _context.Students
                .FirstOrDefaultAsync(s => s.Id == id && 
                                        (s.Department == "CSEDS" || s.Department == "CSE(DS)"));

            if (student == null)
            {
                TempData["ErrorMessage"] = "Student not found";
                return RedirectToAction("ManageCSEDSStudents");
            }

            var viewModel = new CSEDSStudentViewModel
            {
                StudentId = student.Id,
                FullName = student.FullName,
                RegdNumber = student.RegdNumber,
                Email = student.Email,
                Year = student.Year,
                Department = student.Department,
                IsEdit = true,
                AvailableYears = new List<string> { "I Year", "II Year", "III Year", "IV Year" }
            };

            return View(viewModel);
        }

        /// <summary>
        /// Edit CSEDS student POST action
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> EditCSEDSStudent(CSEDSStudentViewModel model)
        {
            var department = HttpContext.Session.GetString("AdminDepartment");
            if (!IsCSEDSDepartment(department))
                return RedirectToAction("Login");

            // Validate model
            if (!ModelState.IsValid)
            {
                model.AvailableYears = new List<string> { "I Year", "II Year", "III Year", "IV Year" };
                return View(model);
            }

            try
            {
                var student = await _context.Students
                    .FirstOrDefaultAsync(s => s.Id == model.StudentId && 
                                            (s.Department == "CSEDS" || s.Department == "CSE(DS)"));

                if (student == null)
                {
                    TempData["ErrorMessage"] = "Student not found";
                    return RedirectToAction("ManageCSEDSStudents");
                }

                // Check if email is already used by another student
                var existingStudent = await _context.Students
                    .FirstOrDefaultAsync(s => s.Email == model.Email && s.Id != model.StudentId);

                if (existingStudent != null)
                {
                    ModelState.AddModelError("Email", "This email is already registered to another student");
                    model.AvailableYears = new List<string> { "I Year", "II Year", "III Year", "IV Year" };
                    return View(model);
                }

                // Update student information
                student.FullName = model.FullName;
                student.Email = model.Email;
                student.Year = model.Year;

                // Update password only if provided
                if (!string.IsNullOrWhiteSpace(model.Password))
                {
                    student.Password = model.Password;
                }

                await _context.SaveChangesAsync();

                await _signalRService.NotifyUserActivity(
                    HttpContext.Session.GetString("AdminEmail") ?? "",
                    "Admin",
                    "Student Updated",
                    $"CSEDS student {student.FullName} information has been updated"
                );

                TempData["SuccessMessage"] = "Student information updated successfully!";
                return RedirectToAction("ManageCSEDSStudents");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error updating student: {ex.Message}");
                ModelState.AddModelError("", $"Error updating student: {ex.Message}");
                model.AvailableYears = new List<string> { "I Year", "II Year", "III Year", "IV Year" };
                return View(model);
            }
        }

        /// <summary>
        /// Manage Faculty Selection Schedule page
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> ManageFacultySelectionSchedule()
        {
            var adminId = HttpContext.Session.GetInt32("AdminId");
            var department = HttpContext.Session.GetString("AdminDepartment");

            if (adminId == null)
            {
                TempData["ErrorMessage"] = "Please login to access schedule management.";
                return RedirectToAction("Login");
            }

            if (!IsCSEDSDepartment(department))
            {
                TempData["ErrorMessage"] = "Access denied. CSEDS department access only.";
                return RedirectToAction("Login");
            }

            // Get or create schedule for CSEDS department
            var schedule = await _context.FacultySelectionSchedules
                .FirstOrDefaultAsync(s => s.Department == "CSEDS" || s.Department == "CSE(DS)");

            if (schedule == null)
            {
                // Create default schedule
                schedule = new FacultySelectionSchedule
                {
                    Department = "CSEDS",
                    IsEnabled = true,
                    UseSchedule = false,
                    DisabledMessage = "Faculty selection is currently disabled. Please check back later.",
                    CreatedAt = DateTime.Now,
                    UpdatedAt = DateTime.Now,
                    UpdatedBy = HttpContext.Session.GetString("AdminEmail") ?? "System"
                };
                _context.FacultySelectionSchedules.Add(schedule);
                await _context.SaveChangesAsync();
            }

            // Get impact statistics
            var studentsCount = await _context.Students
                .Where(s => s.Department == "CSEDS" || s.Department == "CSE(DS)")
                .CountAsync();

            var subjectsCount = await _context.Subjects
                .Where(s => s.Department == "CSEDS" || s.Department == "CSE(DS)")
                .CountAsync();

            var enrollmentsCount = await _context.StudentEnrollments
                .Include(se => se.Student)
                .Where(se => se.Student.Department == "CSEDS" || se.Student.Department == "CSE(DS)")
                .CountAsync();

            var viewModel = new FacultySelectionScheduleViewModel
            {
                ScheduleId = schedule.ScheduleId,
                Department = schedule.Department,
                IsEnabled = schedule.IsEnabled,
                UseSchedule = schedule.UseSchedule,
                StartDateTime = schedule.StartDateTime,
                EndDateTime = schedule.EndDateTime,
                DisabledMessage = schedule.DisabledMessage,
                IsCurrentlyAvailable = schedule.IsCurrentlyAvailable,
                StatusDescription = schedule.StatusDescription,
                UpdatedAt = schedule.UpdatedAt,
                UpdatedBy = schedule.UpdatedBy,
                AffectedStudents = studentsCount,
                AffectedSubjects = subjectsCount,
                TotalEnrollments = enrollmentsCount
            };

            return View(viewModel);
        }

        /// <summary>
        /// Update faculty selection schedule
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> UpdateFacultySelectionSchedule([FromBody] FacultySelectionScheduleUpdateRequest request)
        {
            var department = HttpContext.Session.GetString("AdminDepartment");
            if (!IsCSEDSDepartment(department))
                return Json(new { success = false, message = "Unauthorized access" });

            try
            {
                var schedule = await _context.FacultySelectionSchedules
                    .FirstOrDefaultAsync(s => s.Department == "CSEDS" || s.Department == "CSE(DS)");

                if (schedule == null)
                {
                    return Json(new { success = false, message = "Schedule not found" });
                }

                // Validation
                if (request.UseSchedule && request.StartDateTime.HasValue && request.EndDateTime.HasValue)
                {
                    if (request.EndDateTime <= request.StartDateTime)
                    {
                        return Json(new { success = false, message = "End date must be after start date" });
                    }
                }

                // Update schedule
                schedule.IsEnabled = request.IsEnabled;
                schedule.UseSchedule = request.UseSchedule;
                schedule.StartDateTime = request.StartDateTime;
                schedule.EndDateTime = request.EndDateTime;
                schedule.DisabledMessage = request.DisabledMessage ?? schedule.DisabledMessage;
                schedule.UpdatedAt = DateTime.Now;
                schedule.UpdatedBy = HttpContext.Session.GetString("AdminEmail") ?? "Admin";

                await _context.SaveChangesAsync();

                await _signalRService.NotifyUserActivity(
                    HttpContext.Session.GetString("AdminEmail") ?? "",
                    "Admin",
                    "Schedule Updated",
                    $"Faculty selection schedule updated for CSEDS department"
                );

                return Json(new { success = true, message = "Schedule updated successfully" });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error updating schedule: {ex.Message}");
                return Json(new { success = false, message = $"Error updating schedule: {ex.Message}" });
            }
        }

        /// <summary>
        /// Get selection schedule status for a department
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> GetSelectionScheduleStatus(string department)
        {
            try
            {
                if (!IsCSEDSDepartment(department))
                    return Json(new { isAvailable = true, message = "Not a CSEDS department" });

                var schedule = await _context.FacultySelectionSchedules
                    .FirstOrDefaultAsync(s => s.Department == "CSEDS" || s.Department == "CSE(DS)");

                if (schedule == null)
                {
                    return Json(new { 
                        isAvailable = true, 
                        message = "Faculty selection is currently available",
                        statusDescription = "No schedule configured"
                    });
                }

                // Check if enabled
                if (!schedule.IsEnabled)
                {
                    return Json(new { 
                        isAvailable = false, 
                        message = schedule.DisabledMessage,
                        statusDescription = "Disabled by administrator"
                    });
                }

                // Check if using schedule
                if (!schedule.UseSchedule)
                {
                    return Json(new { 
                        isAvailable = true, 
                        message = "Faculty selection is currently available",
                        statusDescription = "Always Available"
                    });
                }

                // Check schedule window
                var now = DateTime.Now;
                if (schedule.StartDateTime.HasValue && schedule.EndDateTime.HasValue)
                {
                    if (now < schedule.StartDateTime.Value)
                    {
                        return Json(new { 
                            isAvailable = false, 
                            message = $"Faculty selection opens on {schedule.StartDateTime.Value:MMM dd, yyyy} at {schedule.StartDateTime.Value:hh:mm tt}",
                            statusDescription = "Not Yet Started",
                            startDateTime = schedule.StartDateTime,
                            endDateTime = schedule.EndDateTime
                        });
                    }
                    else if (now > schedule.EndDateTime.Value)
                    {
                        return Json(new { 
                            isAvailable = false, 
                            message = "Faculty selection period has ended",
                            statusDescription = "Period Ended",
                            startDateTime = schedule.StartDateTime,
                            endDateTime = schedule.EndDateTime
                        });
                    }
                    else
                    {
                        return Json(new { 
                            isAvailable = true, 
                            message = $"Faculty selection is available until {schedule.EndDateTime.Value:MMM dd, yyyy} at {schedule.EndDateTime.Value:hh:mm tt}",
                            statusDescription = "Active",
                            startDateTime = schedule.StartDateTime,
                            endDateTime = schedule.EndDateTime
                        });
                    }
                }

                return Json(new { 
                    isAvailable = true, 
                    message = "Faculty selection is currently available",
                    statusDescription = "Always Available"
                });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error checking schedule status: {ex.Message}");
                return Json(new { 
                    isAvailable = true, 
                    message = "Faculty selection is currently available"
                });
            }
        }
    }

    /// <summary>
    /// Request model for student filtering
    /// </summary>
    public class StudentFilterRequest
    {
        public string? SearchText { get; set; }
        public string? Year { get; set; }
        public string? Semester { get; set; }
        public bool? HasEnrollments { get; set; }
    }

    /// <summary>
    /// Request model for faculty selection schedule update
    /// </summary>
    public class FacultySelectionScheduleUpdateRequest
    {
        public bool IsEnabled { get; set; }
        public bool UseSchedule { get; set; }
        public DateTime? StartDateTime { get; set; }
        public DateTime? EndDateTime { get; set; }
        public string? DisabledMessage { get; set; }
    }
}
