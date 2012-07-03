/* Database schema:
   users table: id, email, password hash, start time
   session table: session id, userid, last use
   submissions table: id, submission time, result (pass/fail), notes
   results table?
   problems table?
   */

create table if not exists users (
      id int auto_increment primary key not null, 
      email text not null,
      password text not null,
      start datetime);

create table if not exists session (
      id char(128) primary key not null,
      userid int not null,
      foreign key (userid) references users (id),
      last_used int unsigned not null);

create table if not exists submissions (
      id int auto_increment primary key not null,
      userid int not null,
      foreign key (userid) references users (id),
      time int unsigned not null,
      problem int not null,
      filename text not null,
      result int not null,
      note text null);
