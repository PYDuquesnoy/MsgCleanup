/// Scans all the Persitent Clases to detect possible problems with Message Purging
Class Alt.Msg.Scan Extends %RegisteredObject
{

/// List the Persistent Classes which have No Instances directly referenced by Ens.MessageHeader:
/// these are Classes that need to be Purged through a Trigger defined in the Referencing Message/Class
/// This will only work well in a Production Environment where some messages have been sent!
ClassMethod ListNotReferenced(pNS As %String = "") As %Status
{
	#DIM tSC as %Status=$$$OK
	#DIM errObj as %Exception.AbstractException
	set tCurNS=$Namespace
	if (pNS'="") {
		set $namespace=pNS
	} 
	try {
		#DIM tPersistentList
		#DIM tStmt as %SQL.Statement
		#DIM tRS as %SQL.StatementResult
		
		//---Get List of Persistent Classes, that are not System or related (Ens,EnsLib,HS,...)
		$$$THROWONERROR(tSC,..ListPersistent(.tPersistentList))
		
		//---Find a List of MessageBodyClassNames as Referenced in Ens.MessageHeader
		set tSql="Select distinct BY (%EXACT(MessageBodyClassname)) MessageBodyClassName from Ens.MessageHeader"
		set tStmt=##class(%SQL.Statement).%New()
		$$$THROWONERROR(tSC,tStmt.%Prepare(tSql))
		set tRS=tStmt.%Execute()
		if (tRS.%SQLCODE'=0) { 
			$$$ThrowStatus($$$ERROR($$$GeneralError,"Execute Failed: "_$system.SQL.SQLCODE(tRS.%SQLCODE)_" ("_tRS.%SQLCODE_")"))
		}
		kill tMsgList
		while (tRS.%Next()) {
			if (tRS.%GetData(1)'="") { 
				set tMsgList(tRS.%GetData(1))=""
			}
		}
		//Write "MessageBody:",!
		//zw tMsgList
		Write !
		//---Compare the Two Lists
		Write "List of Persistent Classes in this Namespace not directly Referenced by Ens.MessageHeader:",!
		set tP=$Order(tPersistentList(""))
		while (tP'="") {
			if ('$Data(tMsgList(tP))) {
				Write tP,!
			}
			//---Next
			set tP=$Order(tPersistentList(tP))
		}
		
	}catch (errObj) {
		
		
		Write "CATCH:",errObj.DisplayString(),!
		set tSC=errObj.AsStatus()
	}
	set $Namespace=tCurNS
	quit tSC
}

/// Scans all the Properties in Persistent Classes that Also Reference a Persistent Class and List them
ClassMethod ListPersistentProperties(pNS As %String = "") As %Status
{
	#DIM tSC as %Status=$$$OK
	#DIM errObj as %Exception.AbstractException
	set tCurNS=$Namespace
	if (pNS'="") {
		set $namespace=pNS
	} 
	try {
		///----First Get list of persistent Classes
		$$$THROWONERROR(tSC,..ListPersistent(.tPersistentList))
		
		///---Open the Definition of Each, and Loop Over their Properties
		set tCName=$order(tPersistentList(""))
		
		Write "List of Persistent Properties In Classes",!
		while (tCName'="") {
			if ($piece(tCName,".",$length(tCName,"."))="Context") {
				//Skip Business Process Context
			}else {
				set tC=##class(%Dictionary.CompiledClass).%OpenId(tCName)
				quit:('$isObject(tC))
				for tIx=1:1:tC.Properties.Count() {
					set tProp=tC.Properties.GetAt(tIx)
					if ($Data(tPersistentList(tProp.Type))) {
						//---The property is referencing a Persistent Class
						Write tCName_" -> "_tProp.Name_": ",tProp.Type,!
					}
				}
			}
			//---Next
			set tCName=$Order(tPersistentList(tCName))
		}
		
	}catch (errObj) {
		
		
		Write "CATCH:",errObj.DisplayString(),!
		set tSC=errObj.AsStatus()
	}
	set $Namespace=tCurNS
	quit tSC
}

/// For Each Class that is Referenced by Ens.MessageHeader
///   - Find lowest Ens.MessageHeader MessageBodyId LL
///   - Count #of instances with ID < LL
///       **these Instances could be deleted...
ClassMethod ListNotRef(pNS As %String = "") As %Status
{
	
	#DIM tSC as %Status=$$$OK
	#DIM errObj as %Exception.AbstractException
	set tCurNS=$Namespace
	if (pNS'="") {
		set $namespace=pNS
	} 
	try {
		#DIM tStmt as %SQL.Statement
		#DIM tRS as %SQL.StatementResult
		//---Find a List of MessageBodyClassNames as Referenced in Ens.MessageHeader
		set tSql="Select %EXACT(MessageBodyClassName), Min (MessageBodyId) as MinReferencedId from Ens.MessageHeader Group By MessageBodyClassName"
		set tStmt=##class(%SQL.Statement).%New()
		$$$THROWONERROR(tSC,tStmt.%Prepare(tSql))
		set tRS=tStmt.%Execute()
		if (tRS.%SQLCODE'=0) { 
			$$$ThrowStatus($$$ERROR($$$GeneralError,"Execute Failed: "_$system.SQL.SQLCODE(tRS.%SQLCODE)_" ("_tRS.%SQLCODE_")"))
		}
		kill tMsgList
		while (tRS.%Next()) {
			if (tRS.%GetData(1)'="") { 
				set tMsgList(tRS.%GetData(1))=tRS.%GetData(2)
			}
		}
		//---For each item in tMsgList, Count how many Instances exist below the MinReferencedId
		set tI=$Order(tMsgList(""))
		Write "List of Tables with InstanceIds < MessageHeader.MessageBodyid low Boundary for table",! 
		while (tI'="") {
			set tC=##class(%Dictionary.CompiledClass).%OpenId(tI)
			//break
			if ($isObject(tC)) {
				set tTbName=tC.SqlQualifiedNameQ
				set tSql="select count(*) from """_tC.SqlSchemaName_"""."""_tC.SqlTableName_""" where ID <"_tMsgList(tI)
				set tStmt=##class(%SQL.Statement).%New()
				$$$THROWONERROR(tSC,tStmt.%Prepare(tSql))
				set tRS=tStmt.%Execute()
				if (tRS.%SQLCODE'=0) { 
					$$$ThrowStatus($$$ERROR($$$GeneralError,"Execute Failed: "_$system.SQL.SQLCODE(tRS.%SQLCODE)_" ("_tRS.%SQLCODE_")"))
				}
			
				if (tRS.%Next()) {	
					set tCount=tRS.%GetData(1)
					if (tCount>0) {
						Write tI," : ",tRS.%GetData(1),!
					}
				}	
			}			
			//---
			Set tI=$order(tMsgList(tI))
		}
	}catch (errObj) {
			
		Write "CATCH:",errObj.DisplayString(),!
		set tSC=errObj.AsStatus()
	}
	set $Namespace=tCurNS
	quit tSC
}

/// Return List of Persistent Classes as MultiDimentional array
/// Method used internally
ClassMethod ListPersistent(ByRef pList As %String) As %Status
{
	#DIM tSC as %Status=$$$OK
	#DIM errObj as %Exception.AbstractException
	try {
		#DIM tStmt as %SQL.Statement
		#DIM tRS as %SQL.StatementResult
		kill pList
		set tStmt=##class(%SQL.Statement).%New()
		$$$THROWONERROR(tSC,tStmt.%PrepareClassQuery("%Dictionary.CompiledClassQuery","Summary"))
		set tRS=tStmt.%Execute()
		if (tRS.%SQLCODE'=0) { 
			$$$ThrowStatus($$$ERROR($$$GeneralError,"Execute Failed: "_$system.SQL.SQLCODE(tRS.%SQLCODE)_" ("_tRS.%SQLCODE_")"))
		}
		while (tRS.%Next()) {
			if ((tRS.%Get("Persistent")=1)&&(tRS.%Get("System")=0)) {
				set tName=tRS.%Get("Name")
				if ($extract(tName,1)'="%") {
					if (",INFORMATION,HS,Ens,EnsLib,"'[(","_$piece(tName,".",1)_",")) {			 	
						set pList(tName)=""
					}
				}
			}
		}
		
	}catch (errObj) {
		Write "CATCH:",errObj.DisplayString(),!
		set tSC=errObj.AsStatus()
	}
	quit tSC
}

}
