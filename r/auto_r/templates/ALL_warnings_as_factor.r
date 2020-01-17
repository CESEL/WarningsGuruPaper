library("RPostgreSQL", lib.loc="~/R/x86_64-pc-linux-gnu-library/3.1")

# Used to obtain deviance explained
library("modEvA", lib.loc="~/R/x86_64-pc-linux-gnu-library/3.1")

# used for multi-colinearity | vif
library("car", lib.loc="~/R/x86_64-pc-linux-gnu-library/3.1")

con <- dbConnect(dbDriver("PostgreSQL"), dbname="cas", host="localhost")


avgDevDelta <- dbGetQuery(con, "SELECT c.fix = 'True' as fix, c.contains_bug = 'TRUE' as contains_bug, repo_name,  ns, nd, nf, entrophy,
la, ld, @lt as lt, ndev, @age as age, nuc, exp, @rexp as rexp, sexp, warnings > 0 as warnings, new_warnings > 0 as new_warnings,
security_warnings > 0 as security_warnings, new_security_warnings > 0 as new_security_warnings,
build != 'BUILD' as build_failed, warnings > 0 as w_bool
from commits as c, commit_warning_summary as w
where c.repository_id = w.repo and c.commit_hash = w.commit")

#detach(avgDevDelta)
attach(avgDevDelta)


sink("{summary_path}/warnings_models_as_factor_all_repo_logged.txt")
summary(avgDevDelta)

# Add the new warning counts
print("Predicting warnings")
mb = glm(warnings ~ log2(1+ns) + log2(1+nd) + log2(1+nf) + log2(1+entrophy) + log2(1+la) + log2(1+ld) + log2(1+lt) + fix + log2(1+ndev) + log2(1+age) + log2(1+nuc)
+ log2(1+exp) + log2(1+rexp) + log2(1+sexp)
+ as.factor(repo_name), family=binomial(), control = list(maxit = 50))
summary(mb)
vif(mb)
print(round(exp(coef(mb)),digits=2))
print(paste("d2 = ", Dsquared(mb)))

# Add the new warning counts
print("Predicting new warnings")
mb = glm(new_warnings ~ log2(1+ns) + log2(1+nd) + log2(1+nf) + log2(1+entrophy) + log2(1+la) + log2(1+ld) + log2(1+lt) + fix + log2(1+ndev) + log2(1+age) + log2(1+nuc)
                        + log2(1+exp) + log2(1+rexp) + log2(1+sexp)
+ as.factor(repo_name), family=binomial(), control = list(maxit = 50))
summary(mb)
vif(mb)
print(round(exp(coef(mb)),digits=2))
print(paste("d2 = ", Dsquared(mb)))

# Add the new warning counts
print("Predicting security warnings")
mb = glm(security_warnings ~ log2(1+ns) + log2(1+nd) + log2(1+nf) + log2(1+entrophy) + log2(1+la) + log2(1+ld) + log2(1+lt) + fix + log2(1+ndev) + log2(1+age) + log2(1+nuc)
                             + log2(1+exp) + log2(1+rexp) + log2(1+sexp)
+ as.factor(repo_name), family=binomial(), control = list(maxit = 50))
summary(mb)
vif(mb)
print(round(exp(coef(mb)),digits=2))
print(paste("d2 = ", Dsquared(mb)))

# Add the new security warning counts
mb = glm(new_security_warnings ~ log2(1+ns) + log2(1+nd) + log2(1+nf) + log2(1+entrophy) + log2(1+la) + log2(1+ld) + log2(1+lt) + fix + log2(1+ndev) + log2(1+age) + log2(1+nuc)
                                 + log2(1+exp) + log2(1+rexp) + log2(1+sexp)
+ as.factor(repo_name), family=binomial(), control = list(maxit = 50))
summary(mb)
vif(mb)
print(round(exp(coef(mb)),digits=2))

print(paste("d2 = ", Dsquared(mb)))

sink()



