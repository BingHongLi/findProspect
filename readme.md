### project about finding prospect
參考來源
http://www.104.com.tw/i/api_doc/jobsearch/documentation.cfm#url_enc


找 所有工作機會， page:頁數， pgsz為每一個網頁顯現筆數， fmt為回傳格式
http://www.104.com.tw/i/apis/jobsearch.cfm?page=1&pgsz=2000&fmt=4&cols=J,JOB,NAME

職缺關鍵字(也許可從此知道該公司的取向)
http://www.104.com.tw/i/apis/jobsearch.cfm?kws=Internet%E7%A8%8B%E5%BC%8F%E8%A8%AD%E8%A8%88%E5%B8%AB&area=6001001000&order=2&fmt=4&cols=J,JOB,NAME

查職務類別(也許可以查交通類公司) 產業類別 comp jskill 地區別可能要限制為台灣

職務名稱JOB, 職務類別JOBCAT_DESCRIPT, 職務說明DESCRIPTION 其他條件OTHERS

公司名NAME 公司地區類目描述ADDR_NO_DESCRIPT  公司地址ADDRESS   公司所在工業區ADDR_INDZONE  公司產業別自填描述INDCAT  公司網頁連結LINK 公司主要產品PRODUCT 公司簡介PROFILE


http://www.104.com.tw/i/apis/jobsearch.cfm?page=1&pgsz=2000&order=2&fmt=4&cols=JOB,JOBCAT_DESCRIPT,OTHERS,NAME,ADDR_NO_DESCRIPT,ADDRESS,ADDR_INDZONE,INDCAT,LINK,PRODUCT,PROFILE
