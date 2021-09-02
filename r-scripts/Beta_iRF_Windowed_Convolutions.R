###Select which beta diversity file to use

beta <- read.csv("/mnt/c/Users/elija/Desktop/Lab/Covid/Data/Joshua_Data/Beta_Diversity/Beta_May/beta-diversity-data-merged-all-taxa.csv")
beta <- read.csv("/mnt/c/Users/elija/Desktop/Lab/Covid/Data/Joshua_Data/Beta_Diversity/Beta_May/beta-diversity-data-merged-selected-taxa-no-tox1500.csv")
beta <- read.csv("/mnt/c/Users/elija/Desktop/Lab/Covid/Data/Joshua_Data/Beta_Diversity/Beta_May/beta-diversity-data-merged-selected-taxa.csv")

colnames(beta) <- c('FIPS','IFR','Beta_Diversity')

beta <- beta[,c(1,3,2)]

beta$TAXA <- NULL
colnames(beta) <- c('FIPS','Beta_Diversity','IFR')
rownames(data) <- 1:nrow(data)

#function to create windowed means
#Average the following 19 valuees and self
#stop when there are no longer 19 values to average

win_mean <- function(data,col){
  i <- 1
  tmp_mean <- c()
  for(i in 1:nrow(data)){
    if((i+19)>nrow(data)){
      break
    }
    
    tmp <- data[i:(i+19),col]
    # data <- data[-c(i:(i+19)),] 
    tmp_mean <- c(tmp_mean,mean(tmp))
  }
  return(tmp_mean) 
}

#function to get 75th percentile of IFR values.
#Same as above, but instead of averaging calculate the 75th percentile of the window

ifr_75 <- function(data,col){
  ifr_75 <- c()
  for(i in 1:nrow(data)){
    if((i+19)>nrow(data)){
      break
    }
    
    tmp <- data[i:(i+19),col]
    
    ifr_75 <- c(ifr_75,quantile(tmp,probs = .75))
  }
  
  return(ifr_75)
}



#I went to 30 covariate here, we reach our max R^2 value a bit before 30
ORNL <- read.csv('/mnt/c/Users/elija/Desktop/Lab_Shit/Covid/Data/Elijah_Data/Permuted_Bray_Curtis_Abundance_Averaged/Marginal_Bray_Curtis_Abundance_30.csv')
#Subset, I pulled from an older version that included 150 beta divesity values, the Top 60 data I sent shouldnt need subseting
ORNL <- ORNL[,c(2,154:183)]

All <- merge(data,ORNL,by='FIPS')
All <- All[rev(order(All$Beta_Diversity)),]
All$FIPS <- NULL

#Remove IFR
tmp <- All[,c(-2)]

#Shuffle columns with replacement


shuffle <- function(x){
  tmp1 <- x[sample(length(x))]
  return(tmp1)
}

shuffled <- as.data.frame(apply(tmp,MARGIN = c(2),shuffle))
colnames(shuffled) <- paste(colnames(shuffled),'_shuffled',sep='')

All <- cbind(All,shuffled)

###Apply convolutions

#Calculate 75th percentil for IFR
ifr_conv <- ifr_75(All,2)
cols <- colnames(All)[-2]

output <- c()
#Loop through columns and apply mean convultions and calculate R^2
#This is what I reported in our meetings, the following chunk exports the data

for(col in cols){
  name  <- paste(col)
  
  #IFR is reduntant here, I just wanted to keep it as a dataframe
  All_tmp <- All[,c(c('IFR',col))]
  All_tmp <- All_tmp[rev(order(All_tmp[,2])),]
  
  #apply convolutions
  ifr_conv <- ifr_75(All_tmp,1)
  cov_conv <- win_mean(All_tmp,2)
  
  data <- data.frame(ifr_conv=ifr_conv,cov_conv=cov_conv)
  
  #Fit linear model to extract R^2
  lin <- lm(ifr_conv~cov_conv,data=data)
  new <- data.frame(cov_conv=data$cov_conv)
  pred <- predict(lin,newdata=new)
  R2 <- rsq(data$ifr_conv,pred)
  names(R2) <- name
  output <- c(output,R2)
}

#change to non sci-notation 
options(scipen=999)

out <- data.frame(names(output),output)
colnames(out) <- c('Covariate','R^2')
rownames(out) <- NULL
out <- out[rev(order(out$`R^2`)),]

write.csv(out,'/mnt/c/Users/elija/Desktop/Lab/Covid/Simple_Exports/Convolved_Regression_All_Taxa.csv',row.names = F)
write.csv(out,'/mnt/c/Users/elija/Desktop/Lab/Covid/Simple_Exports/Convolved_Regression_Selected_Taxa_No_Tox.csv',row.names = F)
write.csv(out,'/mnt/c/Users/elija/Desktop/Lab/Covid/Simple_Exports/Convolved_Regression_Selected_Taxa.csv',row.names = F)

#Create convolved dataset

Conv_Data <- data.frame()
for(i in 1:ncol(All)){
  print(i)
  tmp <- win_mean(All,i)
  
  if(nrow(conv)==0){
    Conv_Data <- data.frame(tmp)
  } else{
    Conv_Data <- cbind(Conv_Data,tmp)
  }
}

colnames(Conv_Data) <- colnames(All)
Conv_Data$IFR <- ifr_conv

#Done