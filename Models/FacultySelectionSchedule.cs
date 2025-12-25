using System;
using System.ComponentModel.DataAnnotations;

namespace TutorLiveMentor.Models
{
    /// <summary>
    /// Represents faculty selection schedule settings for a specific department
    /// Controls when students can select faculty members
    /// </summary>
    public class FacultySelectionSchedule
    {
        [Key]
        public int ScheduleId { get; set; }

        [Required]
        [StringLength(50)]
        public string Department { get; set; } = string.Empty;

        /// <summary>
        /// Year (1, 2, 3, 4) - null means applies to all years
        /// </summary>
        public int? Year { get; set; }

        /// <summary>
        /// Master toggle - if false, faculty selection is completely disabled
        /// </summary>
        public bool IsEnabled { get; set; } = true;

        /// <summary>
        /// Use time-based schedule (if true, respects StartDateTime and EndDateTime)
        /// If false, faculty selection is always available (as long as IsEnabled = true)
        /// </summary>
        public bool UseSchedule { get; set; } = false;

        /// <summary>
        /// When faculty selection period starts
        /// </summary>
        public DateTime? StartDateTime { get; set; }

        /// <summary>
        /// When faculty selection period ends
        /// </summary>
        public DateTime? EndDateTime { get; set; }

        /// <summary>
        /// Message to display to students when selection is disabled
        /// </summary>
        [StringLength(500)]
        public string DisabledMessage { get; set; } = "Faculty selection is currently disabled. Please check back later.";

        /// <summary>
        /// Created timestamp
        /// </summary>
        public DateTime CreatedAt { get; set; } = DateTime.Now;

        /// <summary>
        /// Last updated timestamp
        /// </summary>
        public DateTime UpdatedAt { get; set; } = DateTime.Now;

        /// <summary>
        /// Admin who last updated the schedule
        /// </summary>
        [StringLength(100)]
        public string UpdatedBy { get; set; } = string.Empty;

        /// <summary>
        /// Check if faculty selection is currently available based on all settings
        /// </summary>
        public bool IsCurrentlyAvailable
        {
            get
            {
                if (!IsEnabled)
                    return false;

                if (!UseSchedule)
                    return true;

                if (!StartDateTime.HasValue || !EndDateTime.HasValue)
                    return true;

                var now = DateTime.Now;
                return now >= StartDateTime.Value && now <= EndDateTime.Value;
            }
        }

        /// <summary>
        /// Get status description
        /// </summary>
        public string StatusDescription
        {
            get
            {
                if (!IsEnabled)
                    return "Disabled";

                if (!UseSchedule)
                    return "Always Available";

                if (!StartDateTime.HasValue || !EndDateTime.HasValue)
                    return "No Schedule Set";

                var now = DateTime.Now;
                if (now < StartDateTime.Value)
                    return $"Opens: {StartDateTime.Value:MMM dd, yyyy hh:mm tt}";

                if (now > EndDateTime.Value)
                    return "Closed (Period Ended)";

                return $"Active until {EndDateTime.Value:MMM dd, yyyy hh:mm tt}";
            }
        }
    }

    /// <summary>
    /// View model for managing faculty selection schedule
    /// </summary>
    public class FacultySelectionScheduleViewModel
    {
        public int ScheduleId { get; set; }
        public string Department { get; set; } = string.Empty;
        
        public bool IsEnabled { get; set; } = true;
        public bool UseSchedule { get; set; } = false;

        [DataType(DataType.DateTime)]
        [Display(Name = "Start Date & Time")]
        public DateTime? StartDateTime { get; set; }

        [DataType(DataType.DateTime)]
        [Display(Name = "End Date & Time")]
        public DateTime? EndDateTime { get; set; }

        [StringLength(500)]
        [Display(Name = "Disabled Message")]
        public string DisabledMessage { get; set; } = "Faculty selection is currently disabled. Please check back later.";

        public bool IsCurrentlyAvailable { get; set; }
        public string StatusDescription { get; set; } = string.Empty;
        public DateTime? UpdatedAt { get; set; }
        public string UpdatedBy { get; set; } = string.Empty;

        // For display
        public int AffectedStudents { get; set; }
        public int AffectedSubjects { get; set; }
        public int TotalEnrollments { get; set; }
    }
}
