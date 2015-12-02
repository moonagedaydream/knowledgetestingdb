--//-------------------------------------------------------
--//---ДОБАВЛЕНИЕ ВАРИАНТА ОТВЕТА--------------------------
--//-------------------------------------------------------
IF OBJECTPROPERTY(object_id('dbo.addAnswer'), N'IsProcedure') = 1
  DROP PROCEDURE [dbo].[addAnswer]
GO
CREATE PROCEDURE addAnswer @question_id UNIQUEIDENTIFIER, @answer_text VARCHAR(300), @answer_order INT, @is_correct BIT = NULL
  AS
  INSERT INTO Answers (question_id, answer_text, answer_order, is_correct) 
          VALUES (@question_id, @answer_text, @answer_order, @is_correct);
GO

--//-------------------------------------------------------
--//---ДОБАВЛЕНИЕ ВОПРОСА----------------------------------
--//-------------------------------------------------------
IF OBJECTPROPERTY(object_id('dbo.addQuestion'), N'IsProcedure') = 1
  DROP PROCEDURE [dbo].[addQuestion]
GO
CREATE PROCEDURE addQuestion @subtest_id UNIQUEIDENTIFIER, @question_type VARCHAR(50), @question_text VARCHAR(300), 
							@question_filename VARCHAR(50) = NULL, @question_filepath VARCHAR(300) = NULL, @question_order INT = NULL,
							@question_id UNIQUEIDENTIFIER OUTPUT
  AS
  SET @question_id = NEWID();
  DECLARE @qtype INT = (SELECT TOP 1 qtype_id FROM Question_types WHERE qtype_name = @question_type);
  --извлекаем файл
  DECLARE @qfiledata VARBINARY(MAX);
  DECLARE @sqlCommand nvarchar(max);
  SET @sqlCommand = 'SELECT @qfiledata= (SELECT * FROM OPENROWSET(BULK ''' + @question_filepath + ''', SINGLE_BLOB) AS x)';
  EXEC sp_executesql @sqlCommand, N'@qfiledata VARBINARY(MAX) OUTPUT', @qfiledata = @qfiledata OUTPUT;
  --
  INSERT INTO Questions(question_id, subtest_id, question_type, question_text, question_filename, question_filedata,
						question_order, creation_date, edit_date) 
				VALUES
  (@question_id, @subtest_id, @qtype, @question_text, @question_filename, @qfiledata, @question_order, GETDATE(), NULL);
  RETURN
GO

--//-------------------------------------------------------
--//---ДОБАВЛЕНИЕ САБТЕСТА---------------------------------
--//-------------------------------------------------------
IF OBJECTPROPERTY(object_id('dbo.addSubtest'), N'IsProcedure') = 1
  DROP PROCEDURE [dbo].[addSubtest]
GO
CREATE PROCEDURE addSubtest @test_id UNIQUEIDENTIFIER, @subtest_maxscores INT, @subtest_totaltime_minutes INT = NULL, @subtest_name VARCHAR(50) = NULL, @subtest_instruction VARCHAR(MAX) = NULL, 
							@subtest_filename VARCHAR(50) = NULL, @subtest_filepath VARCHAR(300) = NULL,
							@subtest_id UNIQUEIDENTIFIER OUTPUT
  AS
  SET @subtest_id = NEWID();
  --извлекаем файл
  DECLARE @sfiledata VARBINARY(MAX);
  DECLARE @sqlCommand nvarchar(max);
  SET @sqlCommand = 'SELECT @sfiledata= (SELECT * FROM OPENROWSET(BULK ''' + @subtest_filepath + ''', SINGLE_BLOB) AS x)';
  EXEC sp_executesql @sqlCommand, N'@sfiledata VARBINARY(MAX) OUTPUT', @sfiledata = @sfiledata OUTPUT;
  --
  INSERT INTO Subtests(subtest_id, test_id, subtest_name, subtest_instruction, subtest_filename, subtest_filedata, subtest_totaltime_minutes, subtest_maxscores, creation_date,
						edit_date) 
				VALUES
  (@subtest_id, @test_id, @subtest_name, @subtest_instruction, @subtest_filename, @sfiledata, @subtest_totaltime_minutes, @subtest_maxscores, GETDATE(), NULL);
  RETURN
GO

--//-------------------------------------------------------
--//---ДОБАВЛЕНИЕ ТЕСТА------------------------------------
--//-------------------------------------------------------
IF OBJECTPROPERTY(object_id('dbo.addTest'), N'IsProcedure') = 1
  DROP PROCEDURE [dbo].[addTest]
GO
CREATE PROCEDURE addTest @test_name VARCHAR(50) = NULL, @test_branch VARCHAR(50) = 'Central', @test_instruction VARCHAR(MAX) = NULL, 
							@test_filename VARCHAR(50) = NULL, @test_filepath VARCHAR(300) = NULL, @test_totaltime_minutes INT = NULL,
							@test_id UNIQUEIDENTIFIER OUTPUT							
  AS
  SET @test_id = NEWID();
  --извлекаем файл
  DECLARE @tfiledata VARBINARY(MAX);
  DECLARE @sqlCommand nvarchar(max);
  SET @sqlCommand = 'SELECT @tfiledata= (SELECT * FROM OPENROWSET(BULK ''' + @test_filepath + ''', SINGLE_BLOB) AS x)';
  EXEC sp_executesql @sqlCommand, N'@tfiledata VARBINARY(MAX) OUTPUT', @tfiledata = @tfiledata OUTPUT;
  --
  DECLARE @branch INT = (SELECT TOP 1 branch_id FROM Branches WHERE branch_name = @test_branch);
  INSERT INTO Tests(test_id, test_name, test_branch, test_instruction, test_filename, test_filedata, test_totaltime_minutes, creation_date,
						edit_date) 
				VALUES
  (@test_id, @test_name, @branch, @test_instruction, @test_filename, @tfiledata, @test_totaltime_minutes, GETDATE(), NULL);
GO

--//-------------------------------------------------------
--//---ДОБАВЛЕНИЕ ПОЛЬЗОВАТЕЛЯ-----------------------------
--//-------------------------------------------------------
IF OBJECTPROPERTY(object_id('dbo.addUser'), N'IsProcedure') = 1
  DROP PROCEDURE [dbo].[addUser]
GO
CREATE PROCEDURE addUser  @user_branch VARCHAR(50), @user_name VARCHAR(50), @user_surname VARCHAR(50), @user_middlename VARCHAR(50) = NULL, 
							@user_mail VARCHAR(50) = NULL, @user_login VARCHAR(50), @user_password VARCHAR(300), @usertype VARCHAR(50) = 'Student'					
  AS
  DECLARE @type_id INT = (SELECT TOP 1 usertype_id FROM Usertypes WHERE usertype_name = @usertype);
  DECLARE @branch INT = (SELECT TOP 1 branch_id FROM Branches WHERE branch_name = @user_branch);
  INSERT INTO Users(user_branch, user_name, user_surname, user_middlename, user_mail, user_login, user_password,
						usertype_id) 
				VALUES
  (@branch, @user_name, @user_surname, @user_middlename, @user_mail, @user_login, @user_password, @type_id);
GO

--//-------------------------------------------------------
--//---ДОБАВЛЕНИЕ ОТВЕТА СТУДЕНТА НА ВОПРОС----------------
--//-------------------------------------------------------
IF OBJECTPROPERTY(object_id('dbo.addUserAnswer'), N'IsProcedure') = 1
  DROP PROCEDURE [dbo].[addUserAnswer]
GO
CREATE PROCEDURE addUserAnswer @user_id UNIQUEIDENTIFIER, @usubtest_id UNIQUEIDENTIFIER, @question_id UNIQUEIDENTIFIER, 
								@answer_id UNIQUEIDENTIFIER = NULL, @answer_text VARCHAR(MAX) = NULL, 
								@answer_filename VARCHAR(50) = NULL, @answer_filepath VARCHAR(300) = NULL
  AS
  DECLARE @qtype VARCHAR(50) = (SELECT qtype_name FROM Question_types, Questions WHERE qtype_id = question_type AND question_id = @question_id)
  IF (@qtype = 'Closed')
  BEGIN
    DECLARE @isCorrect BIT = (SELECT is_correct FROM Answers WHERE answer_id = @answer_id);
    INSERT INTO User_answers(user_id, usubtest_id, answer_id, question_id, answer_score) VALUES
	  (@user_id, @usubtest_id, @answer_id, @question_id, @isCorrect)
  END
  ELSE IF (@qtype = 'Open')
  BEGIN
    INSERT INTO User_answers(user_id, usubtest_id, question_id, answer_text)
          VALUES (@user_id, @usubtest_id, @question_id, @answer_text)
  END
  ELSE IF (@qtype = 'Spoken')
  BEGIN
    --извлекаем файл
    DECLARE @afiledata VARBINARY(MAX);
    DECLARE @sqlCommand nvarchar(max);
    SET @sqlCommand = 'SELECT @afiledata= (SELECT * FROM OPENROWSET(BULK ''' + @answer_filepath + ''', SINGLE_BLOB) AS x)';
    EXEC sp_executesql @sqlCommand, N'@afiledata VARBINARY(MAX) OUTPUT', @afiledata = @afiledata OUTPUT;
    --
    INSERT INTO User_answers(user_id, usubtest_id, question_id, answer_filename, answer_filedata) 
          VALUES
	    (@user_id, @usubtest_id, @question_id, @answer_filename, @afiledata)
  END
GO

--//-------------------------------------------------------
--//---ДОБАВЛЕНИЕ ПОЛЬЗОВАТЕЛЬСКОГО САБТЕСТА---------------
--//-------------------------------------------------------
IF OBJECTPROPERTY(object_id('dbo.addUserSubtest'), N'IsProcedure') = 1
  DROP PROCEDURE [dbo].[addUserSubtest]
GO
CREATE PROCEDURE addUserSubtest @user_id UNIQUEIDENTIFIER, @utest_id UNIQUEIDENTIFIER, @subtest_id UNIQUEIDENTIFIER,
								@usubtest_id UNIQUEIDENTIFIER OUTPUT
  AS
  SET @usubtest_id = NEWID();
  INSERT INTO User_subtests(usubtest_id, user_id, utest_id, subtest_id) VALUES
	  (@usubtest_id, @user_id, @utest_id, @subtest_id)
  RETURN
GO

--//-------------------------------------------------------
--//---ДОБАВЛЕНИЕ ПОЛЬЗОВАТЕЛЬСКОГО ТЕСТА------------------
--//-------------------------------------------------------
IF OBJECTPROPERTY(object_id('dbo.addUserTest'), N'IsProcedure') = 1
  DROP PROCEDURE [dbo].[addUserTest]
GO
CREATE PROCEDURE addUserTest @user_id UNIQUEIDENTIFIER, @test_id UNIQUEIDENTIFIER, @evaluation_type VARCHAR(50),
								@utest_id UNIQUEIDENTIFIER OUTPUT
  AS
  SET @utest_id = NEWID();
  DECLARE @type_id INT = (SELECT TOP 1 type_id FROM Test_evaluation_types WHERE type_name = @evaluation_type);
  INSERT INTO User_tests(utest_id, user_id, test_id, evaluation_type, test_senddate) VALUES
  	(@utest_id, @user_id, @test_id, @type_id, GETDATE())
RETURN
GO

--//-------------------------------------------------------
--//---выставляем баллы за открытые и устные вопросы-------
--//-------------------------------------------------------
IF OBJECTPROPERTY(object_id('dbo.checkUserAnswer'), N'IsProcedure') = 1
  DROP PROCEDURE [dbo].[checkUserAnswer]
GO
CREATE PROCEDURE checkUserAnswer @uanswer_id UNIQUEIDENTIFIER, @answer_score INT
  AS
  UPDATE User_answers SET answer_score = @answer_score
  WHERE uanswer_id = @uanswer_id
GO

--//-------------------------------------------------------
--//---проверка сабтестов (высчитываем процент правильных--
--//---ответов, проверяем по таблице, выставляем оценку---- 
--//---(можно автоматизировать и перенести в таблицу))-----
--//-------------------------------------------------------
IF OBJECTPROPERTY(object_id('dbo.checkUserSubtest'), N'IsProcedure') = 1
  DROP PROCEDURE [dbo].[checkUserSubtest]
GO
CREATE PROCEDURE checkUserSubtest @usubtest_id UNIQUEIDENTIFIER
  AS
  IF (NOT EXISTS (SELECT * FROM User_answers WHERE usubtest_id = @usubtest_id AND answer_score = NULL))
  BEGIN
    DECLARE @qtype VARCHAR(50) = (SELECT TOP 1 qtype_name FROM Question_types, Questions, User_answers WHERE 
		    usubtest_id = @usubtest_id AND User_answers.question_id = Questions.question_id AND question_type = qtype_id);
    DECLARE @maxscores INT = (SELECT subtest_maxscores FROM Subtests, User_subtests
						WHERE usubtest_id = @usubtest_id AND User_subtests.subtest_id = Subtests.subtest_id);
    IF (@qtype = 'Closed')
    BEGIN
      DECLARE @score FLOAT = @maxscores / (SELECT COUNT(*) FROM Subtests, Questions, User_subtests WHERE  usubtest_id = @usubtest_id
						AND User_subtests.subtest_id = Subtests.subtest_id AND Questions.subtest_id = Subtests.subtest_id);
      UPDATE User_answers SET answer_score = @score
      WHERE answer_score = 1;
    END
    
    DECLARE @userscores INT = (SELECT SUM(answer_score) FROM User_answers WHERE usubtest_id = @usubtest_id);
    DECLARE @percents INT = 100 * @userscores / @maxscores;

    UPDATE User_subtests SET usubtest_scores = @userscores
      WHERE usubtest_id = @usubtest_id;

    IF (@percents >= 85) 
    BEGIN
      UPDATE User_subtests SET usubtest_mark = 5
        WHERE usubtest_id = @usubtest_id;
    END
    ELSE IF (@percents >= 65) 
    BEGIN
      UPDATE User_subtests SET usubtest_mark = 4
        WHERE usubtest_id = @usubtest_id;
    END
    ELSE IF (@percents >= 50) 
    BEGIN
      UPDATE User_subtests SET usubtest_mark = 3
        WHERE usubtest_id = @usubtest_id;
    END
    ELSE BEGIN
      UPDATE User_subtests SET usubtest_mark = 2
        WHERE usubtest_id = @usubtest_id;
    END
  END
GO
