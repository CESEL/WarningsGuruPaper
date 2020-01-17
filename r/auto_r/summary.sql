DROP TABLE IF EXISTS COMMIT_WARNING_SUMMARY;

CREATE TABLE COMMIT_WARNING_SUMMARY
(repo text,
 repo_name text,
 commit text,
 build text,
 warnings int default 0,
 new_warnings int default 0,
 jlint_warnings int default 0,
 new_jlint_warnings int default 0,
 findbugs_warnings int default 0,
 new_findbugs_warnings int default 0,
 security_warnings int default 0,
 new_security_warnings int default 0,
 fallback_warnings boolean default false,
 fallback_security_warnings boolean default false
);


INSERT INTO COMMIT_WARNING_SUMMARY (repo, repo_name, commit, build)
  SELECT repo, name, commit, BUILD FROM static_commit_processed as p, repositories as r
  WHERE REPO IN (SELECT distinct repo FROM static_commit_processed WHERE build = 'BUILD')
        AND BUILD IN ('FAILURE', 'BUILD') AND p.repo = r.id;

UPDATE COMMIT_WARNING_SUMMARY c
SET warnings = w.warnings,
  new_warnings = w.new_warnings,
  jlint_warnings = w.jlint_warnings,
  new_jlint_warnings = w.new_jlint_warnings,
  findbugs_warnings = w.findbugs_warnings,
  new_findbugs_warnings = w.new_findbugs_warnings,
  security_warnings = w.security_warnings,
  new_security_warnings = w.new_security_warnings
from
  (select w.repo, w.commit,
     count(*) as warnings,
     count(*) filter (where b.is_new_line) as new_warnings,
     count(*) filter (where generator_tool = 'JLint') as jlint_warnings,
     count(*) filter (where generator_tool = 'JLint' and b.is_new_line) as new_jlint_warnings,
     count(*) filter (where generator_tool = 'Findbugs + Security Plugin') as findbugs_warnings,
     count(*) filter (where generator_tool = 'Findbugs + Security Plugin' and b.is_new_line) as new_findbugs_warnings,
     count(*) filter (where sfp != 'SFP--1') as security_warnings,
     count(*) filter (where sfp != 'SFP--1' and b.is_new_line) as new_security_warnings
   from static_commit_line_warning as w, static_commit_line_blame as b
   where w.repo = b.repo and w.commit = b.commit and w.resource = b.resource and w.line = b.line
   group by w.repo, w.commit) as w
where c.repo=w.repo and c.commit = w.commit;


UPDATE COMMIT_WARNING_SUMMARY c
SET fallback_warnings = w.fallback_warnings,
  fallback_security_warnings = w.fallback_security_warnings
from
  (select w.repo, b.origin_commit,
     count(*) > 0 as fallback_warnings,
     count(*) filter (where w.sfp != 'SFP--1') > 0 as fallback_security_warnings
   from static_commit_line_warning as w, static_commit_line_blame as b
   where w.repo = b.repo and w.commit = b.commit and w.resource = b.resource and w.line = b.line
   group by w.repo, b.origin_commit) as w
where c.repo=w.repo and c.commit = w.origin_commit;
