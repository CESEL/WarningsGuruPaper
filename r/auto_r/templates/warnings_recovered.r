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
where c.repository_id = w.repo and c.commit_hash = w.commit and REPO = '{repository_id}'")

#detach(avgDevDelta)
attach(avgDevDelta)


sink("{summary_path}/recovered/warnings/{repository}_warnings_models_logged_recovered.txt")
summary(avgDevDelta)


# Add the new warning counts
print("Predicting warnings")
mb = glm(warnings ~ log2(1+ns) + log2(1+nd) + log2(1+nf) + log2(1+entrophy) + log2(1+la) + log2(1+ld) + log2(1+lt) + fix + log2(1+ndev) + log2(1+age) + log2(1+nuc)
+ log2(1+exp) + log2(1+rexp) + log2(1+sexp)
, family=binomial(), control = list(maxit = 50))
summary(mb)
vif(mb)
exp(coef(mb))
print(paste("d2 = ", Dsquared(mb)))

# Add the new warning counts
print("Predicting new warnings")
mb = glm(new_warnings ~ log2(1+ns) + log2(1+nd) + log2(1+nf) + log2(1+entrophy) + log2(1+la) + log2(1+ld) + log2(1+lt) + fix + log2(1+ndev) + log2(1+age) + log2(1+nuc)
                        + log2(1+exp) + log2(1+rexp) + log2(1+sexp)
, family=binomial(), control = list(maxit = 50))
summary(mb)
vif(mb)
exp(coef(mb))
print(paste("d2 = ", Dsquared(mb)))

# Add the new warning counts
print("Predicting security warnings")
mb = glm(security_warnings ~ log2(1+ns) + log2(1+nd) + log2(1+nf) + log2(1+entrophy) + log2(1+la) + log2(1+ld) + log2(1+lt) + fix + log2(1+ndev) + log2(1+age) + log2(1+nuc)
                             + log2(1+exp) + log2(1+rexp) + log2(1+sexp)
, family=binomial(), control = list(maxit = 50))
summary(mb)
vif(mb)
exp(coef(mb))
print(paste("d2 = ", Dsquared(mb)))

# Add the new security warning counts
mb = glm(new_security_warnings ~ log2(1+ns) + log2(1+nd) + log2(1+nf) + log2(1+entrophy) + log2(1+la) + log2(1+ld) + log2(1+lt) + fix + log2(1+ndev) + log2(1+age) + log2(1+nuc)
                                 + log2(1+exp) + log2(1+rexp) + log2(1+sexp)
, family=binomial(), control = list(maxit = 50))
summary(mb)
vif(mb)
exp(coef(mb))

print(paste("d2 = ", Dsquared(mb)))

sink()



