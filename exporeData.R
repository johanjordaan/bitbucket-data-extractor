library(ggplot2)
library(data.table)

commits <- read.csv("commits.csv")
commits$user <- gsub(" <.*$","",commits$author)

DT <- data.table(repo=commits$repo_slug,user=commits$user,count=1L)

commitsByUserByRepo <- DT[,.(sum=sum(count)), by=list(repo,user)]
commitsByUser <- DT[,.(user,sum=sum(count)), by=list(user)]
#commitsByUser <- commitsByUser[order(c(sum,user))]

#p <- ggplot(commitsByUserByRepo,aes(x=repo,y=user,size=sum))
#p <- p + geom_point()
#print(p)


p <- ggplot(commitsByUser,aes(y=user,x=sum))
p <- p + geom_point()
print(p)

#users <- unique(commits$user)
#table(commits$user)
#table(commits$user,commits$repo_slug)



#print(users)
