CREATE DATABASE IF NOT EXISTS college;

USE college;

CREATE TABLE IF NOT EXISTS students (
  id INT(5),
  name VARCHAR(255),
  age INT(3),
  email VARCHAR(255)
);

INSERT INTO students (id, name, age, email) VALUES
  (101, "alex", 30, "alex@gmail.com"),
  (102, "don", 20, "don@gmail.com"),
  (103, "kevin", 25, "kevin@gmail.com"),
  (104, "devon", 35, "devon@gmail.com"),
  (105, "john", 42, "john@gmail.com"),
  (106, "ron", 38, "ron@gmail.com"),
  (107, "thomas", 19, "thomas@gmail.com");

CREATE USER 'appadmin'@'%' IDENTIFIED BY 'appadmin';
GRANT ALL PRIVILEGES ON college.* TO 'appadmin'@'%';
FLUSH PRIVILEGES;

