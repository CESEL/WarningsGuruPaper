library("RPostgreSQL", lib.loc="~/R/x86_64-pc-linux-gnu-library/3.1")

# Used to obtain deviance explained
library("modEvA", lib.loc="~/R/x86_64-pc-linux-gnu-library/3.1")

# used for multi-colinearity | vif
library("car", lib.loc="~/R/x86_64-pc-linux-gnu-library/3.1")

con <- dbConnect(dbDriver("PostgreSQL"), dbname="cas", host="localhost")

avgDevDelta <- dbGetQuery(con, "SELECT c.fix = 'True' as fix, c.contains_bug = 'TRUE' as contains_bug, ns, nd, nf, entrophy,
la, ld, lt, ndev, age, nuc, exp, rexp, sexp, warnings, new_warnings, jlint_warnings, new_jlint_warnings, findbugs_warnings,
new_findbugs_warnings, security_warnings, new_security_warnings, fallback_warnings, fallback_security_warnings,
build != 'BUILD' as build_failed, warnings > 0 as w_bool, d.pre_file_defects, d.pre_defects_commit
from commits as c, commit_warning_summary as w, commit_pre_defect as d
where c.repository_id = w.repo and c.commit_hash = w.commit
and c.repository_id = d.repository_id and c.commit_hash = d.commit_hash
and REPO = '{repository_id}'")

#detach(avgDevDelta)
attach(avgDevDelta)


sink("{summary_path}/{repository}_pcr_warnings_summary.txt")
summary(avgDevDelta)

print("baseline")
mb = glm(contains_bug ~ ns + nd + nf + entrophy + la + ld + lt + fix + ndev + age + nuc + exp + rexp + sexp,
family=binomial(), control = list(maxit = 50))
summary(mb)
vif(mb)
exp(coef(mb))
print(paste("d2 = ", Dsquared(mb)))



print("PCR model")
mb = glm(contains_bug ~ ns + nd + nf + entrophy + la + ld + lt + fix + ndev + age + nuc + exp + rexp + sexp + pre_file_defect + pre_defect_commit,
family=binomial(), control = list(maxit = 50))
summary(mb)
vif(mb)
exp(coef(mb))
print(paste("d2 = ", Dsquared(mb)))



sink()
