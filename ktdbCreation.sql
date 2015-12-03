--для теста бд директории могут быть изменены по собственному усмотрению
--в данном примере необходимо существование директории D:\KTDB
CREATE DATABASE KnowledgeTestingDB
ON PRIMARY
   (NAME = KnowledgeTestingDB_data,
      FILENAME = N'D:\KTDB\KTDB_data.mdf'),
FILEGROUP FileStreamFileGroup CONTAINS FILESTREAM
   (NAME = FileStreamTestDBDocuments,
      FILENAME = N'D:\KTDB\Documents')
LOG ON
   (NAME = 'KnowledgeTestingDB_log',
      FILENAME = N'D:\KTDB\KTDB_log.ldf');
GO

--создание таблиц
CREATE TABLE Branches
(
branch_id INT IDENTITY(1,1) PRIMARY KEY,
branch_name VARCHAR(50) NOT NULL,
branch_mail VARCHAR(50)
);

CREATE TABLE Tests
(
test_id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWSEQUENTIALID() ROWGUIDCOL,
test_name VARCHAR(50),
test_branch INT NOT NULL FOREIGN KEY REFERENCES Branches(branch_id),
test_instruction VARCHAR(MAX),
test_filename VARCHAR(50),
test_filedata VARBINARY(MAX) FILESTREAM,
test_totaltime_minutes INT,
creation_date DATETIME NOT NULL,
edit_date DATETIME
);


CREATE TABLE Subtests
(
subtest_id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWSEQUENTIALID() ROWGUIDCOL,
test_id UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Tests(test_id),
subtest_name VARCHAR(50),
subtest_instruction VARCHAR(MAX),
subtest_filename VARCHAR(50),
subtest_filedata VARBINARY(MAX) FILESTREAM,
subtest_totaltime_minutes INT,
subtest_maxscores INT NOT NULL,
creation_date DATETIME NOT NULL,
edit_date DATETIME
--оценка
);

CREATE TABLE Question_types
(
qtype_id INT IDENTITY(1,1) PRIMARY KEY,
qtype_name VARCHAR(30) NOT NULL
);

CREATE TABLE Questions
(
question_id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWSEQUENTIALID() ROWGUIDCOL,
subtest_id UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Subtests(subtest_id),
question_type INT NOT NULL FOREIGN KEY REFERENCES Question_types(qtype_id),
question_text VARCHAR(MAX),
question_filename VARCHAR(50),
question_filedata VARBINARY(MAX) FILESTREAM,
question_order INT,
creation_date DATETIME NOT NULL,
edit_date DATETIME 
);

CREATE TABLE Answers
(
answer_id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWSEQUENTIALID() ROWGUIDCOL,
question_id UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Questions(question_id),
answer_text VARCHAR(300) NOT NULL,
answer_order INT,
is_correct BIT  
);

CREATE TABLE Usertypes
(
usertype_id INT IDENTITY(1,1) PRIMARY KEY,
usertype_name VARCHAR(50) NOT NULL
);

CREATE TABLE Users 
(
user_id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWSEQUENTIALID() ROWGUIDCOL,
user_branch INT NOT NULL FOREIGN KEY REFERENCES Branches(branch_id),
user_name VARCHAR(50) NOT NULL,
user_surname  VARCHAR(50) NOT NULL,
user_middlename  VARCHAR(50),
user_mail  VARCHAR(50),
user_login  VARCHAR(50) NOT NULL,
user_password VARCHAR(300) NOT NULL,
usertype_id INT NOT NULL FOREIGN KEY REFERENCES Usertypes(usertype_id)
);

CREATE TABLE Test_evaluation_levels
(
level_id INT IDENTITY(1,1) PRIMARY KEY,
level_name VARCHAR(50) NOT NULL,
scores_threshold INT NOT NULL,
acceptable_threshold INT,
good_threshold INT,
excellent_threshold INT
);

CREATE TABLE User_tests 
(
utest_id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWSEQUENTIALID() ROWGUIDCOL,
user_id UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Users(user_id),
test_id UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Tests(test_id),
evaluation_type INT NOT NULL FOREIGN KEY REFERENCES Test_evaluation_types(type_id),
test_senddate DATETIME NOT NULL,
utest_mark INT
);

CREATE TABLE User_subtests 
(
usubtest_id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWSEQUENTIALID() ROWGUIDCOL,
user_id UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Users(user_id),
utest_id UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES User_tests(utest_id),
subtest_id UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Subtests(subtest_id),
usubtest_scores INT,
usubtest_mark INT
);

CREATE TABLE User_answers
(
uanswer_id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWSEQUENTIALID() ROWGUIDCOL,
user_id UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Users(user_id),
usubtest_id UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES User_subtests(usubtest_id),
answer_id UNIQUEIDENTIFIER FOREIGN KEY REFERENCES Answers(answer_id),
question_id UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Questions(question_id),
answer_text VARCHAR(MAX),
answer_filename VARCHAR(50),
answer_filedata VARBINARY(MAX) FILESTREAM,
answer_score INT
);
