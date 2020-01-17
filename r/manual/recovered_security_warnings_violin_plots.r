source("/home/louisq/git/louis/authorship/thesis/r/manual/vioplot2log.r")

require("RPostgreSQL")
require("vioplot")

con <- dbConnect(dbDriver("PostgreSQL"), dbname="cas_exp", host="localhost")

commit <- dbGetQuery(con, "select repo_name, warnings, new_warnings, jlint_warnings, new_jlint_warnings, findbugs_warnings,
new_findbugs_warnings, security_warnings, new_security_warnings,
build != 'BUILD' as build_failed, warnings > 0 as w_bool
from commits as c, commit_warning_recovered_summary as w where c.repository_id = w.repo and c.commit_hash = w.commit")

result = split(commit, as.factor(commit$repo_name))
b_commons_lang = result[['commons-lang']]$security_warnings
b_hadoop = result[['hadoop']]$security_warnings
b_ignite = result[['ignite']]$security_warnings
b_kylin = result[['kylin']]$security_warnings
b_phoenix = result[['phoenix']]$security_warnings
b_ranger = result[['ranger']]$security_warnings
b_tika = result[['tika']]$security_warnings
b_wicket = result[['wicket']]$security_warnings

#b_commons_lang = result[['commons-lang']]$new_warnings
#b_hadoop = result[['hadoop']]$new_warnings
#b_ignite = result[['ignite']]$new_warnings
#b_kylin = result[['kylin']]$new_warnings
#b_phoenix = result[['phoenix']]$new_warnings
#b_ranger = result[['ranger']]$new_warnings
#b_tika = result[['tika']]$new_warnings
#b_wicket = result[['wicket']]$new_warnings

n_commons_lang = result[['commons-lang']]$new_security_warnings
n_hadoop = result[['hadoop']]$new_security_warnings
n_ignite = result[['ignite']]$new_security_warnings
n_kylin = result[['kylin']]$new_security_warnings
n_phoenix = result[['phoenix']]$new_security_warnings
n_ranger = result[['ranger']]$new_security_warnings
n_tika = result[['tika']]$new_security_warnings
n_wicket = result[['wicket']]$new_security_warnings

values <- c(b_commons_lang, n_commons_lang, b_hadoop, n_hadoop, b_ignite, n_ignite, b_kylin, n_kylin, b_phoenix, n_phoenix, b_ranger, n_ranger, b_tika, n_tika, b_wicket, n_wicket)
treatment <- c(
rep(c(1), each=length(b_commons_lang) + length(n_commons_lang)),
rep(c(2), each=length(b_hadoop)+ length(n_hadoop)),
rep(c(3), each=length(b_ignite)+ length(n_ignite)),
rep(c(4), each=length(b_kylin)+ length(n_kylin)),
rep(c(5), each=length(b_phoenix)+ length(n_phoenix)),
rep(c(6), each=length(b_ranger)+ length(n_ranger)),
rep(c(7), each=length(b_tika)+ length(n_tika)),
rep(c(8), each=length(b_wicket)+ length(n_wicket))
)

group <- c(
rep(c("1"), each=length(b_commons_lang)), rep(c("2"), each=length(n_commons_lang)),
rep(c("1"), each=length(b_hadoop)), rep(c("2"), each=length(n_hadoop)),
rep(c("1"), each=length(b_ignite)), rep(c("2"), each=length(n_ignite)),
rep(c("1"), each=length(b_kylin)), rep(c("2"), each=length(n_kylin)),
rep(c("1"), each=length(b_phoenix)), rep(c("2"), each=length(n_phoenix)),
rep(c("1"), each=length(b_ranger)), rep(c("2"), each=length(n_ranger)),
rep(c("1"), each=length(b_tika)), rep(c("2"), each=length(n_tika)),
rep(c("1"), each=length(b_wicket)), rep(c("2"), each=length(n_wicket))

)


require(vioplot)
require(devtools)
require(digest)


pdf('/home/louisq/git/louis/authorship/thesis/r/figures/recovered_new_security_warnings_violin.pdf', width=11)
#png(filename="/home/louisq/git/louis/authorship/thesis/r/figures/recovered_new_warnings_violin.png", width = 1000, height = 570, pointsize = 18)
plot(x=NULL, y=list(),
     #xlim = c(0.5, 8.5), ylim=c(log1p(min(values)), log1p(max(values))),
     xlim = c(0.5, 8.5), ylim=c(1, max(values)),
     log="y",
     type="n", ann=FALSE, axes=F)

axis(1, at=c(1, 2, 3, 4, 5, 6, 7, 8),  labels=c("Commons-lang", "Hadoop", "Ignite", "Kylin", "Phoenix", "Ranger", "Tika", "Wicket"))
axis(2)
for (i in unique(treatment)) {
  for (j in unique(group)){
    #vioplot2(log1p(values[which(treatment == i & group == j)]),
    vioplot2log(1+values[which(treatment == i & group == j)],
             at = i,
             side = ifelse(j == 1, "left", "right"),
             col = ifelse(j == 1, "darkorange3", "lightblue"),
             add = T)
  }
}
title("Total Security Warnings and New Security Warnings in Commits", xlab="Projects", ylab="Number of warnings + 1 (log)")
legend("topright", fill = c("darkorange3", "lightblue"),
       legend = c("Total Security Warnings", "New Security Warnings"), box.lty=0)
dev.off()
