# Set the file path to the bugMeasures.csv file
bugPredictionMeasures <- read.csv("bugMeasures.csv")

# Used to obtain deviance explained
require("modEvA")

# used for multi-colinearity | vif
require("car")

attach(bugPredictionMeasures)

summary(bugPredictionMeasures)


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
