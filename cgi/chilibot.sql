

CREATE TABLE users (
	fname	 VARCHAR(50),
	lname	 VARCHAR(50),
	job		 VARCHAR(100),
	org		 VARCHAR(300),
	dep		 VARCHAR(100),
	country  VARCHAR(50),
	uname	 VARCHAR(20),
	pass	 VARCHAR(20),
	email	 VARCHAR(50),
	moddate	 TIMESTAMP DEFAULT now()
);

