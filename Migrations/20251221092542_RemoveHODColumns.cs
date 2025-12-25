using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TutorLiveMentor.Migrations
{
    /// <inheritdoc />
    public partial class RemoveHODColumns : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "HeadOfDepartment",
                table: "Departments");

            migrationBuilder.DropColumn(
                name: "HeadOfDepartmentEmail",
                table: "Departments");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "HeadOfDepartment",
                table: "Departments",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "HeadOfDepartmentEmail",
                table: "Departments",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                defaultValue: "");

            migrationBuilder.UpdateData(
                table: "Departments",
                keyColumn: "DepartmentId",
                keyValue: 1,
                columns: new[] { "HeadOfDepartment", "HeadOfDepartmentEmail" },
                values: new object[] { "", "" });

            migrationBuilder.UpdateData(
                table: "Departments",
                keyColumn: "DepartmentId",
                keyValue: 2,
                columns: new[] { "HeadOfDepartment", "HeadOfDepartmentEmail" },
                values: new object[] { "", "" });

            migrationBuilder.UpdateData(
                table: "Departments",
                keyColumn: "DepartmentId",
                keyValue: 3,
                columns: new[] { "HeadOfDepartment", "HeadOfDepartmentEmail" },
                values: new object[] { "", "" });

            migrationBuilder.UpdateData(
                table: "Departments",
                keyColumn: "DepartmentId",
                keyValue: 4,
                columns: new[] { "HeadOfDepartment", "HeadOfDepartmentEmail" },
                values: new object[] { "", "" });

            migrationBuilder.UpdateData(
                table: "Departments",
                keyColumn: "DepartmentId",
                keyValue: 5,
                columns: new[] { "HeadOfDepartment", "HeadOfDepartmentEmail" },
                values: new object[] { "", "" });

            migrationBuilder.UpdateData(
                table: "Departments",
                keyColumn: "DepartmentId",
                keyValue: 6,
                columns: new[] { "HeadOfDepartment", "HeadOfDepartmentEmail" },
                values: new object[] { "", "" });
        }
    }
}
