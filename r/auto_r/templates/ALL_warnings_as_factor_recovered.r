require("RPostgreSQL")

# Used to obtain deviance explained
require("modEvA")

# used for multi-colinearity | vif
require("car")

con <- dbConnect(dbDriver("PostgreSQL"), dbname="cas_exp", host="localhost")


avgDevDelta <- dbGetQuery(con, "SELECT c.fix = 'True' as fix, c.contains_bug = 'TRUE' as contains_bug, repo_name,  ns, nd, nf, entrophy,
la, ld, @lt as lt, ndev, @age as age, nuc, exp, @rexp as rexp, sexp, warnings > 0 as warnings, new_warnings > 0 as new_warnings,
security_warnings > 0 as security_warnings, new_security_warnings > 0 as new_security_warnings,
build != 'BUILD' as build_failed, warnings > 0 as w_bool
from commits as c, commit_warning_recovered_summary as w
where c.repository_id = w.repo and c.commit_hash = w.commit")

#detach(avgDevDelta)
attach(avgDevDelta)


sink("{summary_path}/recovered/warnings/warnings_models_as_factor_all_repo_logged_recovered.txt")
summary(avgDevDelta)

# Add the new warning counts
print("Predicting warnings")
mb1 = glm(warnings ~
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
print("Predicting new warnings")
mb2 = glm(new_warnings ~
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
summary(mb2)
vif(mb2)
print(round(exp(coef(mb2)),digits=2))
print(paste("d2 = ", Dsquared(mb2)))

# Add the new warning counts
print("Predicting security warnings")
mb3 = glm(security_warnings ~
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
summary(mb3)
vif(mb3)
print(round(exp(coef(mb3)),digits=2))
print(paste("d2 = ", Dsquared(mb3)))

# Add the new security warning counts
mb4 = glm(new_security_warnings ~
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
summary(mb4)
vif(mb4)
print(round(exp(coef(mb4)),digits=2))

print(paste("d2 = ", Dsquared(mb4)))

sink()



