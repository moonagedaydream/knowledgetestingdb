IF EXISTS (SELECT * FROM sys.views  WHERE name = 'All Open Questions TO Check')
   DROP VIEW dbo.[All Open Questions TO Check]
GO
CREATE VIEW [All Open Questions TO Check]
AS
	SELECT uanswer_id, User_answers.usubtest_id, utest_id, User_answers.user_id, Questions.question_id, question_text, answer_text  
		FROM User_answers
		INNER JOIN Questions
			ON User_answers.question_id = Questions.question_id
		INNER JOIN Question_types
			ON question_type = qtype_id
		INNER JOIN User_subtests 
			ON User_answers.usubtest_id = User_subtests.usubtest_id
		WHERE qtype_name = 'Open' AND answer_score IS NULL
GO

IF EXISTS (SELECT * FROM sys.views  WHERE name = 'All Spoken Questions TO Check')
   DROP VIEW dbo.[All Spoken Questions TO Check]
GO
CREATE VIEW [All Spoken Questions TO Check]
AS
	SELECT uanswer_id, User_answers.usubtest_id, utest_id, User_answers.user_id, Questions.question_id, question_text, answer_text  
		FROM User_answers
		INNER JOIN Questions
			ON User_answers.question_id = Questions.question_id
		INNER JOIN Question_types
			ON question_type = qtype_id
		INNER JOIN User_subtests 
			ON User_answers.usubtest_id = User_subtests.usubtest_id
		WHERE qtype_name = 'Spoken' AND answer_score IS NULL
GO
