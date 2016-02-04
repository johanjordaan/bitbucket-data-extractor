library(ggplot2)
library(data.table)

commits <- read.csv("commits.csv")
commits$user <- gsub(" <.*$","",commits$author)
users <- unique(commits$user)

extract <- function(tokens, i) {
   if(length(tokens) == 1) {
      tokens = unlist(strsplit(tokens[1], "(?<=[A-Z])(?=[A-Z])", perl = TRUE))
      tokens[i]
   } else {
      if(i==2) {
         paste(tokens[i:length(tokens)], collapse = ' ')
      } else {
         tokens[1]
      }
   }
}

getname <- function(str) {
   lapply(strsplit(str,"[ _]"), function(x) extract(x,1) )
}

getsurname <- function(str) {
   lapply(strsplit(str,"[ _]"), function(x) extract(x,2) )
}

DT <- data.table(fullname=users)
DT <- DT[,.(fullname,name=getname(fullname),surname=getsurname(fullname)),]







#DT <- data.table(repo=commits$repo_slug,user=commits$user,count=1L)

#commitsByUserByRepo <- DT[,.(sum=sum(count)), by=list(repo,user)]
#commitsByUser <- DT[,.(user,sum=sum(count)), by=list(user)]
#commitsByUser <- commitsByUser[order(c(sum,user))]

#p <- ggplot(commitsByUserByRepo,aes(x=repo,y=user,size=sum))
#p <- p + geom_point()
#print(p)


#p <- ggplot(commitsByUser,aes(y=user,x=sum))
#p <- p + geom_point()
#print(p)

#users <- unique(commits$user)
#table(commits$user)
#table(commits$user,commits$repo_slug)



#print(users)
