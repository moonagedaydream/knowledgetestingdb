USE KnowledgeTestingDB;

DECLARE @tid UNIQUEIDENTIFIER, @stid UNIQUEIDENTIFIER, @qid UNIQUEIDENTIFIER, 
@qid2 UNIQUEIDENTIFIER, @uid UNIQUEIDENTIFIER, @utid UNIQUEIDENTIFIER, @utid2 UNIQUEIDENTIFIER, 
@ustid UNIQUEIDENTIFIER, @ustid2 UNIQUEIDENTIFIER;

--//-------------------------------------------------------
--//---данные-вспомогательных-таблиц-----------------------
--//-------------------------------------------------------

INSERT INTO Branches (branch_name)
VALUES ('Central'), ('Branch1'), ('Branch2');

INSERT INTO Question_types (qtype_name)
VALUES ('Closed'), ('Open'), ('Spoken');

INSERT INTO Usertypes (usertype_name)
VALUES ('Student'), ('Teacher'), ('Branch Administrator'), ('Central Unit Operator'), ('Central Unit Administrator');

INSERT INTO Test_evaluation_levels (level_name,scores_threshold, acceptable_threshold,good_threshold,excellent_threshold)
VALUES ('First', 50, NULL, 50, 60), ('Second', 60, 60, 70, 80), ('Third', 80, NULL, 80, 90);

--//-------------------------------------------------------
--//---загрузка-основных-таблиц-с-использованием-скриптов--
--//-------------------------------------------------------

--//-пользователь
EXEC addUser 'Central', 'M', 'P', 'V', 'qqq@aa.ru', 'm', '123', 'Student';
SET @uid = (SELECT TOP 1 user_id FROM Users);

--//-тест
EXEC addTest 'NewTest', 'Central', 'Answer all questions', @test_id = @tid OUTPUT;
EXEC addUserTest @uid, @tid, 'Second', @utid OUTPUT;
EXEC addUserTest @uid, @tid, 'First', @utid2 OUTPUT;

--//-первый сабтест
EXEC addSubtest @tid, 30, 10, 'Subtest 1', @subtest_id = @stid OUTPUT;
EXEC addUserSubtest @uid, @utid, @stid, @ustid OUTPUT;
EXEC addUserSubtest @uid, @utid2, @stid, @ustid2 OUTPUT;

EXEC addQuestion @stid, 'Closed', 'What do you wnat from this life?', 1, @question_id = @qid OUTPUT;
EXEC addAnswer @qid, 'nothing', 1, 0; 
EXEC addAnswer @qid, 'to eat something', 2, 0; 
EXEC addAnswer @qid, '42', 3, 1; 

DECLARE @aid UNIQUEIDENTIFIER = (SELECT answer_id FROM Answers WHERE question_id = @qid AND answer_order = 3);
EXEC addUserAnswer @uid, @ustid, @qid, @aid;
SET @aid = (SELECT answer_id FROM Answers WHERE question_id = @qid AND answer_order = 2);
EXEC addUserAnswer @uid, @ustid2, @qid, @aid;

EXEC addQuestion @stid, 'Closed', 'Why do you keep reading it?', 2, @question_id = @qid OUTPUT;
EXEC addAnswer @qid, 'i have nothing to do', 1, 0; 
EXEC addAnswer @qid, 'i''m miserable', 2, 1; 
EXEC addAnswer @qid, 'why not', 3, 0;

SET @aid = (SELECT answer_id FROM Answers WHERE question_id = @qid AND answer_order = 2);
EXEC addUserAnswer @uid, @ustid, @qid, @aid;
EXEC addUserAnswer @uid, @ustid2, @qid, @aid; 

EXEC addQuestion @stid, 'Closed', 'Why do I keep writing it?', 3, @question_id = @qid OUTPUT;
EXEC addAnswer @qid, 'justforfun', 1, 1; 
EXEC addAnswer @qid, 'it''s a secret', 2, 0; 
EXEC addAnswer @qid, 'my life is sad', 3, 0;

SET @aid = (SELECT answer_id FROM Answers WHERE question_id = @qid AND answer_order = 1);
EXEC addUserAnswer @uid, @ustid, @qid, @aid;
SET @aid = (SELECT answer_id FROM Answers WHERE question_id = @qid AND answer_order = 3);
EXEC addUserAnswer @uid, @ustid2, @qid, @aid;

--//-второй сабтест 
EXEC addSubtest @tid, 20, 10, 'Subtest 2', @subtest_id = @stid OUTPUT;
EXEC addUserSubtest @uid, @utid, @stid, @ustid OUTPUT;
EXEC addUserSubtest @uid, @utid2, @stid, @ustid2 OUTPUT;

EXEC addQuestion @stid, 'Open', 'Why do you love databases. Go an write an essay.', 1, @question_id = @qid OUTPUT;

EXEC addUserAnswer @uid, @ustid, @qid, @answer_text = 'Potomychto because';
EXEC addUserAnswer @uid, @ustid2, @qid, @answer_text = 'They''re cool!';

EXEC addQuestion @stid, 'Open', 'Write hello world in assembler.', 2, @question_id = @qid OUTPUT;

EXEC addUserAnswer @uid, @ustid, @qid, @answer_text = 'No.Just.No.';
EXEC addUserAnswer @uid, @ustid2, @qid, @answer_text = 'For $100 i might';

--//-------------------------------------------------------
--//---проверка-работы-основных-скриптов-------------------
--//-------------------------------------------------------

--//--проверка вопросов открытого типа
SET @aid = (SELECT TOP 1 uanswer_id FROM User_answers WHERE answer_text = 'Potomychto because');
EXEC checkUserAnswer @aid, 10;
SET @aid = (SELECT TOP 1 uanswer_id FROM User_answers WHERE answer_text = 'No.Just.No.');
EXEC checkUserAnswer @aid, 5;

--//--автоматическая проверка сабтестов
SET @aid = (SELECT TOP 1 usubtest_id FROM User_subtests, Subtests 
						WHERE User_subtests.subtest_id = Subtests.subtest_id AND utest_id = @utid AND subtest_name = 'Subtest 1');
EXEC checkUserSubtest @aid;
SET @aid = (SELECT TOP 1 usubtest_id FROM User_subtests, Subtests 
						WHERE User_subtests.subtest_id = Subtests.subtest_id AND utest_id = @utid AND subtest_name = 'Subtest 2');
EXEC checkUserSubtest @aid;

--//--автоматическая проверка теста с проверенными сабтестами
EXEC checkUserTest @utid;
