library(stringdist)

library(ggplot2)
library(data.table)

extractFirstname <- function(tokens) {
   retVal <- tokens[1]
   tolower(retVal)
}

extractSurname <- function(tokens) {
   l <- length(tokens)
   retVal <- NA

   if(l == 1) {
      retVal <- ""
   } else if (l == 2) {
      retVal <- tokens[2]
   } else if(l > 2) {
      retVal <- paste0(tokens[2:l-1][grepl("^[a-z]",tokens[2:l-1])],tokens[l])
      retVal <- gsub("([a-z])([A-Z])", "\\1 \\2",retVal)
   }

   tolower(retVal)
}

extractNames <- function(tokens) {
   firstname <- extractFirstname(tokens)
   surname <- extractSurname(tokens)

   names <- tolower(paste(tokens,collapse=" "))
   names <- gsub(firstname,"",names)
   names <- gsub(surname,"",names)
   names <- gsub("^[ ]+|[ ]+$","",names)
}

extractInitial <- function(str) {
   retVal <- substr(str,1,1)
   tolower(retVal)
}


commits <- read.csv("commits.csv")
commits$user <- commits$author
commits$user <- gsub(" <.*$","",commits$user)    # Kill the email part
commits$user <- gsub("[_@-]","",commits$user)    # Kill special chacracters
commits$user <- gsub("[ ]+"," ",commits$user)     # Replace multiple ws with a single space

users <- unique(commits$user)
tokens <- strsplit(gsub("([A-Z])", " \\1",users)," ")
tokens <- lapply(tokens,function(t) t[t!=""])

firstname <- sapply(tokens, extractFirstname)
surname <- sapply(tokens, extractSurname)
names <- sapply(tokens,extractNames)
firstnameInitial <- extractInitial(firstname)
surnameInitial <- extractInitial(surname)

createVariant <- function(a,b) {
   retVal = gsub("[ ]","",paste0(a,b,colapse=""))
}

variant_1 <- createVariant(firstname,surname)
variant_2 <- createVariant(surname,firstname)
variant_3 <- createVariant(firstnameInitial,surname)
variant_4 <- createVariant(firstname,surnameInitial)

DT <- data.table(  variant_1=variant_1
                  ,variant_2=variant_2
                  ,variant_3=variant_3
                  ,variant_4=variant_4
                )
SIM <- data.table()

s = nrow(DT)
for(i in 1:(s-1)) {
   for(j in (i+1):s) {
      mins <- apply(m,2,min)  # by col
      m <- stringdistmatrix(as.character(DT[i,]),as.character(DT[j,]),method="lv")
      print("--------")
      print(i)
      print(j)
      print(mean(mins))
   }
}

#grid <- expand.grid(i=1:nrow(DT)-1,j=2:nrow(DT))
#for(p in 1:nrow(grid)) {
#   i <- grid$i[p]
#   j <- grid$j[p]
#
#   m <- stringdistmatrix(as.character(DT[i,]),as.character(DT[j,]),method="lv")
#   mins <- apply(m,2,min)  # by col
#   #print(mean(mins))
#}



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
