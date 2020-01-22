
/*
This is where the data preprocessing happens.  Age, sex, income, and hours per week get regularized while the state gets one hot encoded.
*/



DROP TABLE IF EXISTS ##TempTable
DROP TABLE IF EXISTS ##TrainNeuralNetwork
DROP TABLE IF EXISTS ##TestNeuralNetwork
DROP TABLE IF EXISTS ##ProgressTracker
DROP TABLE IF EXISTS ##States

DECLARE @inputlayer INT = 53
DECLARE @hiddenlayer INT = 2









/*
Generating a table of all the possible values of state that should be valid (data wasn't perfect) and includes 48 different states.  A cursor object will be able to go through this to one hot encode state
*/

SELECT DISTINCT 
	CONVERT(VARCHAR(8),UPPER(statecode)) statecode 
	,COUNT(CONVERT(VARCHAR(8),UPPER(statecode))) AS 'total'
INTO ##States
[INTERNAL QUERY]
WHERE statecode IS NOT NULL AND statecode <> ''
GROUP BY CONVERT(VARCHAR(8),UPPER(statecode))
HAVING COUNT(CONVERT(VARCHAR(8),UPPER(statecode))) > 1000
ORDER BY statecode












/*
Initializing a useful tool to track how the network is performing.  The next two SP's will be run multiple times so this table has to be created beforehand
*/

CREATE TABLE ##ProgressTracker
(
	RunID INT IDENTITY(1,1) PRIMARY KEY 
	,LOSS FLOAT
	,Overall_SR FLOAT
	,Positive_SR FLOAT
    ,Negative_SR FLOAT
    ,True_Percentage FLOAT
	,Test_Train VARCHAR(8)
)


/*
The regularized data is entered into table alongside the neural network id, with the order of entries are randomized
*/

SELECT 
	STR(@inputlayer,LEN(@inputlayer)) + 'x' + STR(@hiddenlayer,LEN(@hiddenlayer)) AS 'NNID'
	,[INTERNAL SELECT STATEMENTS for Age,Sex,Salary,Hours, and State]
INTO ##TempTable
[INTERNAL QUERY]
ORDER BY RAND();
	




DECLARE @State NVARCHAR(8)

DECLARE StateCursor CURSOR FOR 
	SELECT DISTINCT 
		statecode 
	FROM ##States
	ORDER BY statecode

OPEN StateCursor

FETCH NEXT FROM StateCursor INTO @State

WHILE @@FETCH_STATUS = 0
	BEGIN
	
	DECLARE @addcolumn NVARCHAR(MAX) = 'ALTER TABLE ##TempTable
											ADD [' + @State + '] INT;'
	EXEC(@addcolumn)



	DECLARE @addvalues NVARCHAR(MAX) = 'UPDATE ##TempTable
										SET [' + @State + '] = CASE WHEN Statecode = ''' + @State + ''' THEN 1 ELSE 0 END
										FROM ##TempTable;'
	EXEC(@addvalues)


	FETCH NEXT FROM StateCursor INTO @State
	END


CLOSE StateCursor
DEALLOCATE StateCursor



/*
Train/Test split with the training also separated into 4 different folds.  At the beginning of the feedforward, a random fold is chosen
*/



SELECT TOP(80) PERCENT *
INTO ##TrainNeuralNetwork
FROM ##TempTable tt
JOIN ##TempWeights tw ON tw.WeightId = tt.NNID
WHERE tt.STATECODE IN (SELECT DISTINCT Statecode FROM ##States)


ALTER TABLE ##TrainNeuralNetwork
ADD [Set] FLOAT;

UPDATE ##TrainNeuralNetwork
SET [Set] = ABS(CHECKSUM(NEWID()))%4;




/*
Now that data and weights have been prepared, they are joined together so that every row has someone's data plus the weights.  Feeding forward becomes as simple as a select statement.
Because of how SQL works, this will be utilizing batch gradient descent, as it is much faster than having to use a cursor
*/

SELECT *
INTO ##TestNeuralNetwork
FROM ##TempTable tt
JOIN ##TempWeights tw ON tw.WeightId = tt.NNID
WHERE tt.EmployeeID NOT IN (SELECT DISTINCT employeeid FROM ##TrainNeuralNetwork) AND tt.STATECODE IN (SELECT DISTINCT Statecode FROM ##States);



SELECT * FROM ##TrainNeuralNetwork
SELECT * FROM ##TestNeuralNetwork


