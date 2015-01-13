#########################################
# 流程解說
# 1.爬蟲
# 2.初步ETL，刪除長度不足的資料
# 3.二次ETL，將檔案轉成UTF-8格式
# 4.三次ETL及分析，對檔案進行斷詞，並比對，保留符合條件的資料列
# 5.四次ETL，過濾重複出現的資料列，儲存成csv檔(建議檔名可為日期)
# 6.製作Shiny互動介面，
# 7.每日自動化

#########################################

# 爬蟲
# 來源網址:http://www.104.com.tw/i/apis/jobsearch.cfm?page=1&pgsz=2000&order=2&fmt=4&cols=JOB,JOBCAT_DESCRIPT,OTHERS,NAME,ADDR_NO_DESCRIPT,ADDRESS,ADDR_INDZONE,INDCAT,LINK,PRODUCT,PROFILE"
# 作法: 先建立nameList，供命名resultList之用
#       建立resultList，準備存放爬回來的網頁
#       進行迴圈，迴圈內的內容
#           1.讓系統暫時停止爬蟲幾秒
#           2.取得104網頁的XML檔(此時為字串)
#           3.解析XML檔(將字串轉為可辨認的格式)
#           4.存放至resultList 
#           5.將resultList在當前目錄下存成RDS檔
# 變數及函數方法解釋
# start         參數為從第幾頁開始爬
# end           參數為爬至第幾頁停止
# sleep         參數為每爬一次要等待幾秒後繼續爬
# i             為目前正在爬的頁碼
# getURL()      爬下網頁內容
# xmlParse()    解析XML內容
# xmlChildren() 抓取我們要的xml
# xmlToList()   將xml轉存為List
crawler <- function(start,end,sleep){
  nameList <- paste("c",start:end,sep="")
  resultList <- list()
  system.time(
    for(i in start:end){
      Sys.sleep(sleep)
      getXML<- getURL(url=sprintf("http://www.104.com.tw/i/apis/jobsearch.cfm?page=%d&pgsz=2000&order=2&fmt=4&cols=JOB,JOBCAT_DESCRIPT,OTHERS,NAME,ADDR_NO_DESCRIPT,ADDRESS,ADDR_INDZONE,INDCAT,LINK,PRODUCT,PROFILE",i),encoding="UTF-8")
      xml <-xmlParse(getXML,encoding="UTF-8") 
      resultList[[nameList[i]]] <- xmlToList(xmlChildren(xml)[[1]]) 
    }
  )
  resultList
}
# 在當前目錄把resultList存成crawlerFile.RDS
saveRDS(resultList,"E://LBH//crawlerFile.RDS")
###############################################

# 第一次ETL

# 因原始資料部分為104外包網，該些資料不會透露徵才公司的資訊，故要做刪除的動作
# 1. 初始化一個DataFrame用來存放篩選後的結果，必須先預設好欄位，不然在rbind階段時，會因factor報錯
# 2. 撰寫保留欄位數為11的資料列的函數
# 3. 以lapply對firstETL執行(全部元素皆會遍歷)
# 4. 儲存第一次ETL結果

# 0.讀入爬蟲檔案
firstETL <- readRDS("E://LBH//crawlerFile.RDS")

# 1.初始化dataFrame
initDF <- data.frame(ADDRESS="",ADDR_INDZONE="",ADDR_NO_DESCRIPT="",INDCAT="",JOB="",JOBCAT_DESCRIPT="",LINK="",NAME="",OTHERS="",PRODUCT="",PROFILE="",stringsAsFactors=F)

# 2.撰寫過濾函數
pfilter <- function(x){ 
  if(length(x)==11){
    initDF <<- rbind(initDF,unlist(x,use.names=F,recursive = F),deparse.level = 0)
    print("success!")
  }
}

# 3.對大List內的小List進行動作
# 針對testList的每一個list執行篩選，並計數(多核可用foreach加速)
t <- 1
(lapply(firstETL,function(x){  
  print(t)
  lapply(x,pfilter)
  t <<-t+1 
}))

# 4.儲存第一次ETL結果
saveRDS(initDF,"E://LBH//step1FilterLengthDone.RDS")

###############################################
# 第二次ETL
# 讀取第一次ETL的檔案，並轉成UTF-8編碼，
# 然後儲存成RDS，供分析使用
# 0. 載入第一次ETL所儲存的檔案
# 1. 以iconv函數轉編碼為UTF-8，準備供TextMining使用
# 2. 儲存第二次ETL結果

# 0.載入
step2ConvertUTF8<- readRDS("E://LBH//step1FilterLengthDone.RDS") 

# 1.轉編碼
for(i in 1:length(step2ConvertUTF8)){  
  for(j in 1:length(step2ConvertUTF8[,1])){
    step2ConvertUTF8[[i]][[j]] <- iconv(step2ConvertUTF8[[i]][[j]],from="UTF-8",to="UTF-8")
    #print(paste(i,j,sep=" and "))
  }
  print(i)
}

# 2.儲存第二次ETL結果
saveRDS(step2ConvertUTF8,"E://LBH//step2ConvertUTF8.RDS")


###############################################
# 第三次ETL及分析
# 將分出來的詞與目標詞作比對，若有包含，則留下該筆紀錄
# 0. 載入第二次ETL所儲存的檔案
# 1. 設定比對字詞
# 2. 對所有欄位進行分詞，並與比對字詞作比對，若有相同，則標記該筆紀錄至thirdRowNumber向量中
# 3. 針對thirdRowNumber向量提取不重複的值，並存成thirdUniqueRowNumber向量
# 4. 依照thirdUniqueRowNumber向量，從step3ConvertUTF8中提取資料列
# 5. 針對該些資料列，過濾，抓出不重複出現的資料

# 0.載入第二次ETL所儲存的檔案
step3ConvertUTF8 <- readRDS("E://LBH//step2ConvertUTF8.RDS") 

# 1.設定比對字詞

# 安裝rJava, Rwordseg套件
if (!require(rJava)) install.packages("rJava")
if (!require(Rwordseg)) install.packages("Rwordseg",repos="http://R-Forge.R-project.org",type="source")

# 設定字典檔, 假設工作目錄在專案資料夾下
options(dic.dir="./dic")
loadDict()

# 設定比對字詞
thirdTarget <- c("數據分析","大數據","數據探勘","數據挖掘","巨量數據","海量數據","資料分析",
                 "資料探勘","大資料","巨量資料","海量資料","數據採礦","資料採礦",
                 "data","Data","analysis","Analysis","hadoop","Hadoop","HADOOP",
                 "spark","Spark","SPARK","scala","Scala","SCALA","R","hdfs","Hdfs","HDFS",
                 "hive","Hive","HIVE","pig","Pig","PIG")
thirdRowNumber <- c()

# 2. 分詞並比對
for(i in 1:length(step3ConvertUTF8)){
  for(j in 1:length(step3ConvertUTF8[,1])){
    if(any(thirdTarget %in% segmentCN(step3ConvertUTF8[j,i]))){
      thirdRowNumber <<- c(thirdRowNumber,j) 
    }
  }
  print(i)
}

# 3. 提取出不重複的元素，並依照該些元素去提出step3ConvertUTF8的資料列
thirdUniqueRowNumber <-unique(thirdRowNumber) 
thirdResultDF <- step3ConvertUTF8[thirdUniqueRowNumber,]

# 4. 結果提取
finalResultDF <- data.frame(ADDRESS="",ADDR_INDZONE="",ADDR_NO_DESCRIPT="",INDCAT="",JOB="",JOBCAT_DESCRIPT="",LINK="",NAME="",OTHERS="",PRODUCT="",PROFILE="",stringsAsFactors=F)
for(i in unique(thirdResultDF[["NAME"]])){
  finalResultDF <- rbind(finalResultDF,unique(thirdResultDF[thirdResultDF[["NAME"]]==i,]))
}

# 5. 儲存結果
saveRDS(finalResultDF,"E://LBH//finalResultDF.RDS")
write.csv(finalResultDF,"E://LBH//finalResultDF.csv")
###########################################
# Shiny自動更新
 
