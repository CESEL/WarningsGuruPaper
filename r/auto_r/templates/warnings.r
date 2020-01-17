library("RPostgreSQL", lib.loc="~/R/x86_64-pc-linux-gnu-library/3.1")

# Used to obtain deviance explained
library("modEvA", lib.loc="~/R/x86_64-pc-linux-gnu-library/3.1")

# used for multi-colinearity | vif
library("car", lib.loc="~/R/x86_64-pc-linux-gnu-library/3.1")

con <- dbConnect(dbDriver("PostgreSQL"), dbname="cas", host="localhost")

avgDevDelta <- dbGetQuery(con, "SELECT c.fix = 'True' as fix, c.contains_bug = 'TRUE' as contains_bug, ns, nd, nf, entrophy,
la, ld, lt, ndev, age, nuc, exp, rexp, sexp, warnings > 0 as warnings, new_warnings > 0 as new_warnings, jlint_warnings, new_jlint_warnings, findbugs_warnings,
new_findbugs_warnings, security_warnings > 0 as security_warnings, new_security_warnings > 0 as new_security_warnings, fallback_warnings, fallback_security_warnings,
build != 'BUILD' as build_failed, warnings > 0 as w_bool
from commits as c, commit_warning_summary as w where c.repository_id = w.repo and c.commit_hash = w.commit and REPO = '{repository_id}'")

#detach(avgDevDelta)
attach(avgDevDelta)


sink("{summary_path}/{repository}_warnings_models.txt")
summary(avgDevDelta)

# Add the new warning counts
print("Predicting warnings")
mb = glm(warnings ~ ns + nd + nf + entrophy + la + ld + lt + ndev + age + nuc + exp + rexp + sexp + contains_bug + fix, family=binomial(),
control = list(maxit = 50))
summary(mb)
#vif(mb)
exp(coef(mb))
print(paste("d2 = ", Dsquared(mb)))


# Add the new warning counts
print("Predicting new warnings")
mb = glm(new_warnings ~ ns + nd + nf + entrophy + la + ld + lt + ndev + age + nuc + exp + rexp + sexp + contains_bug + fix, family=binomial(),
control = list(maxit = 50))
summary(mb)
#vif(mb)
exp(coef(mb))
print(paste("d2 = ", Dsquared(mb)))

# Add the new warning counts
print("Predicting security warnings")
mb = glm(security_warnings ~ ns + nd + nf + entrophy + la + ld + lt + ndev + age + nuc + exp + rexp + sexp + contains_bug + fix, family=binomial(),
control = list(maxit = 50))
summary(mb)
#vif(mb)
exp(coef(mb))
print(paste("d2 = ", Dsquared(mb)))

# Add the new warning counts
print("Predicting new security warnings")
mb = glm(new_security_warnings ~ ns + nd + nf + entrophy + la + ld + lt + ndev + age + nuc + exp + rexp + sexp + contains_bug + fix, family=binomial(),
control = list(maxit = 50))
summary(mb)
#vif(mb)
exp(coef(mb))
print(paste("d2 = ", Dsquared(mb)))

# Add the new warning counts
print("Predicting build failures")
mb = glm(new_security_warnings ~ ns + nd + nf + entrophy + la + ld + lt + ndev + age + nuc + exp + rexp + sexp + contains_bug + fix, family=binomial(),
control = list(maxit = 50))
summary(mb)
#vif(mb)
exp(coef(mb))
print(paste("d2 = ", Dsquared(mb)))

sink()



