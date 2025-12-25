using Microsoft.EntityFrameworkCore;
using System;
using TutorLiveMentor.Helpers;

namespace TutorLiveMentor.Models
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
        {
        }

        // Existing DbSets
        public DbSet<Student> Students { get; set; }
        public DbSet<Faculty> Faculties { get; set; }
        public DbSet<Subject> Subjects { get; set; }
        public DbSet<AssignedSubject> AssignedSubjects { get; set; }
        public DbSet<StudentEnrollment> StudentEnrollments { get; set; }
        public DbSet<Admin> Admins { get; set; }
        public DbSet<FacultySelectionSchedule> FacultySelectionSchedules { get; set; }

        // Super Admin DbSets
        public DbSet<SuperAdmin> SuperAdmins { get; set; }
        public DbSet<Department> Departments { get; set; }
        public DbSet<DepartmentAdmin> DepartmentAdmins { get; set; }
        public DbSet<SystemConfiguration> SystemConfigurations { get; set; }
        public DbSet<AuditLog> AuditLogs { get; set; }

        /// <summary>
        /// PERMANENT FIX: Automatically normalize departments before saving to database
        /// This prevents CSE(DS) vs CSEDS mismatch issues
        /// </summary>
        public override int SaveChanges()
        {
            NormalizeDepartments();
            return base.SaveChanges();
        }

        /// <summary>
        /// PERMANENT FIX: Automatically normalize departments before saving to database (async)
        /// </summary>
        public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        {
            NormalizeDepartments();
            return base.SaveChangesAsync(cancellationToken);
        }

        /// <summary>
        /// Normalizes all department fields before saving
        /// </summary>
        private void NormalizeDepartments()
        {
            var entries = ChangeTracker.Entries()
                .Where(e => e.State == EntityState.Added || e.State == EntityState.Modified);

            foreach (var entry in entries)
            {
                // Check if entity has a Department property
                var departmentProperty = entry.Properties
                    .FirstOrDefault(p => p.Metadata.Name == "Department");

                if (departmentProperty != null && departmentProperty.CurrentValue != null)
                {
                    var currentValue = departmentProperty.CurrentValue.ToString();
                    var normalizedValue = DepartmentNormalizer.Normalize(currentValue);

                    // Only update if different
                    if (currentValue != normalizedValue)
                    {
                        Console.WriteLine($"[AUTO-NORMALIZE] {entry.Entity.GetType().Name}.Department: '{currentValue}' → '{normalizedValue}'");
                        departmentProperty.CurrentValue = normalizedValue;
                    }
                }
            }
        }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Simple, clean configuration - let EF Core use conventions
            
            // AssignedSubject -> Subject (many-to-one)
            modelBuilder.Entity<AssignedSubject>()
                .HasOne(a => a.Subject)
                .WithMany(s => s.AssignedSubjects)
                .HasForeignKey(a => a.SubjectId);

            // AssignedSubject -> Faculty (many-to-one)
            modelBuilder.Entity<AssignedSubject>()
                .HasOne(a => a.Faculty)
                .WithMany(f => f.AssignedSubjects)
                .HasForeignKey(a => a.FacultyId);

            // Configure the many-to-many relationship
            modelBuilder.Entity<StudentEnrollment>()
                .HasKey(se => new { se.StudentId, se.AssignedSubjectId });

            modelBuilder.Entity<StudentEnrollment>()
                .HasOne(se => se.Student)
                .WithMany(s => s.Enrollments)
                .HasForeignKey(se => se.StudentId);

            modelBuilder.Entity<StudentEnrollment>()
                .HasOne(se => se.AssignedSubject)
                .WithMany(a => a.Enrollments)
                .HasForeignKey(se => se.AssignedSubjectId);

            // Super Admin Configurations
            
            // SuperAdmin - unique email
            modelBuilder.Entity<SuperAdmin>()
                .HasIndex(sa => sa.Email)
                .IsUnique();

            // Department - unique code
            modelBuilder.Entity<Department>()
                .HasIndex(d => d.DepartmentCode)
                .IsUnique();

            // DepartmentAdmin relationships
            modelBuilder.Entity<DepartmentAdmin>()
                .HasOne(da => da.Admin)
                .WithMany()
                .HasForeignKey(da => da.AdminId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<DepartmentAdmin>()
                .HasOne(da => da.Department)
                .WithMany(d => d.DepartmentAdmins)
                .HasForeignKey(da => da.DepartmentId)
                .OnDelete(DeleteBehavior.Cascade);

            // SystemConfiguration - unique key
            modelBuilder.Entity<SystemConfiguration>()
                .HasIndex(sc => sc.ConfigKey)
                .IsUnique();

            // AuditLog relationship
            modelBuilder.Entity<AuditLog>()
                .HasOne(al => al.SuperAdmin)
                .WithMany(sa => sa.AuditLogs)
                .HasForeignKey(al => al.SuperAdminId)
                .OnDelete(DeleteBehavior.SetNull);

            // Admin configuration
            modelBuilder.Entity<Admin>()
                .HasIndex(a => a.Email)
                .IsUnique();

            // Seed initial super admin
            modelBuilder.Entity<SuperAdmin>().HasData(
                new SuperAdmin
                {
                    SuperAdminId = 1,
                    Name = "System Administrator",
                    Email = "superadmin@rgmcet.edu.in",
                    Password = "Super@123",
                    PhoneNumber = "9876543210",
                    IsActive = true,
                    CreatedDate = new DateTime(2024, 1, 1),
                    Role = "SuperAdmin"
                }
            );

            // Seed initial departments
            modelBuilder.Entity<Department>().HasData(
                new Department
                {
                    DepartmentId = 1,
                    DepartmentName = "Computer Science and Engineering (Data Science)",
                    DepartmentCode = "CSEDS",
                    Description = "Department of Computer Science and Engineering with specialization in Data Science",
                    IsActive = true,
                    CreatedDate = new DateTime(2024, 1, 1),
                    AllowStudentRegistration = true,
                    AllowFacultyAssignment = true,
                    AllowSubjectSelection = true
                },
                new Department
                {
                    DepartmentId = 2,
                    DepartmentName = "Computer Science and Engineering",
                    DepartmentCode = "CSE",
                    Description = "Department of Computer Science and Engineering",
                    IsActive = true,
                    CreatedDate = new DateTime(2024, 1, 1),
                    AllowStudentRegistration = true,
                    AllowFacultyAssignment = true,
                    AllowSubjectSelection = true
                },
                new Department
                {
                    DepartmentId = 3,
                    DepartmentName = "Electronics and Communication Engineering",
                    DepartmentCode = "ECE",
                    Description = "Department of Electronics and Communication Engineering",
                    IsActive = true,
                    CreatedDate = new DateTime(2024, 1, 1),
                    AllowStudentRegistration = true,
                    AllowFacultyAssignment = true,
                    AllowSubjectSelection = true
                },
                new Department
                {
                    DepartmentId = 4,
                    DepartmentName = "Mechanical Engineering",
                    DepartmentCode = "MECH",
                    Description = "Department of Mechanical Engineering",
                    IsActive = true,
                    CreatedDate = new DateTime(2024, 1, 1),
                    AllowStudentRegistration = true,
                    AllowFacultyAssignment = true,
                    AllowSubjectSelection = true
                },
                new Department
                {
                    DepartmentId = 5,
                    DepartmentName = "Civil Engineering",
                    DepartmentCode = "CIVIL",
                    Description = "Department of Civil Engineering",
                    IsActive = true,
                    CreatedDate = new DateTime(2024, 1, 1),
                    AllowStudentRegistration = true,
                    AllowFacultyAssignment = true,
                    AllowSubjectSelection = true
                },
                new Department
                {
                    DepartmentId = 6,
                    DepartmentName = "Electrical and Electronics Engineering",
                    DepartmentCode = "EEE",
                    Description = "Department of Electrical and Electronics Engineering",
                    IsActive = true,
                    CreatedDate = new DateTime(2024, 1, 1),
                    AllowStudentRegistration = true,
                    AllowFacultyAssignment = true,
                    AllowSubjectSelection = true
                }
            );

            // Link existing CSEDS admin to CSEDS department
            modelBuilder.Entity<DepartmentAdmin>().HasData(
                new DepartmentAdmin
                {
                    DepartmentAdminId = 1,
                    AdminId = 1, // cseds@rgmcet.edu.in
                    DepartmentId = 1, // CSEDS
                    AssignedDate = new DateTime(2024, 1, 1),
                    CanManageStudents = true,
                    CanManageFaculty = true,
                    CanManageSubjects = true,
                    CanViewReports = true,
                    CanManageSchedules = true
                }
            );

            // Seed the specific admin data you requested
            modelBuilder.Entity<Admin>().HasData(
                new Admin
                {
                    AdminId = 1,
                    Email = "cseds@rgmcet.edu.in",
                    Password = "admin123",
                    Department = "CSEDS",
                    CreatedDate = new DateTime(2024, 1, 1),
                    LastLogin = null
                }
            );
        }
    }
}
