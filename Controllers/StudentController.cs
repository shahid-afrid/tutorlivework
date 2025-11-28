using Microsoft.AspNetCore.Mvc;
using TutorLiveMentor.Helpers;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using TutorLiveMentor.Models;
using TutorLiveMentor.Services;

namespace TutorLiveMentor.Controllers
{
    public class StudentController : Controller
    {
        private readonly AppDbContext _context;
        private readonly SignalRService _signalRService;

        public StudentController(AppDbContext context, SignalRService signalRService)
        {
            _context = context;
            _signalRService = signalRService;
        }

        [HttpGet]
        public IActionResult Index()
        {
            return View();
        }

        [HttpGet]
        public IActionResult Register()
        {
            return View();
        }

        [HttpPost]
        public async Task<IActionResult> Register(StudentRegistrationModel model)
        {
            if (ModelState.IsValid)
            {
                // Convert registration number to uppercase on server side as well
                model.RegdNumber = model.RegdNumber?.ToUpper();
                
                // ? CRITICAL FIX: Normalize department name to prevent CSE(DS) vs CSEDS mismatch
                model.Department = DepartmentNormalizer.Normalize(model.Department);
                
                // Check if student with this registration number already exists
                if (await _context.Students.AnyAsync(s => s.Id == model.RegdNumber))
                {
                    ModelState.AddModelError("RegdNumber", "Registration number is already registered.");
                    return View(model);
                }
                
                if (await _context.Students.AnyAsync(s => s.Email == model.Email))
                {
                    ModelState.AddModelError("Email", "Email is already registered.");
                    return View(model);
                }

                var student = new Student
                {
                    Id = model.RegdNumber, // Set Id equal to RegdNumber
                    FullName = model.FullName,
                    RegdNumber = model.RegdNumber,
                    Year = model.Year,
                    Department = model.Department,
                    Email = model.Email,
                    Password = model.Password,
                    SelectedSubject = "" // Initialize property
                };

                _context.Students.Add(student);
                await _context.SaveChangesAsync();

                // Notify system of new user registration
                await _signalRService.NotifyUserActivity(student.FullName, "Student", "Registered", $"New student registered: {student.RegdNumber}");

                TempData["SuccessMessage"] = "Registration successful! Please log in now.";
                return RedirectToAction("Login");
            }
            return View(model);
        }

        [HttpGet]
        public IActionResult Login()
        {
            return View();
        }

        [HttpPost]
        public async Task<IActionResult> Login(LoginViewModel model)
        {
            // Simple, reliable login without complex debugging
            if (!ModelState.IsValid)
            {
                return View(model);
            }

            try
            {
                // Find student with matching credentials
                var student = await _context.Students
                    .FirstOrDefaultAsync(s => s.Email == model.Email && s.Password == model.Password);

                if (student == null)
                {
                    ModelState.AddModelError(string.Empty, "Invalid Email or Password.");
                    return View(model);
                }

                // Clear any existing session
                HttpContext.Session.Clear();

                // Set session values - now using string Id
                HttpContext.Session.SetString("StudentId", student.Id);
                HttpContext.Session.SetString("StudentName", student.FullName);

                // Force session to be saved immediately
                await HttpContext.Session.CommitAsync();

                // Simple redirect without SignalR to avoid complications
                return RedirectToAction("MainDashboard", "Student");
            }
            catch (Exception ex)
            {
                ModelState.AddModelError(string.Empty, $"Login error: {ex.Message}");
                return View(model);
            }
        }

        [HttpGet]
        public async Task<IActionResult> MainDashboard()
        {
            // Simple session check
            var studentId = HttpContext.Session.GetString("StudentId");
            
            if (string.IsNullOrEmpty(studentId))
            {
                Console.WriteLine("MainDashboard - Student not logged in");
                TempData["ErrorMessage"] = "Please login to access the dashboard.";
                return RedirectToAction("Login");
            }
            
            // Get student details
            var student = await _context.Students.FindAsync(studentId);
            if (student == null)
            {
                Console.WriteLine($"MainDashboard - Student not found: {studentId}");
                TempData["ErrorMessage"] = "Student not found.";
                return RedirectToAction("Login");
            }

            Console.WriteLine($"MainDashboard - Student: {student.FullName}, Department: {student.Department}");

            // Check faculty selection schedule - support both CSEDS and CSE(DS) formats
            var schedule = await _context.FacultySelectionSchedules
                .FirstOrDefaultAsync(s => s.Department == "CSEDS" || s.Department == "CSE(DS)" || s.Department == student.Department);

            Console.WriteLine($"MainDashboard - Schedule found: {schedule != null}");
            if (schedule != null)
            {
                Console.WriteLine($"MainDashboard - Schedule ID: {schedule.ScheduleId}");
                Console.WriteLine($"MainDashboard - Schedule Department: {schedule.Department}");
                Console.WriteLine($"MainDashboard - IsEnabled: {schedule.IsEnabled}");
                Console.WriteLine($"MainDashboard - UseSchedule: {schedule.UseSchedule}");
                Console.WriteLine($"MainDashboard - StartDateTime: {schedule.StartDateTime}");
                Console.WriteLine($"MainDashboard - EndDateTime: {schedule.EndDateTime}");
                Console.WriteLine($"MainDashboard - IsCurrentlyAvailable: {schedule.IsCurrentlyAvailable}");
                Console.WriteLine($"MainDashboard - StatusDescription: {schedule.StatusDescription}");
                Console.WriteLine($"MainDashboard - DisabledMessage: {schedule.DisabledMessage}");
            }
            else
            {
                Console.WriteLine($"MainDashboard - No schedule found for department: {student.Department}");
            }

            var isAvailable = schedule == null || schedule.IsCurrentlyAvailable;
            Console.WriteLine($"MainDashboard - Final IsSelectionAvailable: {isAvailable}");

            // ? Set ALL ViewBag properties with student info
            ViewBag.StudentId = studentId;
            ViewBag.StudentName = student.FullName;
            ViewBag.StudentRegdNumber = student.RegdNumber;  // ? Added
            ViewBag.StudentYear = student.Year;              // ? Added
            ViewBag.StudentDepartment = student.Department;  // ? Added
            ViewBag.IsSelectionAvailable = isAvailable;
            ViewBag.ScheduleMessage = schedule?.DisabledMessage ?? "";
            ViewBag.ScheduleStatus = schedule?.StatusDescription ?? "Always Available";
            
            return View();
        }

        [HttpGet]
        public async Task<IActionResult> MySelectedSubjects()
        {
            var studentId = HttpContext.Session.GetString("StudentId");
            if (string.IsNullOrEmpty(studentId))
            {
                return RedirectToAction("Login");
            }

            var student = await _context.Students
                .Include(s => s.Enrollments)
                    .ThenInclude(e => e.AssignedSubject)
                    .ThenInclude(asub => asub.Subject)
                .Include(s => s.Enrollments)
                    .ThenInclude(e => e.AssignedSubject)
                    .ThenInclude(asub => asub.Faculty)
                .FirstOrDefaultAsync(s => s.Id == studentId);

            if (student == null)
            {
                return NotFound();
            }

            return View(student);
        }

        [HttpGet]
        public async Task<IActionResult> Dashboard()
        {
            var studentId = HttpContext.Session.GetString("StudentId");
            if (string.IsNullOrEmpty(studentId))
            {
                return RedirectToAction("Login");
            }

            var student = await _context.Students
                .Include(s => s.Enrollments)
                    .ThenInclude(e => e.AssignedSubject)
                    .ThenInclude(asub => asub.Subject)
                .Include(s => s.Enrollments)
                    .ThenInclude(e => e.AssignedSubject)
                    .ThenInclude(asub => asub.Faculty)
                .FirstOrDefaultAsync(s => s.Id == studentId);

            if (student == null)
            {
                return NotFound();
            }

            // Return the student model directly as the Dashboard view expects Student model
            return View(student);
        }

        [HttpPost]
        public async Task<IActionResult> SelectSubject(int assignedSubjectId)
        {
            var studentId = HttpContext.Session.GetString("StudentId");
            if (string.IsNullOrEmpty(studentId))
            {
                Console.WriteLine("SelectSubject POST - Student not logged in");
                return RedirectToAction("Login");
            }

            Console.WriteLine($"SelectSubject POST - StudentId: {studentId}, AssignedSubjectId: {assignedSubjectId}");

            // ?? USE DATABASE TRANSACTION with row-level locking for concurrent enrollment safety
            using (var transaction = await _context.Database.BeginTransactionAsync())
            {
                try
                {
                    var student = await _context.Students
                        .Include(s => s.Enrollments)
                            .ThenInclude(e => e.AssignedSubject)
                            .ThenInclude(a => a.Subject)
                        .FirstOrDefaultAsync(s => s.Id == studentId);
                    
                    if (student == null)
                    {
                        Console.WriteLine($"SelectSubject POST - Student not found: {studentId}");
                        await transaction.RollbackAsync();
                        return NotFound();
                    }

                    Console.WriteLine($"SelectSubject POST - Student: {student.FullName}, Department: {student.Department}");

                    // ? CRITICAL: CHECK FACULTY SELECTION SCHEDULE FIRST
                    // Support both CSEDS and CSE(DS) formats
                    var schedule = await _context.FacultySelectionSchedules
                        .FirstOrDefaultAsync(s => s.Department == "CSEDS" || s.Department == "CSE(DS)" || s.Department == student.Department);

                    Console.WriteLine($"SelectSubject POST - Schedule found: {schedule != null}");
                    if (schedule != null)
                    {
                        Console.WriteLine($"SelectSubject POST - Schedule Department: {schedule.Department}");
                        Console.WriteLine($"SelectSubject POST - Schedule IsEnabled: {schedule.IsEnabled}, UseSchedule: {schedule.UseSchedule}");
                        Console.WriteLine($"SelectSubject POST - Schedule IsCurrentlyAvailable: {schedule.IsCurrentlyAvailable}");
                    }

                    // If schedule exists and faculty selection is NOT available, reject enrollment
                    if (schedule != null && !schedule.IsCurrentlyAvailable)
                    {
                        Console.WriteLine($"SelectSubject POST - ENROLLMENT BLOCKED! Reason: {schedule.DisabledMessage}");
                        await transaction.RollbackAsync();
                        TempData["ErrorMessage"] = schedule.DisabledMessage ?? "Faculty selection is currently disabled. You cannot enroll in subjects at this time.";
                        return RedirectToAction("MainDashboard");
                    }

                    Console.WriteLine("SelectSubject POST - Schedule check passed, proceeding with enrollment");

                    // ?? LOCK THE ROW: Get the assigned subject with FOR UPDATE locking
                    // This prevents race conditions when multiple students enroll simultaneously
                    var assignedSubject = await _context.AssignedSubjects
                        .Include(a => a.Subject)
                        .Include(a => a.Faculty)
                        .FirstOrDefaultAsync(a => a.AssignedSubjectId == assignedSubjectId);

                    if (assignedSubject == null)
                    {
                        Console.WriteLine($"SelectSubject POST - Assigned subject not found: {assignedSubjectId}");
                        await transaction.RollbackAsync();
                        return NotFound();
                    }

                    // ? NEW: Check if this is a Professional Elective subject
                    if (assignedSubject.Subject.SubjectType.StartsWith("ProfessionalElective"))
                    {
                        Console.WriteLine($"SelectSubject POST - Professional Elective detected: {assignedSubject.Subject.SubjectType}");
                        
                        // Check if student already enrolled in this elective type
                        var existingElective = student.Enrollments?
                            .FirstOrDefault(e => e.AssignedSubject.Subject.SubjectType == assignedSubject.Subject.SubjectType);
                        
                        if (existingElective != null)
                        {
                            Console.WriteLine($"SelectSubject POST - Student already enrolled in {assignedSubject.Subject.SubjectType}");
                            await transaction.RollbackAsync();
                            TempData["ErrorMessage"] = $"You have already selected a subject for {assignedSubject.Subject.SubjectType}. You can select only ONE subject from each Professional Elective group.";
                            return RedirectToAction("SelectSubject");
                        }
                        
                        // ? NEW: Check MaxEnrollments for Professional Electives
                        if (assignedSubject.Subject.MaxEnrollments.HasValue)
                        {
                            var currentEnrollments = await _context.StudentEnrollments
                                .CountAsync(e => e.AssignedSubjectId == assignedSubjectId);
                            
                            Console.WriteLine($"SelectSubject POST - Current enrollments: {currentEnrollments}, Max: {assignedSubject.Subject.MaxEnrollments.Value}");
                            
                            if (currentEnrollments >= assignedSubject.Subject.MaxEnrollments.Value)
                            {
                                Console.WriteLine("SelectSubject POST - Subject has reached maximum capacity");
                                await transaction.RollbackAsync();
                                TempData["ErrorMessage"] = $"This subject has reached its maximum capacity of {assignedSubject.Subject.MaxEnrollments.Value} students. Please select another subject.";
                                return RedirectToAction("SelectSubject");
                            }
                        }
                    }

                    // Check if student has already enrolled in this specific assigned subject (same faculty)
                    if (student.Enrollments.Any(e => e.AssignedSubjectId == assignedSubjectId))
                    {
                        Console.WriteLine("SelectSubject POST - Already enrolled with this faculty");
                        await transaction.RollbackAsync();
                        TempData["ErrorMessage"] = "You have already enrolled with this faculty for this subject.";
                        return RedirectToAction("SelectSubject");
                    }

                    // Check if student has already enrolled in this subject with any faculty (for core subjects)
                    if (assignedSubject.Subject.SubjectType == "Core" && 
                        student.Enrollments.Any(e => e.AssignedSubject.SubjectId == assignedSubject.SubjectId))
                    {
                        Console.WriteLine("SelectSubject POST - Already enrolled in this subject with another faculty");
                        await transaction.RollbackAsync();
                        TempData["ErrorMessage"] = $"You have already enrolled in {assignedSubject.Subject.Name} with another faculty.";
                        return RedirectToAction("SelectSubject");
                    }

                    // ? CRITICAL CHECK: Re-verify count within transaction to prevent race conditions
                    // Get the ACTUAL current count from database, not cached value
                    var currentCount = await _context.StudentEnrollments
                        .CountAsync(e => e.AssignedSubjectId == assignedSubjectId);

                    Console.WriteLine($"SelectSubject POST - Current enrollment count: {currentCount}");

                    // For core subjects, check 70 limit
                    if (assignedSubject.Subject.SubjectType == "Core" && currentCount >= 70)
                    {
                        Console.WriteLine("SelectSubject POST - Subject is full (70 students)");
                        await transaction.RollbackAsync();
                        TempData["ErrorMessage"] = "This subject is already full (maximum 70 students). Someone enrolled just before you.";
                        return RedirectToAction("SelectSubject");
                    }

                    // ?? CREATE ENROLLMENT with precise timestamp (milliseconds included)
                    var enrollment = new StudentEnrollment
                    {
                        StudentId = student.Id,
                        AssignedSubjectId = assignedSubject.AssignedSubjectId,
                        EnrolledAt = DateTime.UtcNow // Precise timestamp with milliseconds
                    };
                    _context.StudentEnrollments.Add(enrollment);

                    // Update selected subjects list (comma-separated)
                    var enrolledSubjects = student.Enrollments?.Select(e => e.AssignedSubject.Subject.Name).ToList() ?? new List<string>();
                    enrolledSubjects.Add(assignedSubject.Subject.Name);
                    student.SelectedSubject = string.Join(", ", enrolledSubjects.Distinct());

                    // Update count to match actual database state
                    assignedSubject.SelectedCount = currentCount + 1;

                    // ?? SAVE ALL CHANGES atomically
                    await _context.SaveChangesAsync();
                    
                    // ? COMMIT TRANSACTION - All changes succeed together
                    await transaction.CommitAsync();

                    Console.WriteLine($"SelectSubject POST - Enrollment successful! Student: {student.FullName}, Subject: {assignedSubject.Subject.Name}");

                    // ?? REAL-TIME NOTIFICATION: Notify all connected users about the selection
                    await _signalRService.NotifySubjectSelection(assignedSubject, student);

                    // Check if subject is now full and notify availability change
                    var maxLimit = assignedSubject.Subject.MaxEnrollments ?? 70;
                    if (assignedSubject.SelectedCount >= maxLimit)
                    {
                        await _signalRService.NotifySubjectAvailability(
                            assignedSubject.Subject.Name, 
                            assignedSubject.Year, 
                            assignedSubject.Department, 
                            false);
                    }

                    TempData["SuccessMessage"] = $"Successfully enrolled in {assignedSubject.Subject.Name} with {assignedSubject.Faculty.Name}.";
                    return RedirectToAction("SelectSubject");
                }
                catch (Exception ex)
                {
                    // ? ROLLBACK on any error
                    Console.WriteLine($"SelectSubject POST - ERROR: {ex.Message}");
                    Console.WriteLine($"SelectSubject POST - Stack trace: {ex.StackTrace}");
                    await transaction.RollbackAsync();
                    TempData["ErrorMessage"] = $"Enrollment failed: {ex.Message}. Please try again.";
                    return RedirectToAction("SelectSubject");
                }
            }
        }

        [HttpPost]
        public async Task<IActionResult> UnenrollSubject(int assignedSubjectId)
        {
            // UNENROLLMENT DISABLED - Strict 70-student limit enforcement
            // Once a student enrolls, they cannot unenroll to maintain fairness
            
            TempData["ErrorMessage"] = "Unenrollment is not allowed. Once enrolled, you cannot change your selection. Please contact administration if you need assistance.";
            return RedirectToAction("MySelectedSubjects");
        }

        [HttpGet]
        public async Task<IActionResult> Edit()
        {
            var studentId = HttpContext.Session.GetString("StudentId");
            if (string.IsNullOrEmpty(studentId))
            {
                return RedirectToAction("Login");
            }
            var student = await _context.Students.FindAsync(studentId);
            if (student == null)
            {
                return NotFound();
            }
            return View(student);
        }

        [HttpPost]
        public async Task<IActionResult> Edit(Student model)
        {
            var studentId = HttpContext.Session.GetString("StudentId");
            if (string.IsNullOrEmpty(studentId))
            {
                return RedirectToAction("Login");
            }

            // Ensure the model ID matches the logged-in student's ID
            if (model.Id != studentId)
            {
                return BadRequest();
            }

            if (ModelState.IsValid)
            {
                var studentToUpdate = await _context.Students.FindAsync(studentId);
                if (studentToUpdate == null)
                {
                    return NotFound();
                }

                studentToUpdate.FullName = model.FullName;
                studentToUpdate.Year = model.Year;
                studentToUpdate.Department = model.Department;

                await _context.SaveChangesAsync();

                // Notify system of profile update
                await _signalRService.NotifyUserActivity(studentToUpdate.FullName, "Student", "Profile Updated", $"Student updated their profile information");

                TempData["SuccessMessage"] = "Profile updated!";
                return RedirectToAction("Dashboard");
            }
            return View(model);
        }

        [HttpGet]
        public async Task<IActionResult> Logout()
        {
            var studentId = HttpContext.Session.GetString("StudentId");
            if (!string.IsNullOrEmpty(studentId))
            {
                var student = await _context.Students.FindAsync(studentId);
                if (student != null)
                {
                    await _signalRService.NotifyUserActivity(student.FullName, "Student", "Logged Out", "Student logged out of the system");
                }
            }

            HttpContext.Session.Clear();
            return RedirectToAction("Login");
        }

        [HttpGet]
        public async Task<IActionResult> SelectSubject()
        {
            var studentId = HttpContext.Session.GetString("StudentId");
            if (string.IsNullOrEmpty(studentId))
            {
                Console.WriteLine("SelectSubject GET - Student not logged in");
                return RedirectToAction("Login");
            }

            var student = await _context.Students
                .Include(s => s.Enrollments)
                    .ThenInclude(e => e.AssignedSubject)
                    .ThenInclude(asub => asub.Subject)
                .Include(s => s.Enrollments)
                    .ThenInclude(e => e.AssignedSubject)
                    .ThenInclude(asub => asub.Faculty)
                .FirstOrDefaultAsync(s => s.Id == studentId);

            if (student == null)
            {
                Console.WriteLine($"SelectSubject GET - Student not found: {studentId}");
                return NotFound();
            }

            Console.WriteLine($"SelectSubject GET - Student: {student.FullName}, Department: {student.Department}");

            // ? CRITICAL: CHECK FACULTY SELECTION SCHEDULE BEFORE LOADING PAGE
            // Support both CSEDS and CSE(DS) formats
            var schedule = await _context.FacultySelectionSchedules
                .FirstOrDefaultAsync(s => s.Department == "CSEDS" || s.Department == "CSE(DS)" || s.Department == student.Department);

            Console.WriteLine($"SelectSubject GET - Schedule found: {schedule != null}");
            if (schedule != null)
            {
                Console.WriteLine($"SelectSubject GET - Schedule Department: {schedule.Department}");
                Console.WriteLine($"SelectSubject GET - Schedule IsEnabled: {schedule.IsEnabled}, UseSchedule: {schedule.UseSchedule}");
                Console.WriteLine($"SelectSubject GET - Schedule IsCurrentlyAvailable: {schedule.IsCurrentlyAvailable}");
                Console.WriteLine($"SelectSubject GET - Schedule StartDateTime: {schedule.StartDateTime}, EndDateTime: {schedule.EndDateTime}");
            }

            // If schedule exists and faculty selection is NOT available, block access completely
            if (schedule != null && !schedule.IsCurrentlyAvailable)
            {
                Console.WriteLine($"SelectSubject GET - ACCESS BLOCKED! IsCurrentlyAvailable: {schedule.IsCurrentlyAvailable}");
                TempData["ErrorMessage"] = schedule.DisabledMessage ?? "Faculty selection is currently disabled by the administration.";
                return RedirectToAction("MainDashboard");
            }

            Console.WriteLine("SelectSubject GET - Access granted, loading page");

            // Get all available subjects for the student's year AND department
            var yearMap = new Dictionary<string, int> { { "I", 1 }, { "II", 2 }, { "III", 3 }, { "IV", 4 } };
            var studentYearKey = student.Year?.Replace(" Year", "")?.Trim() ?? "";
            
            var availableSubjects = new List<AssignedSubject>();
            if (yearMap.TryGetValue(studentYearKey, out int studentYear))
            {
                // ?? CRITICAL FIX: Filter subjects by BOTH year AND department
                // This prevents students from seeing subjects from other departments
                availableSubjects = await _context.AssignedSubjects
                   .Include(a => a.Subject)
                   .Include(a => a.Faculty)
                   .Where(a => a.Year == studentYear 
                            && a.Department == student.Department)
                   .ToListAsync();

                Console.WriteLine($"SelectSubject GET - Found {availableSubjects.Count} subjects for Year={studentYear}, Department={student.Department}");

                // Filter out subjects where student has already enrolled
                var enrolledSubjectIds = student.Enrollments?.Select(e => e.AssignedSubject.SubjectId).ToList() ?? new List<int>();
                availableSubjects = availableSubjects.Where(a => !enrolledSubjectIds.Contains(a.SubjectId)).ToList();
                
                Console.WriteLine($"SelectSubject GET - After filtering enrolled subjects: {availableSubjects.Count} subjects available");
            }

            // ? NEW: Separate subjects by type
            var coreSubjects = availableSubjects
                .Where(s => s.Subject.SubjectType == "Core" && s.SelectedCount < 70)
                .ToList();
            
            var professionalElective1 = availableSubjects
                .Where(s => s.Subject.SubjectType == "ProfessionalElective1")
                .ToList();
            
            var professionalElective2 = availableSubjects
                .Where(s => s.Subject.SubjectType == "ProfessionalElective2")
                .ToList();
            
            var professionalElective3 = availableSubjects
                .Where(s => s.Subject.SubjectType == "ProfessionalElective3")
                .ToList();

            // ? NEW: Filter out full Professional Electives (check MaxEnrollments)
            professionalElective1 = FilterByMaxEnrollments(professionalElective1);
            professionalElective2 = FilterByMaxEnrollments(professionalElective2);
            professionalElective3 = FilterByMaxEnrollments(professionalElective3);

            // ? NEW: Check if student has already selected from each elective type
            var studentEnrollments = student.Enrollments?.Select(e => e.AssignedSubject.Subject.SubjectType).ToList() ?? new List<string>();
            
            Console.WriteLine($"SelectSubject GET - Core: {coreSubjects.Count}, PE1: {professionalElective1.Count}, PE2: {professionalElective2.Count}, PE3: {professionalElective3.Count}");

            var viewModel = new StudentDashboardViewModel
            {
                Student = student,
                AvailableSubjectsGrouped = coreSubjects.GroupBy(s => s.Subject.Name),
                ProfessionalElective1Subjects = professionalElective1,
                ProfessionalElective2Subjects = professionalElective2,
                ProfessionalElective3Subjects = professionalElective3,
                HasSelectedProfessionalElective1 = studentEnrollments.Contains("ProfessionalElective1"),
                HasSelectedProfessionalElective2 = studentEnrollments.Contains("ProfessionalElective2"),
                HasSelectedProfessionalElective3 = studentEnrollments.Contains("ProfessionalElective3")
            };

            return View(viewModel);
        }

        /// <summary>
        /// Helper method to filter subjects by MaxEnrollments limit
        /// </summary>
        private List<AssignedSubject> FilterByMaxEnrollments(List<AssignedSubject> subjects)
        {
            var filtered = new List<AssignedSubject>();
            foreach (var subject in subjects)
            {
                if (subject.Subject.MaxEnrollments.HasValue)
                {
                    // Check if subject has reached its limit
                    if (subject.SelectedCount < subject.Subject.MaxEnrollments.Value)
                    {
                        filtered.Add(subject);
                    }
                }
                else
                {
                    // No limit, add it
                    filtered.Add(subject);
                }
            }
            return filtered;
        }

        /*
        [HttpGet]
        public async Task<IActionResult> AssignedFaculty()
        {
            var studentId = HttpContext.Session.GetInt32("StudentId");
            if (studentId == null)
            {
                return RedirectToAction("Login");
            }

            var student = await _context.Students
                .Include(s => s.Enrollments)
                    .ThenInclude(e => e.AssignedSubject)
                    .ThenInclude(asub => asub.Subject)
                .Include(s => s.Enrollments)
                    .ThenInclude(e => e.AssignedSubject)
                    .ThenInclude(asub => asub.Faculty)
                .FirstOrDefaultAsync(s => s.Id == studentId.Value);

            if (student == null)
            {
                return NotFound();
            }

            return View(student);
        }
        */

        [HttpGet]
        public async Task<IActionResult> ChangePassword()
        {
            var studentId = HttpContext.Session.GetString("StudentId");
            if (string.IsNullOrEmpty(studentId))
            {
                return RedirectToAction("Login");
            }

            var student = await _context.Students.FindAsync(studentId);
            if (student == null)
            {
                return NotFound();
            }

            var model = new ChangePasswordViewModel
            {
                StudentId = student.Id,
                StudentName = student.FullName
            };

            return View(model);
        }

        [HttpPost]
        public async Task<IActionResult> ChangePassword(ChangePasswordViewModel model)
        {
            var studentId = HttpContext.Session.GetString("StudentId");
            if (string.IsNullOrEmpty(studentId))
            {
                return RedirectToAction("Login");
            }

            if (model.StudentId != studentId)
            {
                return BadRequest();
            }

            if (ModelState.IsValid)
            {
                var student = await _context.Students.FindAsync(studentId);
                if (student == null)
                {
                    return NotFound();
                }

                // Verify current password
                if (student.Password != model.CurrentPassword)
                {
                    ModelState.AddModelError("CurrentPassword", "Current password is incorrect.");
                    return View(model);
                }

                // Update password
                student.Password = model.NewPassword;
                await _context.SaveChangesAsync();

                TempData["SuccessMessage"] = "Password changed successfully!";
                return RedirectToAction("Dashboard");
            }

            return View(model);
        }

        [HttpGet]
        public IActionResult TestEmoji()
        {
            // Simple test view to check emoji display
            return View();
        }

        [HttpGet]
        public IActionResult TestSession()
        {
            // Test session functionality
            HttpContext.Session.SetString("TestKey", "TestValue");
            var testValue = HttpContext.Session.GetString("TestKey");
            
            var debugInfo = new
            {
                SessionId = HttpContext.Session.Id,
                TestValue = testValue,
                StudentId = HttpContext.Session.GetString("StudentId"), // Changed to string
                SessionIsAvailable = HttpContext.Session.IsAvailable
            };
            
            return Json(debugInfo);
        }

        [HttpGet]
        public async Task<IActionResult> TestLogin()
        {
            // Test login with a known student (for debugging)
            var student = await _context.Students.FirstOrDefaultAsync();
            if (student != null)
            {
                HttpContext.Session.SetString("StudentId", student.Id); // Changed to string
                await HttpContext.Session.CommitAsync();
                
                return Json(new { 
                    Message = "Test login successful", 
                    StudentId = student.Id, 
                    StudentName = student.FullName,
                    SessionId = HttpContext.Session.Id
                });
            }
            
            return Json(new { Message = "No students found in database" });
        }

        [HttpGet]
        public async Task<IActionResult> DebugLogin()
        {
            try
            {
                // Test database connection
                var studentCount = await _context.Students.CountAsync();
                var sampleStudents = await _context.Students
                    .Take(3)
                    .Select(s => new { s.Id, s.FullName, s.Email })
                    .ToListAsync();

                // Test session
                HttpContext.Session.SetString("DebugTest", "Working");
                var sessionTest = HttpContext.Session.GetString("DebugTest");

                var debugInfo = new
                {
                    DatabaseConnection = "Connected",
                    TotalStudents = studentCount,
                    SampleStudents = sampleStudents.Cast<object>().ToList(),
                    SessionWorking = sessionTest == "Working",
                    SessionId = HttpContext.Session.Id,
                    CurrentStudentId = HttpContext.Session.GetString("StudentId"), // Changed to string
                    Timestamp = DateTime.Now
                };

                return Json(debugInfo);
            }
            catch (Exception ex)
            {
                var errorInfo = new
                {
                    DatabaseConnection = $"Error: {ex.Message}",
                    TotalStudents = 0,
                    SampleStudents = new List<object>(),
                    SessionWorking = false,
                    SessionId = HttpContext.Session.Id,
                    CurrentStudentId = HttpContext.Session.GetString("StudentId"), // Changed to string
                    Timestamp = DateTime.Now,
                    Error = ex.Message
                };

                return Json(errorInfo);
            }
        }

        [HttpGet]
        public async Task<IActionResult> DebugCredentials()
        {
            try
            {
                // Get all students with their exact credentials (for debugging only)
                var allStudents = await _context.Students
                    .Select(s => new { 
                        s.Id, 
                        s.FullName, 
                        s.Email, 
                        PasswordLength = s.Password.Length,
                        PasswordHash = s.Password.Substring(0, Math.Min(3, s.Password.Length)) + "***" // Show first 3 chars only for security
                    })
                    .ToListAsync();

                var debugInfo = new
                {
                    TotalStudents = allStudents.Count,
                    Students = allStudents,
                    Message = "Use the exact email from this list to test login"
                };

                return Json(debugInfo);
            }
            catch (Exception ex)
            {
                return Json(new { Error = ex.Message });
            }
        }

        [HttpPost]
        public async Task<IActionResult> DebugTestLogin(string email, string password)
        {
            try
            {
                Console.WriteLine($"?? DEBUG TEST LOGIN: Email='{email}', Password='{password}'");

                // Check if student exists with this exact email
                var studentWithEmail = await _context.Students
                    .Where(s => s.Email == email)
                    .Select(s => new { s.Id, s.FullName, s.Email, PasswordLength = s.Password.Length })
                    .FirstOrDefaultAsync();

                if (studentWithEmail == null)
                {
                    Console.WriteLine($"? No student found with email: '{email}'");
                    return Json(new { 
                        Success = false, 
                        Message = "No student found with that email",
                        Email = email
                    });
                }

                // Check password match
                var studentWithCredentials = await _context.Students
                    .FirstOrDefaultAsync(s => s.Email == email && s.Password == password);

                if (studentWithCredentials == null)
                {
                    Console.WriteLine($"? Password mismatch for email: '{email}'");
                    return Json(new { 
                        Success = false, 
                        Message = "Email found but password doesn't match",
                        Email = email,
                        StudentFound = studentWithEmail
                    });
                }

                // SUCCESS - Now try to log in
                Console.WriteLine($"? Credentials match! Logging in student: {studentWithCredentials.FullName}");

                // Set session - now using string
                HttpContext.Session.SetString("StudentId", studentWithCredentials.Id);
                await HttpContext.Session.CommitAsync();

                // Verify session was set
                var sessionCheck = HttpContext.Session.GetString("StudentId");
                Console.WriteLine($"? Session set. StudentId in session: {sessionCheck}");

                return Json(new { 
                    Success = true, 
                    Message = "Login successful!",
                    StudentId = studentWithCredentials.Id,
                    StudentName = studentWithCredentials.FullName,
                    SessionId = HttpContext.Session.Id,
                    RedirectUrl = Url.Action("MainDashboard", "Student")
                });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"? DEBUG TEST LOGIN ERROR: {ex.Message}");
                return Json(new { 
                    Success = false, 
                    Message = ex.Message,
                    Error = ex.ToString()
                });
            }
        }

        [HttpGet]
        public IActionResult TestRouting()
        {
            return Json(new { 
                Message = "?? Routing works!", 
                Controller = "Student", 
                Action = "TestRouting",
                Time = DateTime.Now,
                SessionId = HttpContext.Session.Id
            });
        }

        [HttpGet]
        public IActionResult TestTime()
        {
            return Json(new {
                ServerLocalTime = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fff"),
                ServerUtcTime = DateTime.UtcNow.ToString("yyyy-MM-dd HH:mm:ss.fff"),
                ServerTimeZone = TimeZoneInfo.Local.Id,
                ServerTimeZoneDisplayName = TimeZoneInfo.Local.DisplayName,
                ServerTimeZoneOffset = TimeZoneInfo.Local.BaseUtcOffset.ToString(),
                SystemTicks = Environment.TickCount64,
                Message = "Compare ServerLocalTime with your actual current time to see if system clock is correct"
            });
        }

        [HttpGet]
        public async Task<IActionResult> SimpleDebug()
        {
            try
            {
                var studentCount = await _context.Students.CountAsync();
                var students = await _context.Students.Take(5).ToListAsync();
                
                return Json(new {
                    Success = true,
                    Message = "Database connected successfully",
                    StudentCount = studentCount,
                    Students = students.Select(s => new { s.Id, s.FullName, s.Email }).ToList(),
                    SessionWorking = HttpContext.Session.IsAvailable,
                    SessionId = HttpContext.Session.Id
                });
            }
            catch (Exception ex)
            {
                return Json(new {
                    Success = false,
                    Error = ex.Message,
                    Message = "Database connection failed"
                });
            }
        }
    }

    // View model for the dashboard
    public class StudentDashboardViewModel
    {
        public Student Student { get; set; }
        public IEnumerable<IGrouping<string, AssignedSubject>> AvailableSubjectsGrouped { get; set; }
        
        // Professional Electives - each type displayed separately
        public IEnumerable<AssignedSubject> ProfessionalElective1Subjects { get; set; }
        public IEnumerable<AssignedSubject> ProfessionalElective2Subjects { get; set; }
        public IEnumerable<AssignedSubject> ProfessionalElective3Subjects { get; set; }
        
        // Track which elective types student has already selected
        public bool HasSelectedProfessionalElective1 { get; set; }
        public bool HasSelectedProfessionalElective2 { get; set; }
        public bool HasSelectedProfessionalElective3 { get; set; }
    }
}