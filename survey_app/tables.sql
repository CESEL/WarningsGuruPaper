CREATE TABLE IF NOT EXISTS static_commit_review_access (
  REPO TEXT,
  COMMIT TEXT,
  CREATED timestamp DEFAULT NOW());

CREATE TABLE IF NOT EXISTS static_commit_line_warning_reviews (
  REPO TEXT,
  COMMIT TEXT,
  warning INt,
  useful TEXT,
  comment TEXT,
  CREATED timestamp DEFAULT NOW());

CREATE TABLE IF NOT EXISTS review_unsubscribe (
  REPO TEXT,
  COMMIT TEXT,
  author_email TEXT,
  CREATED timestamp DEFAULT NOW());

alter table static_commit_review_access add column id serial primary key;
alter table static_commit_line_warning_reviews add column id serial primary key;
alter table review_unsubscribe add column id serial primary key;

alter table static_commit_review_access add column ip text;
alter table static_commit_line_warning_reviews add column ip text;
alter table review_unsubscribe add column ip text;

CREATE TABLE IF NOT EXISTS review_email_logging (
  REPO TEXT,
  COMMIT TEXT,
  email_created timestamp,
  email_sent timestamp default null);

alter table static_commit_review_access add column type text default 'DATA';

