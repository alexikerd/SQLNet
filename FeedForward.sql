DROP TABLE IF EXISTS #Inputs
DROP TABLE IF EXISTS ##InputFeed
DROP TABLE IF EXISTS ##HiddenLayer
DROP TABLE IF EXISTS ##OutputLayer
DROP TABLE IF EXISTS ##FinalTable
DROP TABLE IF EXISTS ##NeuralNetwork




/*
Set is randomly chosen (to determine which fold we are using)
*/

DECLARE @inputlayer INT = 53
DECLARE @hiddenlayer INT = 2
DECLARE @Set INT = ABS(CHECKSUM(NEWID()))%4
DECLARE @Input2 VARCHAR(16)


DECLARE @Test INT = 0







/*
For training/test, we just have to change the @Test variable.  However, the data set is unbalanced (~77% unmarried).  Therefore, the commented out select statement was used in order to test the classifier on a balanced dataset.
Even though it was trained on an unbalanced dataset it should perform fine on the test set.
*/




SELECT *
INTO ##NeuralNetwork
FROM ##TempTable tt
JOIN ##TempWeights tw ON tw.WeightId = tt.NNID
WHERE (tt.EmployeeID IN (SELECT DISTINCT EmployeeID FROM ##TrainNeuralNetwork WHERE [Set] = @Set) AND @Test=0) OR (tt.EmployeeID IN (SELECT DISTINCT EmployeeID FROM ##TestNeuralNetwork) AND @Test=1)





--SELECT * 
--INTO ##NeuralNetwork
--FROM (
--	SELECT *
--	FROM ##TempTable tt
--	JOIN ##TempWeights tw ON tw.WeightId = tt.NNID
--	WHERE tt.EmployeeID IN (SELECT DISTINCT EmployeeID FROM ##TestNeuralNetwork) AND [Married] = 1
	
--	UNION

--	SELECT TOP(33) PERCENT *
--	FROM ##TempTable tt
--	JOIN ##TempWeights tw ON tw.WeightId = tt.NNID
--	WHERE tt.EmployeeID IN (SELECT DISTINCT EmployeeID FROM ##TestNeuralNetwork) AND [Married] = 0
--  ) AS tmp;









CREATE TABLE #Inputs
(
Input VARCHAR(16)
)



INSERT INTO #Inputs
(
    Input
)
VALUES
('AGE')
,('GENDER')
,('WAGE')
,('HOURS')


INSERT INTO #Inputs
(
    Input
)
SELECT DISTINCT 
	statecode 
FROM ##States
ORDER BY statecode ASC



CREATE TABLE ##OutputLayer
	(
	EmployeeID VARCHAR(16)
	)




DECLARE @HiddenCounter INT = 1

/*
standardizing how each weight corresponds to a certain input value
*/
	
SELECT 
	Input
	,ROW_NUMBER() OVER (ORDER BY 
							CASE [Input] 
								WHEN 'AGE' THEN 1 
								WHEN 'GENDER' THEN 2 
								WHEN 'WAGE' THEN 3 
								WHEN 'HOURS' THEN 4 
								ELSE 5 END
						,Input) AS 'Weight Number'
INTO ##InputFeed
FROM #Inputs 
ORDER BY 
	CASE [Input] 
		WHEN 'AGE' THEN 1 
		WHEN 'GENDER' THEN 2 
		WHEN 'WAGE' THEN 3 
		WHEN 'HOURS' THEN 4 
		ELSE 5 END
	,Input



DECLARE @ActivationFunction VARCHAR(MAX) = 'UPDATE ##HiddenLayer
											SET '

DECLARE @feedforward VARCHAR(MAX) = 'SELECT EmployeeID, NNID, '

DECLARE @FinalPass VARCHAR(MAX) = 'INSERT INTO ##OutputLayer (EmployeeID, ' 
DECLARE @FinalPass2 VARCHAR(MAX) = ''
DECLARE @FinalPass3 VARCHAR(MAX) = ') SELECT EmployeeID, '
DECLARE @FinalPass4 VARCHAR(MAX) = ''

DECLARE @feedweights VARCHAR(MAX) = ''
DECLARE @buildoutputtable VARCHAR(MAX) = 'ALTER TABLE ##OutputLayer ADD '



DECLARE @FinalTableCreation1 VARCHAR(MAX) = 'SELECT nn.EmployeeID, '
DECLARE @FinalTableCreation2 VARCHAR(MAX) = ''
DECLARE @FinalTableCreation3 VARCHAR(MAX) = ''
DECLARE @FinalTableCreation4 VARCHAR(MAX) = ''
DECLARE @FinalTableCreation5 VARCHAR(MAX) = '1/(1+EXP(-1*('
DECLARE @FinalTableCreation6 VARCHAR(MAX) = ''
DECLARE @FinalTableCreation7 VARCHAR(MAX) = ''


WHILE @HiddenCounter < @hiddenlayer + 1
	BEGIN
    

	DECLARE @Input VARCHAR(16);
	DECLARE @Weight VARCHAR(16);

	DECLARE feedcursor CURSOR FOR 
		SELECT Input FROM ##InputFeed

	
	OPEN feedcursor


	FETCH NEXT FROM feedcursor INTO @Input

	SET @ActivationFunction = @ActivationFunction + 'hl_' + STR(@HiddenCounter,LEN(@HiddenCounter)) +  ' = [hl_' + STR(@HiddenCounter,LEN(@HiddenCounter)) + '] , '

	SET @FinalPass3 = @FinalPass3 + 'CASE WHEN RAND() > 0.2 OR ' + STR(@Test,1) + ' = 1 THEN [w2_' + STR(@HiddenCounter,LEN(@HiddenCounter)) + '_1]*[hl_' + STR(@HiddenCounter,LEN(@HiddenCounter)) + '] ELSE 0 END AS ol_' + STR(@HiddenCounter,LEN(@HiddenCounter)) + ', '

	SET @FinalPass4 = @FinalPass4 + 'ol_' + STR(@HiddenCounter,LEN(@HiddenCounter)) + ', '


	SET @feedweights = @feedweights + ', [w2_' + STR(@HiddenCounter,LEN(@HiddenCounter)) + '_1]'

	SET @buildoutputtable = @buildoutputtable + 'ol_' + STR(@HiddenCounter,LEN(@HiddenCounter)) + ' Float(16), '

	WHILE @@FETCH_STATUS = 0
		BEGIN
	
	
		SET @Weight = (SELECT [Weight Number] FROM ##InputFeed WHERE Input = @Input);

		SET @feedforward = @feedforward + '[' + @Input + ']*[w_' + @Weight + '_' + STR(@HiddenCounter,LEN(@HiddenCounter)) + '] + '
	

		SET @FinalTableCreation2 = @FinalTableCreation2 + 'nn.[w_' + @Weight + '_' + STR(@HiddenCounter,LEN(@HiddenCounter)) + '], '

		FETCH NEXT FROM feedcursor INTO @Input
		END

	
	SET @feedforward = @feedforward + ' b_' + STR(@HiddenCounter,LEN(@HiddenCounter)) + ' AS hl_' + STR(@HiddenCounter,LEN(@HiddenCounter)) + ', '

	SET @FinalTableCreation3 = @FinalTableCreation3 + 'nn.[w2_' + STR(@HiddenCounter,LEN(@HiddenCounter)) + '_1], '

	SET @FinalTableCreation4 = @FinalTableCreation4 + '[hl_' + STR(@HiddenCounter,LEN(@HiddenCounter)) + '], '

	SET @FinalTableCreation6 = @FinalTableCreation6 + '[ol_' + STR(@HiddenCounter,LEN(@HiddenCounter)) + '], '

	SET @FinalTableCreation5 = @FinalTableCreation5 + '[ol_' + STR(@HiddenCounter,LEN(@HiddenCounter)) + '] + '

	SET @FinalTableCreation7 = @FinalTableCreation7 + 'nn.[b_' + STR(@HiddenCounter,LEN(@HiddenCounter)) + '], '

	CLOSE feedcursor
	DEALLOCATE feedcursor
	
	SET @HiddenCounter += 1

	END

DECLARE inputcursor CURSOR FOR
	SELECT input FROM ##InputFeed

OPEN inputcursor

FETCH NEXT FROM inputcursor INTO @Input2

WHILE @@FETCH_STATUS = 0
	BEGIN

	SET @FinalTableCreation1 = @FinalTableCreation1 + '[' + @Input2 + '], '

	FETCH NEXT FROM inputcursor INTO @Input2
	
	END

CLOSE inputcursor
DEALLOCATE inputcursor

SET @feedforward = LEFT(@feedforward,LEN(@feedforward)-1) + @feedweights + ', b2_1 INTO ##HiddenLayer FROM ##NeuralNetwork'

SET @buildoutputtable = @buildoutputtable + 'b2_1 Float(16)'

SET @FinalTableCreation5 = @FinalTableCreation5 + 'nn.b2_1))) AS Prediction, nn.Married INTO ##FinalTable FROM ##NeuralNetwork nn JOIN ##HiddenLayer hl ON hl.Employeeid = nn.EmployeeId JOIN ##OutputLayer ol ON ol.Employeeid = nn.Employeeid'




SET @ActivationFunction = LEFT(@ActivationFunction,LEN(@ActivationFunction)-1) + ' FROM ##HiddenLayer'
 
SET @FinalPass3 = @FinalPass3 + 'b2_1 FROM ##HiddenLayer WHERE EmployeeID = '




EXEC(@feedforward)


/*

@feedforward represents the first pass through to the hidden layer.  The script will then perform dropout before completing the push through the network


SELECT 
	EmployeeID
	,NNID
	,[AGE]*[w_1_1] + [GENDER]*[w_2_1] + [WAGE]*[w_3_1] + [HOURS]*[w_4_1] + [AK]*[w_5_1] + [AL]*[w_6_1] + [AR]*[w_7_1] + [AZ]*[w_8_1] + [CA]*[w_9_1] + [CO]*[w_10_1] + [CT]*[w_11_1] + [DC]*[w_12_1] + [DE]*[w_13_1] + [FL]*[w_14_1] + [GA]*[w_15_1] + [IA]*[w_16_1] + [ID]*[w_17_1] + [IL]*[w_18_1] + [IN]*[w_19_1] + [KS]*[w_20_1] + [KY]*[w_21_1] + [LA]*[w_22_1] + [MA]*[w_23_1] + [MD]*[w_24_1] + [ME]*[w_25_1] + [MI]*[w_26_1] + [MN]*[w_27_1] + [MO]*[w_28_1] + [MS]*[w_29_1] + [MT]*[w_30_1] + [NC]*[w_31_1] + [ND]*[w_32_1] + [NE]*[w_33_1] + [NH]*[w_34_1] + [NJ]*[w_35_1] + [NM]*[w_36_1] + [NV]*[w_37_1] + [NY]*[w_38_1] + [OH]*[w_39_1] + [OK]*[w_40_1] + [OR]*[w_41_1] + [PA]*[w_42_1] + [RI]*[w_43_1] + [SC]*[w_44_1] + [SD]*[w_45_1] + [TN]*[w_46_1] + [TX]*[w_47_1] + [UT]*[w_48_1] + [VA]*[w_49_1] + [WA]*[w_50_1] + [WI]*[w_51_1] + [WV]*[w_52_1] + [WY]*[w_53_1] +  b_1 AS hl_1
	,[AGE]*[w_1_2] + [GENDER]*[w_2_2] + [WAGE]*[w_3_2] + [HOURS]*[w_4_2] + [AK]*[w_5_2] + [AL]*[w_6_2] + [AR]*[w_7_2] + [AZ]*[w_8_2] + [CA]*[w_9_2] + [CO]*[w_10_2] + [CT]*[w_11_2] + [DC]*[w_12_2] + [DE]*[w_13_2] + [FL]*[w_14_2] + [GA]*[w_15_2] + [IA]*[w_16_2] + [ID]*[w_17_2] + [IL]*[w_18_2] + [IN]*[w_19_2] + [KS]*[w_20_2] + [KY]*[w_21_2] + [LA]*[w_22_2] + [MA]*[w_23_2] + [MD]*[w_24_2] + [ME]*[w_25_2] + [MI]*[w_26_2] + [MN]*[w_27_2] + [MO]*[w_28_2] + [MS]*[w_29_2] + [MT]*[w_30_2] + [NC]*[w_31_2] + [ND]*[w_32_2] + [NE]*[w_33_2] + [NH]*[w_34_2] + [NJ]*[w_35_2] + [NM]*[w_36_2] + [NV]*[w_37_2] + [NY]*[w_38_2] + [OH]*[w_39_2] + [OK]*[w_40_2] + [OR]*[w_41_2] + [PA]*[w_42_2] + [RI]*[w_43_2] + [SC]*[w_44_2] + [SD]*[w_45_2] + [TN]*[w_46_2] + [TX]*[w_47_2] + [UT]*[w_48_2] + [VA]*[w_49_2] + [WA]*[w_50_2] + [WI]*[w_51_2] + [WV]*[w_52_2] + [WY]*[w_53_2] +  b_2 AS hl_2
	,[w2_1_1]
	,[w2_2_1]
	,b2_1 
INTO ##HiddenLayer 
FROM ##NeuralNetwork
*/






EXEC(@ActivationFunction)

/*
@ActivationFunction is where the activation function happens on the hidden layer.  However, I found that the RELU activation function allowed the neural network to cheat the system so I removed it.

UPDATE ##HiddenLayer             
SET hl_1 = [hl_1] 
	,hl_2 = [hl_2]  
FROM ##HiddenLayer
*/





EXEC(@buildoutputtable)

/*
@bildoutputtable sets up the outputlayer so that the results from dropout have a place to populate

ALTER TABLE ##OutputLayer 
ADD ol_1 Float(16)
	,ol_2 Float(16)
	,b2_1 Float(16)
*/







DECLARE @empid VARCHAR(MAX)

DECLARE finalcursor CURSOR FOR
	SELECT DISTINCT EmployeeID FROM ##HiddenLayer

OPEN finalcursor

FETCH NEXt FROM finalcursor INTO @empid

DECLARE @prodpass VARCHAR(MAX) = @FinalPass2 + @FinalPass + @finalpass4 + 'b2_1 ' + @FinalPass3

IF @Test = 0
	BEGIN
    
	WHILE @@FETCH_STATUS = 0
		BEGIN



		SET @FinalPass2 = @FinalPass + @finalpass4 + 'b2_1 ' + @FinalPass3 + STR(@empid)

		EXEC(@FinalPass2)

		FETCH NEXT FROM finalcursor INTO @empid

		END
	END

CLOSE finalcursor
DEALLOCATE finalcursor

/*
This method, while scalable for any number of hiddenlayers, takes forever to process as it performs dropout one by one for each employee.  The main improvemet I made to this was to spell everything out

INSERT INTO ##OutputLayer (EmployeeID
	,ol_1
	,ol_2
	,b2_1 ) SELECT EmployeeID
	,CASE WHEN RAND() > 0.2 OR 0 = 1 THEN [w2_1_1]*[hl_1] ELSE 0 END AS ol_1
	,CASE WHEN RAND() > 0.2 OR 0 = 1 THEN [w2_2_1]*[hl_2] ELSE 0 END AS ol_2
	,b2_1 
FROM ##HiddenLayer 
WHERE EmployeeID =  [@empid]
*/




/*
This is the 'improved' dropout method

A new column is added to the neural network

ALTER TABLE ##NeuralNetwork
ADD [Dropout] INT 

UPDATE ##NeuralNetwork
SET [Dropout] = ABS(CHECKSUM(NEWID()))%100

And then the activation function can be changed to account for this

UPDATE ##HiddenLayer
SET hl_1 = CASE WHEN nn.Dropout < 64 OR (nn.Dropout >= 64 AND nn.Dropout < 80 AND 1 = 1) OR (nn.Dropout >= 80 AND nn.Dropout < 96 AND 1 = 2) THEN hl.[hl_1] ELSE 0 END
	,hl_2 = CASE WHEN nn.Dropout < 64 OR (nn.Dropout >= 64 AND nn.Dropout < 80 AND 2 = 1) OR (nn.Dropout >= 80 AND nn.Dropout < 96 AND 2 = 2) THEN hl.[hl_2] ELSE 0 END 
FROM ##HiddenLayer hl 
JOIN ##NeuralNetwork nn on nn.EmployeeID = hl.EmployeeID


Where the 1=1 and 2=2 means that they are the conditions for the first and second hidden layers respectively.  Because the script is generated iteratively, I allowed for the conditions to both satisfy both kinds of dropout
This solution obviously does not scale well, although it brought down the run time of the feedforward SP from ~12m to ~1m.  

*/
















SET @prodpass = LEFT(@prodpass,LEN(@prodpass)-19)

IF @Test = 1
	BEGIN
    EXEC(@prodpass)
	END


SET @FinalTableCreation1 = @FinalTableCreation1 + @FinalTableCreation2 + @FinalTableCreation7 + @FinalTableCreation3 + @FinalTableCreation4 + 'nn.[b2_1], ' + @FinalTableCreation6 + @FinalTableCreation5

EXEC(@FinalTableCreation1)

/*
@FinalTableCreation1 sets up the end result of the feedfoward.  This table makes backpropogation really easy as it retains all results

SELECT nn.EmployeeID
	,[AGE]
	,[GENDER]
	,[WAGE]
	,[HOURS]
	,[AK]
	,[AL]
	,[AR]
	,[AZ]
	,[CA]
	,[CO]
	,[CT]
	,[DC]
	,[DE]
	,[FL]
	,[GA]
	,[IA]
	,[ID]
	,[IL]
	,[IN]
	,[KS]
	,[KY]
	,[LA]
	,[MA]
	,[MD]
	,[ME]
	,[MI]
	,[MN]
	,[MO]
	,[MS]
	,[MT]
	,[NC]
	,[ND]
	,[NE]
	,[NH]
	,[NJ]
	,[NM]
	,[NV]
	,[NY]
	,[OH]
	,[OK]
	,[OR]
	,[PA]
	,[RI]
	,[SC]
	,[SD]
	,[TN]
	,[TX]
	,[UT]
	,[VA]
	,[WA]
	,[WI]
	,[WV]
	,[WY]
	,nn.[w_1_1]
	,nn.[w_2_1]
	,nn.[w_3_1]
	,nn.[w_4_1]
	,nn.[w_5_1]
	,nn.[w_6_1]
	,nn.[w_7_1]
	,nn.[w_8_1]
	,nn.[w_9_1]
	,nn.[w_10_1]
	,nn.[w_11_1]
	,nn.[w_12_1]
	,nn.[w_13_1]
	,nn.[w_14_1]
	,nn.[w_15_1]
	,nn.[w_16_1]
	,nn.[w_17_1]
	,nn.[w_18_1]
	,nn.[w_19_1]
	,nn.[w_20_1]
	,nn.[w_21_1]
	,nn.[w_22_1]
	,nn.[w_23_1]
	,nn.[w_24_1]
	,nn.[w_25_1]
	,nn.[w_26_1]
	,nn.[w_27_1]
	,nn.[w_28_1]
	,nn.[w_29_1]
	,nn.[w_30_1]
	,nn.[w_31_1]
	,nn.[w_32_1]
	,nn.[w_33_1]
	,nn.[w_34_1]
	,nn.[w_35_1]
	,nn.[w_36_1]
	,nn.[w_37_1]
	,nn.[w_38_1]
	,nn.[w_39_1]
	,nn.[w_40_1]
	,nn.[w_41_1]
	,nn.[w_42_1]
	,nn.[w_43_1]
	,nn.[w_44_1]
	,nn.[w_45_1]
	,nn.[w_46_1]
	,nn.[w_47_1]
	,nn.[w_48_1]
	,nn.[w_49_1]
	,nn.[w_50_1]
	,nn.[w_51_1]
	,nn.[w_52_1]
	,nn.[w_53_1]
	,nn.[w_1_2]
	,nn.[w_2_2]
	,nn.[w_3_2]
	,nn.[w_4_2]
	,nn.[w_5_2]
	,nn.[w_6_2]
	,nn.[w_7_2]
	,nn.[w_8_2]
	,nn.[w_9_2]
	,nn.[w_10_2]
	,nn.[w_11_2]
	,nn.[w_12_2]
	,nn.[w_13_2]
	,nn.[w_14_2]
	,nn.[w_15_2]
	,nn.[w_16_2]
	,nn.[w_17_2]
	,nn.[w_18_2]
	,nn.[w_19_2]
	,nn.[w_20_2]
	,nn.[w_21_2]
	,nn.[w_22_2]
	,nn.[w_23_2]
	,nn.[w_24_2]
	,nn.[w_25_2]
	,nn.[w_26_2]
	,nn.[w_27_2]
	,nn.[w_28_2]
	,nn.[w_29_2]
	,nn.[w_30_2]
	,nn.[w_31_2]
	,nn.[w_32_2]
	,nn.[w_33_2]
	,nn.[w_34_2]
	,nn.[w_35_2]
	,nn.[w_36_2]
	,nn.[w_37_2]
	,nn.[w_38_2]
	,nn.[w_39_2]
	,nn.[w_40_2]
	,nn.[w_41_2]
	,nn.[w_42_2]
	,nn.[w_43_2]
	,nn.[w_44_2]
	,nn.[w_45_2]
	,nn.[w_46_2]
	,nn.[w_47_2]
	,nn.[w_48_2]
	,nn.[w_49_2]
	,nn.[w_50_2]
	,nn.[w_51_2]
	,nn.[w_52_2]
	,nn.[w_53_2]
	,nn.[b_1]
	,nn.[b_2]
	,nn.[w2_1_1]
	,nn.[w2_2_1]
	,[hl_1]
	,[hl_2]
	,nn.[b2_1]
	,[ol_1]
	,[ol_2]
	,1/(1+EXP(-1*([ol_1] + [ol_2] + nn.b2_1))) AS Prediction
	,nn.Married 
INTO ##FinalTable 
FROM ##NeuralNetwork nn 
JOIN ##HiddenLayer hl ON hl.Employeeid = nn.EmployeeId 
JOIN ##OutputLayer ol ON ol.Employeeid = nn.Employeeid
*/


ALTER TABLE ##FinalTable
ADD [Loss Unit] FLOAT
	,[Base Delta] FLOAT;


UPDATE ##FinalTable
SET [Loss Unit] = [Married]-[Prediction]
	,[Base Delta] = 2*([Married]-[Prediction])*([Prediction])*(1-[Prediction])



SELECT * FROM ##FinalTable




INSERT INTO ##ProgressTracker
(
	LOSS
	,Overall_SR
	,Positive_SR
    ,Negative_SR
    ,True_Percentage
	,Test_Train
)
SELECT
	AVG(SQUARE([Loss Unit])) AS 'LOSS'
	,CONVERT(FLOAT, SUM(CASE WHEN CASE WHEN [Prediction] >= .5 THEN 1 ELSE 0 END = [Married] THEN 1 ELSE 0 END))/CONVERT(FLOAT,COUNT(*)) AS 'Overall Success Rate'
	,CONVERT(FLOAT, SUM(CASE WHEN [Prediction] >= .5 AND [Married] = 1 THEN 1 ELSE 0 END))/CONVERT(FLOAT,SUM(CASE WHEN [Married] = 1 THEN 1 ELSE 0 END)) AS 'Positive Success Rate'
	,CONVERT(FLOAT, SUM(CASE WHEN [Prediction] < .5 AND [Married] = 0 THEN 1 ELSE 0 END))/CONVERT(FLOAT,SUM(CASE WHEN [Married] = 0 THEN 1 ELSE 0 END)) AS 'Negative Success Rate'
	,CONVERT(FLOAT, SUM(CASE WHEN [Married] = 1 THEN 1 ELSE 0 END))/CONVERT(FLOAT,COUNT(*)) AS 'Percentage Married'
	,CASE WHEN @Test = 1 THEN 20 ELSE @Set END AS 'Test_Train'
FROM ##FinalTable



SELECT * FROM ##ProgressTracker

