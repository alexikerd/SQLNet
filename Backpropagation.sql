DROP TABLE IF EXISTS ##ChangeWeights










/*
The learning rate decays slowly based on the number of records in the progresstracker table

The final change is the the result of all the respective partial derivatives multiplied with the learning rate

The weight table itself is the table that ends up getting modified, which allows for the feedforward process to be run again
*/


DECLARE @LearningRate FLOAT = 0.0001*POWER(0.9,(SELECT COUNT(*) FROM ##ProgressTracker)-1)
DECLARE @inputlayer INT = 53
DECLARE @hiddenlayer INT = 2
DECLARE @inputcount INT = 1
DECLARE @hiddencount INT = 1
DECLARE @classweight FLOAT = (SELECT CONVERT(FLOAT,(SUM(CASE WHEN [Married] = 1 THEN 1 ELSE 0 END)))/CONVERT(FLOAT,COUNT(*)) FROM ##FinalTable)


CREATE TABLE ##ChangeWeights
	(
	WeightID VARCHAR(8)
	)

INSERT INTO ##ChangeWeights
(
    WeightID
)
VALUES
(STR(@inputlayer,LEN(@inputlayer)) + 'x' + STR(@hiddenlayer,LEN(@hiddenlayer)) -- WeightID - varchar(8)
    )

ALTER TABLE ##ChangeWeights
ADD [cb2_1] FLOAT


UPDATE ##ChangeWeights
SET [cb2_1] = 0--(SELECT SUM(@LearningRate*[Base Delta]) FROM ##FinalTable)



WHILE @hiddencount < @hiddenlayer + 1
	BEGIN
      
	DECLARE @Weight VARCHAR(MAX) = 'cw2_' + STR(@hiddencount,LEN(@hiddencount)) + '_1'
	DECLARE @Bias VARCHAR(MAX) = 'cb_' + STR(@hiddencount,LEN(@hiddencount))

	DECLARE @addcolumn NVARCHAR(MAX) = 'ALTER TABLE ##ChangeWeights
											ADD [' + @Weight + '] FLOAT(8)
											, [' + @Bias + '] FLOAT(8);'
	EXEC(@addcolumn)



	DECLARE @addvalues NVARCHAR(MAX) = 'UPDATE ##ChangeWeights
										SET [' + @Weight + '] = (SELECT SUM(' + CAST(@LearningRate AS VARCHAR(MAX)) + '*[Base Delta]*[hl_' + STR(@hiddencount,LEN(@hiddencount)) + ']/(CASE WHEN [Married] = 1 THEN ' + CAST(@classweight AS VARCHAR(MAX)) + ' ELSE ' + CAST((1-@classweight) AS VARCHAR(MAX)) + ' END)*(CASE WHEN [ol_' + STR(@hiddencount,LEN(@hiddencount)) + ']= 0 THEN 0 ELSE 1 END)) FROM ##FinalTable)
										  ,[' + @Bias + '] = (SELECT SUM(' + CAST(@LearningRate AS VARCHAR(MAX)) + '*[Base Delta]*[w2_' + STR(@hiddencount,LEN(@hiddencount)) + '_1]/(CASE WHEN [Married] = 1 THEN ' + CAST(@classweight AS VARCHAR(MAX)) + ' ELSE ' + CAST((1-@classweight) AS VARCHAR(MAX)) + ' END)*(CASE WHEN [ol_' + STR(@hiddencount,LEN(@hiddencount)) + ']= 0 THEN 0 ELSE 1 END)) FROM ##FinalTable);
										'
	EXEC(@addvalues)

	

	SET @hiddencount += 1
		
	END 




DECLARE @hiddencount2 INT = 1
DECLARE @Input VARCHAR(MAX)


WHILE @hiddencount2 < @hiddenlayer + 1
	BEGIN
    
	DECLARE feedcursor CURSOR FOR 
		SELECT Input FROM ##InputFeed

	
	OPEN feedcursor


	FETCH NEXT FROM feedcursor INTO @Input

	WHILE @@FETCH_STATUS = 0
		BEGIN
        
		DECLARE @Digit INT = (SELECT [Weight Number] FROM ##Inputfeed WHERE [Input] = @Input)

		DECLARE @Weight2 VARCHAR(MAX) = 'cw_' + STR(@Digit,LEN(@Digit)) + '_' + STR(@hiddencount2,LEN(@hiddencount2))

		DECLARE @addcolumn2 NVARCHAR(MAX) = 'ALTER TABLE ##ChangeWeights
											ADD [' + @Weight2 + '] FLOAT(8);'
		
		EXEC(@addcolumn2)



		DECLARE @addvalues2 NVARCHAR(MAX) = 'UPDATE ##ChangeWeights
										SET [' + @Weight2 + '] = (SELECT SUM(' + CAST(@LearningRate AS VARCHAR(MAX)) + '*[Base Delta]*[w2_' + STR(@hiddencount2,LEN(@hiddencount2)) + '_1]*[' + @Input + ']/(CASE WHEN [Married] = 1 THEN ' + CAST(@classweight AS VARCHAR(MAX)) + ' ELSE ' + CAST((1-@classweight) AS VARCHAR(MAX)) + ' END)*(CASE WHEN [ol_' + STR(@hiddencount2,LEN(@hiddencount2)) + ']= 0 THEN 0 ELSE 1 END)) FROM ##FinalTable) 
										'-- extra values to account for sigmoid activation
		EXEC(@addvalues2)


		FETCH NEXT FROM feedcursor INTO @Input

		END

	SET @hiddencount2 += 1



	CLOSE feedcursor
	DEALLOCATE feedcursor

	END

DECLARE @weightname VARCHAR(16)


SELECT * FROM ##TempWeights
SELECT WeightID,cw_1_1,cw_1_2,cw2_1_1,cw2_2_1,cb_1,cb_2,cb2_1 FROM ##ChangeWeights


DECLARE weightcursor CURSOR FOR
	SELECT DISTINCT Weight FROM ##WeightList

OPEN weightcursor

FETCH NEXT FROM weightcursor INTO @weightname

WHILE @@FETCH_STATUS = 0
	BEGIN

	DECLARE @changename VARCHAR(16) = 'c' + @weightname
    
	DECLARE @finalchange VARCHAR(MAX) = 'UPDATE ##TempWeights
										SET [' + @weightname + '] = tw.[' + @weightname + '] + cw.[' + @changename + '] FROM ##TempWeights tw JOIN ##ChangeWeights cw ON cw.WeightID = tw.WeightID'

	EXEC(@finalchange)

	FETCH NEXT FROM weightcursor INTO @weightname

	END

CLOSE weightcursor

DEALLOCATE weightcursor


SELECT * FROM ##TempWeights