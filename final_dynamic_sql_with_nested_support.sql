-- Extended SQL Script with Support for BETWEEN, IS NULL, and Nested Logic

-- 1. Table to store parsed filters CREATE TABLE dbo.FilterStorage ( TableName NVARCHAR(100), BracketLevel INT, ConditionType NVARCHAR(10), ColumnName NVARCHAR(100), Operator NVARCHAR(20), Value1 NVARCHAR(MAX), Value2 NVARCHAR(MAX), ValueType NVARCHAR(20) );

-- 2. Table to store execution logs CREATE TABLE dbo.FilterExecutionLog ( LogID INT IDENTITY(1,1) PRIMARY KEY, TableName NVARCHAR(100), ExecutedBy NVARCHAR(100), ExecutionTime DATETIME, GeneratedSQL NVARCHAR(MAX) );

-- 3. ParseWhereClause: Supports BETWEEN, IS NULL, and nested logic CREATE OR ALTER PROCEDURE dbo.ParseWhereClause @TableName NVARCHAR(100), @WhereClause NVARCHAR(MAX), @ExecutedBy NVARCHAR(100) = SYSTEM_USER AS BEGIN SET NOCOUNT ON; DELETE FROM dbo.FilterStorage WHERE TableName = @TableName;

DECLARE @Clause NVARCHAR(MAX) = REPLACE(REPLACE(@WhereClause, '(', ' ( '), ')', ' ) ');
DECLARE @xml XML = '<r><v>' + REPLACE(@Clause, ' ', '</v><v>') + '</v></r>';
DECLARE @Tokens TABLE (TokenID INT IDENTITY(1,1), Token NVARCHAR(MAX));
INSERT INTO @Tokens(Token) SELECT T.c.value('.', 'NVARCHAR(MAX)') FROM @xml.nodes('/r/v') AS T(c);

DECLARE @i INT = 1, @cnt INT, @bracketLevel INT = 0;
SELECT @cnt = COUNT(*) FROM @Tokens;
DECLARE @condType NVARCHAR(10) = 'AND';

WHILE @i <= @cnt
BEGIN
    DECLARE @tok NVARCHAR(MAX);
    SELECT @tok = Token FROM @Tokens WHERE TokenID = @i;
    IF @tok = '(' SET @bracketLevel += 1;
    ELSE IF @tok = ')' SET @bracketLevel -= 1;
    ELSE IF UPPER(@tok) IN ('AND', 'OR') SET @condType = UPPER(@tok);
    ELSE
    BEGIN
        DECLARE @col NVARCHAR(100), @op NVARCHAR(20), @val1 NVARCHAR(MAX), @val2 NVARCHAR(MAX), @valType NVARCHAR(20);
        SET @col = @tok;
        SET @i += 1; SELECT @tok = Token FROM @Tokens WHERE TokenID = @i;
        SET @op = UPPER(@tok);
        SET @i += 1; SELECT @tok = Token FROM @Tokens WHERE TokenID = @i;

        IF @op IN ('IS', 'IS NOT') AND UPPER(@tok) = 'NULL'
        BEGIN
            INSERT INTO dbo.FilterStorage VALUES (@TableName, @bracketLevel, @condType, @col, @op + ' NULL', NULL, NULL, 'null');
        END
        ELSE IF @op = 'BETWEEN'
        BEGIN
            SET @val1 = REPLACE(REPLACE(@tok, '''', ''), '"', '');
            SET @valType = CASE WHEN ISNUMERIC(@val1) = 1 THEN 'number' ELSE 'string' END;
            SET @i += 2; SELECT @val2 = Token FROM @Tokens WHERE TokenID = @i;
            SET @val2 = REPLACE(REPLACE(@val2, '''', ''), '"', '');
            INSERT INTO dbo.FilterStorage VALUES (@TableName, @bracketLevel, @condType, @col, 'BETWEEN', @val1, @val2, @valType);
        END
        ELSE IF @op IN ('IN', 'NOT IN') AND @tok = '('
        BEGIN
            WHILE 1 = 1
            BEGIN
                SET @i += 1; SELECT @tok = Token FROM @Tokens WHERE TokenID = @i;
                IF @tok = ')' BREAK;
                IF @tok <> ',' BEGIN
                    SET @val1 = REPLACE(REPLACE(@tok, '''', ''), '"', '');
                    SET @valType = CASE WHEN ISNUMERIC(@val1) = 1 THEN 'number' WHEN LOWER(@val1) IN ('true','false') THEN 'boolean' ELSE 'string' END;
                    INSERT INTO dbo.FilterStorage VALUES (@TableName, @bracketLevel, @condType, @col, @op, @val1, NULL, @valType);
                END
            END
        END
        ELSE
        BEGIN
            SET @val1 = REPLACE(REPLACE(@tok, '''', ''), '"', '');
            SET @valType = CASE WHEN ISNUMERIC(@val1) = 1 THEN 'number' WHEN LOWER(@val1) IN ('true','false') THEN 'boolean' ELSE 'string' END;
            INSERT INTO dbo.FilterStorage VALUES (@TableName, @bracketLevel, @condType, @col, @op, @val1, NULL, @valType);
        END
    END
    SET @i += 1;
END

END

-- 4. BuildDynamicSQL: Handles BETWEEN and IS NULL CREATE OR ALTER PROCEDURE dbo.BuildDynamicSQL @TableName NVARCHAR(100), @ExecutedBy NVARCHAR(100) = SYSTEM_USER AS BEGIN SET NOCOUNT ON; DECLARE @sql NVARCHAR(MAX) = N'SELECT * FROM ' + QUOTENAME(@TableName) + ' WHERE '; DECLARE @output NVARCHAR(MAX) = '', @first BIT = 1, @currentLevel INT = 0;

DECLARE cur CURSOR FOR
SELECT BracketLevel, ConditionType, ColumnName, Operator, Value1, Value2, ValueType
FROM dbo.FilterStorage WHERE TableName = @TableName ORDER BY BracketLevel, ColumnName;

DECLARE @lvl INT, @cond NVARCHAR(10), @col NVARCHAR(100), @op NVARCHAR(20), @v1 NVARCHAR(MAX), @v2 NVARCHAR(MAX), @vt NVARCHAR(20);
OPEN cur
FETCH NEXT FROM cur INTO @lvl, @cond, @col, @op, @v1, @v2, @vt;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF @first = 0 SET @output += ' ' + @cond + ' ';
    ELSE SET @first = 0;

    IF @lvl > @currentLevel SET @output += REPLICATE('(', @lvl - @currentLevel);
    IF @lvl < @currentLevel SET @output += REPLICATE(')', @currentLevel - @lvl);
    SET @currentLevel = @lvl;

    IF @op IN ('IN', 'NOT IN')
    BEGIN
        DECLARE @vals NVARCHAR(MAX);
        SELECT @vals = STRING_AGG(QUOTENAME(Value1, ''''), ', ') FROM dbo.FilterStorage WHERE TableName = @TableName AND ColumnName = @col AND Operator = @op;
        SET @output += QUOTENAME(@col) + ' ' + @op + ' (' + @vals + ')';
    END
    ELSE IF @op = 'BETWEEN'
    BEGIN
        SET @output += QUOTENAME(@col) + ' BETWEEN ' +
            CASE WHEN @vt = 'string' THEN '''' + @v1 + '''' ELSE @v1 END + ' AND ' +
            CASE WHEN @vt = 'string' THEN '''' + @v2 + '''' ELSE @v2 END;
    END
    ELSE IF @op IN ('IS NULL', 'IS NOT NULL')
    BEGIN
        SET @output += QUOTENAME(@col) + ' ' + @op;
    END
    ELSE
    BEGIN
        SET @output += QUOTENAME(@col) + ' ' + @op + ' ' +
            CASE WHEN @vt = 'string' THEN '''' + @v1 + '''' WHEN @vt = 'boolean' THEN LOWER(@v1) ELSE @v1 END;
    END
    FETCH NEXT FROM cur INTO @lvl, @cond, @col, @op, @v1, @v2, @vt;
END

CLOSE cur; DEALLOCATE cur;
IF @currentLevel > 0 SET @output += REPLICATE(')', @currentLevel);
SET @sql += @output;
INSERT INTO dbo.FilterExecutionLog (TableName, ExecutedBy, ExecutionTime, GeneratedSQL)
VALUES (@TableName, @ExecutedBy, GETDATE(), @sql);

PRINT @sql;
EXEC sp_executesql @sql;

END

    
