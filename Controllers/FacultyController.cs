using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TutorLiveMentor.Models;
using TutorLiveMentor.Services;
using System.Linq;
using System.Collections.Generic;

namespace TutorLiveMentor.Controllers
{
    /// <summary>
    /// Controller for managing faculty-related operations
    /// </summary>
    public class FacultyController : Controller
    {
        private readonly AppDbContext _context;
        private readonly SignalRService _signalRService;

        public FacultyController(AppDbContext context, SignalRService signalRService)
        {
            _context = context;
            _signalRService = signalRService;
        }

        [HttpGet]
        public IActionResult Login()
        {
            return View();
        }

        [HttpPost]
        public async Task<IActionResult> Login(FacultyLoginViewModel model)
        {
            if (!ModelState.IsValid) 
                return View(model);

            try
            {
                var faculty = await _context.Faculties
                    .FirstOrDefaultAsync(f => f.Email == model.Email && f.Password == model.Password);

                if (faculty == null)
                {
                    ModelState.AddModelError("", "Invalid credentials!");
                    return View(model);
                }

                // Clear any existing session
                HttpContext.Session.Clear();

                // Store faculty ID and department in session
                HttpContext.Session.SetInt32("FacultyId", faculty.FacultyId);
                HttpContext.Session.SetString("FacultyName", faculty.Name);
                HttpContext.Session.SetString("FacultyDepartment", faculty.Department);

                // Force session to be saved immediately
                await HttpContext.Session.CommitAsync();

                return RedirectToAction("MainDashboard");
            }
            catch (Exception ex)
            {
                ModelState.AddModelError("", $"Login error: {ex.Message}");
                return View(model);
            }
        }

        [HttpGet]
        public IActionResult MainDashboard()
        {
            var facultyId = HttpContext.Session.GetInt32("FacultyId");
            
            if (facultyId == null)
            {
                TempData["ErrorMessage"] = "Please login to access the dashboard.";
                return RedirectToAction("Login");
            }

            ViewBag.FacultyId = facultyId;
            ViewBag.FacultyName = HttpContext.Session.GetString("FacultyName");
            ViewBag.FacultyDepartment = HttpContext.Session.GetString("FacultyDepartment");
            
            return View();
        }

        [HttpGet]
        public IActionResult Dashboard()
        {
            var facultyId = HttpContext.Session.GetInt32("FacultyId");
            if (facultyId == null) return RedirectToAction("Login");

            var faculty = _context.Faculties
                .Include(f => f.AssignedSubjects)
                .FirstOrDefault(f => f.FacultyId == facultyId.Value);

            return View(faculty);
        }

        [HttpGet]
        public IActionResult Profile()
        {
            var facultyId = HttpContext.Session.GetInt32("FacultyId");
            if (facultyId == null) return RedirectToAction("Login");

            var faculty = _context.Faculties.FirstOrDefault(f => f.FacultyId == facultyId.Value);
            return View(faculty);
        }

        // ----------- EDIT PROFILE ----------
        [HttpGet]
        public IActionResult EditProfile()
        {
            var facultyId = HttpContext.Session.GetInt32("FacultyId");
            if (facultyId == null) return RedirectToAction("Login");

            var faculty = _context.Faculties.FirstOrDefault(f => f.FacultyId == facultyId.Value);
            if (faculty == null) return RedirectToAction("Login");

            // Map Faculty to FacultyEditProfileViewModel
            var viewModel = new FacultyEditProfileViewModel
            {
                FacultyId = faculty.FacultyId,
                Name = faculty.Name,
                Email = faculty.Email,
                Department = faculty.Department
            };

            return View(viewModel);
        }

        [HttpPost]
        public async Task<IActionResult> EditProfile(FacultyEditProfileViewModel model)
        {
            var facultyId = HttpContext.Session.GetInt32("FacultyId");
            if (facultyId == null) return RedirectToAction("Login");

            // Ensure the model ID matches the logged-in faculty's ID
            if (model.FacultyId != facultyId.Value)
            {
                return BadRequest();
            }

            // Custom validation for password change
            if (!string.IsNullOrEmpty(model.CurrentPassword) || !string.IsNullOrEmpty(model.NewPassword) || !string.IsNullOrEmpty(model.ConfirmPassword))
            {
                // If any password field is filled, all three must be filled
                if (string.IsNullOrEmpty(model.CurrentPassword))
                {
                    ModelState.AddModelError("CurrentPassword", "Current password is required to change password");
                }
                if (string.IsNullOrEmpty(model.NewPassword))
                {
                    ModelState.AddModelError("NewPassword", "New password is required");
                }
                if (string.IsNullOrEmpty(model.ConfirmPassword))
                {
                    ModelState.AddModelError("ConfirmPassword", "Please confirm your new password");
                }
            }

            if (!ModelState.IsValid)
            {
                return View(model);
            }

            var faculty = _context.Faculties.FirstOrDefault(f => f.FacultyId == model.FacultyId);
            if (faculty == null)
            {
                return RedirectToAction("Profile");
            }

            // Update basic profile properties
            faculty.Name = model.Name;
            faculty.Email = model.Email;
            faculty.Department = model.Department;

            // Handle password change if requested
            bool passwordChanged = false;
            if (!string.IsNullOrEmpty(model.CurrentPassword))
            {
                // Verify current password
                if (faculty.Password != model.CurrentPassword)
                {
                    ModelState.AddModelError("CurrentPassword", "Current password is incorrect");
                    return View(model);
                }

                // Update to new password
                faculty.Password = model.NewPassword!;
                passwordChanged = true;
            }

            _context.SaveChanges();

            // Update session with new department info
            HttpContext.Session.SetString("FacultyDepartment", faculty.Department);

            // 🚀 REAL-TIME NOTIFICATION: Notify system of profile update
            string activityMessage = passwordChanged 
                ? "Faculty member updated profile and changed password" 
                : "Faculty member updated profile information";
            await _signalRService.NotifyUserActivity(faculty.Name, "Faculty", "Profile Updated", activityMessage);

            TempData["SuccessMessage"] = passwordChanged 
                ? "Profile and password updated successfully!" 
                : "Profile updated successfully!";
            
            return RedirectToAction("Profile");
        }

        [HttpGet]
        public IActionResult AssignedSubjects()
        {
            var facultyId = HttpContext.Session.GetInt32("FacultyId");
            if (facultyId == null) return RedirectToAction("Login");

            var subjects = _context.AssignedSubjects
                .Include(a => a.Subject)
                .Where(x => x.FacultyId == facultyId.Value)
                .ToList();
            return View(subjects);
        }

        [HttpGet]
        public IActionResult StudentsEnrolled(string subject = null)
        {
            var facultyId = HttpContext.Session.GetInt32("FacultyId");
            if (facultyId == null) return RedirectToAction("Login");

            var subjects = _context.AssignedSubjects
                .Include(a => a.Subject)
                .Where(x => x.FacultyId == facultyId.Value)
                .ToList();

            ViewBag.Subjects = subjects;
            ViewBag.SelectedSubject = subject;

            List<Student> students = new List<Student>();
            if (!string.IsNullOrEmpty(subject))
            {
                // Get the assigned subject IDs for this faculty and subject name
                var assignedSubjectIds = subjects
                    .Where(subj => subj.Subject.Name == subject)
                    .Select(subj => subj.AssignedSubjectId)
                    .ToList();

                // Get students enrolled in any of these assigned subjects WITH enrollment data
                students = _context.StudentEnrollments
                    .Include(se => se.Student)
                        .ThenInclude(s => s.Enrollments)
                            .ThenInclude(e => e.AssignedSubject)
                                .ThenInclude(a => a.Subject)
                    .Include(se => se.AssignedSubject)
                        .ThenInclude(a => a.Subject)
                    .Where(se => assignedSubjectIds.Contains(se.AssignedSubjectId))
                    .Select(se => se.Student)
                    .Distinct()
                    .ToList();
            }

            return View(students);
        }

        [HttpGet]
        public async Task<IActionResult> Logout()
        {
            var facultyId = HttpContext.Session.GetInt32("FacultyId");
            if (facultyId != null)
            {
                var faculty = await _context.Faculties.FindAsync(facultyId.Value);
                if (faculty != null)
                {
                    // 🚀 REAL-TIME NOTIFICATION: Notify system of faculty logout
                    await _signalRService.NotifyUserActivity(faculty.Name, "Faculty", "Logged Out", "Faculty member logged out of the system");
                }
            }

            HttpContext.Session.Clear();
            return RedirectToAction("Login");
        }
    }
}
