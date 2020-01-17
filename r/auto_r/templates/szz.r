library("RPostgreSQL", lib.loc="~/R/x86_64-pc-linux-gnu-library/3.1")

# Used to obtain deviance explained
library("modEvA", lib.loc="~/R/x86_64-pc-linux-gnu-library/3.1")

# used for multi-colinearity | vif
library("car", lib.loc="~/R/x86_64-pc-linux-gnu-library/3.1")

con <- dbConnect(dbDriver("PostgreSQL"), dbname="cas", host="localhost")

avgDevDelta <- dbGetQuery(con, "SELECT c.fix = 'True' as fix, c.contains_bug = 'TRUE' as contains_bug, ns, nd, nf, entrophy,
la, ld, lt, ndev, age, nuc, exp, rexp, sexp, warnings, new_warnings, jlint_warnings, new_jlint_warnings, findbugs_warnings,
new_findbugs_warnings, security_warnings, new_security_warnings, fallback_warnings, fallback_security_warnings,
build != 'BUILD' as build_failed, warnings > 0 as w_bool
from commits as c, commit_warning_summary as w where c.repository_id = w.repo and c.commit_hash = w.commit and REPO = '{repository_id}'")

#detach(avgDevDelta)
attach(avgDevDelta)


sink("{summary_path}/{repository}_warnings_new_summary.txt")
summary(avgDevDelta)

print("model 1")
mb = glm(contains_bug ~ ns + nd + nf + entrophy + la + ld + lt + fix, family=binomial(), control = list(maxit = 50))
vif(mb)
summary(mb)
exp(coef(mb))
print(paste("d2 = ", Dsquared(mb)))


print("model 2")
mb = glm(contains_bug ~ ns + nd + nf + entrophy + la + ld + lt + fix + ndev + age + nuc + exp + rexp + sexp,
family=binomial(), control = list(maxit = 50))
summary(mb)
vif(mb)
exp(coef(mb))
print(paste("d2 = ", Dsquared(mb)))

# Add the warning count information
print("model 3 - all warnings on commit")
mb = glm(contains_bug ~ ns + nd + nf + entrophy + la + ld + lt + fix + ndev + age + nuc + exp + rexp + sexp + warnings +
findbugs_warnings + jlint_warnings, family=binomial(), control = list(maxit = 50))
summary(mb)
#vif(mb)
exp(coef(mb))
print(paste("d2 = ", Dsquared(mb)))

# Add the new warning counts
print("model 4 - new warnings on commit")
mb = glm(contains_bug ~ ns + nd + nf + entrophy + la + ld + lt + fix + ndev + age + nuc + exp + rexp + sexp + warnings +
findbugs_warnings + jlint_warnings + new_warnings + new_findbugs_warnings + new_jlint_warnings, family=binomial(),
control = list(maxit = 50))
summary(mb)
#vif(mb)
exp(coef(mb))
print(paste("d2 = ", Dsquared(mb)))

# Do security warnings
print("model 5 - security warnings on commit")
mb = glm(contains_bug ~ ns + nd + nf + entrophy + la + ld + lt + fix + ndev + age + nuc + exp + rexp + sexp + warnings +
findbugs_warnings + jlint_warnings + new_warnings + new_findbugs_warnings + new_jlint_warnings + security_warnings +
new_security_warnings, family=binomial(),
control = list(maxit = 50))
summary(mb)
#vif(mb)
exp(coef(mb))
print(paste("d2 = ", Dsquared(mb)))



# Build failures

print("model X - with build failure")
mb = glm(contains_bug ~ ns + nd + nf + entrophy + la + ld + lt + fix + ndev + age + nuc + exp + rexp + sexp + warnings +
findbugs_warnings + jlint_warnings + new_warnings + new_findbugs_warnings + new_jlint_warnings + security_warnings +
new_security_warnings + build_failed, family=binomial(),
control = list(maxit = 50))
summary(mb)
#vif(mb)
print(exp(coef(mb)))
print(paste("d2 = ", Dsquared(mb)))


# Generate model using step-wise selection
new = step(mb)
summary(new)

exp(coef(mb))
print(paste("d2 = ", Dsquared(new)))
#vif(mb)


sink()
