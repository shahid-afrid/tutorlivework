using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using TutorLiveMentor.Models;

namespace TutorLiveMentor.Services
{
    /// <summary>
    /// Dynamic DbContext Factory - Creates department-specific DbContext instances
    /// Caches contexts per department for performance
    /// Maps entities to department-specific tables at runtime
    /// </summary>
    public class DynamicDbContextFactory
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly string _connectionString;
        private static readonly ConcurrentDictionary<string, DbContextOptions<DepartmentDbContext>> _contextCache 
            = new ConcurrentDictionary<string, DbContextOptions<DepartmentDbContext>>();

        public DynamicDbContextFactory(IServiceProvider serviceProvider, IConfiguration configuration)
        {
            _serviceProvider = serviceProvider;
            _connectionString = configuration.GetConnectionString("DefaultConnection") ?? string.Empty;
        }

        /// <summary>
        /// Get or create a DbContext for a specific department
        /// </summary>
        public DepartmentDbContext GetContext(string departmentCode)
        {
            var normalizedCode = NormalizeDepartmentCode(departmentCode);
            
            var options = _contextCache.GetOrAdd(normalizedCode, code =>
            {
                var optionsBuilder = new DbContextOptionsBuilder<DepartmentDbContext>();
                optionsBuilder.UseSqlServer(_connectionString);
                return optionsBuilder.Options;
            });

            return new DepartmentDbContext(options, normalizedCode);
        }

        /// <summary>
        /// Clear cached context for a department (useful after table recreation)
        /// </summary>
        public void ClearCache(string departmentCode)
        {
            var normalizedCode = NormalizeDepartmentCode(departmentCode);
            _contextCache.TryRemove(normalizedCode, out _);
        }

        /// <summary>
        /// Clear all cached contexts
        /// </summary>
        public void ClearAllCache()
        {
            _contextCache.Clear();
        }

        private string NormalizeDepartmentCode(string code)
        {
            return code.Replace("(", "").Replace(")", "").Replace(" ", "");
        }
    }

    /// <summary>
    /// Department-specific DbContext - Maps to department tables dynamically
    /// </summary>
    public class DepartmentDbContext : DbContext
    {
        private readonly string _departmentCode;

        public DepartmentDbContext(DbContextOptions<DepartmentDbContext> options, string departmentCode) 
            : base(options)
        {
            _departmentCode = departmentCode;
        }

        // Department-specific DbSets
        public DbSet<Faculty> Faculties { get; set; }
        public DbSet<Student> Students { get; set; }
        public DbSet<Subject> Subjects { get; set; }
        public DbSet<AssignedSubject> AssignedSubjects { get; set; }
        public DbSet<StudentEnrollment> StudentEnrollments { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Map entities to department-specific tables
            modelBuilder.Entity<Faculty>().ToTable($"Faculty_{_departmentCode}");
            modelBuilder.Entity<Student>().ToTable($"Students_{_departmentCode}");
            modelBuilder.Entity<Subject>().ToTable($"Subjects_{_departmentCode}");
            modelBuilder.Entity<AssignedSubject>().ToTable($"AssignedSubjects_{_departmentCode}");
            modelBuilder.Entity<StudentEnrollment>().ToTable($"StudentEnrollments_{_departmentCode}");

            // Configure relationships for AssignedSubject
            modelBuilder.Entity<AssignedSubject>()
                .HasOne(a => a.Subject)
                .WithMany(s => s.AssignedSubjects)
                .HasForeignKey(a => a.SubjectId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<AssignedSubject>()
                .HasOne(a => a.Faculty)
                .WithMany(f => f.AssignedSubjects)
                .HasForeignKey(a => a.FacultyId)
                .OnDelete(DeleteBehavior.Cascade);

            // Configure StudentEnrollment composite key
            modelBuilder.Entity<StudentEnrollment>()
                .HasKey(se => new { se.StudentId, se.AssignedSubjectId });

            modelBuilder.Entity<StudentEnrollment>()
                .HasOne(se => se.Student)
                .WithMany(s => s.Enrollments)
                .HasForeignKey(se => se.StudentId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<StudentEnrollment>()
                .HasOne(se => se.AssignedSubject)
                .WithMany()
                .HasForeignKey(se => se.AssignedSubjectId)
                .OnDelete(DeleteBehavior.Cascade);

            // Configure indexes for performance
            modelBuilder.Entity<Faculty>()
                .HasIndex(f => f.Email)
                .IsUnique();

            modelBuilder.Entity<Student>()
                .HasIndex(s => s.Email)
                .IsUnique();

            modelBuilder.Entity<Student>()
                .HasIndex(s => s.Year);

            modelBuilder.Entity<Subject>()
                .HasIndex(s => new { s.Year, s.Department });

            modelBuilder.Entity<AssignedSubject>()
                .HasIndex(a => a.SubjectId);

            modelBuilder.Entity<AssignedSubject>()
                .HasIndex(a => a.FacultyId);
        }

        /// <summary>
        /// Get the department code this context is mapped to
        /// </summary>
        public string GetDepartmentCode() => _departmentCode;
    }

    /// <summary>
    /// Extension methods for easy access to department contexts
    /// </summary>
    public static class DynamicDbContextExtensions
    {
        /// <summary>
        /// Get department-specific context from HttpContext
        /// </summary>
        public static DepartmentDbContext GetDepartmentContext(
            this HttpContext httpContext, 
            string departmentCode)
        {
            var factory = httpContext.RequestServices.GetRequiredService<DynamicDbContextFactory>();
            return factory.GetContext(departmentCode);
        }

        /// <summary>
        /// Execute action with department context
        /// </summary>
        public static async Task<T> WithDepartmentContext<T>(
            this IServiceProvider serviceProvider,
            string departmentCode,
            Func<DepartmentDbContext, Task<T>> action)
        {
            var factory = serviceProvider.GetRequiredService<DynamicDbContextFactory>();
            using (var context = factory.GetContext(departmentCode))
            {
                return await action(context);
            }
        }
    }
}
