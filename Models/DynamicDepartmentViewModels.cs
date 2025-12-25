namespace TutorLiveMentor.Models
{
    /// <summary>
    /// Universal Department Dashboard ViewModel
    /// Works for ALL departments dynamically
    /// </summary>
    public class DepartmentDashboardViewModel
    {
        public string DepartmentCode { get; set; }
        public string DepartmentName { get; set; }
        public string AdminEmail { get; set; }
        public int TotalStudents { get; set; }
        public int TotalFaculty { get; set; }
        public int TotalSubjects { get; set; }
        public int TotalEnrollments { get; set; }
        public int TotalAssignments { get; set; }
        public List<StudentYearStatistic> StudentsByYear { get; set; } = new List<StudentYearStatistic>();
        public List<YearStatistic> SubjectsByYear { get; set; } = new List<YearStatistic>();
        public List<Student> RecentStudents { get; set; } = new List<Student>();
        public List<Faculty> RecentFaculty { get; set; } = new List<Faculty>();
        public List<StudentActivityDto> RecentActivities { get; set; } = new List<StudentActivityDto>();
        public List<EnrollmentActivityDto> RecentEnrollments { get; set; } = new List<EnrollmentActivityDto>();
        public List<Faculty> DepartmentFaculty { get; set; } = new List<Faculty>();
        public List<Subject> DepartmentSubjects { get; set; } = new List<Subject>();
        public List<SubjectFacultyMappingDto> SubjectFacultyMappings { get; set; } = new List<SubjectFacultyMappingDto>();
        
        // Department settings
        public bool AllowStudentRegistration { get; set; }
        public bool AllowFacultyAssignment { get; set; }
        public bool AllowSubjectSelection { get; set; }
        public bool IsActive { get; set; }
    }

    public class YearStatistic
    {
        public int Year { get; set; }
        public int Count { get; set; }
    }

    public class StudentYearStatistic
    {
        public string Year { get; set; }
        public int Count { get; set; }
    }

    public class SubjectWithStats
    {
        public Subject Subject { get; set; }
        public int EnrollmentCount { get; set; }
        public string AssignedFacultyName { get; set; }
        public int AvailableSeats { get; set; }
    }

    public class SubjectAssignmentViewModel
    {
        public int AssignmentId { get; set; }
        public string SubjectName { get; set; }
        public string SubjectCode { get; set; }
        public string FacultyName { get; set; }
        public string FacultyEmail { get; set; }
        public int Year { get; set; }
        public int Semester { get; set; }
        public DateTime AssignedDate { get; set; }
    }

    public class EnrollmentStatistic
    {
        public int Year { get; set; }
        public int Semester { get; set; }
        public int TotalEnrollments { get; set; }
        public int UniqueStudents { get; set; }
    }

    // Dynamic Department Request Models (no duplicate DTOs)

    public class AddFacultyRequest
    {
        public string Name { get; set; }
        public string Email { get; set; }
        public string Password { get; set; }
    }

    public class UpdateFacultyRequest
    {
        public int FacultyId { get; set; }
        public string Name { get; set; }
        public string Email { get; set; }
        public string Password { get; set; }
    }

    public class DeleteFacultyRequest
    {
        public int FacultyId { get; set; }
    }

    public class AddSubjectRequest
    {
        public string Name { get; set; }
        public int Year { get; set; }
        public string Semester { get; set; }
        public DateTime? SemesterStartDate { get; set; }
        public DateTime? SemesterEndDate { get; set; }
        public int? MaxEnrollments { get; set; }
    }

    public class UpdateSubjectRequest
    {
        public int SubjectId { get; set; }
        public string Name { get; set; }
        public int Year { get; set; }
        public string Semester { get; set; }
        public DateTime? SemesterStartDate { get; set; }
        public DateTime? SemesterEndDate { get; set; }
        public int? MaxEnrollments { get; set; }
    }

    public class DeleteSubjectRequest
    {
        public int SubjectId { get; set; }
    }

    public class AddStudentRequest
    {
        public string FullName { get; set; }
        public string RegdNumber { get; set; }
        public string Email { get; set; }
        public string Password { get; set; }
        public string Year { get; set; }
        public string Semester { get; set; }
    }

    public class UpdateStudentRequest
    {
        public string StudentId { get; set; } // Changed from int to string to match Student.Id
        public string FullName { get; set; }
        public string Email { get; set; }
        public string Year { get; set; }
        public string Semester { get; set; }
        public string Password { get; set; }
    }

    public class DeleteStudentRequest
    {
        public string StudentId { get; set; } // Changed from int to string to match Student.Id
    }

    public class ReportFilterRequest
    {
        public string Year { get; set; }
        public int? SubjectId { get; set; }
        public int? FacultyId { get; set; }
        public string Semester { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
    }

    public class ToggleFacultySelectionRequest
    {
        public bool IsEnabled { get; set; }
    }

    public class UpdateScheduleRequest
    {
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
    }

    // Note: FacultyDetailDto and AssignedSubjectInfo already exist in CSEDSViewModels.cs
    // SubjectAssignmentInfo is similar to AssignedSubjectInfo but with different properties
    
    public class SubjectAssignmentInfo
    {
        public string SubjectName { get; set; }
        public int Year { get; set; }
        public string Semester { get; set; }
        public int SelectedCount { get; set; }
    }

    public class StudentFilterRequest
    {
        public string SearchText { get; set; }
        public string Year { get; set; }
        public string Semester { get; set; }
        public bool? HasEnrollments { get; set; }
    }

    public class AssignmentManagementViewModel
    {
        public List<Subject> Subjects { get; set; } = new List<Subject>();
        public List<Faculty> Faculty { get; set; } = new List<Faculty>();
        public List<AssignmentDetailDto> Assignments { get; set; } = new List<AssignmentDetailDto>();
    }

    public class AssignmentDetailDto
    {
        public int AssignedSubjectId { get; set; }
        public string SubjectName { get; set; }
        public string FacultyName { get; set; }
        public int Year { get; set; }
        public string Semester { get; set; }
        public int SelectedCount { get; set; }
    }

    /// <summary>
    /// DTO for faculty with their assigned subjects
    /// </summary>
    public class FacultyWithAssignmentsDto
    {
        public int FacultyId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Department { get; set; } = string.Empty;
        public List<AssignedSubjectDto> AssignedSubjects { get; set; } = new List<AssignedSubjectDto>();
    }

    /// <summary>
    /// DTO for assigned subject information
    /// </summary>
    public class AssignedSubjectDto
    {
        public int AssignedSubjectId { get; set; }
        public int SubjectId { get; set; }
        public string SubjectName { get; set; } = string.Empty;
        public int Year { get; set; }
        public string Semester { get; set; } = string.Empty;
    }

    /// <summary>
    /// ViewModel for Subject-Faculty Assignment Management (Dynamic Departments)
    /// </summary>
    public class SubjectAssignmentManagementViewModel
    {
        public string DepartmentCode { get; set; } = string.Empty;
        public string DepartmentName { get; set; } = string.Empty;
        public List<SubjectWithAssignmentsDto> SubjectsWithAssignments { get; set; } = new List<SubjectWithAssignmentsDto>();
        public List<Subject> Subjects { get; set; } = new List<Subject>(); // For backward compatibility
        public List<Subject> DepartmentSubjects { get; set; } = new List<Subject>(); // Alias
        public List<Faculty> AvailableFaculty { get; set; } = new List<Faculty>();
        public List<Faculty> Faculty { get; set; } = new List<Faculty>(); // Alias
        public List<AssignedSubject> ExistingAssignments { get; set; } = new List<AssignedSubject>();
        public int TotalSubjects { get; set; }
        public int TotalAssignments { get; set; }
        public int TotalEnrollments { get; set; }
    }

    /// <summary>
    /// Subject with faculty assignments DTO
    /// </summary>
    public class SubjectWithAssignmentsDto
    {
        public int SubjectId { get; set; }
        public string SubjectName { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty; // Alias for SubjectName
        public string Department { get; set; } = string.Empty;
        public int Year { get; set; }
        public string Semester { get; set; } = string.Empty;
        public DateTime? SemesterStartDate { get; set; }
        public DateTime? SemesterEndDate { get; set; }
        public bool IsActive { get; set; } = true;
        public List<FacultyAssignmentInfo> AssignedFaculty { get; set; } = new List<FacultyAssignmentInfo>();
        public int TotalEnrollments { get; set; }
    }

    /// <summary>
    /// Faculty assignment info
    /// </summary>
    public class FacultyAssignmentInfo
    {
        public int FacultyId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public int AssignedSubjectId { get; set; }
    }
}
