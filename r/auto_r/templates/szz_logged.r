library("RPostgreSQL", lib.loc="~/R/x86_64-pc-linux-gnu-library/3.1")

# Used to obtain deviance explained
library("modEvA", lib.loc="~/R/x86_64-pc-linux-gnu-library/3.1")

# used for multi-colinearity | vif
library("car", lib.loc="~/R/x86_64-pc-linux-gnu-library/3.1")

con <- dbConnect(dbDriver("PostgreSQL"), dbname="cas_exp", host="localhost")

avgDevDelta <- dbGetQuery(con, "SELECT c.fix = 'True' as fix, c.contains_bug = 'TRUE' as contains_bug, repo_name,  ns, nd, nf, entrophy,
la, ld, lt, ndev, age, nuc, exp, rexp, sexp, warnings, new_warnings, jlint_warnings, new_jlint_warnings, findbugs_warnings,
new_findbugs_warnings, security_warnings, new_security_warnings, fallback_warnings, fallback_security_warnings,
fallback_warnings as new_warnings_present, fallback_security_warnings as new_security_warnings_present,
build != 'BUILD' as build_failed, warnings > 0 as w_bool
from commits as c, commit_warning_summary as w
where c.repository_id = w.repo and c.commit_hash = w.commit
and REPO = '{repository_id}'")

#detach(avgDevDelta)
attach(avgDevDelta)


sink("{summary_path}/{repository}_warnings_log_summary.txt")
summary(avgDevDelta)

print("model 1")
mb = glm(contains_bug ~
log2(1+ns) +
log2(1+la) +
log2(1+ld) +
log2(1+lt) +
fix +
log2(1+ndev) +
log2(1+age) +
log2(1+exp) +
log2(1+rexp), family=binomial(), control = list(maxit = 50))
summary(mb)
vif(mb)
exp(coef(mb))
print(paste("d2 = ", Dsquared(mb)))



# Add the new warning counts
print("model 2 -  just warnings ")
mb = glm(contains_bug ~
log2(1+new_security_warnings) +
log2(1+security_warnings) +
log2(1+new_findbugs_warnings) +
log2(1+new_jlint_warnings) +
log2(1+findbugs_warnings) +
log2(1+jlint_warnings) +
new_security_warnings_present+
new_warnings_present +
build_failed, family=binomial(),
control = list(maxit = 50))
summary(mb)
#vif(mb)
exp(coef(mb))
print(paste("d2 = ", Dsquared(mb)))

# Build failures

print("model X - with build failure hf")
mb = glm(contains_bug ~
log2(1+ns) +
log2(1+la) +
log2(1+ld) +
log2(1+lt) +
fix +
log2(1+ndev) +
log2(1+age) +
log2(1+exp) +
log2(1+rexp) +
log2(1+new_security_warnings) +
log2(1+security_warnings) +
log2(1+new_findbugs_warnings) +
log2(1+new_jlint_warnings) +
log2(1+findbugs_warnings) +
log2(1+jlint_warnings) +
new_security_warnings_present+
new_warnings_present +
build_failed, family=binomial(),
control = list(maxit = 50))
summary(mb)
#vif(mb)
print(round(exp(coef(mb)),digits=2))
print(paste("d2 = ", Dsquared(mb)))

sink()
