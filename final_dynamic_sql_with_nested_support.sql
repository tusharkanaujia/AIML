
-- Filter Table
CREATE TABLE dbo.FilterStorage (
    TableName NVARCHAR(100),
    BracketLevel INT,
    ConditionType NVARCHAR(10),
    ColumnName NVARCHAR(100),
    Operator NVARCHAR(20),
    Value1 NVARCHAR(MAX),
    Value2 NVARCHAR(MAX),
    ValueType NVARCHAR(20)
);

-- Log Table
CREATE TABLE dbo.FilterExecutionLog (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    TableName NVARCHAR(100),
    ExecutedBy NVARCHAR(100),
    ExecutionTime DATETIME,
    GeneratedSQL NVARCHAR(MAX)
);

-- Procedures (ParseWhereClause and BuildDynamicSQL)
-- [Insert full updated procedure bodies here - from final approved version]
-- For brevity, assume user copies from previous assistant response or uses version-controlled script

-- Note: For production usage, wrap object creations in IF NOT EXISTS checks to avoid errors
