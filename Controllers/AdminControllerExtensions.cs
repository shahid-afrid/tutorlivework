using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TutorLiveMentor.Models;
using TutorLiveMentor.Services;
using TutorLiveMentor.Helpers;
using Microsoft.AspNetCore.Antiforgery;
using OfficeOpenXml;

namespace TutorLiveMentor.Controllers
{
    /// <summary>
    /// Partial class extension for AdminController with missing action methods
    /// </summary>
    public partial class AdminController
    {
        /// <summary>
        /// CSEDS Reports page - NOW USING DYNAMIC TABLES
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

            // ? NEW: Use CSEDS-specific tables
            using var csedsContext = _dbFactory.GetContext("CSEDS");

            // Get data for report filters from CSEDS tables
            var viewModel = new CSEDSReportsViewModel
            {
                AvailableYears = await csedsContext.Subjects
                    .Select(s => s.Year)
                    .Distinct()
                    .OrderBy(y => y)
                    .ToListAsync(),

                AvailableSemesters = new List<SemesterOption>
                {
                    new SemesterOption { Value = "I", Text = "Semester I (1)", NumericValue = 1 },
                    new SemesterOption { Value = "II", Text = "Semester II (2)", NumericValue = 2 }
                },

                AvailableSubjects = await csedsContext.Subjects
                    .OrderBy(s => s.Year)
                    .ThenBy(s => s.Name)
                    .ToListAsync(),

                AvailableFaculty = await csedsContext.Faculties
                    .OrderBy(f => f.Name)
                    .ToListAsync()
            };

            return View(viewModel);
        }

        /// <summary>
        /// Manage CSEDS Students page - NOW USING DYNAMIC TABLES
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

            // ? NEW: Use CSEDS-specific tables
            using var csedsContext = _dbFactory.GetContext("CSEDS");

            // Get all CSEDS students from Students_CSEDS table
            var students = await csedsContext.Students.ToListAsync();

            var studentDetails = new List<StudentDetailDto>();

            foreach (var student in students)
            {
                // Get enrollments from StudentEnrollments_CSEDS table
                var enrollments = await csedsContext.StudentEnrollments
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
                AvailableYears = new List<string> { "II Year", "III Year", "IV Year" }
            };

            return View(viewModel);
        }

        /// <summary>
        /// Filter students based on criteria - NOW USING DYNAMIC TABLES
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> GetFilteredStudents([FromBody] StudentFilterRequest filters)
        {
            var department = HttpContext.Session.GetString("AdminDepartment");
            if (!IsCSEDSDepartment(department))
                return Unauthorized();

            try
            {
                // ? NEW: Use CSEDS-specific tables
                using var csedsContext = _dbFactory.GetContext("CSEDS");

                var query = csedsContext.Students.AsQueryable();

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
                    var enrollments = await csedsContext.StudentEnrollments
                        .Include(se => se.AssignedSubject)
                            .ThenInclude(a => a.Subject)
                        .Include(se => se.AssignedSubject)
                            .ThenInclude(a => a.Faculty)
                        .Where(se => se.StudentId == student.Id)
                        .ToListAsync();

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

                return Json(new { success = true, students = studentDetails });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error filtering students: {ex.Message}");
                return Json(new { success = false, message = "Error filtering students" });
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
                    return Json(new { success = false, message = "Student not found or does not belong to your department" });

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

                // Broadcast dashboard stats update
                await BroadcastDashboardUpdate("Student deleted");

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
                Department = "CSEDS", // PERMANENT FIX: Use CSEDS consistently
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

                // Create new student with normalized department
                var student = new Student
                {
                    Id = model.RegdNumber, // Use RegdNumber as ID
                    FullName = model.FullName,
                    RegdNumber = model.RegdNumber,
                    Email = model.Email,
                    Password = string.IsNullOrWhiteSpace(model.Password) ? "rgmcet123" : model.Password,
                    Year = model.Year,
                    Semester = model.Semester ?? "I", // Save semester, default to I if not provided
                    Department = DepartmentNormalizer.Normalize(model.Department), // PERMANENT FIX: Normalize department
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

                // Broadcast dashboard stats update
                await BroadcastDashboardUpdate($"Student '{student.FullName}' added");

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
                TempData["ErrorMessage"] = "Student not found or does not belong to your department";
                return RedirectToAction("ManageCSEDSStudents");
            }

            var viewModel = new CSEDSStudentViewModel
            {
                StudentId = student.Id,
                FullName = student.FullName,
                RegdNumber = student.RegdNumber,
                Email = student.Email,
                Year = student.Year,
                Semester = student.Semester ?? "I", // Load semester value
                Department = student.Department,
                IsEdit = true,
                AvailableYears = new List<string> { "I Year", "II Year", "III Year", "IV Year" }
            };

            return View(viewModel);
        }

        /// <summary>
        /// Edit CSEDS student - POST
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
                    TempData["ErrorMessage"] = "Student not found or does not belong to your department";
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
                student.Semester = model.Semester ?? "I"; // Update semester, default to I if not provided

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
        /// Download Excel template for bulk student upload
        /// </summary>
        [HttpGet]
        public IActionResult DownloadStudentTemplate()
        {
            var department = HttpContext.Session.GetString("AdminDepartment");
            if (!IsCSEDSDepartment(department))
                return RedirectToAction("Login");

            try
            {
                ExcelPackage.LicenseContext = LicenseContext.NonCommercial;

                using (var package = new ExcelPackage())
                {
                    var worksheet = package.Workbook.Worksheets.Add("Students Template");

                    // Set header style
                    var headerCells = worksheet.Cells["A1:G1"];
                    headerCells.Style.Font.Bold = true;
                    headerCells.Style.Fill.PatternType = OfficeOpenXml.Style.ExcelFillStyle.Solid;
                    headerCells.Style.Fill.BackgroundColor.SetColor(System.Drawing.Color.FromArgb(155, 89, 182));
                    headerCells.Style.Font.Color.SetColor(System.Drawing.Color.White);
                    headerCells.Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;

                    // Add headers
                    worksheet.Cells[1, 1].Value = "StudentID";
                    worksheet.Cells[1, 2].Value = "FullName";
                    worksheet.Cells[1, 3].Value = "Email";
                    worksheet.Cells[1, 4].Value = "DepartmentName";
                    worksheet.Cells[1, 5].Value = "Year";
                    worksheet.Cells[1, 6].Value = "Semester";
                    worksheet.Cells[1, 7].Value = "Password";

                    // Add sample data
                    worksheet.Cells[2, 1].Value = "23091A32D4";
                    worksheet.Cells[2, 2].Value = "John Doe";
                    worksheet.Cells[2, 3].Value = "john.doe@example.com";
                    worksheet.Cells[2, 4].Value = "Cse Ds";
                    worksheet.Cells[2, 5].Value = "2";
                    worksheet.Cells[2, 6].Value = "I";
                    worksheet.Cells[2, 7].Value = "Password123";

                    // Add instructions
                    worksheet.Cells[4, 1].Value = "Instructions:";
                    worksheet.Cells[4, 1].Style.Font.Bold = true;
                    worksheet.Cells[5, 1].Value = "1. StudentID must be unique (e.g., 23091A32D4)";
                    worksheet.Cells[6, 1].Value = "2. DepartmentName should be 'Cse Ds' or 'CSEDS'";
                    worksheet.Cells[7, 1].Value = "3. Year should be 1, 2, 3, or 4";
                    worksheet.Cells[8, 1].Value = "4. Semester should be I or II (or 1 or 2)";
                    worksheet.Cells[9, 1].Value = "5. Password is optional (default: rgmcet123 if blank)";
                    worksheet.Cells[10, 1].Value = "6. Delete this sample row and instructions before uploading";

                    // Auto-fit columns
                    worksheet.Cells[worksheet.Dimension.Address].AutoFitColumns();

                    var stream = new MemoryStream();
                    package.SaveAs(stream);
                    stream.Position = 0;

                    var fileName = $"Students_Template_{DateTime.Now:yyyyMMdd_HHmmss}.xlsx";
                    return File(stream, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", fileName);
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error generating template: {ex.Message}");
                TempData["ErrorMessage"] = $"Error generating template: {ex.Message}";
                return RedirectToAction("ManageCSEDSStudents");
            }
        }

        /// <summary>
        /// Bulk upload students from Excel file
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> BulkUploadStudents(IFormFile excelFile)
        {
            var department = HttpContext.Session.GetString("AdminDepartment");
            if (!IsCSEDSDepartment(department))
                return RedirectToAction("Login");

            if (excelFile == null || excelFile.Length == 0)
            {
                TempData["ErrorMessage"] = "Please select an Excel file to upload.";
                return RedirectToAction("ManageCSEDSStudents");
            }

            if (!excelFile.FileName.EndsWith(".xlsx", StringComparison.OrdinalIgnoreCase))
            {
                TempData["ErrorMessage"] = "Only .xlsx files are supported.";
                return RedirectToAction("ManageCSEDSStudents");
            }

            try
            {
                ExcelPackage.LicenseContext = LicenseContext.NonCommercial;

                var successCount = 0;
                var errorCount = 0;
                var errors = new List<string>();

                using (var stream = new MemoryStream())
                {
                    await excelFile.CopyToAsync(stream);
                    using (var package = new ExcelPackage(stream))
                    {
                        var worksheet = package.Workbook.Worksheets[0];
                        var rowCount = worksheet.Dimension?.Rows ?? 0;

                        if (rowCount < 2)
                        {
                            TempData["ErrorMessage"] = "The Excel file is empty or has no data rows.";
                            return RedirectToAction("ManageCSEDSStudents");
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
                                var deptName = worksheet.Cells[row, 4].Value?.ToString()?.Trim();
                                var yearStr = worksheet.Cells[row, 5].Value?.ToString()?.Trim();
                                var semesterStr = worksheet.Cells[row, 6].Value?.ToString()?.Trim();
                                var password = worksheet.Cells[row, 7].Value?.ToString()?.Trim();

                                // Validate required fields
                                if (string.IsNullOrWhiteSpace(studentId) ||
                                    string.IsNullOrWhiteSpace(fullName) ||
                                    string.IsNullOrWhiteSpace(email) ||
                                    string.IsNullOrWhiteSpace(deptName) ||
                                    string.IsNullOrWhiteSpace(yearStr))
                                {
                                    errors.Add($"Row {row}: Missing required fields");
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
                                    // Accept both Roman numerals (I, II) and numbers (1, 2)
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
                                    Department = DepartmentNormalizer.Normalize(deptName),
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
                                $"{successCount} students uploaded successfully"
                            );

                            await BroadcastDashboardUpdate($"Bulk upload: {successCount} students added");
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

                return RedirectToAction("ManageCSEDSStudents");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error processing Excel file: {ex.Message}");
                TempData["ErrorMessage"] = $"Error processing file: {ex.Message}";
                return RedirectToAction("ManageCSEDSStudents");
            }
        }

        /// <summary>
        /// Download Excel template for bulk faculty upload (CSEDS)
        /// </summary>
        [HttpGet]
        public IActionResult DownloadCSEDSFacultyTemplate()
        {
            var department = HttpContext.Session.GetString("AdminDepartment");
            if (!IsCSEDSDepartment(department))
                return RedirectToAction("Login");

            try
            {
                ExcelPackage.LicenseContext = LicenseContext.NonCommercial;

                using (var package = new ExcelPackage())
                {
                    var worksheet = package.Workbook.Worksheets.Add("Faculty Template");

                    // Set header style
                    var headerCells = worksheet.Cells["A1:D1"];
                    headerCells.Style.Font.Bold = true;
                    headerCells.Style.Fill.PatternType = OfficeOpenXml.Style.ExcelFillStyle.Solid;
                    headerCells.Style.Fill.BackgroundColor.SetColor(System.Drawing.Color.FromArgb(155, 89, 182));
                    headerCells.Style.Font.Color.SetColor(System.Drawing.Color.White);
                    headerCells.Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;

                    // Add headers
                    worksheet.Cells[1, 1].Value = "FacultyName";
                    worksheet.Cells[1, 2].Value = "Email";
                    worksheet.Cells[1, 3].Value = "DepartmentName";
                    worksheet.Cells[1, 4].Value = "Password";

                    // Add sample data
                    worksheet.Cells[2, 1].Value = "Dr. John Doe";
                    worksheet.Cells[2, 2].Value = "john.doe@rgmcet.edu.in";
                    worksheet.Cells[2, 3].Value = "Cse Ds";
                    worksheet.Cells[2, 4].Value = "Faculty@123";

                    // Add instructions
                    worksheet.Cells[4, 1].Value = "Instructions:";
                    worksheet.Cells[4, 1].Style.Font.Bold = true;
                    worksheet.Cells[5, 1].Value = "1. FacultyName is required (e.g., Dr. John Doe)";
                    worksheet.Cells[6, 1].Value = "2. Email must be unique and valid";
                    worksheet.Cells[7, 1].Value = "3. DepartmentName should be 'Cse Ds' or 'CSEDS'"
;
                    worksheet.Cells[8, 1].Value = "4. Password is optional (default: rgmcet123 if blank)";
                    worksheet.Cells[9, 1].Value = "5. Delete this sample row and instructions before uploading";

                    // Auto-fit columns
                    worksheet.Cells[worksheet.Dimension.Address].AutoFitColumns();

                    var stream = new MemoryStream();
                    package.SaveAs(stream);
                    stream.Position = 0;

                    var fileName = $"CSEDS_Faculty_Template_{DateTime.Now:yyyyMMdd_HHmmss}.xlsx";
                    return File(stream, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", fileName);
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error generating faculty template: {ex.Message}");
                TempData["ErrorMessage"] = $"Error generating template: {ex.Message}";
                return RedirectToAction("ManageCSEDSFaculty");
            }
        }

        /// <summary>
        /// Bulk upload faculty from Excel file (CSEDS)
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> BulkUploadCSEDSFaculty(IFormFile excelFile)
        {
            var department = HttpContext.Session.GetString("AdminDepartment");
            if (!IsCSEDSDepartment(department))
                return RedirectToAction("Login");

            if (excelFile == null || excelFile.Length == 0)
            {
                TempData["ErrorMessage"] = "Please select an Excel file to upload.";
                return RedirectToAction("ManageCSEDSFaculty");
            }

            if (!excelFile.FileName.EndsWith(".xlsx", StringComparison.OrdinalIgnoreCase))
            {
                TempData["ErrorMessage"] = "Only .xlsx files are supported.";
                return RedirectToAction("ManageCSEDSFaculty");
            }

            try
            {
                ExcelPackage.LicenseContext = LicenseContext.NonCommercial;

                var successCount = 0;
                var errorCount = 0;
                var errors = new List<string>();

                using (var stream = new MemoryStream())
                {
                    await excelFile.CopyToAsync(stream);
                    using (var package = new ExcelPackage(stream))
                    {
                        var worksheet = package.Workbook.Worksheets[0];
                        var rowCount = worksheet.Dimension?.Rows ?? 0;

                        if (rowCount < 2)
                        {
                            TempData["ErrorMessage"] = "The Excel file is empty or has no data rows.";
                            return RedirectToAction("ManageCSEDSFaculty");
                        }

                        // Start from row 2 (skip header)
                        for (int row = 2; row <= rowCount; row++)
                        {
                            try
                            {
                                // Read data from Excel
                                var facultyName = worksheet.Cells[row, 1].Value?.ToString()?.Trim();
                                var email = worksheet.Cells[row, 2].Value?.ToString()?.Trim();
                                var deptName = worksheet.Cells[row, 3].Value?.ToString()?.Trim();
                                var password = worksheet.Cells[row, 4].Value?.ToString()?.Trim();

                                // Validate required fields
                                if (string.IsNullOrWhiteSpace(facultyName) ||
                                    string.IsNullOrWhiteSpace(email) ||
                                    string.IsNullOrWhiteSpace(deptName))
                                {
                                    errors.Add($"Row {row}: Missing required fields");
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
                                    Department = DepartmentNormalizer.Normalize(deptName)
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
                                $"{successCount} faculty members uploaded successfully"
                            );

                            await BroadcastDashboardUpdate($"Bulk upload: {successCount} faculty added");
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

                return RedirectToAction("ManageCSEDSFaculty");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error processing Excel file: {ex.Message}");
                TempData["ErrorMessage"] = $"Error processing file: {ex.Message}";
                return RedirectToAction("ManageCSEDSFaculty");
            }
        }

        /// <summary>
        /// Manage Faculty Selection Schedule page - ENHANCED WITH DEPARTMENT-SPECIFIC ACCESS
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> ManageFacultySelectionSchedule()
        {
            var adminId = HttpContext.Session.GetInt32("AdminId");
            var department = HttpContext.Session.GetString("AdminDepartment");

            Console.WriteLine($"?? ManageFacultySelectionSchedule Access Check:");
            Console.WriteLine($"   - AdminId: {adminId}");
            Console.WriteLine($"   - Department: {department}");

            if (adminId == null)
            {
                Console.WriteLine("? Admin not logged in");
                TempData["ErrorMessage"] = "Please login to access schedule management.";
                return RedirectToAction("Login");
            }

            if (!IsCSEDSDepartment(department))
            {
                Console.WriteLine($"? Access denied - Department: {department} is not CSEDS");
                TempData["ErrorMessage"] = "Access denied. CSEDS department access only.";
                return RedirectToAction("Login");
            }

            Console.WriteLine("? Access granted - Admin is CSEDS department");

            // Use department normalizer to ensure consistent department handling
            var normalizedDept = DepartmentNormalizer.Normalize(department);
            Console.WriteLine($"?? Normalized department: {normalizedDept}");

            // Get or create schedule specifically for this admin's department
            var schedule = await _context.FacultySelectionSchedules
                .FirstOrDefaultAsync(s => s.Department == "CSEDS" || s.Department == "CSE(DS)");

            if (schedule == null)
            {
                Console.WriteLine("?? Creating new schedule for CSEDS department");
                // Create default schedule for this specific department
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
                Console.WriteLine($"? Schedule created with ID: {schedule.ScheduleId}");
            }
            else
            {
                Console.WriteLine($"?? Found existing schedule with ID: {schedule.ScheduleId}");
            }

            // Get impact statistics - ONLY for this admin's department
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

            Console.WriteLine($"?? Department Statistics:");
            Console.WriteLine($"   - Students: {studentsCount}");
            Console.WriteLine($"   - Subjects: {subjectsCount}");
            Console.WriteLine($"   - Enrollments: {enrollmentsCount}");

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

            Console.WriteLine($"?? Current Schedule Status: {schedule.IsCurrentlyAvailable}");
            return View(viewModel);
        }

        /// <summary>
        /// Update faculty selection schedule - ENHANCED WITH DEPARTMENT-SPECIFIC CONTROL
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> UpdateFacultySelectionSchedule([FromBody] FacultySelectionScheduleUpdateRequest request)
        {
            // Manual anti-forgery token validation for JSON requests
            try
            {
                await _antiforgery.ValidateRequestAsync(HttpContext);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"? Anti-forgery validation failed: {ex.Message}");
                return Json(new { success = false, message = "Security validation failed. Please refresh the page and try again." });
            }

            var adminId = HttpContext.Session.GetInt32("AdminId");
            var department = HttpContext.Session.GetString("AdminDepartment");
            var adminEmail = HttpContext.Session.GetString("AdminEmail");

            Console.WriteLine($"?? UpdateFacultySelectionSchedule Request:");
            Console.WriteLine($"   - AdminId: {adminId}");
            Console.WriteLine($"   - Department: {department}");
            Console.WriteLine($"   - Email: {adminEmail}");
            Console.WriteLine($"   - IsEnabled: {request?.IsEnabled}");
            Console.WriteLine($"   - UseSchedule: {request?.UseSchedule}");
            Console.WriteLine($"   - StartDateTime: {request?.StartDateTime}");
            Console.WriteLine($"   - EndDateTime: {request?.EndDateTime}");

            if (adminId == null)
            {
                Console.WriteLine("? Admin not logged in");
                return Json(new { success = false, message = "Please login to continue" });
            }

            if (!IsCSEDSDepartment(department))
            {
                Console.WriteLine($"? Unauthorized access - Department: {department}");
                return Json(new { success = false, message = "Unauthorized access. CSEDS department only." });
            }

            if (request == null)
            {
                Console.WriteLine("? Request is null");
                return Json(new { success = false, message = "Invalid request data" });
            }

            try
            {
                // Use department normalizer for consistent queries
                var normalizedDept = DepartmentNormalizer.Normalize(department);
                Console.WriteLine($"?? Normalized department: {normalizedDept}");

                // Find schedule specifically for this admin's department
                var schedule = await _context.FacultySelectionSchedules
                    .FirstOrDefaultAsync(s => s.Department == "CSEDS" || s.Department == "CSE(DS)");

                if (schedule == null)
                {
                    Console.WriteLine("? Schedule not found for this department");
                    return Json(new { success = false, message = "Schedule not found for your department" });
                }

                Console.WriteLine($"?? Found schedule ID: {schedule.ScheduleId} for department: {schedule.Department}");
                Console.WriteLine($"?? Current values - IsEnabled: {schedule.IsEnabled}, UseSchedule: {schedule.UseSchedule}");

                // Enhanced validation
                if (request.UseSchedule && request.StartDateTime.HasValue && request.EndDateTime.HasValue)
                {
                    if (request.EndDateTime <= request.StartDateTime)
                    {
                        Console.WriteLine("? Validation failed: End date before start date");
                        return Json(new { success = false, message = "End date must be after start date" });
                    }

                    // Check if the time window is reasonable (at least 1 hour)
                    var duration = request.EndDateTime.Value - request.StartDateTime.Value;
                    if (duration.TotalHours < 1)
                    {
                        Console.WriteLine("? Validation failed: Time window too short");
                        return Json(new { success = false, message = "Schedule window must be at least 1 hour" });
                    }
                }

                // Validate disabled message
                if (string.IsNullOrEmpty(request.DisabledMessage) || request.DisabledMessage.Trim().Length < 10)
                {
                    Console.WriteLine("? Validation failed: Disabled message too short");
                    return Json(new { success = false, message = "Disabled message must be at least 10 characters long" });
                }

                Console.WriteLine("? Validation passed - Updating schedule");

                // Update schedule properties with explicit change tracking
                var hasChanges = false;
                
                if (schedule.IsEnabled != request.IsEnabled)
                {
                    Console.WriteLine($"?? IsEnabled changing from {schedule.IsEnabled} to {request.IsEnabled}");
                    schedule.IsEnabled = request.IsEnabled;
                    hasChanges = true;
                }
                
                if (schedule.UseSchedule != request.UseSchedule)
                {
                    Console.WriteLine($"?? UseSchedule changing from {schedule.UseSchedule} to {request.UseSchedule}");
                    schedule.UseSchedule = request.UseSchedule;
                    hasChanges = true;
                }
                
                var newStartDateTime = request.UseSchedule ? request.StartDateTime : null;
                if (schedule.StartDateTime != newStartDateTime)
                {
                    Console.WriteLine($"?? StartDateTime changing from {schedule.StartDateTime} to {newStartDateTime}");
                    schedule.StartDateTime = newStartDateTime;
                    hasChanges = true;
                }
                
                var newEndDateTime = request.UseSchedule ? request.EndDateTime : null;
                if (schedule.EndDateTime != newEndDateTime)
                {
                    Console.WriteLine($"?? EndDateTime changing from {schedule.EndDateTime} to {newEndDateTime}");
                    schedule.EndDateTime = newEndDateTime;
                    hasChanges = true;
                }
                
                var trimmedMessage = request.DisabledMessage?.Trim() ?? schedule.DisabledMessage;
                if (schedule.DisabledMessage != trimmedMessage)
                {
                    Console.WriteLine($"?? DisabledMessage changing");
                    schedule.DisabledMessage = trimmedMessage;
                    hasChanges = true;
                }
                
                // Always update metadata
                schedule.UpdatedAt = DateTime.Now;
                schedule.UpdatedBy = adminEmail ?? "Unknown Admin";
                
                Console.WriteLine($"?? HasChanges: {hasChanges}");

                // Mark entity as modified to ensure EF Core tracks changes
                _context.Entry(schedule).State = EntityState.Modified;

                // Save changes with verification
                var changeCount = await _context.SaveChangesAsync();
                Console.WriteLine($"?? Database changes saved: {changeCount}");

                if (changeCount == 0 && hasChanges)
                {
                    Console.WriteLine("?? Warning: Expected changes but none were saved to database");
                    // Try to reload and check
                    await _context.Entry(schedule).ReloadAsync();
                    Console.WriteLine($"?? After reload - IsEnabled: {schedule.IsEnabled}, UseSchedule: {schedule.UseSchedule}");
                }

                Console.WriteLine("? Changes successfully processed");

                // Calculate current status
                var isCurrentlyAvailable = schedule.IsCurrentlyAvailable;
                var statusDescription = schedule.StatusDescription;

                Console.WriteLine($"?? Updated Schedule Status:");
                Console.WriteLine($"   - IsEnabled: {schedule.IsEnabled}");
                Console.WriteLine($"   - UseSchedule: {schedule.UseSchedule}");
                Console.WriteLine($"   - IsCurrentlyAvailable: {isCurrentlyAvailable}");
                Console.WriteLine($"   - StatusDescription: {statusDescription}");

                // Get affected students count
                var affectedStudentsCount = await _context.Students
                    .Where(s => s.Department == "CSEDS" || s.Department == "CSE(DS)")
                    .CountAsync();

                // Send notification
                await _signalRService.NotifyUserActivity(
                    adminEmail ?? "",
                    "Admin",
                    "Faculty Selection Schedule Updated",
                    $"CSEDS department schedule updated by {adminEmail} - IsEnabled: {schedule.IsEnabled}, Affects {affectedStudentsCount} students"
                );

                Console.WriteLine($"?? Notification sent - Affected students: {affectedStudentsCount}");

                return Json(new { 
                    success = true, 
                    message = $"Schedule updated successfully! {(changeCount > 0 ? $"Changes saved to database ({changeCount} records updated)." : "No database changes needed.")} Affects {affectedStudentsCount} CSEDS students.",
                    data = new {
                        isCurrentlyAvailable = isCurrentlyAvailable,
                        statusDescription = statusDescription,
                        isEnabled = schedule.IsEnabled,
                        useSchedule = schedule.UseSchedule,
                        affectedStudents = affectedStudentsCount,
                        updatedAt = schedule.UpdatedAt,
                        changeCount = changeCount
                    }
                });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"? Error updating schedule: {ex.Message}");
                Console.WriteLine($"   Stack trace: {ex.StackTrace}");
                
                var errorMessage = "Error updating schedule: ";
                if (ex.InnerException != null)
                {
                    errorMessage += ex.InnerException.Message;
                    Console.WriteLine($"   Inner exception: {ex.InnerException.Message}");
                }
                else
                {
                    errorMessage += ex.Message;
                }
                
                return Json(new { success = false, message = errorMessage });
            }
        }

        /// <summary>
        /// Generate report data for dynamic department
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> GetDynamicReportData([FromBody] dynamic filters)
        {
            var adminId = HttpContext.Session.GetInt32("AdminId");
            var department = HttpContext.Session.GetString("AdminDepartment");

            if (adminId == null || string.IsNullOrEmpty(department))
            {
                return Json(new { success = false, message = "Session expired. Please log in again.", unauthorized = true });
            }

            try
            {
                var normalizedDept = DepartmentNormalizer.Normalize(department);

                var query = _context.StudentEnrollments
                    .Include(se => se.Student)
                    .Include(se => se.AssignedSubject)
                        .ThenInclude(a => a.Subject)
                    .Include(se => se.AssignedSubject)
                        .ThenInclude(a => a.Faculty)
                    .Where(se => se.Student.Department == normalizedDept);

                int? subjectId = filters.selectedSubjectId;
                int? facultyId = filters.selectedFacultyId;
                int? year = filters.selectedYear;
                string semester = filters.selectedSemester;

                if (subjectId.HasValue)
                    query = query.Where(se => se.AssignedSubject.SubjectId == subjectId.Value);

                if (facultyId.HasValue)
                    query = query.Where(se => se.AssignedSubject.FacultyId == facultyId.Value);

                if (year.HasValue)
                    query = query.Where(se => se.AssignedSubject.Subject.Year == year.Value);

                if (!string.IsNullOrEmpty(semester))
                    query = query.Where(se => se.AssignedSubject.Subject.Semester == semester);

                var results = await query
                    .OrderBy(se => se.EnrolledAt)
                    .ThenBy(se => se.Student.FullName)
                    .Select(se => new
                    {
                        StudentName = se.Student.FullName,
                        StudentRegdNumber = se.Student.RegdNumber,
                        StudentEmail = se.Student.Email,
                        StudentYear = se.Student.Year,
                        SubjectName = se.AssignedSubject.Subject.Name,
                        FacultyName = se.AssignedSubject.Faculty.Name,
                        FacultyEmail = se.AssignedSubject.Faculty.Email,
                        EnrollmentDate = se.EnrolledAt.Date,
                        EnrolledAt = se.EnrolledAt,
                        Semester = se.AssignedSubject.Subject.Semester ?? ""
                    })
                    .ToListAsync();

                return Json(new { success = true, data = results });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[GetDynamicReportData] Error: {ex.Message}");
                return Json(new { success = false, message = $"Error generating report: {ex.Message}" });
            }
        }

        /// <summary>
        /// Export report to Excel for dynamic department
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> ExportDynamicReport([FromBody] dynamic filters)
        {
            var adminId = HttpContext.Session.GetInt32("AdminId");
            var department = HttpContext.Session.GetString("AdminDepartment");

            if (adminId == null || string.IsNullOrEmpty(department))
                return Unauthorized(new { success = false, message = "Unauthorized access" });

            try
            {
                var normalizedDept = DepartmentNormalizer.Normalize(department);

                var query = _context.StudentEnrollments
                    .Include(se => se.Student)
                    .Include(se => se.AssignedSubject)
                        .ThenInclude(a => a.Subject)
                    .Include(se => se.AssignedSubject)
                        .ThenInclude(a => a.Faculty)
                    .Where(se => se.Student.Department == normalizedDept);

                int? subjectId = filters.selectedSubjectId;
                int? facultyId = filters.selectedFacultyId;
                int? year = filters.selectedYear;
                string semester = filters.selectedSemester;

                if (subjectId.HasValue)
                    query = query.Where(se => se.AssignedSubject.SubjectId == subjectId.Value);

                if (facultyId.HasValue)
                    query = query.Where(se => se.AssignedSubject.FacultyId == facultyId.Value);

                if (year.HasValue)
                    query = query.Where(se => se.AssignedSubject.Subject.Year == year.Value);

                if (!string.IsNullOrEmpty(semester))
                    query = query.Where(se => se.AssignedSubject.Subject.Semester == semester);

                var data = await query
                    .OrderBy(se => se.Student.FullName)
                    .ThenBy(se => se.AssignedSubject.Subject.Name)
                    .Select(se => new
                    {
                        StudentName = se.Student.FullName,
                        StudentRegdNumber = se.Student.RegdNumber,
                        StudentEmail = se.Student.Email,
                        StudentYear = se.Student.Year,
                        SubjectName = se.AssignedSubject.Subject.Name,
                        FacultyName = se.AssignedSubject.Faculty.Name,
                        FacultyEmail = se.AssignedSubject.Faculty.Email,
                        Semester = se.AssignedSubject.Subject.Semester ?? "",
                        EnrolledAt = se.EnrolledAt
                    })
                    .ToListAsync();

                if (data.Count == 0)
                {
                    return BadRequest(new { success = false, message = "No data found for the selected criteria" });
                }

                ExcelPackage.LicenseContext = LicenseContext.NonCommercial;
                using var package = new ExcelPackage();
                var worksheet = package.Workbook.Worksheets.Add($"{department} Enrollment Report");

                worksheet.Cells[1, 1].Value = "Student Name";
                worksheet.Cells[1, 2].Value = "Registration Number";
                worksheet.Cells[1, 3].Value = "Email";
                worksheet.Cells[1, 4].Value = "Year";
                worksheet.Cells[1, 5].Value = "Subject";
                worksheet.Cells[1, 6].Value = "Faculty";
                worksheet.Cells[1, 7].Value = "Semester";
                worksheet.Cells[1, 8].Value = "Enrolled At";

                using (var range = worksheet.Cells[1, 1, 1, 8])
                {
                    range.Style.Font.Bold = true;
                    range.Style.Fill.PatternType = OfficeOpenXml.Style.ExcelFillStyle.Solid;
                    range.Style.Fill.BackgroundColor.SetColor(System.Drawing.Color.LightGray);
                }

                for (int i = 0; i < data.Count; i++)
                {
                    var row = data[i];
                    worksheet.Cells[i + 2, 1].Value = row.StudentName;
                    worksheet.Cells[i + 2, 2].Value = row.StudentRegdNumber;
                    worksheet.Cells[i + 2, 3].Value = row.StudentEmail;
                    worksheet.Cells[i + 2, 4].Value = row.StudentYear;
                    worksheet.Cells[i + 2, 5].Value = row.SubjectName;
                    worksheet.Cells[i + 2, 6].Value = row.FacultyName;
                    worksheet.Cells[i + 2, 7].Value = row.Semester;
                    worksheet.Cells[i + 2, 8].Value = row.EnrolledAt.ToString("yyyy-MM-dd HH:mm:ss");
                }

                worksheet.Cells.AutoFitColumns();

                var stream = new MemoryStream();
                package.SaveAs(stream);
                stream.Position = 0;

                var fileName = $"{department}_Enrollment_Report_{DateTime.Now:yyyyMMddHHmmss}.xlsx";

                await _signalRService.NotifyUserActivity(
                    HttpContext.Session.GetString("AdminEmail") ?? "",
                    "Admin",
                    "Report Exported",
                    $"{department} enrollment report exported to Excel"
                );

                return File(stream, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", fileName);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[ExportDynamicReport] Error: {ex.Message}");
                return BadRequest(new { success = false, message = $"Error exporting report: {ex.Message}" });
            }
        }

        /// <summary>
        /// Get year-specific schedules for CSEDS department
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> GetYearSchedules()
        {
            var adminId = HttpContext.Session.GetInt32("AdminId");
            var department = HttpContext.Session.GetString("AdminDepartment");

            if (adminId == null || !IsCSEDSDepartment(department))
            {
                return Json(new { success = false, message = "Unauthorized access" });
            }

            try
            {
                var schedules = new List<object>();

                for (int year = 1; year <= 4; year++)
                {
                    var schedule = await _context.FacultySelectionSchedules
                        .FirstOrDefaultAsync(s => s.Department == "CSEDS" && s.Year == year);

                    schedules.Add(new
                    {
                        year = year,
                        isEnabled = schedule?.IsEnabled ?? false,
                        scheduleId = schedule?.ScheduleId ?? 0
                    });
                }

                return Json(new { success = true, schedules });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error getting year schedules: {ex.Message}");
                return Json(new { success = false, message = $"Error loading schedules: {ex.Message}" });
            }
        }

        /// <summary>
        /// Get statistics for a specific year
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> GetYearStatistics(int year)
        {
            var adminId = HttpContext.Session.GetInt32("AdminId");
            var department = HttpContext.Session.GetString("AdminDepartment");

            if (adminId == null || !IsCSEDSDepartment(department))
            {
                return Json(new { success = false, message = "Unauthorized access" });
            }

            try
            {
                using var csedsContext = _dbFactory.GetContext("CSEDS");

                // Convert year number to Roman numeral format used in database
                // 1 -> "I Year", 2 -> "II Year", 3 -> "III Year", 4 -> "IV Year"
                string[] romanYears = { "", "I Year", "II Year", "III Year", "IV Year" };
                var yearString = year >= 1 && year <= 4 ? romanYears[year] : year.ToString();

                // Also check for numeric format (just "1", "2", "3", "4")
                var yearNumericString = year.ToString();

                var studentsCount = await csedsContext.Students
                    .Where(s => s.Year == yearString || s.Year == yearNumericString)
                    .CountAsync();

                var subjectsCount = await csedsContext.Subjects
                    .Where(s => s.Year == year)
                    .CountAsync();

                var enrollmentsCount = await csedsContext.StudentEnrollments
                    .Include(se => se.Student)
                    .Where(se => se.Student.Year == yearString || se.Student.Year == yearNumericString)
                    .CountAsync();

                return Json(new
                {
                    success = true,
                    year,
                    studentsCount,
                    subjectsCount,
                    enrollmentsCount
                });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error getting year statistics: {ex.Message}");
                return Json(new { success = false, message = $"Error loading statistics: {ex.Message}" });
            }
        }

        /// <summary>
        /// Update year-specific schedule for CSEDS department
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> UpdateYearSchedule([FromBody] YearScheduleUpdateRequest request)
        {
            // Manual anti-forgery token validation for JSON requests
            try
            {
                await _antiforgery.ValidateRequestAsync(HttpContext);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Anti-forgery validation failed: {ex.Message}");
                return Json(new { success = false, message = "Security validation failed. Please refresh the page and try again." });
            }

            var adminId = HttpContext.Session.GetInt32("AdminId");
            var department = HttpContext.Session.GetString("AdminDepartment");
            var adminEmail = HttpContext.Session.GetString("AdminEmail");

            if (adminId == null || !IsCSEDSDepartment(department))
            {
                return Json(new { success = false, message = "Unauthorized access. CSEDS department only." });
            }

            if (request == null || request.Year < 1 || request.Year > 4)
            {
                return Json(new { success = false, message = "Invalid year specified" });
            }

            try
            {
                // Find or create schedule for this year
                var schedule = await _context.FacultySelectionSchedules
                    .FirstOrDefaultAsync(s => s.Department == "CSEDS" && s.Year == request.Year);

                if (schedule == null)
                {
                    // Create new schedule for this year
                    schedule = new FacultySelectionSchedule
                    {
                        Department = "CSEDS",
                        Year = request.Year,
                        IsEnabled = request.IsEnabled,
                        UseSchedule = false,
                        DisabledMessage = $"Faculty selection for Year {request.Year} is currently disabled. Please contact your administrator.",
                        CreatedAt = DateTime.Now,
                        UpdatedAt = DateTime.Now,
                        UpdatedBy = adminEmail ?? "System"
                    };
                    _context.FacultySelectionSchedules.Add(schedule);
                }
                else
                {
                    // Update existing schedule
                    schedule.IsEnabled = request.IsEnabled;
                    schedule.UpdatedAt = DateTime.Now;
                    schedule.UpdatedBy = adminEmail ?? "System";
                    _context.Entry(schedule).State = EntityState.Modified;
                }

                await _context.SaveChangesAsync();

                // Get affected students count
                using var csedsContext = _dbFactory.GetContext("CSEDS");
                
                // Convert year number to Roman numeral format used in database
                string[] romanYears = { "", "I Year", "II Year", "III Year", "IV Year" };
                var yearString = request.Year >= 1 && request.Year <= 4 ? romanYears[request.Year] : request.Year.ToString();
                var yearNumericString = request.Year.ToString();
                
                var affectedStudentsCount = await csedsContext.Students
                    .Where(s => s.Year == yearString || s.Year == yearNumericString)
                    .CountAsync();

                // Send notification
                await _signalRService.NotifyUserActivity(
                    adminEmail ?? "",
                    "Admin",
                    $"Year {request.Year} Schedule Updated",
                    $"Faculty selection for Year {request.Year} {(request.IsEnabled ? "ENABLED" : "DISABLED")} by {adminEmail} - Affects {affectedStudentsCount} students"
                );

                return Json(new
                {
                    success = true,
                    message = $"Year {request.Year} faculty selection {(request.IsEnabled ? "enabled" : "disabled")} successfully! Affects {affectedStudentsCount} students.",
                    data = new
                    {
                        year = request.Year,
                        isEnabled = schedule.IsEnabled,
                        affectedStudents = affectedStudentsCount,
                        updatedAt = schedule.UpdatedAt
                    }
                });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error updating year schedule: {ex.Message}");
                return Json(new { success = false, message = $"Error updating schedule: {ex.Message}" });
            }
        }
    }

    /// <summary>
    /// Request model for filtering students
    /// </summary>
    public class StudentFilterRequest
    {
        public string? SearchText { get; set; }
        public string? Year { get; set; }
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

    /// <summary>
    /// Request model for year-specific schedule update
    /// </summary>
    public class YearScheduleUpdateRequest
    {
        public string Department { get; set; } = string.Empty;
        public int Year { get; set; }
        public bool IsEnabled { get; set; }
    }
}
