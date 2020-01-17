require("RPostgreSQL")

# Used to obtain deviance explained
require("modEvA")

# used for multi-colinearity | vif
require("car")


con <- dbConnect(dbDriver("PostgreSQL"), dbname="cas_exp", host="localhost")

newWarnings <- dbGetQuery(con, "SELECT new_warnings
from commit_warning_summary as w
where w.new_warnings > 0")


avgDevDelta <- dbGetQuery(con, "SELECT c.fix = 'True' as fix, c.contains_bug = 'TRUE' as contains_bug, repo_name, nd,
la, ld, @lt as lt, ndev, @age as age, exp, @rexp as rexp, jlint_warnings, new_jlint_warnings, findbugs_warnings,
new_findbugs_warnings, security_warnings, new_security_warnings,
build != 'BUILD' as build_failed, warnings > 0 as w_bool
from commits as c, commit_warning_recovered_summary as w
where c.repository_id = w.repo and c.commit_hash = w.commit")

#detach(avgDevDelta)
attach(avgDevDelta)


sink("{summary_path}/recovered/bugs/models_as_factor_all_repo_logged_recovered.txt")
summary(newWarnings)


summary(avgDevDelta)


print("model 1")
mb1 = glm(contains_bug ~
log2(1+nd) +
log2(1+la) +
log2(1+ld) +
log2(1+lt) +
fix +
log2(1+ndev) +
log2(1+age) +
log2(1+exp) +
log2(1+rexp) +
as.factor(repo_name), family=binomial(), control = list(maxit = 50))
summary(mb1)
vif(mb1)
print(round(exp(coef(mb1)),digits=2))
print(paste("d2 = ", Dsquared(mb1)))



# Add the new warning counts
print("model 2 -  just warnings")
mb2 = glm(contains_bug ~
log2(1+new_security_warnings) +
log2(1+security_warnings) +
log2(1+new_findbugs_warnings) +
log2(1+new_jlint_warnings) +
log2(1+findbugs_warnings) +
log2(1+jlint_warnings) +
build_failed +
as.factor(repo_name), family=binomial(),
control = list(maxit = 50))
summary(mb2)
#vif(mb2)
print(round(exp(coef(mb2)),digits=2))
print(paste("d2 = ", Dsquared(mb2)))

# Combined model

print("combined model")
mb3 = glm(contains_bug ~
log2(1+nd) +
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
build_failed +
as.factor(repo_name), family=binomial(),
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
