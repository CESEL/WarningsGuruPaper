require("RPostgreSQL")

# Used to obtain deviance explained
require("modEvA")

# used for multi-colinearity | vif
require("car")

con <- dbConnect(dbDriver("PostgreSQL"), dbname="cas_exp", host="localhost")

avgDevDelta <- dbGetQuery(con, "SELECT c.fix = 'True' as fix, c.contains_bug = 'TRUE' as contains_bug, repo_name,  ns, nd, nf, entrophy,
la, ld, lt, ndev, age, nuc, exp, rexp, sexp, warnings, new_warnings, jlint_warnings, new_jlint_warnings, findbugs_warnings,
new_findbugs_warnings, security_warnings, new_security_warnings, recovered_warnings,
build != 'BUILD' as build_failed, warnings > 0 as w_bool
from commits as c, commit_warning_recovered_summary as w
where c.repository_id = w.repo and c.commit_hash = w.commit
and REPO = '{repository_id}'")

#detach(avgDevDelta)
attach(avgDevDelta)


sink("{summary_path}/recovered/bugs/{repository}_models_recovered_log_summary.txt")
summary(avgDevDelta)

print("model 1")
mb1 = glm(contains_bug ~
log2(1+ns) +
log2(1+la) +
log2(1+ld) +
log2(1+lt) +
fix +
log2(1+ndev) +
log2(1+age) +
log2(1+exp) +
log2(1+rexp), family=binomial(), control = list(maxit = 50))
summary(mb1)
vif(mb1)
exp(coef(mb1))
print(paste("d2 = ", Dsquared(mb1)))



# Add the new warning counts
print("model 2 -  just warnings ")
mb2 = glm(contains_bug ~
log2(1+new_security_warnings) +
log2(1+security_warnings) +
log2(1+new_findbugs_warnings) +
log2(1+new_jlint_warnings) +
log2(1+findbugs_warnings) +
log2(1+jlint_warnings) +
build_failed, family=binomial(),
control = list(maxit = 50))
summary(mb2)
#vif(mb2)
exp(coef(mb2))
print(paste("d2 = ", Dsquared(mb2)))


print("model 3 - combined model")
mb3 = glm(contains_bug ~
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
build_failed, family=binomial(),
control = list(maxit = 50))
summary(mb3)
#vif(mb3)
print(round(exp(coef(mb3)),digits=2))
print(paste("d2 = ", Dsquared(mb3)))

print("original with combined")
md1 = anova(mb1, mb3)
print(md1)
summary(md1)

print("warnings with combined")
md2 = anova(mb2, mb3)
print(md2)
summary(md2)

sink()
