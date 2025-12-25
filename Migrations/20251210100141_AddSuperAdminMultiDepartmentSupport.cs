using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace TutorLiveMentor.Migrations
{
    /// <inheritdoc />
    public partial class AddSuperAdminMultiDepartmentSupport : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Departments",
                columns: table => new
                {
                    DepartmentId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    DepartmentName = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    DepartmentCode = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    Description = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    HeadOfDepartment = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    HeadOfDepartmentEmail = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false),
                    CreatedDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    LastModifiedDate = table.Column<DateTime>(type: "datetime2", nullable: true),
                    AllowStudentRegistration = table.Column<bool>(type: "bit", nullable: false),
                    AllowFacultyAssignment = table.Column<bool>(type: "bit", nullable: false),
                    AllowSubjectSelection = table.Column<bool>(type: "bit", nullable: false),
                    TotalStudents = table.Column<int>(type: "int", nullable: false),
                    TotalFaculty = table.Column<int>(type: "int", nullable: false),
                    TotalSubjects = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Departments", x => x.DepartmentId);
                });

            migrationBuilder.CreateTable(
                name: "SuperAdmins",
                columns: table => new
                {
                    SuperAdminId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Email = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Password = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: false),
                    PhoneNumber = table.Column<string>(type: "nvarchar(15)", maxLength: 15, nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false),
                    CreatedDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    LastLogin = table.Column<DateTime>(type: "datetime2", nullable: true),
                    Role = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SuperAdmins", x => x.SuperAdminId);
                });

            migrationBuilder.CreateTable(
                name: "SystemConfigurations",
                columns: table => new
                {
                    ConfigId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ConfigKey = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    ConfigValue = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    Description = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    Category = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false),
                    CreatedDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    LastModifiedDate = table.Column<DateTime>(type: "datetime2", nullable: true),
                    ModifiedBySuperAdminId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SystemConfigurations", x => x.ConfigId);
                });

            migrationBuilder.CreateTable(
                name: "DepartmentAdmins",
                columns: table => new
                {
                    DepartmentAdminId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    AdminId = table.Column<int>(type: "int", nullable: false),
                    DepartmentId = table.Column<int>(type: "int", nullable: false),
                    AssignedDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    CanManageStudents = table.Column<bool>(type: "bit", nullable: false),
                    CanManageFaculty = table.Column<bool>(type: "bit", nullable: false),
                    CanManageSubjects = table.Column<bool>(type: "bit", nullable: false),
                    CanViewReports = table.Column<bool>(type: "bit", nullable: false),
                    CanManageSchedules = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DepartmentAdmins", x => x.DepartmentAdminId);
                    table.ForeignKey(
                        name: "FK_DepartmentAdmins_Admins_AdminId",
                        column: x => x.AdminId,
                        principalTable: "Admins",
                        principalColumn: "AdminId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_DepartmentAdmins_Departments_DepartmentId",
                        column: x => x.DepartmentId,
                        principalTable: "Departments",
                        principalColumn: "DepartmentId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "AuditLogs",
                columns: table => new
                {
                    AuditLogId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    SuperAdminId = table.Column<int>(type: "int", nullable: true),
                    ActionPerformedBy = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    ActionType = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    EntityType = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    EntityId = table.Column<int>(type: "int", nullable: true),
                    ActionDescription = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    OldValue = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    NewValue = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    IpAddress = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    ActionDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Status = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AuditLogs", x => x.AuditLogId);
                    table.ForeignKey(
                        name: "FK_AuditLogs_SuperAdmins_SuperAdminId",
                        column: x => x.SuperAdminId,
                        principalTable: "SuperAdmins",
                        principalColumn: "SuperAdminId",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.InsertData(
                table: "Departments",
                columns: new[] { "DepartmentId", "AllowFacultyAssignment", "AllowStudentRegistration", "AllowSubjectSelection", "CreatedDate", "DepartmentCode", "DepartmentName", "Description", "HeadOfDepartment", "HeadOfDepartmentEmail", "IsActive", "LastModifiedDate", "TotalFaculty", "TotalStudents", "TotalSubjects" },
                values: new object[,]
                {
                    { 1, true, true, true, new DateTime(2024, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "CSEDS", "Computer Science and Engineering (Data Science)", "Department of Computer Science and Engineering with specialization in Data Science", "", "", true, null, 0, 0, 0 },
                    { 2, true, true, true, new DateTime(2024, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "CSE", "Computer Science and Engineering", "Department of Computer Science and Engineering", "", "", true, null, 0, 0, 0 },
                    { 3, true, true, true, new DateTime(2024, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "ECE", "Electronics and Communication Engineering", "Department of Electronics and Communication Engineering", "", "", true, null, 0, 0, 0 },
                    { 4, true, true, true, new DateTime(2024, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "MECH", "Mechanical Engineering", "Department of Mechanical Engineering", "", "", true, null, 0, 0, 0 },
                    { 5, true, true, true, new DateTime(2024, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "CIVIL", "Civil Engineering", "Department of Civil Engineering", "", "", true, null, 0, 0, 0 },
                    { 6, true, true, true, new DateTime(2024, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "EEE", "Electrical and Electronics Engineering", "Department of Electrical and Electronics Engineering", "", "", true, null, 0, 0, 0 }
                });

            migrationBuilder.InsertData(
                table: "SuperAdmins",
                columns: new[] { "SuperAdminId", "CreatedDate", "Email", "IsActive", "LastLogin", "Name", "Password", "PhoneNumber", "Role" },
                values: new object[] { 1, new DateTime(2024, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), "superadmin@rgmcet.edu.in", true, null, "System Administrator", "Super@123", "9876543210", "SuperAdmin" });

            migrationBuilder.InsertData(
                table: "DepartmentAdmins",
                columns: new[] { "DepartmentAdminId", "AdminId", "AssignedDate", "CanManageFaculty", "CanManageSchedules", "CanManageStudents", "CanManageSubjects", "CanViewReports", "DepartmentId" },
                values: new object[] { 1, 1, new DateTime(2024, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), true, true, true, true, true, 1 });

            migrationBuilder.CreateIndex(
                name: "IX_AuditLogs_SuperAdminId",
                table: "AuditLogs",
                column: "SuperAdminId");

            migrationBuilder.CreateIndex(
                name: "IX_DepartmentAdmins_AdminId",
                table: "DepartmentAdmins",
                column: "AdminId");

            migrationBuilder.CreateIndex(
                name: "IX_DepartmentAdmins_DepartmentId",
                table: "DepartmentAdmins",
                column: "DepartmentId");

            migrationBuilder.CreateIndex(
                name: "IX_Departments_DepartmentCode",
                table: "Departments",
                column: "DepartmentCode",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_SuperAdmins_Email",
                table: "SuperAdmins",
                column: "Email",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_SystemConfigurations_ConfigKey",
                table: "SystemConfigurations",
                column: "ConfigKey",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "AuditLogs");

            migrationBuilder.DropTable(
                name: "DepartmentAdmins");

            migrationBuilder.DropTable(
                name: "SystemConfigurations");

            migrationBuilder.DropTable(
                name: "SuperAdmins");

            migrationBuilder.DropTable(
                name: "Departments");
        }
    }
}
