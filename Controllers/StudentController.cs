using Microsoft.AspNetCore.Mvc;
using TutorLiveMentor.Helpers;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using TutorLiveMentor.Models;
using TutorLiveMentor.Services;
using TutorLiveMentor.Attributes;

namespace TutorLiveMentor.Controllers
{
    public class StudentController : Controller
    {
        private readonly AppDbContext _context;
        private readonly SignalRService _signalRService;
        private readonly SubjectSelectionValidator _selectionValidator;

        public StudentController(AppDbContext context, SignalRService signalRService)
        {
            _context = context;
            _signalRService = signalRService;
            _selectionValidator = new SubjectSelectionValidator(context);
        }

        [HttpGet]
        [AllowAnonymous]
        public IActionResult Index()
        {
            return View();
        }

        [HttpGet]
        [AllowAnonymous]
        public IActionResult Register()
        {
            return View();
        }

        [HttpPost]
        [AllowAnonymous]
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
        [AllowAnonymous]
        public IActionResult Login()
        {
            return View();
        }

        [HttpPost]
        [AllowAnonymous]
        public async Task<IActionResult> Login(LoginViewModel model)
        {
            // Simple, reliable login without complex debugging
            if (!ModelState.IsValid)
            {
                return View(model);
            }

            try
            {
                // Finds student with matching credentials
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
                HttpContext.Session.SetString("LastActivity", DateTime.Now.ToString("o"));

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
        [StudentAuthorize]
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

            // Check if student is in selection process and hasn't completed it
            var isInSelectionProcess = HttpContext.Session.GetString("IsInSelectionProcess");
            var selectionCompleted = HttpContext.Session.GetString("SelectionCompleted");

            if (isInSelectionProcess == "true" && selectionCompleted != "true")
            {
                // Check if student has actually completed all selections
                var hasCompleted = await _selectionValidator.HasCompletedAllSelections(studentId);
                
                if (!hasCompleted)
                {
                    TempData["ErrorMessage"] = "Please complete all subject selections before accessing other pages. Select all available core subjects and professional electives.";
                    return RedirectToAction("SelectSubject");
                }
                else
                {
                    // Mark selection as completed
                    HttpContext.Session.SetString("SelectionCompleted", "true");
                    HttpContext.Session.Remove("IsInSelectionProcess");
                }
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

            // ?? ENHANCED: Use OR condition for consistent schedule checking instead of DepartmentNormalizer in query
            Console.WriteLine($"MainDashboard - Student Department: {student.Department}");

            // Check faculty selection schedule - now using standardized CSE(DS) only
            // Get schedule by normalized department (FIXED)
            var normalizedDept = DepartmentNormalizer.Normalize(student.Department);
            var schedule = await _context.FacultySelectionSchedules
                .FirstOrDefaultAsync(s => s.Department == normalizedDept);

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

            // Check if student's department matches schedule department using normalizer
            var isAvailable = schedule == null || schedule.IsCurrentlyAvailable;
            if (schedule != null)
            {
                var normalizedStudentDept = DepartmentNormalizer.Normalize(student.Department);
                var normalizedScheduleDept = DepartmentNormalizer.Normalize(schedule.Department);
                if (normalizedStudentDept != normalizedScheduleDept)
                {
                    // Student is not in CSEDS department, so schedule doesn't apply
                    isAvailable = true;
                }
            }
            
            Console.WriteLine($"MainDashboard - Final IsSelectionAvailable: {isAvailable}");

            // Set ALL ViewBag properties with student info
            ViewBag.StudentId = studentId;
            ViewBag.StudentName = student.FullName;
            ViewBag.StudentRegdNumber = student.RegdNumber;
            ViewBag.StudentYear = student.Year;
            ViewBag.StudentDepartment = DepartmentNormalizer.Normalize(student.Department); // Apply normalizer for display
            ViewBag.IsSelectionAvailable = isAvailable;
            ViewBag.ScheduleMessage = schedule?.DisabledMessage ?? "";
            ViewBag.ScheduleStatus = schedule?.StatusDescription ?? "Always Available";
            
            return View();
        }

        [HttpGet]
        [StudentAuthorize]
        public async Task<IActionResult> MySelectedSubjects()
        {
            var studentId = HttpContext.Session.GetString("StudentId");
            if (string.IsNullOrEmpty(studentId))
            {
                return RedirectToAction("Login");
            }

            // Check if student is in selection process and hasn't completed it
            var isInSelectionProcess = HttpContext.Session.GetString("IsInSelectionProcess");
            var selectionCompleted = HttpContext.Session.GetString("SelectionCompleted");

            if (isInSelectionProcess == "true" && selectionCompleted != "true")
            {
                // Check if student has actually completed all selections
                var hasCompleted = await _selectionValidator.HasCompletedAllSelections(studentId);
                
                if (!hasCompleted)
                {
                    TempData["ErrorMessage"] = "Please complete all subject selections before accessing other pages. Select all available core subjects and professional electives.";
                    return RedirectToAction("SelectSubject");
                }
                else
                {
                    // Mark selection as completed
                    HttpContext.Session.SetString("SelectionCompleted", "true");
                    HttpContext.Session.Remove("IsInSelectionProcess");
                }
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
        [StudentAuthorize]
        public async Task<IActionResult> Dashboard()
        {
            var studentId = HttpContext.Session.GetString("StudentId");
            if (string.IsNullOrEmpty(studentId))
            {
                return RedirectToAction("Login");
            }

            // Check if student is in selection process and hasn't completed it
            var isInSelectionProcess = HttpContext.Session.GetString("IsInSelectionProcess");
            var selectionCompleted = HttpContext.Session.GetString("SelectionCompleted");

            if (isInSelectionProcess == "true" && selectionCompleted != "true")
            {
                // Check if student has actually completed all selections
                var hasCompleted = await _selectionValidator.HasCompletedAllSelections(studentId);
                
                if (!hasCompleted)
                {
                    TempData["ErrorMessage"] = "Please complete all subject selections before accessing other pages. Select all available core subjects and professional electives.";
                    return RedirectToAction("SelectSubject");
                }
                else
                {
                    // Mark selection as completed
                    HttpContext.Session.SetString("SelectionCompleted", "true");
                    HttpContext.Session.Remove("IsInSelectionProcess");
                }
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
        [StudentAuthorize]
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

                    // ?? ENHANCED: CRITICAL FACULTY SELECTION SCHEDULE CHECK WITH OR CONDITION
                    Console.WriteLine($"SelectSubject POST - Student Department: {student.Department}");
                    
                    // Get schedule by normalized department (FIXED)
                    
                    var normalizedDept = DepartmentNormalizer.Normalize(student.Department);
                    
                    var schedule = await _context.FacultySelectionSchedules
                    
                        .FirstOrDefaultAsync(s => s.Department == normalizedDept);

                    Console.WriteLine($"SelectSubject POST - Schedule found: {schedule != null}");
                    if (schedule != null)
                    {
                        Console.WriteLine($"SelectSubject POST - Schedule Department: {schedule.Department}");
                        Console.WriteLine($"SelectSubject POST - Schedule IsEnabled: {schedule.IsEnabled}, UseSchedule: {schedule.UseSchedule}");
                        Console.WriteLine($"SelectSubject POST - Schedule IsCurrentlyAvailable: {schedule.IsCurrentlyAvailable}");
                    }

                    // ?? Check if schedule applies to this student and if selection is blocked
                    if (schedule != null)
                    {
                        var studentNormalizedDept = DepartmentNormalizer.Normalize(student.Department);
                        var scheduleNormalizedDept = DepartmentNormalizer.Normalize(schedule.Department);
                        
                        if (studentNormalizedDept == scheduleNormalizedDept && !schedule.IsCurrentlyAvailable)
                        {
                            Console.WriteLine($"SelectSubject POST - ENROLLMENT BLOCKED! Reason: {schedule.DisabledMessage}");
                            await transaction.RollbackAsync();
                            TempData["ErrorMessage"] = schedule.DisabledMessage ?? "Faculty selection is currently disabled. You cannot enroll in subjects at this time.";
                            return RedirectToAction("MainDashboard");
                        }
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

                    // ?? ENHANCED: Verify the assigned subject belongs to the student's department
                    var subjectNormalizedDept = DepartmentNormalizer.Normalize(assignedSubject.Subject.Department);
                    var studentDeptNormalized = DepartmentNormalizer.Normalize(student.Department);
                    if (subjectNormalizedDept != studentDeptNormalized)
                    {
                        Console.WriteLine($"SelectSubject POST - DEPARTMENT MISMATCH! Student: {studentDeptNormalized}, Subject: {subjectNormalizedDept}");
                        await transaction.RollbackAsync();
                        TempData["ErrorMessage"] = "You can only enroll in subjects from your own department.";
                        return RedirectToAction("SelectSubject");
                    }

                    // NEW: Check if this is a Professional Elective subject
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
                        
                        // NEW: Check MaxEnrollments for Professional Electives
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

                    // ?? CRITICAL CHECK: Re-verify count within transaction to prevent race conditions
                    // Get the ACTUAL current count from database, not cached value
                    var currentCount = await _context.StudentEnrollments
                        .CountAsync(e => e.AssignedSubjectId == assignedSubjectId);

                    Console.WriteLine($"SelectSubject POST - Current enrollment count: {currentCount}");

                    // Check enrollment limit based on Subject's MaxEnrollments (handles Year 2=60, Year 3/4=70)
                    var maxLimit = assignedSubject.Subject.MaxEnrollments ?? 70; // Default to 70 if not set
                    
                    if (assignedSubject.Subject.SubjectType == "Core" && currentCount >= maxLimit)
                    {
                        Console.WriteLine($"SelectSubject POST - Subject is full ({maxLimit} students)");
                        await transaction.RollbackAsync();
                        TempData["ErrorMessage"] = $"This subject is already full (maximum {maxLimit} students). Someone enrolled just before you.";
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
                    
                    // ?? COMMIT TRANSACTION - All changes succeed together
                    await transaction.CommitAsync();

                    Console.WriteLine($"SelectSubject POST - Enrollment successful! Student: {student.FullName}, Subject: {assignedSubject.Subject.Name}");

                    // ?? REAL-TIME NOTIFICATION: Notify all connected users about the selection
                    await _signalRService.NotifySubjectSelection(assignedSubject, student);

                    // Check if subject is now full and notify availability change
                    var limit = assignedSubject.Subject.MaxEnrollments ?? 70;
                    if (assignedSubject.SelectedCount >= limit)
                    {
                        await _signalRService.NotifySubjectAvailability(
                            assignedSubject.Subject.Name, 
                            assignedSubject.Year, 
                            assignedSubject.Department, 
                            false);
                    }

                    // Check if all selections are complete
                    var allSelectionsComplete = await _selectionValidator.HasCompletedAllSelections(studentId);
                    if (allSelectionsComplete)
                    {
                        HttpContext.Session.SetString("SelectionCompleted", "true");
                        HttpContext.Session.Remove("IsInSelectionProcess");
                        TempData["SuccessMessage"] = $"Successfully enrolled in {assignedSubject.Subject.Name} with {assignedSubject.Faculty.Name}. All selections completed!";
                    }
                    else
                    {
                        TempData["SuccessMessage"] = $"Successfully enrolled in {assignedSubject.Subject.Name} with {assignedSubject.Faculty.Name}. Please complete remaining selections.";
                    }

                    return RedirectToAction("SelectSubject");
                }
                catch (Exception ex)
                {
                    // ?? ROLLBACK on any error
                    Console.WriteLine($"SelectSubject POST - ERROR: {ex.Message}");
                    Console.WriteLine($"SelectSubject POST - Stack trace: {ex.StackTrace}");
                    await transaction.RollbackAsync();
                    TempData["ErrorMessage"] = $"Enrollment failed: {ex.Message}. Please try again.";
                    return RedirectToAction("SelectSubject");
                }
            }
        }

        [HttpPost]
        [StudentAuthorize]
        public async Task<IActionResult> UnenrollSubject(int assignedSubjectId)
        {
            // UNENROLLMENT DISABLED - Strict 70-student limit enforcement
            // Once a student enrolls, they cannot unenroll to maintain fairness
            
            TempData["ErrorMessage"] = "Unenrollment is not allowed. Once enrolled, you cannot change your selection. Please contact administration if you need assistance.";
            return RedirectToAction("MySelectedSubjects");
        }

        [HttpGet]
        [StudentAuthorize]
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
        [StudentAuthorize]
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
        [AllowAnonymous]
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
        [StudentAuthorize]
        public async Task<IActionResult> SelectSubject()
        {
            var studentId = HttpContext.Session.GetString("StudentId");
            if (string.IsNullOrEmpty(studentId))
            {
                Console.WriteLine("SelectSubject GET - Student not logged in");
                return RedirectToAction("Login");
            }

            // Set session flag to indicate student is in selection process
            HttpContext.Session.SetString("IsInSelectionProcess", "true");
            HttpContext.Session.Remove("SelectionCompleted");

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

            Console.WriteLine($"SelectSubject GET - Student: {student.FullName}, Department: '{student.Department}'");

            // ?? ENHANCED: CRITICAL FACULTY SELECTION SCHEDULE CHECK WITH OR CONDITION
            // Get schedule by normalized department (FIXED)
            var normalizedDept = DepartmentNormalizer.Normalize(student.Department);
            var schedule = await _context.FacultySelectionSchedules
                .FirstOrDefaultAsync(s => s.Department == normalizedDept);

            if (schedule != null)
            {
                Console.WriteLine($"SelectSubject GET - Schedule Department: {schedule.Department}");
                Console.WriteLine($"SelectSubject GET - Schedule IsEnabled: {schedule.IsEnabled}, UseSchedule: {schedule.UseSchedule}");
                Console.WriteLine($"SelectSubject GET - Schedule IsCurrentlyAvailable: {schedule.IsCurrentlyAvailable}");
            }

            // ?? Check if schedule applies to this student and if selection is blocked
            if (schedule != null)
            {
                var studentNormalizedDept = DepartmentNormalizer.Normalize(student.Department);
                var scheduleNormalizedDept = DepartmentNormalizer.Normalize(schedule.Department);
                
                if (studentNormalizedDept == scheduleNormalizedDept && !schedule.IsCurrentlyAvailable)
                {
                    Console.WriteLine($"SelectSubject GET - ACCESS BLOCKED! IsCurrentlyAvailable: {schedule.IsCurrentlyAvailable}");
                    TempData["ErrorMessage"] = schedule.DisabledMessage ?? "Faculty selection is currently disabled by the administration.";
                    return RedirectToAction("MainDashboard");
                }
            }

            Console.WriteLine("SelectSubject GET - Access granted, loading page");

            // Enhanced year parsing that handles BOTH formats
            int studentYear = ParseStudentYear(student.Year);
            
            var availableSubjects = new List<AssignedSubject>();
            if (studentYear > 0)
            {
                // Normalize student department first
                var normalizedStudentDept = DepartmentNormalizer.Normalize(student.Department);
                
                Console.WriteLine($"SelectSubject GET - Student normalized dept: '{normalizedStudentDept}'");
                Console.WriteLine($"SelectSubject GET - Student Year: {student.Year} -> {studentYear}");
                
                // Get ALL assigned subjects for the year first (no department filter in SQL)
                var allYearSubjects = await _context.AssignedSubjects
                   .Include(a => a.Subject)
                   .Include(a => a.Faculty)
                   .Where(a => a.Year == studentYear)
                   .ToListAsync();
                
                Console.WriteLine($"SelectSubject GET - Found {allYearSubjects.Count} total subjects for Year={studentYear}");
                
                // ENHANCED LOGGING: Log all subjects with their exact departments
                foreach (var subj in allYearSubjects)
                {
                    var subjRaw = subj.Subject.Department;
                    var subjNormalized = DepartmentNormalizer.Normalize(subjRaw);
                    var matches = (subjNormalized == normalizedStudentDept);
                    Console.WriteLine($"  - {subj.Subject.Name} | Raw: '{subjRaw}' -> Normalized: '{subjNormalized}' | Match: {matches} | Type: {subj.Subject.SubjectType}");
                }
                
                // Filter by normalized department in memory
                availableSubjects = allYearSubjects
                    .Where(a => {
                        var subjNormalized = DepartmentNormalizer.Normalize(a.Subject.Department);
                        var matches = subjNormalized == normalizedStudentDept;
                        if (!matches)
                        {
                            Console.WriteLine($"  FILTERED OUT: {a.Subject.Name} ('{a.Subject.Department}' -> '{subjNormalized}' != '{normalizedStudentDept}')");
                        }
                        return matches;
                    })
                    .ToList();

                Console.WriteLine($"SelectSubject GET - After department filter: {availableSubjects.Count} subjects for Department='{normalizedStudentDept}'");

                // Filter out subjects where student has already enrolled
                var enrolledSubjectIds = student.Enrollments?.Select(e => e.AssignedSubject.SubjectId).ToList() ?? new List<int>();
                availableSubjects = availableSubjects.Where(a => !enrolledSubjectIds.Contains(a.SubjectId)).ToList();
                
                Console.WriteLine($"SelectSubject GET - After filtering enrolled subjects: {availableSubjects.Count} subjects available");
            }
            else
            {
                Console.WriteLine($"SelectSubject GET - ERROR: Could not parse student year '{student.Year}' (format not recognized)");
            }

            // Separate subjects by type
            var coreSubjects = availableSubjects
                .Where(s => s.Subject.SubjectType == "Core" && 
                           s.SelectedCount < (s.Subject.MaxEnrollments ?? 70))
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

            // Filter out full Professional Electives (check MaxEnrollments)
            professionalElective1 = FilterByMaxEnrollments(professionalElective1);
            professionalElective2 = FilterByMaxEnrollments(professionalElective2);
            professionalElective3 = FilterByMaxEnrollments(professionalElective3);

            // Check if student has already selected from each elective type
            var studentEnrollments = student.Enrollments?.Select(e => e.AssignedSubject.Subject.SubjectType).ToList() ?? new List<string>();

            // Check which electives have been selected
            var hasSelectedPE1 = studentEnrollments.Contains("ProfessionalElective1");
            var hasSelectedPE2 = studentEnrollments.Contains("ProfessionalElective2");
            var hasSelectedPE3 = studentEnrollments.Contains("ProfessionalElective3");

            // Clear the lists if already selected to hide the cards completely
            if (hasSelectedPE1)
            {
                professionalElective1 = new List<AssignedSubject>();
            }
            if (hasSelectedPE2)
            {
                professionalElective2 = new List<AssignedSubject>();
            }
            if (hasSelectedPE3)
            {
                professionalElective3 = new List<AssignedSubject>();
            }

            Console.WriteLine($"SelectSubject GET - Core: {coreSubjects.Count}, PE1: {professionalElective1.Count}, PE2: {professionalElective2.Count}, PE3: {professionalElective3.Count}");

            var viewModel = new StudentDashboardViewModel
            {
                Student = student,
                AvailableSubjectsGrouped = coreSubjects.GroupBy(s => s.Subject.Name),
                ProfessionalElective1Subjects = professionalElective1,
                ProfessionalElective2Subjects = professionalElective2,
                ProfessionalElective3Subjects = professionalElective3,
                HasSelectedProfessionalElective1 = hasSelectedPE1,
                HasSelectedProfessionalElective2 = hasSelectedPE2,
                HasSelectedProfessionalElective3 = hasSelectedPE3
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

        /// <summary>
        /// Parse student year string to integer, handling BOTH formats:
        /// - Roman numerals: "I Year", "II Year", "III Year", "IV Year" ? 1, 2, 3, 4
        /// - Numeric: "1", "2", "3", "4" ? 1, 2, 3, 4
        /// Returns 0 if format is invalid
        /// </summary>
        private int ParseStudentYear(string? yearString)
        {
            if (string.IsNullOrWhiteSpace(yearString))
            {
                Console.WriteLine("?? ParseStudentYear: Year string is null or empty");
                return 0;
            }

            // Remove " Year" suffix if present (handles "II Year" ? "II")
            var yearKey = yearString.Replace(" Year", "").Trim();
            
            Console.WriteLine($"ParseStudentYear: Input='{yearString}' ? Key='{yearKey}'");

            // Try Roman numerals first (case-insensitive)
            var romanMap = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase)
            {
                { "I", 1 },
                { "II", 2 },
                { "III", 3 },
                { "IV", 4 }
            };
            
            if (romanMap.TryGetValue(yearKey, out int romanYear))
            {
                Console.WriteLine($"? ParseStudentYear: Matched Roman numeral '{yearKey}' ? {romanYear}");
                return romanYear;
            }

            // Try numeric format as fallback (handles "3" ? 3)
            if (int.TryParse(yearKey, out int numericYear) && numericYear >= 1 && numericYear <= 4)
            {
                Console.WriteLine($"? ParseStudentYear: Matched numeric '{yearKey}' ? {numericYear}");
                return numericYear;
            }

            // Log error if format is unrecognized
            Console.WriteLine($"? ParseStudentYear: Unrecognized format '{yearString}' (key: '{yearKey}')");
            return 0;
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
