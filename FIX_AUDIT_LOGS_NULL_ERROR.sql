-- ============================================
-- FIX AUDIT LOGS NULL CONSTRAINT ERROR
-- ============================================

USE [WorkingDb]
GO

PRINT 'Starting AuditLogs table fix...'

-- Step 1: Check if table has any data
IF EXISTS (SELECT 1 FROM AuditLogs)
BEGIN
    PRINT 'Updating existing records with default values...'
    
    -- Update existing NULL values
    UPDATE AuditLogs 
    SET ActionPerformedBy = 'System' 
    WHERE ActionPerformedBy IS NULL

    UPDATE AuditLogs 
    SET EntityType = '' 
    WHERE EntityType IS NULL

    UPDATE AuditLogs 
    SET ActionDescription = '' 
    WHERE ActionDescription IS NULL

    UPDATE AuditLogs 
    SET OldValue = '' 
    WHERE OldValue IS NULL

    UPDATE AuditLogs 
    SET NewValue = '' 
    WHERE NewValue IS NULL

    UPDATE AuditLogs 
    SET IpAddress = '127.0.0.1' 
    WHERE IpAddress IS NULL

    UPDATE AuditLogs 
    SET Status = 'Success' 
    WHERE Status IS NULL
    
    PRINT 'Existing records updated!'
END
ELSE
BEGIN
    PRINT 'No existing records to update.'
END

-- Step 2: Alter columns to allow NULL or set defaults
PRINT 'Altering table columns...'

-- Make ActionPerformedBy nullable with default
ALTER TABLE AuditLogs 
ALTER COLUMN ActionPerformedBy NVARCHAR(100) NULL

ALTER TABLE AuditLogs 
ADD CONSTRAINT DF_AuditLogs_ActionPerformedBy DEFAULT 'System' FOR ActionPerformedBy

-- Make EntityType nullable with default
ALTER TABLE AuditLogs 
ALTER COLUMN EntityType NVARCHAR(100) NULL

ALTER TABLE AuditLogs 
ADD CONSTRAINT DF_AuditLogs_EntityType DEFAULT '' FOR EntityType

-- Make ActionDescription nullable with default
ALTER TABLE AuditLogs 
ALTER COLUMN ActionDescription NVARCHAR(500) NULL

ALTER TABLE AuditLogs 
ADD CONSTRAINT DF_AuditLogs_ActionDescription DEFAULT '' FOR ActionDescription

-- Make OldValue nullable
ALTER TABLE AuditLogs 
ALTER COLUMN OldValue NVARCHAR(MAX) NULL

ALTER TABLE AuditLogs 
ADD CONSTRAINT DF_AuditLogs_OldValue DEFAULT '' FOR OldValue

-- Make NewValue nullable
ALTER TABLE AuditLogs 
ALTER COLUMN NewValue NVARCHAR(MAX) NULL

ALTER TABLE AuditLogs 
ADD CONSTRAINT DF_AuditLogs_NewValue DEFAULT '' FOR NewValue

-- Make IpAddress nullable with default
ALTER TABLE AuditLogs 
ALTER COLUMN IpAddress NVARCHAR(50) NULL

ALTER TABLE AuditLogs 
ADD CONSTRAINT DF_AuditLogs_IpAddress DEFAULT '127.0.0.1' FOR IpAddress

-- Make Status nullable with default
ALTER TABLE AuditLogs 
ALTER COLUMN Status NVARCHAR(50) NULL

ALTER TABLE AuditLogs 
ADD CONSTRAINT DF_AuditLogs_Status DEFAULT 'Success' FOR Status

PRINT 'Table columns altered successfully!'

-- Step 3: Verify the changes
PRINT ''
PRINT 'Verifying table structure...'
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE,
    COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'AuditLogs'
ORDER BY ORDINAL_POSITION

PRINT ''
PRINT '? AuditLogs table fixed successfully!'
PRINT 'You can now login to Super Admin without errors.'

GO
