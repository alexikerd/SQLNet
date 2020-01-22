
/*
Initializing the weights for the neural network, in the format of a single row with one column per weight in the network.  This makes forward propogation much easier given this is in SQL
*/




DROP TABLE IF EXISTS ##TempWeights
DROP TABLE IF EXISTS ##WeightList









DECLARE @inputlayer INT = 52
DECLARE @hiddenlayer INT = 2

DECLARE @inputcount INT = 1
DECLARE @hiddencount INT = 1

CREATE TABLE ##WeightList
(
Weight VARCHAR(16)
)


CREATE TABLE ##TempWeights
	(
	WeightID VARCHAR(64)
	)




/*
The weight id is the unique name of the neural network.  In the case of multiple networks, each row would be it's own set of weights for the network and the first column would be its id
The next section iteratively generates a new column for each weight and then adds a random value (0-1 for weights, 0-1/3 for first set of biases, and 0 for the second bias)
*/


INSERT INTO ##TempWeights
(
    WeightID
)
VALUES
(STR(@inputlayer,LEN(@inputlayer)) + 'x' + STR(@hiddenlayer,LEN(@hiddenlayer)) -- WeightID - varchar(64)
    )


WHILE @inputcount < @inputlayer + 1
	BEGIN


	SET @hiddencount = 1

	WHILE @hiddencount < @hiddenlayer + 1
		BEGIN

		DECLARE @Weight VARCHAR(64) = 'w_' + STR(@inputcount,LEN(@inputcount))+ '_' + STR(@hiddencount,LEN(@hiddencount))

		DECLARE @addcolumn NVARCHAR(MAX) = 'ALTER TABLE ##TempWeights
											ADD [' + @Weight + '] FLOAT(8);'
		EXEC(@addcolumn)

		DECLARE @addweight VARCHAR(MAX) = 'INSERT INTO ##WeightList (Weight) VALUES (''' + @Weight + ''')'

		EXEC(@addweight)

		DECLARE @addvalues NVARCHAR(MAX) = 'UPDATE ##TempWeights
										SET [' + @Weight + '] = RAND();
										'
		EXEC(@addvalues)

		SET @hiddencount += 1

		END

	SET @inputcount += 1

	END

DECLARE @biascount INT = 1

WHILE @biascount < @hiddenlayer + 1
	BEGIN

	DECLARE @Bias VARCHAR(8) = 'b_' + STR(@biascount,1)

	DECLARE @addbiascolumn NVARCHAR(MAX) = 'ALTER TABLE ##TempWeights
											ADD [' + @Bias + '] FLOAT(8);'
	EXEC(@addbiascolumn)

	DECLARE @addweight2 VARCHAR(MAX) = 'INSERT INTO ##WeightList (Weight) VALUES (''' + @Bias + ''')'

	EXEC(@addweight2)

	DECLARE @addbiasvalues NVARCHAR(MAX) = 'UPDATE ##TempWeights
										SET [' + @Bias + '] = RAND()/3;
										'
	EXEC(@addbiasvalues)

	SET @biascount += 1

	END







DECLARE @inputcount2 INT = 1




WHILE @inputcount2 < @hiddenlayer + 1
	BEGIN



	DECLARE @Weight2 VARCHAR(64) = 'w2_' + STR(@inputcount2,LEN(@inputcount2)) + '_1'

	DECLARE @addcolumn2 NVARCHAR(MAX) = 'ALTER TABLE ##TempWeights
											ADD [' + @Weight2 + '] FLOAT(8);'
	EXEC(@addcolumn2)

	DECLARE @addweight3 VARCHAR(MAX) = 'INSERT INTO ##WeightList (Weight) VALUES (''' + @Weight2 + ''')'

	EXEC(@addweight3)

	DECLARE @addvalues2 NVARCHAR(MAX) = 'UPDATE ##TempWeights
										SET [' + @Weight2 + '] = RAND();
										'
	EXEC(@addvalues2)


	SET @inputcount2 += 1

	END



DECLARE @Bias2 VARCHAR(8) = 'b2_1'

DECLARE @addbiascolumn2 NVARCHAR(MAX) = 'ALTER TABLE ##TempWeights
											ADD [' + @Bias2 + '] FLOAT(8);'
EXEC(@addbiascolumn2)

DECLARE @addweight4 VARCHAR(MAX) = 'INSERT INTO ##WeightList (Weight) VALUES (''' + @Bias2 + ''')'

EXEC(@addweight4)

DECLARE @addbiasvalues2 NVARCHAR(MAX) = 'UPDATE ##TempWeights
										SET [' + @Bias2 + '] = 0;
										'
EXEC(@addbiasvalues2)





SELECT * FROM ##TempWeights

SELECT * FROM ##WeightList


