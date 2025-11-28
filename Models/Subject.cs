using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace TutorLiveMentor.Models
{
    public class Subject
    {
        public int SubjectId { get; set; }
        
        [Required]
        public string Name { get; set; }
        
        [Required]
        public string Department { get; set; }

        // Additional fields for CSEDS semester management
        public int Year { get; set; } = 1;
        
        public string Semester { get; set; } = string.Empty;
        
        public DateTime? SemesterStartDate { get; set; }
        
        public DateTime? SemesterEndDate { get; set; }

        // NEW: Subject Type - "Core", "OpenElective1", "OpenElective2", etc.
        public string SubjectType { get; set; } = "Core";
        
        // NEW: Maximum enrollment limit (null = unlimited, number = specific limit)
        // Used for Open Electives (typically 70, but can be 60, 65, etc.)
        public int? MaxEnrollments { get; set; } = null;

        // Navigation property
        public virtual ICollection<AssignedSubject> AssignedSubjects { get; set; }
    }
}
