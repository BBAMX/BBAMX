Class LIS.WS.DHCLISServiceBase Extends %RegisteredObject
{

/// 写日志到文件中
/// w ##Class(LIS.WS.DHCLISServiceBase).WriteLog("我是张珊")
/// logStr:日志串
/// logpath:日志路径，不给就由内部控制
ClassMethod WriteLog(logStr, logpath)
{
	s logStr=$g(logStr)
	s logpath=$g(logpath)
	s IsLinux=1
	i ##class(%SYSTEM.Version).GetOS()="Windows" s IsLinux=0
	//默认路径
	i '$l(logpath) d
	.i IsLinux=0 d
	..s logpath="D:\cachelog\"
	.e  d
	..s logpath="/"
	i '$d(^LogFileIndex) s ^LogFileIndex=0
	s index=$g(^LogFileIndex)
	s logName=logpath_"Log"_index_".txt"
	s file=##class(%File).%New(logName)
	//存在就追加
	i ##class(%File).Exists(logName) d
	.Do file.Open("AWS:/SHARED")
	//不存在就新建
	e  d
	.Do file.Open("WSN:/SHARED")
	//日志头
	s HeadStr=$zd($h,8)_" ["_$zt($p($h,",",2))_"] "
	//写日志
	d file.WriteLine($zcvt(HeadStr_logStr,"O","UTF8"))
	//判断大小
	s fileSize=file.Size
	//文件大了就换一个
	i fileSize>(1024*1000) d
	.s ^LogFileIndex=^LogFileIndex+1
	d file.Close()
	q ""
}

/// 带日志的删除
/// TableClassName:表的类名
/// RowID:要删除的RowID
/// Session:会话串，可以不给
/// ClientIPAddress:IP,不给会自动获取
/// w ##Class(LIS.WS.DHCLISServiceBase).LogDelete()
ClassMethod LogDelete(TableClassName, RowID, Session, ClientIPAddress)
{
	s TableClassName=$g(TableClassName)
	s Session=$g(Session)
	s ClientIPAddress=$g(ClientIPAddress)
	//得到IP
	i '$l(ClientIPAddress) s ClientIPAddress=##Class(LIS.Util.Common).GetClientIP()
	s LogMain =##class(%DynamicObject).%New()
	s LogMain.Sql=""
	s Action="D"
	s OldJson=..GetTableRowLogJson(TableClassName,RowID,"")
	s LogMain.OldData=OldJson.%ToJSON()
	s LogMain.NewData=""
	//删除数据
	s @("ret=##Class("_TableClassName_").%DeleteId("_RowID_")")
	s retDo=@"ret"
	i $SYSTEM.Status.IsOK(retDo) d
	.//得到表主键
	.s TableCodeI=##Class(LIS.Util.Common).IndexData($p(TableClassName,".",2))
	.s TableDR=$o(^dbo.SYSTableI("IndexCode",TableCodeI,""))
	.//没有表就插入
	.i '$l(TableDR) d
	..s objTabel=##Class(dbo.SYSTable).%New()
	..s objTabel.CName=$p(TableClassName,".",2)
	..s objTabel.Code=$p(TableClassName,".",2)
	..s objTabel.Description=$p(TableClassName,".",2)
	..s objTabel.ParentName=""
	..s objTabel.Sequence=999
	..s retTable=objTabel.%Save()
	..s TableDR=objTabel.RowID
	.//保存日志
	.s objLog=##Class(dbo.SYSTableLog).%New()
	.s objLog.ActData=LogMain.%ToJSON()
	.s objLog.Action=Action
	.s objLog.AddDate=$zd($h,8)
	.s objLog.AddTime=$p($h,",",2)
	.s objLog.AddUserDR=$p(Session,"^",1)
	.s objLog.ClientIPAddress=ClientIPAddress
	.s objLog.RecordID=RowID
	.s objLog.Remark="M"
	.s objLog.TableDR=TableDR
	.s retLog=objLog.%Save()
	q retDo
}

/// 带日志的保存
/// TableObj:通过%OpenId或%New的表对象
/// Session:会话串，可以不给
/// ClientIPAddress:IP,不给会自动获取
/// w ##Class(LIS.WS.DHCLISServiceBase).LogSave()
ClassMethod LogSave(TableObj, Session, ClientIPAddress)
{
	s TableObj=$g(TableObj)
	s Session=$g(Session)
	s ClientIPAddress=$g(ClientIPAddress)
	//得到IP
	i '$l(ClientIPAddress) s ClientIPAddress=##Class(LIS.Util.Common).GetClientIP()
	s LogMain =##class(%DynamicObject).%New()
	s LogMain.Sql=""
	s Action=""
	s ObjName=""
	s RowID=""
	//更新表数据
	i $l(TableObj.RowID) d
	.s Action="U"
	.s ObjName=$CLASSNAME(TableObj)
	.s OldJson=..GetTableRowLogJson(ObjName,TableObj.RowID,"")
	.s NewJson=..GetTableRowLogJson(ObjName,"",TableObj)
	.s LogMain.OldData=OldJson.%ToJSON()
	.s LogMain.NewData=NewJson.%ToJSON()
	//插入表数据
	e  d
	.s Action="I"
	.s ObjName=$CLASSNAME(TableObj)
	.s NewJson=..GetTableRowLogJson(ObjName,"",TableObj)
	.s LogMain.OldData=""
	.s LogMain.NewData=NewJson.%ToJSON()
	//执行数据保存
	s ret=TableObj.%Save()
	s RowID=TableObj.RowID
	
	i $SYSTEM.Status.IsOK(ret) d
	.//得到表主键
	.s TableCodeI=##Class(LIS.Util.Common).IndexData($p(ObjName,".",2))
	.s TableDR=$o(^dbo.SYSTableI("IndexCode",TableCodeI,""))
	.//没有表就插入
	.i '$l(TableDR) d
	..s objTabel=##Class(dbo.SYSTable).%New()
	..s objTabel.CName=$p(ObjName,".",2)
	..s objTabel.Code=$p(ObjName,".",2)
	..s objTabel.Description=$p(ObjName,".",2)
	..s objTabel.ParentName=""
	..s objTabel.Sequence=999
	..s retTable=objTabel.%Save()
	..s TableDR=objTabel.RowID
	.//保存日志
	.s objLog=##Class(dbo.SYSTableLog).%New()
	.s objLog.ActData=LogMain.%ToJSON()
	.s objLog.Action=Action
	.s objLog.AddDate=$zd($h,8)
	.s objLog.AddTime=$p($h,",",2)
	.s objLog.AddUserDR=$p(Session,"^",1)
	.s objLog.ClientIPAddress=ClientIPAddress
	.s objLog.RecordID=RowID
	.s objLog.Remark="M"
	.s objLog.TableDR=TableDR
	.s retLog=objLog.%Save()
	q ret
}

/// 拷贝相同表的两个对象属性
/// w ##Class(LIS.WS.DHCLISServiceBase).CopyTableRow()
/// SourceObj：源对象
/// PerObj：目标对象
/// NoCopyList:不复制列名列表 s NoCopyMap=$lb("aa","bb")
ClassMethod CopyTableRow(SourceObj, PerObj, NoCopyList)
{
	s SourceObj=$g(SourceObj)
	s PerObj=$g(PerObj)
	s NoCopyList=$g(NoCopyList)
	s NoCopyMap=""
	i $l(NoCopyList) d
	.f i=1:1:$ll(NoCopyList) d
	..s NoCopyMap($lg(NoCopyList,i))=""
	s TableName=$CLASSNAME(SourceObj)
	s rset = ##class(%ResultSet).%New()
	d rset.Prepare("select COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='dbo' AND REPLACE(TABLE_NAME,'_','')='"_$REPLACE(TableName,"dbo.","")_"' Order by ORDINAL_POSITION")
	s exeret=rset.Execute()
	While(rset.Next())
    {
	    s colField=rset.GetColumnName(1)
        s ColValue=rset.GetDataByName(colField)
        i (ColValue'="RowID")&&('$d(NoCopyMap(ColValue))) d
        .s exeStr="(SourceObj,PerObj) s PerObj."_ColValue_"=SourceObj."_ColValue
        .x (exeStr,.SourceObj,.PerObj)
    }
    q 1
}

/// 得到一行数据的JSON对象
/// w ##Class(LIS.WS.DHCLISServiceBase).GetTableRowLogJson("dbo.SYSUser","113").%ToJSON()
/// TableName:表类名
/// RowID：数据主键，和TableObj二传1
/// TableObj：数据对象，和RowID二传1
ClassMethod GetTableRowLogJson(TableName, RowID, TableObj)
{
	s TableName=$g(TableName)
	s RowID=$g(RowID)
	s TableObj=$g(TableObj)
	s retArr=[]
	s @"RetJsonObj =##class(%DynamicObject).%New()"
	i $l(RowID) d
	.//更新的这里不能用OpenId，用他取的数据是改了之后的对象
	.//s @("Obj=##class("_TableName_").%OpenId("_RowID_")")
	.s @("Obj=$g(^"_TableName_"D("_RowID_"))")
	e  d
	.s @("Obj")=TableObj
	s rset = ##class(%ResultSet).%New()
	d rset.Prepare("select COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='dbo' AND REPLACE(TABLE_NAME,'_','')='"_$REPLACE(TableName,"dbo.","")_"' Order by ORDINAL_POSITION")
	s exeret=rset.Execute()
	s colCount=rset.GetColumnCount()
	s dealNum=0
	s PropertyMap=""
	s Index=0
    While(rset.Next())
    {
	    s colField=rset.GetColumnName(1)
        s ColValue=rset.GetDataByName(colField)
        s Index=Index+1
        i $l(RowID) d
        .i Index=1 d
        ..s @("RetJsonObj."_ColValue_"="_RowID)
        .e  d
        ..s @("RetJsonObj."_ColValue_"=$lg(Obj,"_Index_")")
        e  d
        .s @("RetJsonObj."_ColValue_"=Obj."_ColValue)
    }
    d retArr.%Push(@"RetJsonObj")
    q retArr
}

/// 调用Query得到JSON数组对象
/// ClassName:类名
/// FuncName:Query名字
/// w ##Class(LIS.WS.DHCLISServiceBase).GetQueryJsonArr()
ClassMethod GetQueryJsonArr(ClassName, FuncName, P0, P1, P2, P3, P4, P5, P6, P7, P8, P9, P10, P11, P12, P13, Sessions)
{
	s ClassName=$g(ClassName)
	s FuncName=$g(FuncName)
	s P0=$g(P0),P1=$g(P1),P2=$g(P2),P3=$g(P3),P4=$g(P4),P5=$g(P5),P6=$g(P6),P7=$g(P7),P8=$g(P8),P9=$g(P9),P10=$g(P10),P11=$g(P11),P12=$g(P12),P13=$g(P13),Sessions=$g(Sessions)
	s rsetNew=##class(%XML.DataSet).%New()
	s rsetNew.ClassName = ClassName
	s rsetNew.QueryName = FuncName
	s rsetNew.NeedSchema=1
	s rsetNew.DiffGram=0
	s sc=rsetNew.Execute(P0, P1, P2, P3, P4, P5, P6, P7, P8, P9, P10, P11, P12, P13, Sessions)
	s colCount=rsetNew.GetColumnCount()
	set retArr=[]
    While (rsetNew.Next()) 
    {
       s OneRow =##class(%DynamicObject).%New()
       f i=1:1:colCount
       {
          s colName=rsetNew.GetColumnName(i)
          s colValue=rsetNew.GetDataByName(colName)
          s CodeStr="(OneRow,colValue) s OneRow."_colName_"=colValue"
          x (CodeStr,.OneRow,colValue)
       }
       d retArr.%Push(OneRow)
    }
    q retArr
}

/// 往指定URL里Post数据，用于Post和动态请求Webservice
/// Https:是否是https的，1：是， 其他否
/// Server:服务IP
/// Port：端口
/// Url:相对url
/// SOAPAction:
/// Xml:Post的串数据
/// 如下:请求30的ashx查询码表用户数据
/// w ##Class(LIS.WS.DHCLISServiceBase).PostData("0","114.251.235.30","80","/imedicallis/login/ashx/ashLogin.ashx?Method=CommonQueryAll","","{""ModelName"":""SYSUser"",""Pram"":[],""IsDisplayCount"":false,""Joiner"":[],""Operators"":[]}")
/// 如下提交xml调用webservice
/// w ##Class(LIS.WS.DHCLISServiceBase).PostData("1","119.255.194.169","1443","/imedicallis/service/asmx/wbsDHCLISReportServiceHandler.asmx","http://tempuri.org/Print","<?xml version=""1.0"" encoding=""utf-8""?><soap:Envelope xmlns:soap=""http://schemas.xmlsoap.org/soap/envelope/"" xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance"" xmlns:xsd=""http://www.w3.org/2001/XMLSchema"" xmlns:wsa=""http://schemas.xmlsoap.org/ws/2004/08/addressing"" xmlns:wsse=""http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"" xmlns:wsu=""http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd""><soap:Body><Print xmlns=""http://tempuri.org/""><regNo>123456</regNo><cardType></cardType><patSelectModel></patSelectModel></Print></soap:Body></soap:Envelope>")
ClassMethod PostData(Https, Server, Port, Url, SOAPAction, Xml)
{
	Set httprequest=##class(%Net.HttpRequest).%New()
 	Set httprequest.Server=Server
 	Set httprequest.Port=Port
 	//https
 	i Https="1" d
 	.s httprequest.Https=Https
 	.//请到 系统 > 安全管理 > SSL/TLS 配置 > 编辑 SSL/TLS 配置配置名称为SSLECP的配置，协议勾选所有，其他默认
 	.s httprequest.SSLConfiguration="SSLECP"
 	.s httprequest.SSLCheckServerIdentity=0
 	Set sc=httprequest.SetHeader("SOAPAction",SOAPAction)
 	Do httprequest.EntityBody.Write(Xml)
 	set status=httprequest.Post(Url)
 	//异常处理
 	i $$$ISERR(status) d
 	.d $SYSTEM.Status.DisplayError(status)
 	.THROW ##class(%Exception.SystemException).%New("调用异常","D",,"往URL里Post数据异常")
 	s retStr=httprequest.HttpResponse.Data.Read()
 	q retStr
}

/// 处理申明式事务
/// 框架按申明调用为申明式事务
/// 业务方法主动调用为委托式事务
/// w ##Class(LIS.WS.DHCLISServiceBase).DeclarativeTrans("")
/// 声明式事务在方法开始加上以下申明
/// //LIS申明式事务申明，方法头加上该申明，系统调M自动托管事务，抛异常就退出事务*************************************************************************
/// 	i '$d(^LISDeclarativeTrans("LIS.WS.DeclarativeTransTest","DeclarativeTrans")) d
/// 	.s ^LISDeclarativeTrans("LIS.WS.DeclarativeTransTest","DeclarativeTrans")=""
/// 	//去除申明式事务，就注释上面两行，放开注释下一行
/// 	//k ^LISDeclarativeTrans("LIS.WS.DeclarativeTransTest","DeclarativeTrans")
/// 	//异常抛出示例
/// 	//THROW ##class(%Exception.SystemException).%New("名称","代码",,"抛异常回滚事务带回的返回信息")
/// 	//LIS申明式事务申明，方法头加上该申明，系统调M自动托管事务，抛异常就退出事务*************************************************************************
ClassMethod DeclarativeTrans(ClassName, FuncName, P0, P1, P2, P3, P4, P5, P6, P7, P8, P9, P10, P11, P12, P13, Sessions, Output RowCount As %String, IsSelfStart, Output Err As %String) As %String
{
	s ClassName=$g(ClassName),FuncName=$g(FuncName),P0=$g(P0),P1=$g(P1),P2=$g(P2),P3=$g(P3),P4=$g(P4),P5=$g(P5),P6=$g(P6),P7=$g(P7),P8=$g(P8),P9=$g(P9),P10=$g(P10),P11=$g(P11),P12=$g(P12),P13=$g(P13),Sessions=$g(Sessions),RowCount=$g(RowCount)
	s IsSelfStart=$g(IsSelfStart)
	s Err=$g(Err)
	s err=""
	set ret=""
	//先记录开始事务之前的事务层级
	s StartTLEVEL=$TLEVEL
	s OldNameSpace=$NAMESPACE
	try
	{
		//没强调要自己开启事务的就开启事务
		i IsSelfStart'="1" TSTART
		s ret=$CLASSMETHOD(ClassName,FuncName,P0,P1,P2,P3,P4,P5,P6,P7,P8,P9,P10,P11,P12,P13,Sessions,.RowCount)
		//防止别人调我方事务被回滚
		i ($TLEVEL-StartTLEVEL)>1 TROLLBACK  s err="-1^"_ClassName_"的方法"_FuncName_"发生开放性事务，请联系开发！"	
		//判断有事务，万一标明要自己开始事务实际没到那个开启
		i ('$l(err)),($TLEVEL>0) TCOMMIT
		e  s ret=err
	}
	catch ex
	{
		//只回滚到开启前层级
		i ($TLEVEL-StartTLEVEL)>1 d
		.f ti=1:1:($TLEVEL-StartTLEVEL) d
		..TROLLBACK 1
		else  TROLLBACK //捕获异常回滚全部事务
		i ex.Code="D" d
		.s ret=ex.Data
		e  d
		.s ret="-1^"_$ZERROR
		s Err=ret
	}
	//检测命名空间不同就切回来
    i ($NAMESPACE'=OldNameSpace) s $NAMESPACE=OldNameSpace
	q ret
}

/// 处理死循环进程
/// w ##Class(LIS.WS.DHCLISServiceBase).DealOldJob("")
ClassMethod DealOldJob(ClassName, FuncName, Param As %String(MAXLEN=99999999), Session)
{
	//防止M死循环部分******************************************
    //结束运行10分钟还没完成的进程
    s DBCurDateTime=$h
    
    //杀进程,默认配置到任务执行
    d ..KillOldJob()
    //统计唯一键
    s Session=$g(Session)
    s StateUniqueKey=$p(Session,"^",12)
    //统计关注
    i $l(StateUniqueKey) d
    .s ^TMPLISCore("STATECARE",DBCurDateTime,$j)=StateUniqueKey
    //记录当前进程开始时间，杀掉超时进程
	s ^TMPLISCore("DBCARE",DBCurDateTime,$j)=$lb(ClassName,FuncName,Param,Session)
	
	//防止M死循环部分******************************************
	q DBCurDateTime
}

/// 杀死进程，配置任务
/// w ##Class(LIS.WS.DHCLISServiceBase).KillOldJob()
ClassMethod KillOldJob()
{
	s DBCurDateTime=$h
    s DBCurDate=$p(DBCurDateTime,",",1)
	s DBCurTime=$p(DBCurDateTime,",",2)
	//检测节点数
	s DBCheakNum=0
	
	SET $ZTRAP="ERRHander"
	//每个查询有义务检测时间最久的5个进程，超过时间就接收
	s JobRunDateTime="" f  s JobRunDateTime=$o(^TMPLISCore("DBCARE",JobRunDateTime)) q:(JobRunDateTime="")||(DBCheakNum>10)  d
    .s JobID="" f  s JobID=$o(^TMPLISCore("DBCARE",JobRunDateTime,JobID)) q:(JobID="")||(DBCheakNum>10)  d
    ..s DBCheakNum=DBCheakNum+1
    ..s JobRunDate=$p(JobRunDateTime,",",1)
    ..s JobRunTime=$p(JobRunDateTime,",",2)
    ..//最长运行时间
	..s MaxRunTime=600
	..//统计限定执行30分钟
    ..i $d(^TMPLISCore("STATECARE",JobRunDateTime,JobID)) s MaxRunTime=1800
    ..//超过最长分钟的缓存删掉,防止死循环
	..i (DBCurDate=JobRunDate),(DBCurTime-JobRunTime>MaxRunTime) d
	...//存入杀进程信息
	...s ^LISCoreKillJobInfo(JobRunDateTime,JobID)=$g(^TMPLISCore("DBCARE",JobRunDateTime,JobID))
	...i $d(^TMPLISCore("DBCARE",JobRunDateTime,JobID)) d
	....k ^TMPLISCore("DBCARE",JobRunDateTime,JobID)
	....i $d(^TMPLISCore("STATECARE",JobRunDateTime,JobID)) k ^TMPLISCore("STATECARE",JobRunDateTime,JobID)
    ....s Stop=##Class(LIS.WS.DHCLISServiceBase).KillJobByID(JobID)
	...//给前台放入消息
	...s objMsg=##class(dbo.OTMsgStock).%New()
	...s objMsg.AddDate=$zd(+$h,8)
	...s objMsg.AddTime=$p($h,",",2)
	...s objMsg.SendDate=$zd(+$h,8)
	...s objMsg.SendTime=$p($h,",",2)
	...s objMsg.AddUser=""
	...s objMsg.SendUser="dhcc"
	...s objMsg.PerUser="SYS"
	...s objMsg.MsgType="Crisis"
	...s objMsg.Msg="{""type"": ""系统警告-刚重启数据库的忽略"", ""info"": """_##Class(LIS.Util.Common).GetServerIP()_" "_$zt($p($h,",",2))_"结束异常进程，^LISCoreKillJobInfo="_$lg(^LISCoreKillJobInfo(JobRunDateTime,JobID),1)_","_$lg(^LISCoreKillJobInfo(JobRunDateTime,JobID),2)_"，请联系开发排查"", ""dealurl"": """" }"
	...s objMsg.BllType="JOB"
	...s objMsg.BllID=JobID
	...s objMsg.IsReply=0
	...s sc=objMsg.%Save()
    ..//超过最长分钟的缓存删掉
    ..i (DBCurDate>JobRunDate) d
    ...s TimeCha=((DBCurDate-JobRunDate)*3600*24)+((DBCurTime-JobRunTime))
    ...i TimeCha>MaxRunTime d
    ....//存入杀进程信息
	....s ^LISCoreKillJobInfo(JobRunDateTime,JobID)=$g(^TMPLISCore("DBCARE",JobRunDateTime,JobID))
	....i $d(^TMPLISCore("DBCARE",JobRunDateTime,JobID)) d
	.....k ^TMPLISCore("DBCARE",JobRunDateTime,JobID)
	.....i $d(^TMPLISCore("STATECARE",JobRunDateTime,JobID)) k ^TMPLISCore("STATECARE",JobRunDateTime,JobID)
	.....s Stop=##Class(LIS.WS.DHCLISServiceBase).KillJobByID(JobID)
	....//给前台放入消息
	....s objMsg=##class(dbo.OTMsgStock).%New()
	....s objMsg.AddDate=$zd(+$h,8)
	....s objMsg.AddTime=$p($h,",",2)
	....s objMsg.SendDate=$zd(+$h,8)
	....s objMsg.SendTime=$p($h,",",2)
	....s objMsg.AddUser=""
	....s objMsg.SendUser="dhcc"
	....s objMsg.PerUser="SYS"
	....s objMsg.MsgType="Crisis"
	....s objMsg.Msg="{""type"": ""系统警告-刚重启数据库的忽略"", ""info"": """_##Class(LIS.Util.Common).GetServerIP()_" "_$zt($p($h,",",2))_"结束异常进程，^LISCoreKillJobInfo="_$lg(^LISCoreKillJobInfo(JobRunDateTime,JobID),1)_","_$lg(^LISCoreKillJobInfo(JobRunDateTime,JobID),2)_"，请联系开发排查"", ""dealurl"": """" }"
	....s objMsg.BllType="JOB"
	....s objMsg.BllID=JobID
	....s objMsg.IsReply=0
	....s sc=objMsg.%Save()
	//得到可用的连接
	s Lisence=$SYSTEM.License.LUAvailable()
	//小于10个可用授权就发消息
	i Lisence<10 d
	.s ShouldSend=1
	.i $d(^TMPLISLastSendLisenceMsg) d
	..s LastSendTime=$g(^TMPLISLastSendLisenceMsg)
	..s CurTime=$p($h,",",2)
	..s SendTime=CurTime-LastSendTime
	..//十分钟以内只发送一次
	..i (SendTime>0)&&(SendTime<600) s ShouldSend=0
	.i ShouldSend=1 d
	..//给前台放入消息
	..s objMsg=##class(dbo.OTMsgStock).%New()
	..s objMsg.AddDate=$zd(+$h,8)
	..s objMsg.AddTime=$p($h,",",2)
	..s objMsg.SendDate=$zd(+$h,8)
	..s objMsg.SendTime=$p($h,",",2)
	..s objMsg.AddUser=""
	..s objMsg.SendUser="dhcc"
	..s objMsg.PerUser="SYS"
	..s objMsg.MsgType="Crisis"
	..s objMsg.Msg="{""type"": ""数据库lisence不足"", ""info"": """_##Class(LIS.Util.Common).GetServerIP()_" "_$zt($p($h,",",2))_"剩余:"_Lisence_"个可用lisence,请联系管理员排查"", ""dealurl"": """" }"
	..s objMsg.BllType="LSC"
	..s objMsg.BllID=""
	..s objMsg.IsReply=0
	..s sc=objMsg.%Save()
	..s ^TMPLISLastSendLisenceMsg=$p($h,",",2)
	q ""
	
ERRHander
 q ""
}

/// Creator：      zlz
/// CreatDate：    20200608
/// Description:： 查询死循环信息
/// Table：        
/// Input：        
/// Output：       
/// Return：       
/// Others：  Rahel20200414修改 
/// d ##Class(%ResultSet).RunQuery("LIS.WS.DHCLISServiceBase","QryOTNotice","1","","","","","","","","","","","",20,1,"106^10^^13^1")
Query QryLISCoreKillJobInfo(P0, P1, P2, P3, P4, P5, P6, P7, P8, P9, P10, P11, PageSize, PageIndex, Sessions, Output RowCount As %String) As %Query(ROWSPEC = "CreateDate,CreateTime,ClassName,FuncName,Param")
{
}

ClassMethod QryLISCoreKillJobInfoExecute(ByRef qHandle As %Binary, P0, P1, P2, P3, P4, P5, P6, P7, P8, P9, P10, P11, PageSize, PageIndex, Sessions, Output RowCount As %String) As %Status
{
	Set repid=$I(^CacheTemp)
    If $g(ind)="" Set ind=1
	//Session数据
	Set UserID=$p(Sessions,"^",1),WorkGroupDR=$p(Sessions,"^",2),HospitalDR=$p(Sessions,"^",5),LocationDR=$p(Sessions,"^",3)
    //总数与分页
	s RowCount=0
 	s PageSize=+$g(PageSize),PageIndex=+$g(PageIndex),ToRow=0,FormRow=0
 	i PageIndex>0,PageSize>0 s ToRow=PageIndex*PageSize,FormRow=ToRow-PageSize+1
 	s JobRunDateTime="" f  s JobRunDateTime=$o(^LISCoreKillJobInfo(JobRunDateTime),-1) q:JobRunDateTime=""  d
 	.s JobID="" f  s JobID=$o(^LISCoreKillJobInfo(JobRunDateTime,JobID)) q:JobID=""  d
 	..s KillData=$g(^LISCoreKillJobInfo(JobRunDateTime,JobID))
 	..s ClassName=$lg(KillData,1)
 	..s FuncName=$lg(KillData,2)
 	..s Param=$lg(KillData,3)
	..s CreateDate=$zd($p(JobRunDateTime,",",1),8)
	..s CreateTime=$p(JobRunDateTime,",",2)
	..s Data=$lb(CreateDate,CreateTime,ClassName,FuncName,Param)
 	..d OutPut
 	
 	Set qHandle=$lb(0,repid,0)
    q $$$OK
 	
OutPut
	set ColFields="CreateDate,CreateTime,ClassName,FuncName,Param"
 	Set ^CacheTemp(repid,ind)=##Class(LIS.Util.Common).TransListNull(Data,ColFields)
 	Set ind=ind+1
	Quit
}

ClassMethod QryLISCoreKillJobInfoClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = QryLISCoreKillJobInfoExecute ]
{
	Set repid=$li(qHandle,2)
 	Kill ^CacheTemp(repid)
	Quit $$$OK
}

ClassMethod QryLISCoreKillJobInfoFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = QryLISCoreKillJobInfoExecute ]
{
	Set AtEnd=$li(qHandle,1)
 	Set repid=$li(qHandle,2)
 	Set ind=$li(qHandle,3)
 	
 	Set ind=$o(^CacheTemp(repid,ind))
 	If ind="" {				
 		Set AtEnd=1
 		Set Row=""
 	}
 	else      {			
 		Set Row=^CacheTemp(repid,ind)
 	}
 	Set qHandle=$lb(AtEnd,repid,ind)
	Quit $$$OK
}

/// 结束指定进程号的进程
/// w ##Class(LIS.WS.DHCLISServiceBase).KillJobByID()
ClassMethod KillJobByID(JobID)
{
	s JobID=$g(JobID)
	i '$l(JobID) q ""
	s Stop=$zu(4,JobID)
    //s OldNameSpace=$NAMESPACE
    //s $NAMESPACE="%sys"
    //s KRet=##class(SYS.Process).%OpenId(JobID)
    //i KRet="" s $NAMESPACE=OldNameSpace
    //i KRet="" q
	//s Stop=KRet.Terminate()
	//s $NAMESPACE=OldNameSpace
	q Stop
}

/// 查询检验运行进程信息
/// Creator：      zlz
/// CreateDate：   20210422
/// Description:： 查询检验运行进程信息
/// Table：        ^TMPLISCore("DBCARE",JobRunDateTime,JobID)
/// Input：        ^TMPLISCore("STATECARE",JobRunDateTime,JobID)
/// Output：       
/// Others：       无  
/// 
/// D ##Class(%ResultSet).RunQuery("LIS.WS.DHCLISServiceBase","QryLisRunPS","","","","","","","","","","","","","","","113^7^0^12^1")
Query QryLisRunPS(StateUniqueKey As %String, P1, P2, P3, P4, P5, P6, P7, P8, P9, P10, Search, PageSize, PageIndex, Sessions, Output RowCount As %String) As %Query(ROWSPEC = "JobID,ClassName,FuncName,Param,Session,CreateDate,CreateTime,IsStat")
{
}

ClassMethod QryLisRunPSExecute(ByRef qHandle As %Binary, StateUniqueKey As %String, P1, P2, P3, P4, P5, P6, P7, P8, P9, P10, Search, PageSize, PageIndex, Sessions, Output RowCount As %String) As %Status
{
	//s ^TMPLIS("zlz")=$lb(StateUniqueKey,P1, P2, P3, P4, P5, P6, P7, P8, P9, P10, Search, PageSize, PageIndex, Sessions)
	s Sessions=$g(Sessions)
	s StateUniqueKey=$g(StateUniqueKey)
	s repid=$i(^CacheTemp)
 	s ind=1
    s RowCount=0
  	s JobRunDateTime="" f  s JobRunDateTime=$o(^TMPLISCore("DBCARE",JobRunDateTime)) q:JobRunDateTime=""  d
  	.s JobID="" f  s JobID=$o(^TMPLISCore("DBCARE",JobRunDateTime,JobID)) q:JobID=""  d
  	..i JobID=$j q
    ..s CurStateUniqueKey=""
    ..s IsStat=0
    ..i $d(^TMPLISCore("STATECARE",JobRunDateTime,JobID)) d
    ...s IsStat=1
    ...s CurStateUniqueKey=$g(^TMPLISCore("STATECARE",JobRunDateTime,JobID))
    ..i $l(StateUniqueKey),(StateUniqueKey'=CurStateUniqueKey) q
    ..s CareData=$g(^TMPLISCore("DBCARE",JobRunDateTime))
    ..s ClassName=$lg(CareData,1)
    ..s FuncName=$lg(CareData,2)
    ..s Param=$lg(CareData,3) 
    ..s Session=$lg(CareData,4)
    ..s CreateDate=$zd($p(JobRunDateTime,",",1),8)
	..s CreateTime=$p(JobRunDateTime,",",2)
	..s Data=$lb(JobID,ClassName,FuncName,Param,Session,CreateDate,CreateTime,IsStat)
    ..d OutPut
    
	
 	Set qHandle=$lb(0,repid,0)
	Quit $$$OK	
	
OutPut
 	set ColFields="JobID,ClassName,FuncName,Param,Session,CreateDate,CreateTime,IsStat"
 	Set ^CacheTemp(repid,ind)=##Class(LIS.Util.Common).TransListNull(Data,ColFields)
 	Set ind=ind+1
	Quit
}

ClassMethod QryLisRunPSClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = QryLisRunPSExecute ]
{
	Set repid=$li(qHandle,2)
 	Kill ^CacheTemp(repid)
	Quit $$$OK
}

ClassMethod QryLisRunPSFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = QryLisRunPSExecute ]
{
	Set AtEnd=$li(qHandle,1)
 	Set repid=$li(qHandle,2)
 	Set ind=$li(qHandle,3)
 	
 	Set ind=$o(^CacheTemp(repid,ind))
 	If ind="" {				
 		Set AtEnd=1
 		Set Row=""
 	}
 	else      {			
 		Set Row=^CacheTemp(repid,ind)
 	}
 	Set qHandle=$lb(AtEnd,repid,ind)
	Quit $$$OK
}

/// 结束检验进程
/// W ##class(LIS.WS.DHCLISServiceBase).LisTerminalPSMTHD()
/// JobID:结束的进程号
ClassMethod LisTerminalPSMTHD(JobID, P1, P2, P3, P4, P5, P6, P7, P8, P9, P10, P11, P12, P13, Sessions, Output RowCount As %String) As %String
{
	s PerJobRunDateTime=""
	s JobRunDateTime="" f  s JobRunDateTime=$o(^TMPLISCore("DBCARE",JobRunDateTime)) q:JobRunDateTime=""  d
  	.s CurJobID="" f  s CurJobID=$o(^TMPLISCore("DBCARE",JobRunDateTime,CurJobID)) q:CurJobID=""  d
  	..i CurJobID=JobID s PerJobRunDateTime=JobRunDateTime
  	i $l(PerJobRunDateTime) d
  	.d ..KillJobByID(JobID)
  	.i $d(^TMPLISCore("DBCARE",PerJobRunDateTime,JobID)) d
	..k ^TMPLISCore("DBCARE",PerJobRunDateTime,JobID)
	..i $d(^TMPLISCore("STATECARE",PerJobRunDateTime,JobID)) k ^TMPLISCore("STATECARE",PerJobRunDateTime,JobID)
	e  q "-1^不允许结束非检验管理的进程！"
	q ""
}

/// 查询第三方数据库的数据得到json
/// w ##class(LIS.WS.DHCLISServiceBase).SQLGatewayGetJsonMTHD("xianfen","cx","cx123456","select top 10 * from listm" )
/// mDSN:SQL网关配置的名称
/// mUsrName:数据库密码
/// mUsrPwd:数据库密码
/// sql:SQL语句
ClassMethod SQLGatewayGetJsonMTHD(mDSN, mUsrName, mUsrPwd, sql, P4, P5, P6, P7, P8, P9, P10, P11, P12, P13, Sessions, Output RowCount As %String) As %String
{
	//ODBC-系统DSN的名称,在SQL网关配置的名称
	s mDSN=$g(mDSN)
	//数据库账号
    s mUsrName=$g(mUsrName)  
    //数据库密码   
    s mUsrPwd=$g(mUsrPwd) 
    //执行的SQL语句
    s sql=$g(sql)  
    s RowCount=$g(RowCount)
    //创建连接
    s conn=##class(%SQLGatewayConnection).%New()
    set $ZTRAP="ERR" 
    //设置超时
    s sc=conn.Connect(mDSN,mUsrName,mUsrPwd,10)  
    i $$$ISERR(sc) do $System.Status.DisplayError(sc) d
    .THROW ##class(%Exception.SystemException).%New("连接异常","D",,"-1^第三方数据库连接失败")
    s rset = ##class(%ResultSet).%New("%DynamicQueryGW:SQLGW")
    //调用第三方SQL
    s sc = rset.Prepare(sql,,conn)  
    //发送错误就释放连接
    i $$$ISERR(sc) do $System.Status.DisplayError(sc) d
    .s close=rset.Close()
    .s sc=conn.Disconnect() 
    .THROW ##class(%Exception.SystemException).%New("连接异常","D",,"-1^第三方数据库连接失败")
    s sc=rset.Execute()
    //发送错误就释放连接
    i $$$ISERR(sc) do $System.Status.DisplayError(sc) d
    .s close=rset.Close()
    .s sc=conn.Disconnect() 
    .THROW ##class(%Exception.SystemException).%New("连接异常","D",,"-1^第三方数据库连接失败")
    s Xml=##Class(LIS.WS.BLL.DHCDataJSON).DataSetToSortJSONStream(rset , "", "", "", "", .RowCount,"","")
    s sc=conn.Disconnect()
    q Xml.Read()
    
ERR
    s sc=conn.Disconnect()
    s err=$tr("查询异常.错误"_$tr($ZERROR,"^","--")_".错误代码:"_$ECODE,"<>")
	s objStream=##Class(LIS.Util.Response).GetReturn("","-1",err)
    Quit objStream.Read()
}

/// 查询第三方数据库的数据得到xml
/// w ##class(LIS.WS.DHCLISServiceBase).SQLGatewayGetXmlMTHD("xianfen","cx","cx123456","select top 10 * from listm" )
/// mDSN:SQL网关配置的名称
/// mUsrName:数据库密码
/// mUsrPwd:数据库密码
/// sql:SQL语句
ClassMethod SQLGatewayGetXmlMTHD(mDSN, mUsrName, mUsrPwd, sql, P4, P5, P6, P7, P8, P9, P10, P11, P12, P13, Sessions, Output RowCount As %String) As %String
{
	//ODBC-系统DSN的名称,在SQL网关配置的名称
	s mDSN=$g(mDSN)
	//数据库账号
    s mUsrName=$g(mUsrName)  
    //数据库密码   
    s mUsrPwd=$g(mUsrPwd) 
    //执行的SQL语句
    s sql=$g(sql)  
    s RowCount=$g(RowCount)
    //创建连接
    s conn=##class(%SQLGatewayConnection).%New()
    set $ZTRAP="ERR" 
    //设置超时
    s sc=conn.Connect(mDSN,mUsrName,mUsrPwd,10)  
    i $$$ISERR(sc) do $System.Status.DisplayError(sc) d
    .THROW ##class(%Exception.SystemException).%New("连接异常","D",,"-1^第三方数据库连接失败")
    s rset = ##class(%ResultSet).%New("%DynamicQueryGW:SQLGW")
    //调用第三方SQL
    s sc = rset.Prepare(sql,,conn)  
    //发送错误就释放连接
    i $$$ISERR(sc) do $System.Status.DisplayError(sc) d
    .s close=rset.Close()
    .s sc=conn.Disconnect() 
    .THROW ##class(%Exception.SystemException).%New("连接异常","D",,"-1^第三方数据库连接失败")
    s sc=rset.Execute()
    //发送错误就释放连接
    i $$$ISERR(sc) do $System.Status.DisplayError(sc) d
    .s close=rset.Close()
    .s sc=conn.Disconnect() 
    .THROW ##class(%Exception.SystemException).%New("连接异常","D",,"-1^第三方数据库连接失败")
    s Xml=##class(LIS.Util.DataSetXML).DataSetToSortStream(rset,"", "", "", "", .RowCount,"","")
    s sc=conn.Disconnect()
    q Xml.Read()
    
ERR
    s sc=conn.Disconnect()
    s err=$tr("查询异常.错误"_$tr($ZERROR,"^","--")_".错误代码:"_$ECODE,"<>")
	s objStream=##Class(LIS.Util.Response).GetReturn("","-1",##Class(LIS.WS.BLL.DHCDataJSON).DealForXML(err))
    Quit objStream.Read()
}

/// 查询第三方数据库的数据得集合,返回二维数组，第一行为列名，后面的为数据行,最多返回1000行
/// w ##class(LIS.WS.DHCLISServiceBase).SQLGatewayGetList("xianfen","cx","cx123456","select top 10 * from listm" )
/// zw ##class(LIS.WS.DHCLISServiceBase).SQLGatewayGetList("lis","_system","SYS","select * from dbo.SYS_User where Code='dhcc'" )
/// mDSN:SQL网关配置的名称
/// mUsrName:数据库密码
/// mUsrPwd:数据库密码
/// sql:SQL语句
ClassMethod SQLGatewayGetList(mDSN, mUsrName, mUsrPwd, sql, P4, P5, P6, P7, P8, P9, P10, P11, P12, P13, Sessions, Output RowCount As %String)
{
	//ODBC-系统DSN的名称,在SQL网关配置的名称
	s mDSN=$g(mDSN)
	//数据库账号
    s mUsrName=$g(mUsrName)  
    //数据库密码   
    s mUsrPwd=$g(mUsrPwd) 
    //执行的SQL语句
    s sql=$g(sql)  
    s RowCount=$g(RowCount)
    //创建连接
    s conn=##class(%SQLGatewayConnection).%New()
    set $ZTRAP="ERR" 
    //设置超时
    s sc=conn.Connect(mDSN,mUsrName,mUsrPwd,10)  
    i $$$ISERR(sc) do $System.Status.DisplayError(sc) d
    .THROW ##class(%Exception.SystemException).%New("连接异常","D",,"-1^第三方数据库连接失败")
    s rset = ##class(%ResultSet).%New("%DynamicQueryGW:SQLGW")
    //调用第三方SQL
    s sc = rset.Prepare(sql,,conn)  
    //发送错误就释放连接
    i $$$ISERR(sc) do $System.Status.DisplayError(sc) d
    .s close=rset.Close()
    .s sc=conn.Disconnect() 
    .THROW ##class(%Exception.SystemException).%New("连接异常","D",,"-1^第三方数据库连接失败")
    s sc=rset.Execute()
    //发送错误就释放连接
    i $$$ISERR(sc) do $System.Status.DisplayError(sc) d
    .s close=rset.Close()
    .s sc=conn.Disconnect() 
    .THROW ##class(%Exception.SystemException).%New("连接异常","D",,"-1^第三方数据库连接失败")
    s retLb=""
    //查询语句
    i ($zcvt(sql,"U")["SELECT ")
    {
	    s colCount=rset.GetColumnCount()
		s rownum=0
		While(rset.Next())
    	{
	    	i rownum>1000 break
	    	s oneRow=""
			s oneRowName=""
        	f i=1:1:colCount 
        	{
	      	s colField=rset.GetColumnName(i)
    	  	s colVal=rset.GetData(i)
	      	i i=1 d
	      	.s oneRowName=$lb(colField)
	      	.s oneRow=$lb(colVal)
	      	e  d
	      	.s oneRowName=oneRowName_$lb(colField)
	      	.s oneRow=oneRow_$lb(colVal)
        	}
        	i '$l(retLb) d
        	.s retLb=$lb(oneRowName)
        	s retLb=retLb_$lb(oneRow)
        	s rownum=rownum+1
    	}
    }
    else
    {
	    s retLb=$lb(sc)
    }
    s sc=conn.Disconnect()
    q retLb
    
ERR
    s sc=conn.Disconnect()
    Quit ""
}

/// 到远程数据库执行M方法返回数据
/// w ##class(LIS.WS.DHCLISServiceBase).RemoteExcMethod("http://114.251.235.30:57772/imedicallis/csp/LIS.WS.DHCLISService.cls?wsdl=1&amp;CacheUserName=_system&amp;CachePassword=SYS","LIS.WS.DHCLISServiceBase","RemoteCacheActiveTestMTHD","")
/// Address:webservice地址
/// ClassName:调用类名
/// FuncName:调用方法名
/// P0-P14的参数
ClassMethod RemoteExcMethod(Address, ClassName As %String, FuncName As %String, P0 As %String, P1 As %String, P2 As %String, P3 As %String, P4 As %String, P5 As %String, P6 As %String, P7 As %String, P8 As %String, P9 As %String, P10 As %String, P11 As %String, P12 As %String, P13 As %String, P14 As %String) As %String [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 	s Address=$g(Address)
	s ClassName=$g(ClassName)
	s FuncName=$g(FuncName)
	s P0=$g(P0)
	s P1=$g(P1)
	s P2=$g(P2)
	s P3=$g(P3)
	s P4=$g(P4)
	s P5=$g(P5)
	s P6=$g(P6)
	s P7=$g(P7)
	s P8=$g(P8)
	s P9=$g(P9)
	s P10=$g(P10)
	s P11=$g(P11)
	s P12=$g(P12)
	s P13=$g(P13)
	s P14=$g(P14)
	s soapObj=##Class(LIS.WS.DHCLISServiceSoap).%New()
	s soapObj.Address=Address
	s retstr=soapObj.ExcMethod(ClassName,FuncName,P0,P1,P2,P3,P4,P5,P6,P7,P8,P9,P10,P11,P12,P13,P14)
	q retstr
}

/// 到远程数据库执行M返回数据
/// w ##class(LIS.WS.DHCLISServiceBase).RemoteGetData("http://10.10.2.161:57772/csp/lis/LIS.WS.DHCLISService.cls?wsdl=1&CacheUserName=_system&CachePassword=SYS","LISSP.BLL.DHCRPVisitNumberCrossDB","SaveMachineResultMTHD","AU5800",2303150310,"104\1.45,107\326,108\21.61,111\2,112\21,113\0.98,114\2.43,116\66.21,117\48,118\1.06,097\141,098\3.78,099\105,001\27.4,009\89,017\5.1,002\6.23,010\15.6,018\4.01,003\25,011\2.9,019\48,004\15,012\399,005\73.1,006\137,014\1.19,007\22,008\49.4,016\2.48,025\73,026\2.6,032\12036.20,033\86.22,024\12.7,027\0.60,029\3.1,","","","","PYSDSRMYY","","","","","","","","")
/// Address:webservice地址
/// ClassName:调用类名
/// FuncName:调用方法名
/// P0-P13的参数
/// OutFormat:输出类型，不传输出JSON，否则输出xml
ClassMethod RemoteGetData(Address, ClassName, FuncName, P0, P1, P2, P3, P4, P5, P6, P7, P8, P9, P10, P11, P12, P13, Sessions, OutFormat) As %String
{
	//s ^tempRemoteGetData("RemoteGetData")=$lb(Address, ClassName, FuncName, P0, P1, P2, P3, P4, P5, P6, P7, P8, P9, P10, P11, P12, P13, Sessions)
	s Address=$g(Address)
	s ClassName=$g(ClassName)
	s FuncName=$g(FuncName)
	s P0=$g(P0)
	s P1=$g(P1)
	s P2=$g(P2)
	s P3=$g(P3)
	s P4=$g(P4)
	s P5=$g(P5)
	s P6=$g(P6)
	s P7=$g(P7)
	s P8=$g(P8)
	s P9=$g(P9)
	s P10=$g(P10)
	s P11=$g(P11)
	s P12=$g(P12)
	s P13=$g(P13)
	s Sessions=$g(Sessions)
	s OutFormat=$g(OutFormat)
	s RowCount=$g(RowCount)
	s soapObj=##Class(LIS.WS.DHCLISServiceSoap).%New()
	s soapObj.Address=Address
	s ParaXml="<Parameter>"
	s ParaXml=ParaXml_"<P0>"_##Class(LIS.WS.BLL.DHCDataJSON).DealForXML(P0)_"</P0>"
	s ParaXml=ParaXml_"<P1>"_##Class(LIS.WS.BLL.DHCDataJSON).DealForXML(P1)_"</P1>"
	s ParaXml=ParaXml_"<P2>"_##Class(LIS.WS.BLL.DHCDataJSON).DealForXML(P2)_"</P2>"
	s ParaXml=ParaXml_"<P3>"_##Class(LIS.WS.BLL.DHCDataJSON).DealForXML(P3)_"</P3>"
	s ParaXml=ParaXml_"<P4>"_##Class(LIS.WS.BLL.DHCDataJSON).DealForXML(P4)_"</P4>"
	s ParaXml=ParaXml_"<P5>"_##Class(LIS.WS.BLL.DHCDataJSON).DealForXML(P5)_"</P5>"
	s ParaXml=ParaXml_"<P6>"_##Class(LIS.WS.BLL.DHCDataJSON).DealForXML(P6)_"</P6>"
	s ParaXml=ParaXml_"<P7>"_##Class(LIS.WS.BLL.DHCDataJSON).DealForXML(P7)_"</P7>"
	s ParaXml=ParaXml_"<P8>"_##Class(LIS.WS.BLL.DHCDataJSON).DealForXML(P8)_"</P8>"
	s ParaXml=ParaXml_"<P9>"_##Class(LIS.WS.BLL.DHCDataJSON).DealForXML(P9)_"</P9>"
	s ParaXml=ParaXml_"<P10>"_##Class(LIS.WS.BLL.DHCDataJSON).DealForXML(P10)_"</P10>"
	s ParaXml=ParaXml_"<P11>"_##Class(LIS.WS.BLL.DHCDataJSON).DealForXML(P11)_"</P11>"
	s ParaXml=ParaXml_"<P12>"_##Class(LIS.WS.BLL.DHCDataJSON).DealForXML(P12)_"</P12>"
	s ParaXml=ParaXml_"<P13>"_##Class(LIS.WS.BLL.DHCDataJSON).DealForXML(P13)_"</P13>"
	s ParaXml=ParaXml_"</Parameter>"
	i '$l(OutFormat) d
	.s OutFormat="JSON"
	i OutFormat="JSON" d
	.s $p(Sessions,"^",7)="JSON"
	.s retxml=soapObj.GetData(ClassName,FuncName,ParaXml,Sessions)
	.s retxml=$REPLACE(retxml,"&lt;","<")
	.s retxml=$REPLACE(retxml,"&gt;",">")
	.s err=..GetXmlValByPath(retxml,"/Response/Error")
	.i $l(err) THROW ##class(%Exception.SystemException).%New("远程调用异常","D",,"调用远程M失败:"_err)
	.s retstr=..GetXmlValByPath(retxml)
	e  d
	.s retstr=soapObj.GetData(ClassName,FuncName,ParaXml,Sessions)
	q retstr
}

/// 通过xpath得到xml节点值
/// w ##class(LIS.WS.DHCLISServiceBase).GetXmlValByPath("<Response><RemoteCacheActiveTestMTHDResult>1</RemoteCacheActiveTestMTHDResult><RetVal>0</RetVal><Error></Error><Node>RemoteCacheActiveTestMTHD</Node><RowCount>0</RowCount><ResType>1</ResType><RetSession>^^^^^^JSON</RetSession></Response>","")
/// xml:xml串
/// xpath:不传就默认为检验csp返回格式的xpath，否则传入/Response/RemoteCacheActiveTestMTHD格式层级路径
ClassMethod GetXmlValByPath(xml, xpath)
{
	s xml=$g(xml)
	s xpath=$g(xpath)
	set sc = ##class(%XML.TextReader).ParseStream(xml, .reader)
	Set repid=$I(^CacheTemp)
	s ret=""
	k ^TMP($zn,repid,$j)
	while (reader.Read()) {
		set Type = reader.NodeType
		set Path = reader.Path
		set Value = reader.Value
		i Type="chars" d
		.i '$d(^TMP($zn,repid,$j,Path)) d
		..s ^TMP($zn,repid,$j,Path)=Value
		.e  d
		..s ^TMP($zn,repid,$j,Path)=^TMP($zn,repid,$j,Path)_Value
	}
	i '$l(xpath) d
	.s nodenamePath="/Response/Node"
	.s resNodeName=$g(^TMP($zn,repid,$j,nodenamePath))
	.s xpath="/Response/"_resNodeName_"Result"
	i $l(xpath) s ret=$g(^TMP($zn,repid,$j,xpath))
	k ^TMP($zn,repid,$j)
	q ret
}

/// 通过xpath得到xml节点值,globle在^TMPXmlGloble("返回主节点"上，业务记得用完k掉
/// w ##class(LIS.WS.DHCLISServiceBase).XmlToGlobleNode("<Request><ReportMsg><OrdID>382||2</OrdID><RecUserCode>1450</RecUserCode><RecUser>王婧婧</RecUser><RecDate>2016-11-13</RecDate><RecTime>16:23:44</RecTime><EntryUserCode>1450</EntryUserCode><EntryUser>王婧婧</EntryUser><EntryDate>2016-11-17</EntryDate><EntryTime>09:43:29</EntryTime><AuthUserCode>1469</AuthUserCode><AuthUser>吴吉芳</AuthUser><AuthDate>2016-11-17</AuthDate><AuthTime>09:43:29</AuthTime><Notes></Notes><ImageFile></ImageFile><MainWarnDesc></MainWarnDesc><ResultMsgs><ResultMsg><LabNo>00000000314</LabNo><TestCode>2298</TestCode><TestName>一般细菌培养及鉴定1</TestName><TestEngName></TestEngName><Result>SAU</Result><Units></Units><Notes></Notes><ResultFlag></ResultFlag><Ranges></Ranges><Sequence>480</Sequence><MICFlag>Y</MICFlag><MICName>金黄色葡萄球菌</MICName><WarnDesc></WarnDesc><OrgResultMsgs><OrgResultMsg><BugsCode>SAU</BugsCode><AntiCode>AMC</AntiCode><AntiName>阿莫西林/棒酸</AntiName><AntiEngName>AMC</AntiEngName><MICRes>≤0.5/0.25</MICRes><KBRes></KBRes><Result>敏感</Result><MICRanges></MICRanges><KBRanges></KBRanges><Order>1</Order></OrgResultMsg><OrgResultMsg><BugsCode>SAU</BugsCode><AntiCode>AN</AntiCode><AntiName>阿米卡星</AntiName><AntiEngName>AN</AntiEngName><MICRes>≤4</MICRes><KBRes></KBRes><Result>敏感</Result><MICRanges></MICRanges><KBRanges></KBRanges><Order>2</Order></OrgResultMsg><OrgResultMsg><BugsCode>SAU</BugsCode><AntiCode>AZT</AntiCode><AntiName>阿奇霉素</AntiName><AntiEngName>AZT</AntiEngName><MICRes>≥8</MICRes><KBRes></KBRes><Result>耐药</Result><MICRanges></MICRanges><KBRanges></KBRanges><Order>3</Order></OrgResultMsg><OrgResultMsg><BugsCode>SAU</BugsCode><AntiCode>CE</AntiCode><AntiName>克林霉素/红霉素</AntiName><AntiEngName>CE</AntiEngName><MICRes>＞0.5/4</MICRes><KBRes></KBRes><Result>耐药</Result><MICRanges></MICRanges><KBRanges></KBRanges><Order>4</Order></OrgResultMsg><OrgResultMsg><BugsCode>SAU</BugsCode><AntiCode>CZO</AntiCode><AntiName>头孢唑啉</AntiName><AntiEngName>CZO</AntiEngName><MICRes>≤1</MICRes><KBRes></KBRes><Result>敏感</Result><MICRanges></MICRanges><KBRanges></KBRanges><Order>5</Order></OrgResultMsg></OrgResultMsgs></ResultMsg><ResultMsg><LabNo>00000000314</LabNo><TestCode>2299</TestCode><TestName>一般细菌培养及鉴定2</TestName><TestEngName></TestEngName><Result>ABA</Result><Units></Units><Notes></Notes><ResultFlag></ResultFlag><Ranges></Ranges><Sequence>480</Sequence><MICFlag>Y</MICFlag><MICName>鲍曼不动杆菌</MICName><WarnDesc></WarnDesc><OrgResultMsgs><OrgResultMsg><BugsCode>ABA</BugsCode><AntiCode>AMC</AntiCode><AntiName>阿莫西林/棒酸</AntiName><AntiEngName>AMC</AntiEngName><MICRes>≤0.5/0.25</MICRes><KBRes></KBRes><Result>敏感</Result><MICRanges></MICRanges><KBRanges></KBRanges><Order>1</Order></OrgResultMsg><OrgResultMsg><BugsCode>ABA</BugsCode><AntiCode>FOX</AntiCode><AntiName>头孢西丁</AntiName><AntiEngName>FOX</AntiEngName><MICRes>≤2</MICRes><KBRes></KBRes><Result>敏感</Result><MICRanges></MICRanges><KBRanges></KBRanges><Order>2</Order></OrgResultMsg><OrgResultMsg><BugsCode>ABA</BugsCode><AntiCode>gm</AntiCode><AntiName>庆大霉素</AntiName><AntiEngName>gm</AntiEngName><MICRes>≤1</MICRes><KBRes></KBRes><Result>敏感</Result><MICRanges></MICRanges><KBRanges></KBRanges><Order>3</Order></OrgResultMsg><OrgResultMsg><BugsCode>ABA</BugsCode><AntiCode>IMI</AntiCode><AntiName>亚胺培南</AntiName><AntiEngName>IMI</AntiEngName><MICRes>≤0.06</MICRes><KBRes></KBRes><Result>敏感</Result><MICRanges></MICRanges><KBRanges></KBRanges><Order>4</Order></OrgResultMsg></OrgResultMsgs></ResultMsg></ResultMsgs></ReportMsg></Request>")
/// xml:xml串
/// xpath:不传就默认为检验csp返回格式的xpath，否则传入/Response/RemoteCacheActiveTestMTHD格式层级路径
ClassMethod XmlToGlobleNode(xml)
{
	s xml=$g(xml)
	set sc = ##class(%XML.TextReader).ParseStream(xml, .reader)
	Set repid=$I(^CacheTemp)
	s ret=""
	s MainNode=$zn_"-"_repid_"-"_$j
	k ^TMPXmlGloble(MainNode)
	s PathNum=""
	while (reader.Read()) {
		set Type = reader.NodeType
		set Path = reader.Path
		set Value = reader.Value
		i Type="element" d
		.i '$d(PathNum(Path)) s PathNum(Path)=0
		.s PathNum(Path)=PathNum(Path)+1
		i Type="chars" d
		.s NodeStr=""
		.s AddPath=""
		.f i=1:1:$l(Path,"/") d
		..s pNode=$p(Path,"/",i)
		..i '$l(pNode) q
		..s AddPath=AddPath_"/"_pNode
		..s AddNum=$g(PathNum(AddPath))
		..i '$l(AddNum) s AddNum="1"
		..s NodeStr=NodeStr_","""_pNode_""","""_AddNum_""""
		.i '$d(@("^TMPXmlGloble("""_MainNode_""""_NodeStr_")")) d
		..s (@("^TMPXmlGloble("""_MainNode_""""_NodeStr_")"))=Value
		.e  d
		..s (@("^TMPXmlGloble("""_MainNode_""""_NodeStr_")"))=(@("^TMPXmlGloble("""_MainNode_""""_NodeStr_")"))_Value
	}
	q MainNode
}

/// 测试远程数据库是否能访问，可以访问返回1，供远程库测试是否能访问的方法
/// w ##class(LIS.WS.DHCLISServiceBase).RemoteCacheActiveTestMTHD("")
ClassMethod RemoteCacheActiveTestMTHD(P0, P1, P2, P3, P4, P5, P6, P7, P8, P9, P10, P11, P12, P13, Sessions, Output RowCount As %String) As %String
{
	q "客户端:"_$zutil(67,15,$j)_"你好，我的IP是:"_##Class(LIS.Util.Common).GetServerIP()
}

///  Creator：      zhanglianzhu
///  CreatDate：    20210701
///  Description:： 查询得到IP和Webservice映射，供内外网打印配置IP映射
///  Table：        
///  Input：        
///  Output：       
///  Return：       
///  Others：
Query QryIPWebserviceMap(P0, P1, P2, P3, P4, P5, P6, P7, P8, P9, P10, P11, P12, P13, Sessions, Output RowCount As %String) As %Query(ROWSPEC = "IP,Webservice")
{
}

/// Query的执行方法
/// d ##class(%ResultSet).RunQuery("LIS.WS.DHCLISServiceBase","QryIPWebserviceMap","","","","","","","","","","","","","","","113^4^^2^1")
ClassMethod QryIPWebserviceMapExecute(ByRef qHandle As %Binary, P0, P1, P2, P3, P4, P5, P6, P7, P8, P9, P10, P11, P12, P13, Sessions, Output RowCount As %String) As %Status
{
 	Set repid=$I(^CacheTemp)
	If $Get(ind)="" Set ind=1

    s ParamCode=" "_$zcvt("IPWebserviceMap","U")
    i $d(^dbo.SYSParameterI("IndexCode",ParamCode))  d 
    .s ParamType="" f  s ParamType=$o(^dbo.SYSParameterI("IndexCode",ParamCode,ParamType)) q:ParamType=""  d
    ..s ParamTypeID="" f  s ParamTypeID=$o(^dbo.SYSParameterI("IndexCode",ParamCode,ParamType,ParamTypeID)) q:ParamTypeID=""  d
    ...s SYSParameterDR="" f  s SYSParameterDR=$o(^dbo.SYSParameterI("IndexCode",ParamCode,ParamType,ParamTypeID,SYSParameterDR)) q:SYSParameterDR=""  d
    ....s IP=$Lg($g(^dbo.SYSParameterD(SYSParameterDR)),5)
    ....s Webservice=$Lg($g(^dbo.SYSParameterD(SYSParameterDR)),6)
    ....d OutputRow
    
 	Set qHandle=$lb(0,repid,0)
	Quit $$$OK
	
	
OutputRow
    Set Data=$lb(IP,Webservice)	
 	Set ColFields = "Code,Value"
 	Set ^CacheTemp(repid,ind)=##Class(LIS.Util.Common).TransListNull(Data,ColFields)
 	Set ind=ind+1
	quit
}

ClassMethod QryIPWebserviceMapClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = QryIPWebserviceMapExecute ]
{
	Set repid=$LIST(qHandle,2)
 	Kill ^CacheTemp(repid)
	Quit $$$OK
}

ClassMethod QryIPWebserviceMapFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = QryIPWebserviceMapExecute ]
{
 	Set AtEnd=$LIST(qHandle,1)
 	Set repid=$LIST(qHandle,2)
 	Set ind=$LIST(qHandle,3)
 	Set ind=$o(^CacheTemp(repid,ind))
 	If ind="" {				// if there are no more rows, finish fetching
 		Set AtEnd=1
 		Set Row=""
 	}
 	Else      {				// fetch row
 		Set Row=^CacheTemp(repid,ind)
 	}
 	// Save QHandle
 	s qHandle=$lb(AtEnd,repid,ind)
	Quit $$$OK
}

/// 上报系统信息
/// w ##class(LIS.WS.DHCLISServiceBase).ReportSystemInfoMTHD("192.168.0.5","209715196^170437024^39278172^81.27070772687355%")
ClassMethod ReportSystemInfoMTHD(IP, DiskInfo, P2, P3, P4, P5, P6, P7, P8, P9, P10, P11, P12, P13, Sessions, Output RowCount As %String) As %String
{
	s IP=$g(IP)
	s OS=$p(IP,"^",2)
	s IP=$p(IP,"^",1)
	s DiskInfo=$g(DiskInfo)
	s DiskTotalSize=$p(DiskInfo,"^",1)
	s DiskUsedSize=$p(DiskInfo,"^",2)
	s DiskAvailableSize=$p(DiskInfo,"^",3)
	s DiskUse=$p(DiskInfo,"^",4)
	s MemTotalSize=$p(DiskInfo,"^",5)
	s MemUsedSize=$p(DiskInfo,"^",6)
	s IPIndex=##Class(LIS.Util.Common).IndexData(IP)
	//最后数据序号
	s Num=""
	//最后数据添加日期
	s AddDate=$zd($h,8)
	s AddTime=$p($h,",",2)
	s PreDiskUsedSize=DiskUsedSize
	s DiskSpeedMoveAve=0
	i $d(^dbo.SYSSystemMonitorI("IndexNum",IPIndex)) d
	.s Num=$o(^dbo.SYSSystemMonitorI("IndexNum",IPIndex,""),-1)
	.s RowID=$o(^dbo.SYSSystemMonitorI("IndexNum",IPIndex,Num,""),-1)
	.i $l(RowID) d
	..s AddDate=$lg($g(^dbo.SYSSystemMonitorD(RowID)),3)
	..s AddTime=$lg($g(^dbo.SYSSystemMonitorD(RowID)),4)
	..s PreDiskUsedSize=$lg($g(^dbo.SYSSystemMonitorD(RowID)),6)
	..s DiskSpeedMoveAve=$lg($g(^dbo.SYSSystemMonitorD(RowID)),11)
	i '$l(Num) s Num=0
	s TimeCha=##Class(LIS.Util.Common).GetDateTimeDiff($zd($h,8),$p($h,",",2),AddDate,AddTime)
	//秒
	s Second=$p(TimeCha,",",4)
	i Second=0 s Second=1
	//增加序号
	s Num=Num+1
	s obj=##Class(dbo.SYSSystemMonitor).%New()
	s obj.AddDate=$zd($h,8)
	s obj.AddTime=$p($h,",",2)
	s obj.DataNum=Num
	s obj.DiskAvailableSize=DiskAvailableSize
	s obj.DiskTotalSize=DiskTotalSize
	s obj.DiskUse=$e(DiskUse,1,15)
	s obj.DiskUsedSize=DiskUsedSize
	//每十分钟使用多少兆
	s obj.DiskUseSpeed=$e((DiskUsedSize-PreDiskUsedSize)*1.0/1024/Second*600,1,15)
	s obj.DiskSpeedMoveAve=$e(((DiskSpeedMoveAve*(Num-1.0))+obj.DiskUseSpeed)/Num,1,15)
	s obj.IP=IP
	s obj.OS=OS
	s obj.MemTotalSize=$e(MemTotalSize,1,15)
	s obj.MemUsedSize=$e(MemUsedSize,1,15)
	s ret=obj.%Save()
	q ""
}

/// Creator：      zlz
/// CreatDate：    20211120
/// Description:： 查询系统监控数据
/// Table：        
/// Input：        
/// Output：       查询系统监控数据
/// Return：       
/// Others：       
Query QrySystemMonitor(P0, P1, P2, P3, P4, P5, P6, P7, P8, P9, P10, P11, P12, P13, Sessions, Output RowCount As %String) As %Query(ROWSPEC = "IP,OutXStr,DiskUseSpeedStr,DiskSpeedMoveAveStr,DiskUseStr,OutDiskTotalSize,OutDiskUsedSize,OutDiskAvailableSize,OutDiskUse,Waring,OutOS,IsOnline,OutMemTotalSize,OutMemUsedSize,OutMemAvailableSize,MemUseStr")
{
}

/// Query的执行方法
/// d ##class(%ResultSet).RunQuery("LIS.WS.DHCLISServiceBase","QrySystemMonitor","","","","","","","","","","","","","","","","")
ClassMethod QrySystemMonitorExecute(ByRef qHandle As %Binary, P0, P1, P2, P3, P4, P5, P6, P7, P8, P9, P10, P11, P12, P13, Sessions, Output RowCount As %String) As %Status
{
 	Set repid=$I(^CacheTemp)
	If $Get(ind)="" Set ind=1
	
	s CurDate=$p($h,",",1)

	//删除时间久的消息
	S MaxMsgDate=CurDate-30
	s MaxDateMsgDay=$zd(MaxMsgDate,8)
	s AddDate=MaxDateMsgDay f  s AddDate=$o(^dbo.SYSSystemMonitorI("IndexAddDate",AddDate),-1) q:AddDate=""  d
	.s MsgRowID="" f  s MsgRowID=$o(^dbo.SYSSystemMonitorI("IndexAddDate",AddDate,MsgRowID)) q:MsgRowID=""  d
	..&sql(delete from dbo.SYS_SystemMonitor where RowID=:MsgRowID)
	
	s IP="" f  s IP=$o(^dbo.SYSSystemMonitorI("IndexNum",IP)) q:IP=""  d
	.s OutNum=0
	.s OutXStr=""
	.s DiskUseSpeedStr=""
	.s DiskUseStr=""
	.s DiskSpeedMoveAveStr=""
	.s OutDiskTotalSize=""
	.s OutDiskUsedSize=""
	.s OutDiskAvailableSize=""
	.s OutDiskUse=""
	.s OutOS=""
	.s OutMemTotalSize=""
	.s OutMemUsedSize=""
	.s OutMemAvailableSize=""
	.s Waring=""
	.s IPOut=""
	.s MemUseStr=""
	.s LastDate=$zd($h,8)
	.s LastTime=$p($h,",",2)
	.s DataNum="" f  s DataNum=$o(^dbo.SYSSystemMonitorI("IndexNum",IP,DataNum),-1) q:DataNum=""||(OutNum>130)  d
	..s RowID="" f  s RowID=$o(^dbo.SYSSystemMonitorI("IndexNum",IP,DataNum,RowID),-1) q:RowID=""  d
	...s OutNum=OutNum+1
	...s AddDate=$lg($g(^dbo.SYSSystemMonitorD(RowID)),3)
	...s AddTime=$lg($g(^dbo.SYSSystemMonitorD(RowID)),4)
	...i $l(OutXStr) s OutXStr=$zt(AddTime)_","_OutXStr
	...e  s OutXStr=$zt(AddTime)
	...s DiskTotalSize=$lg($g(^dbo.SYSSystemMonitorD(RowID)),5)
	...s DiskUsedSize=$lg($g(^dbo.SYSSystemMonitorD(RowID)),6)
	...s DiskAvailableSize=$lg($g(^dbo.SYSSystemMonitorD(RowID)),7)
	...s DiskUse=$lg($g(^dbo.SYSSystemMonitorD(RowID)),8)
	...s DiskUse=$tr(DiskUse,"%")
	...s DiskUseSpeed=$lg($g(^dbo.SYSSystemMonitorD(RowID)),10)
	...s DiskSpeedMoveAve=$lg($g(^dbo.SYSSystemMonitorD(RowID)),11)
	...s OS=$lg($g(^dbo.SYSSystemMonitorD(RowID)),12)
	...s MemTotalSize=$lg($g(^dbo.SYSSystemMonitorD(RowID)),13)
	...s MemUsedSize=$lg($g(^dbo.SYSSystemMonitorD(RowID)),14)
	...i $l(MemUseStr) s MemUseStr=MemUseStr_","_MemUsedSize
	...e  s MemUseStr=MemUsedSize
	...i '$l(OutDiskTotalSize) d
	....s LastDate=AddDate
	....s LastTime=AddTime
	....s OutDiskTotalSize=..DealPointNew(DiskTotalSize/1024/1024,2)
	....s OutDiskUsedSize=..DealPointNew(DiskUsedSize/1024/1024,2)
	....s OutDiskAvailableSize=..DealPointNew(DiskAvailableSize/1024/1024,2)
	....s OutDiskUse=..DealPointNew(DiskUse,2)
	....i OutDiskUse>80 s Waring="1"
	....s OutOS=OS
	....s OutMemTotalSize=..DealPointNew(MemTotalSize,2)
	....s OutMemUsedSize=..DealPointNew(MemUsedSize,2)
	....i $l(OutMemTotalSize),(OutMemTotalSize>0) d
	.....s OutMemAvailableSize=OutMemTotalSize-OutMemUsedSize
	.....s MemUseRate=OutMemUsedSize/OutMemTotalSize*100
	.....i MemUseRate>80 s Waring="1"
	....s IPOut=$lg($g(^dbo.SYSSystemMonitorD(RowID)),2)
	....i IPOut["/" d
	.....s OutOS=$p(IPOut,"/",2)
	.....s IPOut=$p(IPOut,"/",1)
	...i $l(DiskUseSpeedStr) s DiskUseSpeedStr=..DealPointNew(DiskUseSpeed,2)_","_DiskUseSpeedStr
	...e  s DiskUseSpeedStr=..DealPointNew(DiskUseSpeed,2)
	...i $l(DiskSpeedMoveAveStr) s DiskSpeedMoveAveStr=DiskSpeedMoveAve_","_..DealPointNew(DiskSpeedMoveAveStr,2)
	...e  s DiskSpeedMoveAveStr=..DealPointNew(DiskSpeedMoveAve,2)
	...i $l(DiskUseStr) s DiskUseStr=..DealPointNew(DiskUse,2)_","_DiskUseStr
	...e  s DiskUseStr=..DealPointNew(DiskUse,2)
	.s TimeCha=##Class(LIS.Util.Common).GetDateTimeDiff($zd($h,8),$p($h,",",2),LastDate,LastTime)
	.//失去活动一天的机器不查询
	.s LastDateInner=$zdh(LastDate,8)
	.i (($p($h,",",1)-LastDateInner)>1) q
	.//分钟
	.s Minite=$p(TimeCha,",",3)
	.s IsOnline=1
	.i Minite>30 s IsOnline=0
	.d OutputRow

 	Set qHandle=$lb(0,repid,0)
	Quit $$$OK
	
	
OutputRow
	s Data=$lb(IPOut,OutXStr,DiskUseSpeedStr,DiskSpeedMoveAveStr,DiskUseStr,OutDiskTotalSize,OutDiskUsedSize,OutDiskAvailableSize,OutDiskUse,Waring,OutOS,IsOnline,OutMemTotalSize,OutMemUsedSize,OutMemAvailableSize,MemUseStr)
 	Set ColFields = "IPOut,OutXStr,DiskUseSpeedStr,DiskSpeedMoveAveStr,DiskUseStr,OutDiskTotalSize,OutDiskUsedSize,OutDiskAvailableSize,OutDiskUse,Waring,OutOS,IsOnline,OutMemTotalSize,OutMemUsedSize,OutMemAvailableSize,MemUseStr"
 	Set ^CacheTemp(repid,ind)=Data
 	Set ind=ind+1
	quit
}

ClassMethod QrySystemMonitorClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = QrySystemMonitorExecute ]
{
	Set repid=$LIST(qHandle,2)
 	Kill ^CacheTemp(repid)
	Quit $$$OK
}

ClassMethod QrySystemMonitorFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = QrySystemMonitorExecute ]
{
 	Set AtEnd=$LIST(qHandle,1)
 	Set repid=$LIST(qHandle,2)
 	Set ind=$LIST(qHandle,3)
 	Set ind=$o(^CacheTemp(repid,ind))
 	If ind="" {				// if there are no more rows, finish fetching
 		Set AtEnd=1
 		Set Row=""
 	}
 	Else      {				// fetch row
 		Set Row=^CacheTemp(repid,ind)
 	}
 	// Save QHandle
 	s qHandle=$lb(AtEnd,repid,ind)
	Quit $$$OK
}

/// Creator：      zlz
/// CreatDate：    20160318
/// Description:： 新的处理小数点的方法
/// Table：        
/// Input：        
/// Output：       
/// Return：       
/// Others： 
/// d ##class(LIS.WS.DHCLISServiceBase).DealPointNew()      
ClassMethod DealPointNew(Number, Precision)
{
	s Number=$g(Number)
	s Precision=$g(Precision)
	i '$l(Precision) s Precision=2
	i $e(Number,1,1)="." d  s Number="0"_Number
	i ($l(Number)>3)&&($e(Number,1,2)="-.") s Number="-0."_$e(Number,3,$l(Number))
	i '$ISVALIDNUM(Number) q Number
	s Number=$fn(Number,"",Precision)
	q Number
}

/// w ##Class(LIS.WS.DHCLISServiceBase).TranslateErrDataMTHD("异常信息:1级异常 Exception has been thrown by the target of an invocation.2级异常 错误信息:Query not Prepared. SQL代码:-400 SQL语句:select top 30000 * from (select RowID,Code,CName,(select CName from dbo.BT_Hospital where ti.HospitalDR=dbo.BT_Hospital.RowID) as HospitalDR_BTHospital_CName,HospitalDR,LName,EName,Synonym,Units,ResultFormat,Precision,(select CName from dbo.BT_TestMethod where ti.TestMethodDR=dbo.BT_TestMethod.RowID) as TestMethodDR_BTTestMethod_CName,(select Code from dbo.BT_TestMethod where ti.TestMethodDR=dbo.BT_TestMethod.RowID) as TestMethodDR_BTTestMethod_Code,TestMethodDR,IsCalculate,LonicCode,SCode,SOPContent,SOPFile,HISCode,(select CName from dbo.BT_CostItem where ti.CostItemDR=dbo.BT_CostItem.RowID) as CostItemDR_BTCostItem_CName,CostItemDR,Price,ClinicalSignifyS,ClinicalSignifyL,(select CName from dbo.BT_TestSet where ti.TestSetDR=dbo.BT_TestSet.RowID) as TestSetDR_BTTestSet_CName,TestSetDR,PrintOrder,Sequence,Active,CalculateFormula,RefRanges,IsCheckText,RefField,IsAllowNegative,IsAllowNoNumeric,IsExcJudgeRule,(select CName from dbo.BT_ItemClass where ti.ItemClassDR=dbo.BT_ItemClass.RowID) as ItemClassDR_BTItemClass_CName,ItemClassDR,(select CName from dbo.BT_Department where ti.DepartmentDR=dbo.BT_Department.RowID) as DepartmentDR_BTDepartment_CName,DepartmentDR,IsRealCal,UnacceptLow,UnacceptHigh,ReEditFlag,NoCalFlag,(select CName from dbo.BT_TestCode where ti.QCTestCodeDR=dbo.BT_TestCode.RowID) as QCTestCodeDR_BTTestCode_CName,QCTestCodeDR,CheckEqual,IsNormalRange,ShareFlag,QCPatVisEval,AllowDelete,AllowSplit,AllowTrace,DefaultResult from dbo.BT_TestCode ti) as t where   Active =  ?  Order By Sequence asc")
ClassMethod TranslateErrDataMTHD(Data, P1, P2, P3, P4, P5, P6, P7, P8, P9, P10, P11, P12, P13, Sessions, Output RowCount As %String) As %String
{
	s Data=$g(Data)
	s RetData=""

	s DataI=##Class(LIS.Util.Common).IndexData(Data)
	s OperI=##Class(LIS.Util.Common).IndexData("1")
	s FDataI="" f  s FDataI=$o(^dbo.BTErrTranslateI("IndexData",OperI,FDataI)) q:FDataI=""  d
	.s TransDR="" f  s TransDR=$o(^dbo.BTErrTranslateI("IndexData",OperI,FDataI,TransDR)) q:TransDR=""  d
	..s OldData=$lg($g(^dbo.BTErrTranslateD(TransDR)),2)
	..i Data[OldData s RetData=$lg($g(^dbo.BTErrTranslateD(TransDR)),3)
	q RetData
}

/// 查询Web缓存版本号，浏览器按版本号决定是否清除缓存
/// w ##class(LIS.WS.DHCLISServiceBase).GetWebCacheVertionMTHD("1")
ClassMethod GetWebCacheVertionMTHD(IsUpdate, P1, P2, P3, P4, P5, P6, P7, P8, P9, P10, P11, P12, P13, Sessions, Output RowCount As %String) As %String
{
	s IsUpdate=$g(IsUpdate)
	//更新版本号
	i IsUpdate="1" d
	.s RowId=$o(^dbo.SYSParameterI("IndexCode"," WEBCACHEVERTION"," SYS"," DHCC",""))
	.i $l(RowId) d
	..s objPara=##class(dbo.SYSParameter).%OpenId(RowId)
	.e  d
	..s objPara=##class(dbo.SYSParameter).%New()
	..s objPara.Code="WebCacheVertion"
	..s objPara.Description="检验浏览器缓存版本"
	..s objPara.ParaType="SYS"
	..s objPara.ParaTypeCode="DHCC"
	..s objPara.ParaList="检验浏览器缓存版本"
	..s objPara.Sequence=1
	.s VertionStr=$zd($h,8)_$zt($p($h,",",2))
	.s VertionStr=$tr(VertionStr,"-")
	.s VertionStr=$tr(VertionStr,":")
	.s objPara.ParaValue=VertionStr
	.s ret=objPara.%Save()
	s Vertion=##class(OTH.SYSParameter).GetDataValue("WebCacheVertion","SYS","DHCC")
	i '$l(Vertion) s Vertion="1"
	q "imedicallis-v-"_Vertion
}

}
