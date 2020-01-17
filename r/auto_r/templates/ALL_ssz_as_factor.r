require("RPostgreSQL")

# Used to obtain deviance explained
require("modEvA")

# used for multi-colinearity | vif
require("car")


con <- dbConnect(dbDriver("PostgreSQL"), dbname="cas_exp", host="localhost")

newWarnings <- dbGetQuery(con, "SELECT new_warnings
from commit_warning_summary as w
where w.new_warnings > 0")


avgDevDelta <- dbGetQuery(con, "SELECT c.fix = 'True' as fix, c.contains_bug = 'TRUE' as contains_bug, repo_name,  ns,
la, ld, @lt as lt, ndev, @age as age, exp, @rexp as rexp, jlint_warnings, new_jlint_warnings, findbugs_warnings,
new_findbugs_warnings, security_warnings, new_security_warnings, fallback_warnings, fallback_security_warnings,
fallback_warnings as new_warnings_present, fallback_security_warnings as new_security_warnings_present,
build != 'BUILD' as build_failed, warnings > 0 as w_bool
from commits as c, commit_warning_summary as w
where c.repository_id = w.repo and c.commit_hash = w.commit")

list_cor <- function(df) {
  z <- cor(df[sapply(df, is.numeric)], method = 'spearman') #get rid of anything that isn't numeric
  z[lower.tri(z,diag=TRUE)]=NA  #Prepare to drop duplicates and meaningless information
  z=as.data.frame(as.table(z))  #Turn into a 3-column table
  z=na.omit(z)  #Get rid of the junk we flagged above
  z=z[order(-abs(z$Freq)),]    #Sort by highest correlation (whether +ve or -ve)
  z
}

list_cor(avgDevDelta)

#detach(avgDevDelta)
attach(avgDevDelta)


sink("{summary_path}/models_as_factor_all_repo_logged.txt")
summary(newWarnings)


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
log2(1+rexp) +
as.factor(repo_name), family=binomial(), control = list(maxit = 50))
summary(mb)
vif(mb)
print(round(exp(coef(mb)),digits=2))
print(paste("d2 = ", Dsquared(mb)))



# Add the new warning counts
print("model 2 -  just warnings")
mb = glm(contains_bug ~
log2(1+new_security_warnings) +
log2(1+security_warnings) +
log2(1+new_findbugs_warnings) +
log2(1+new_jlint_warnings) +
log2(1+findbugs_warnings) +
log2(1+jlint_warnings) +
new_security_warnings_present+
new_warnings_present +
build_failed +
as.factor(repo_name), family=binomial(),
control = list(maxit = 50))
summary(mb)
#vif(mb)
print(round(exp(coef(mb)),digits=2))
print(paste("d2 = ", Dsquared(mb)))

# Build failures

print("model X - with build failure")
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
build_failed +
as.factor(repo_name), family=binomial(),
control = list(maxit = 50))
summary(mb)
#vif(mb)
print(round(exp(coef(mb)),digits=2))
print(paste("d2 = ", Dsquared(mb)))

sink()
