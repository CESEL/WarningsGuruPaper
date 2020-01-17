# Set the file path to the warningsMeasures.csv file
warningsPredictionMeasures <- read.csv("warningsMeasures.csv")

# Used to obtain deviance explained
require("modEvA")

# used for multi-colinearity | vif
require("car")

attach(warningsPredictionMeasures)

summary(warningsPredictionMeasures)

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
