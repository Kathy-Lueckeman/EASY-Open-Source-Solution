/*******************************************************************************
@description This clas houses the logic to render a Requirement Item
@author Huron Consulting Group

Revision (s): 
*******************************************************************************/
public class ApplicationQuestionGroup {
	
    public Contact con {get;private set;}
    public Application__c app {get;private set;}
    public List<ApplicationQuestion> questions {get;private set;}
    public List<ApplicationQuestion> relatedReferenceQuestions {get;private set;}
    public String newReferenceObjectType {get;private set;}
    public SObject newReferenceObject {get;set;}
    public String newReferenceObjectSelectedWrapper {get;set;}
    public String newReferenceObjectSelectedWrapperName {get;set;}
    public Requirement_Item__c item {get;set;}
    public Boolean isInternal { get { return item != null && (item.Internal_Only__c || item.Requirement__r.Internal_Only__c) && !UserInfo.getUserType().equals('Standard'); } }
    public ContentVersion att {get;set;}
    private Id oldAttId;
    public ContentDocumentLink oldAttLink{get;set;}
    public ContentVersion oldAttVersion{get;set;}
    public Boolean questionGroup {get;set;}
    public Boolean documentUpload {get;set;}
    public Boolean relatedObject {get;set;}
    public Decimal progress {get;set;}
    public Boolean externalResponse {get;set;}
    private Integer newIndex;
    public Requirement_Response__c response{get;set;}
    
    public String instructions {
        get {
            if (item == null) return null;
            return isInternal ? item.Internal_Only_Applicant_Instructions__c : item.Instructions__c;
        }
    }
    
    public List<SObjectWrapper> relatedObjects{
        get{
            if(relatedObjectsMap!=null){
                return relatedObjectsMap.values();
            }else{
                return null;
            }
        }
        set;
    }
    /*******************************************************************************
    * @description Can the user edit this requirement item based on the application status
    ********************************************************************************/
    public Boolean isEditable{
        get{
            if(UserInfo.getUserType() != 'Standard' || Test.isRunningTest()){
                if(app != null && String.isNotBlank(app.Application_Status__c)){
                    if(item != null && (String.isBlank(item.Editable_Application_Status__c) || (String.isNotBlank(item.Editable_Application_Status__c) && new Set<String>(item.Editable_Application_Status__c.split(';')).contains(app.Application_Status__c)))){
                        return true;
                    }
                    return false;
                }
            }
            return true;
        }
    }

    public Boolean creatingNewRelatedRecord{get;set;}

    public Map<String,SObjectWrapper> relatedObjectsMap{get;set;}
    public Map<Id,SObjectWrapper> relatedObjectsMapDelete{get;set;}
    public Map<String,Map<String,Object>> fieldResultMap{get;set;}

    public String selectedRelatedId{get;set;}
	
    public class MultiPicklistWrapper {
        
        public SObject obj {get;set;}
        public String fieldName {get;set;}
        public List<String> multiPicklistValues;
        
        public List<String> getMultiPicklistValues() {
        	return String.isNotBlank((String)(obj.get(fieldName))) ? ((String)(obj.get(fieldName))).split(';') : new List<String>();
    	}

    	public void setMultiPicklistValues(List<String> v) {
        	obj.put(fieldName, String.join(v, ';'));
    	}
        
        public MultiPicklistWrapper(SObject obj, String fieldName) {
            this.obj = obj;
            this.fieldName = fieldName;
        }
    }
    
    public class SObjectWrapper{
        private ApplicationQuestionGroup aqg;
        public SObject obj{get;set;}
        private SObject sobjClone{get;set;}
        public Boolean isEditMode{get;set;}
        public Boolean isDeleted{get;set;}
        public String idx{get;set;}
        public ContentDocumentLink att{get;set;}
        public Boolean isValid;
        
        public Map<ApplicationQuestion, Boolean> showQuestions {
            get {
                SObject objCopy = obj.clone(true, true, true, true);
                showQuestions = new Map<ApplicationQuestion, Boolean>();
                for (ApplicationQuestion aq:aqg.questions)
                    showQuestions.put(aq, aq.getShowQuestion(obj));
                
                for (ApplicationQuestion aq:showQuestions.keySet()) {
                    aq.dependencyCalculated = false;
                    if (showQuestions.get(aq) && String.isNotBlank(aq.question.Related_Object_Field__c))
                        obj.put(aq.question.Related_Object_Field__c, objCopy.get(aq.question.Related_Object_Field__c));
                }
                
                return showQuestions;
            } set;
        }
        
        public Map<String, MultiPicklistWrapper> multiPicklistValues {
            get {
                if (multiPicklistValues == null) {
                    multiPicklistValues = new Map<String, MultiPicklistWrapper>();
                    for (ApplicationQuestion question:aqg.questions)
                        if (question.question.RecordType.DeveloperName.equals('MultiPicklist'))
                            multiPicklistValues.put(question.question.Related_Object_Field__c, new MultiPicklistWrapper(obj, question.question.Related_Object_Field__c));
                }
                
                return multiPicklistValues;
            } set;
        }
        
        public SObjectWrapper(ApplicationQuestionGroup aqg, String idx,SObject obj){
            this.aqg = aqg;
            this.idx = idx;
            this.obj = obj;
            sobjClone = obj.clone(true,true,true,true);
            isEditMode = false;
            isDeleted = false;
            isValid = true;
			
            if(((List<ContentDocumentLink>)obj.getSObjects('ContentDocumentLinks')) != null && ((List<ContentDocumentLink>)obj.getSObjects('ContentDocumentLinks')).size()>0){
                att = ((List<ContentDocumentLink>)obj.getSObjects('ContentDocumentLinks'))[0];
            }
        }
        public SObjectWrapper(ApplicationQuestionGroup aqg, String idx,SObject obj, Boolean startEdit){
            this(aqg, idx,obj);
            this.isEditMode = startEdit;
        }
        public void enableEditMode(){
            isEditMode = true;
        }
        public void enableViewMode(){
            if(!checkValid() && obj.Id == null){
                aqg.selectedRelatedId = idx;
                aqg.enableDeleteMode();
            }else{
                isEditMode = false;
                obj = sobjClone;
                sobjClone = obj.clone(true,true,true,true);
            }
        }
        public void enableConfirmMode(){
            
            if(checkValid()){
                isEditMode = false;
                sobjClone = obj.clone(true,true,true,true);
            }else{
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Error,'Required Fields Missing'));
            }
        }
        public Boolean checkValid(){
            
            Boolean valid = true;
            for (ApplicationQuestion question:aqg.questions) {
                
                if (!question.getShowQuestion(obj))
                    continue;
                
                try {
                    if (String.isNotBlank(question.question.Related_Object_Field__c) && (question.application != null && String.isNotBlank(question.question.Required__c) && new Set<String>(question.question.Required__c.split(';')).contains(question.application.Application_Status__c)) && obj.get(question.question.Related_Object_Field__c) == '')
                        valid = false;
                    
                } catch (Exception e) {}
                
                if (String.isNotBlank(question.question.Related_Object_Field__c) && (question.application != null && String.isNotBlank(question.question.Required__c) && new Set<String>(question.question.Required__c.split(';')).contains(question.application.Application_Status__c)) && obj.get(question.question.Related_Object_Field__c) == null)
                    valid = false;
            }
            
            isValid = valid;
            return valid;
        }
    }

    /*******************************************************************************
    * @description Denotes that we are creating a new related record
    ********************************************************************************/
    public void setCreatingNewRelatedRecord(){
        creatingNewRelatedRecord = true;
    }

    /*******************************************************************************
    * @description Enables edit mode for a row in the related object list
    ********************************************************************************/
    public void enableEditMode(){
        if(String.isNotBlank(selectedRelatedId) && relatedObjectsMap.containsKey(selectedRelatedId)){
            relatedObjectsMap.get(selectedRelatedId).enableEditMode();
            selectedRelatedId = null;
        }
    }
    /*******************************************************************************
    * @description Places the related object list item back into read only mode
    ********************************************************************************/
    public void enableViewMode(){
        if(String.isNotBlank(selectedRelatedId) && relatedObjectsMap.containsKey(selectedRelatedId)){
            relatedObjectsMap.get(selectedRelatedId).enableViewMode();
            selectedRelatedId = null;
        }
    }
    /*******************************************************************************
    * @description Saves the changes on a related object list item and  places it back into read only mode
    ********************************************************************************/
    public void enableConfirmMode(){
        if(String.isNotBlank(selectedRelatedId) && relatedObjectsMap.containsKey(selectedRelatedId)){
            relatedObjectsMap.get(selectedRelatedId).enableConfirmMode();
            selectedRelatedId = null;
        }
    }
    /*******************************************************************************
    * @description Deletes the row for a related object list item
    ********************************************************************************/
    public void enableDeleteMode(){
        if(String.isNotBlank(selectedRelatedId) && relatedObjectsMap.containsKey(selectedRelatedId)){
            if(relatedObjectsmap.get(selectedRelatedId).obj.Id != null){
                relatedObjectsMapDelete.put(selectedRelatedId,relatedObjectsMap.get(selectedRelatedId));
            }
            relatedObjectsMap.remove(selectedRelatedId);
            selectedRelatedId = null;
        }
    }
 
    /*******************************************************************************
    * @description Saves the related object row to allow a supporting document to be uploaded
    ********************************************************************************/
    public void relatedUpload(){
        SYSTEM.DEBUG('RELATED');
        if(String.isNotBlank(selectedRelatedId) && relatedObjectsMap.containsKey(selectedRelatedId) && relatedObjectsMap.get(selectedRelatedId).isEditMode == false){
            if(relatedObjectsMap.get(selectedRelatedId).obj.Id != null){
            }else if(relatedObjectsMap.get(selectedRelatedId).obj.Id == null){
                try{
                    SObjectWrapper objW = relatedObjectsMap.get(selectedRelatedId);
                    insert objW.obj;
                    relatedObjectsMap.remove(selectedRelatedId);
                    relatedObjectsMap.put(objW.obj.Id,objW);
                    selectedRelatedId = objW.obj.Id;
                }catch(DmlException e){
                    ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Error,e.getDMLMessage(0)));
                    selectedRelatedId = null;
                }catch(Exception e){
                    ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Error,e.getMessage()));
                    selectedRelatedId = null;
                }
            }
        }else{
            selectedRelatedId = null;
        }
    }
    /*******************************************************************************
    * @description Creates a new related object row and populates any hardcoded values
    ********************************************************************************/
    public void newRow(){
        if(String.isNotBlank(item.Related_List_Object_Master__c) && String.isNotBlank(item.Related_List_Object_Master_Field__c)){
            sObject sObj = Schema.getGlobalDescribe().get(item.Related_List_Object__c).newSObject();
            sObj.put('User_Created__c',true);
            if(response != null){
                if(item.Related_List_Object_Master__c == 'Contact'){
                    sObj.put(item.Related_List_Object_Master_Field__c,response.Application__r.Contact__c);
                }else if(item.Related_List_Object_Master__c == 'Application'){
                    sObj.put(item.Related_List_Object_Master_Field__c,response.Application__c);
                }
            }
            for(ApplicationQuestion question : questions){
                if(String.isNotBlank(question.question.Hardcoded_Value__c) && String.isNotBlank(question.question.Related_Object_Field__c)){
                    Object questionValue = question.question.Hardcoded_Value__c;
                    if(question.question.RecordType.DeveloperName == 'Checkbox'){
                       questionValue = Boolean.valueOf(question.question.Hardcoded_Value__c);
                    }else if(question.question.RecordType.DeveloperName == 'Currency' || question.question.RecordType.DeveloperName == 'Number' || question.question.RecordType.DeveloperName == 'Percent'){
                       questionValue = Decimal.valueOf(question.question.Hardcoded_Value__c);
                    }else if(question.question.RecordType.DeveloperName == 'Date'){
                       questionValue = Date.valueOf(question.question.Hardcoded_Value__c);
                    }else if(question.question.RecordType.DeveloperName == 'Datetime'){
                       questionValue = DateTime.valueOf(question.question.Hardcoded_Value__c);
                    }
                    sObj.put(question.question.Related_Object_Field__c,questionValue);
                }
            }
            relatedObjectsMap.put('new'+newIndex,new SObjectWrapper(this,'new'+newIndex,sObj,true));
            newIndex++;
        }
    }

    public ApplicationQuestionGroup(SObject obj){
        creatingNewRelatedRecord = false;
        if(((List<ContentDocumentLink>)obj.getSObjects('ContentDocumentLinks')) != null && ((List<ContentDocumentLink>)obj.getSObjects('ContentDocumentLinks')).size()>0){
            String title = ((List<ContentDocumentLink>)obj.getSObjects('ContentDocumentLinks'))[0].ContentDocument.Title;
            att = new ContentVersion();
                att.Title = title;
            oldAttId = ((List<ContentDocumentLink>)obj.getSObjects('ContentDocumentLinks'))[0].Id;
            oldAttLink = ((List<ContentDocumentLink>)obj.getSObjects('ContentDocumentLinks'))[0];
            List<ContentVersion> conV = [Select Id from ContentVersion where ContentDocumentId = :oldAttLink.ContentDocumentId order by createddate desc limit 1];
            if(conV.size()>0){
                oldAttVersion = conV[0];
            }
        }else{
            att = new ContentVersion();
        }
    }

    public ApplicationQuestionGroup(List<ApplicationQuestion> questions) {
        creatingNewRelatedRecord = false;
        this.questions = questions;
        questionGroup = true;
    }
    
    public ApplicationQuestionGroup(Contact con, Application__c app, Requirement_Item__c item, Map<Id, List<Question_Dependency__c>> dQuestions, Requirement_Response__c response, List<Question_Response__c> dResponses, Map<String,Schema.SObjectField> sObjectFields) {
        init(con, app, item, dQuestions, response, dResponses, sObjectFields, false);
    }
    
    public ApplicationQuestionGroup(Contact con, Application__c app, Requirement_Item__c item, Map<Id, List<Question_Dependency__c>> dQuestions, Requirement_Response__c response, List<Question_Response__c> dResponses, Map<String,Schema.SObjectField> sObjectFields, Boolean isAppCreate) {
        init(con, app, item, dQuestions, response, dResponses, sObjectFields, isAppCreate);
    }

    private void init(Contact con, Application__c app, Requirement_Item__c item, Map<Id, List<Question_Dependency__c>> dQuestions, Requirement_Response__c response, List<Question_Response__c> dResponses, Map<String,Schema.SObjectField> sObjectFields, Boolean isAppCreate) {
        creatingNewRelatedRecord = false;
        this.item = item;
        this.response = response;
        this.con = con;
        this.app = app;
        Map<Id, Question_Response__c> qResponses = new Map<Id, Question_Response__c>();
        if(response != null){
            for (Question_Response__c qr:response.Question_Responses__r){
                qResponses.put(qr.Question__c, qr);
            }
        }
        if (item.RecordType.DeveloperName.equals('Question_Group')) {
            questionGroup = true;
            documentUpload = false;
            relatedObject = false;
            externalResponse = false;

            questions = new List<ApplicationQuestion>();
            for (Question__c q:item.Questions__r) {
                if (isAppCreate && String.isNotBlank(q.Contact_Field__c)) {
                    ApplicationQuestion aq = new ApplicationQuestion(con, app, q.Label__c, con, q.Contact_Field__c);
                    aq.addQuestionObject(q);
                    aq.populateContactFieldOnResponse();
                    questions.add(aq);
                } else if (isAppCreate && String.isNotBlank(q.Application_Field__c)) {
                    ApplicationQuestion aq = new ApplicationQuestion(con, app, q.Label__c, app, q.Application_Field__c);
                    aq.addQuestionObject(q);
                    questions.add(aq);
                } else {
                    if (!qResponses.containsKey(q.Id) && response!= null && q.RecordType.DeveloperName != 'Static') {
                        qResponses.put(q.Id, new Question_Response__c(Requirement_Response__c = response.Id, Question__c = q.Id));
                    } else if(response == null && q.RecordType.DeveloperName != 'Static') {
                        qResponses.put(q.Id, new Question_Response__c(Question__c = q.Id));
                    }
                    
                    ApplicationQuestion aq = new ApplicationQuestion(String.isNotBlank(q.Contact_Field__c) ? (SObject)con : (SObject)app, q, qResponses.get(q.Id));
                    if (aq.application == null)
                        aq.application = app;
                    aq.setRequirementResponse(response);
                    questions.add(aq);
                }
            }
            
        } else if (item.RecordType.DeveloperName.equals('Document_Upload')) {
            documentUpload = true;
            questionGroup = false;
            relatedObject = false;
            externalResponse = false;
            if(response != null && response.ContentDocumentLinks != null && response.ContentDocumentLinks.size()>0){
                String title = response.ContentDocumentLinks[0].ContentDocument.Title;
                att = new ContentVersion();
                    att.Title = title;
                oldAttId = response.ContentDocumentLinks[0].Id;
                oldAttLink = response.ContentDocumentLinks[0];
                List<ContentVersion> conV = [Select Id from ContentVersion where ContentDocumentId = :oldAttLink.ContentDocumentId order by createddate desc limit 1];
                if(conV.size()>0){
                    oldAttVersion = conV[0];
                }
            }else{
                att = new ContentVersion();
            }
        } else if (item.RecordType.DeveloperName.equals('Related_Object')) {
            
            newIndex = 0;
            relatedObject = true;
            questionGroup = false;
            documentUpload = false;
            externalResponse = false;
            
            questions = new List<ApplicationQuestion>();
            relatedReferenceQuestions = new List<ApplicationQuestion>();
            Map<Id, ApplicationQuestion> qMap = new Map<Id, ApplicationQuestion>();
            for (Question__c q:item.Questions__r) {
                if (!q.New_Reference_Field__c) {
                    questions.add(new ApplicationQuestion(app, q, null));
                } else {
                    relatedReferenceQuestions.add(new ApplicationQuestion(app,q,null));
                    relatedReferenceQuestions.get(relatedReferenceQuestions.size()-1).showRelatedLabel(true);
                }
            }
            if (item.Questions__r != null && !item.Questions__r.isEmpty()) {
                fieldResultMap = new Map<String,Map<String,Object>>();
                if (sObjectFields != null) {
                    for (String s : sObjectFields.keySet()) {
                        Map<String, Object> fieldResults = new Map<String, Object>();
                        Schema.DescribeFieldResult fResult = SObjectFields.get(s).getDescribe();
                        fieldResults.put('isReference', fResult.getType() == Schema.DisplayType.Reference);
                        fieldResultMap.put(s,fieldResults);
                    }
                }
                Set<String> fieldsSet = new Set<String>{'id','user_created__c','holding_name__c'};
                    for (Question__c q:item.Questions__r) {
                        if (q != null && String.isNotBlank(q.Related_Object_Field__c) && !q.New_Reference_Field__c) {
                            fieldsSet.add(q.Related_Object_Field__c.toLowerCase());
                            if (String.isNotBlank(q.Lookup_Object__c))
                                newReferenceObjectType = q.Lookup_Object__c;
                            if (fieldResultMap.containsKey(q.Related_Object_Field__c.toLowerCase()) && (Boolean)fieldResultMap.get(q.Related_Object_Field__c.toLowerCase()).get('isReference') && q.Related_Object_Field__c.endsWith('__c'))
                                fieldsSet.add(q.Related_Object_Field__c.substring(0,q.Related_Object_Field__c.length()-1)+'r.Name');
                        }
                    }
                relatedObjectsMap = new Map<String,SObjectWrapper>();
                relatedObjectsMapDelete = new Map<Id,SObjectWrapper>();
                if (app.Id != null && app.Contact__c != null) {
                    String connectingId = item.Related_List_Object_Master__c == 'Contact' ? app.Contact__c : app.Id;
                        String query = 'Select (SELECT Id, LinkedEntityId, ContentDocumentId, ContentDocument.Title FROM ContentDocumentLinks Where ContentDocument.Description = \'Supporting Document\'), ' + String.join(new List<String>(fieldsSet),', ') + ' FROM ' + item.Related_List_Object__c + ' WHERE '+item.Related_List_Object_Master_Field__c+' =\''+connectingId+'\'';
                    if (String.isNotBlank(item.Related_List_Where_Clause__c))
                        query += ' AND ' + item.Related_List_Where_Clause__c;
                    for (SObject obj:database.query(query))
                        relatedObjectsMap.put(obj.Id,new SObjectWrapper(this,obj.Id,obj));
                }
            }
        }
    }
    
    // Add question dependencies for group
    public void addQuestionDependencies(Map<Id, ApplicationQuestion> qMap, Map<Id, List<Question_Dependency__c>> dQuestions, List<Question_Response__c> dResponses) {
        
        if (questionGroup || relatedObject) {
            
            if (dResponses != null)
                for (Question_Response__c qr:dResponses)
                    qMap.put(qr.Question__c, new ApplicationQuestion(app, new Question__c(Active__c = true, Id = qr.Question__c), qr));
            else if (relatedObject)
                for (ApplicationQuestion aq:questions)
                	qMap.put(aq.question.Id, aq);
            
            for (ApplicationQuestion aq:questions)
                if (aq.question != null && dQuestions.containsKey(aq.question.Id))
                    aq.addQuestionDependencies(dQuestions.get(aq.question.Id), qMap);
        }
    }
    
    /*******************************************************************************
    * @description Indicates that the user would like to create a new related object reference that doesn't exist such as a new Employer or School
    ********************************************************************************/
    public void createNewReferenceObject(){
        creatingNewRelatedRecord = true;
        if (newReferenceObjectType.toLowerCase().equals('account') && !UserInfo.getUserType().equals('Guest')) {
            newReferenceObject = [SELECT Id, Name FROM Account LIMIT 1];
        } else {
        	newReferenceObject = Schema.getGlobalDescribe().get(newReferenceObjectType).newSObject();
        }
        if(String.isNotBlank(newReferenceObjectSelectedWrapperName)){
            newReferenceObject.put('Name',newReferenceObjectSelectedWrapperName);
        }
    }
    
    /*******************************************************************************
    * @description Saves the JSON data corresponding to a new related object reference that doesn't exist such as a new Employer or School
    ********************************************************************************/
    public void addNewReferenceObject() {
        
        if (String.isNotBlank(newReferenceObjectSelectedWrapper) && relatedObjectsMap.containsKey(newReferenceObjectSelectedWrapper)){
            
            for (ApplicationQuestion aq:relatedReferenceQuestions) {
                if (String.isNotBlank(aq.question.Related_Object_Field__c)) {
                    
                    if (String.isBlank(aq.question.Hardcoded_Value__c) && String.isNotBlank(aq.question.Related_Object_Field__c) && ApplicationUtilities.containsValue(aq.question.Required__c, app.Application_Status__c) && String.isBlank(String.valueOf(newReferenceObject.get(aq.question.Related_Object_Field__c)))) {
                        
                        ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 'Required Fields Missing'));
                        return;
                        
                    } else if (String.isNotBlank(aq.question.Hardcoded_Value__c)) {
                        
                        Object questionValue = aq.question.Hardcoded_Value__c;
                        
                        if (aq.question.RecordType.DeveloperName == 'Checkbox')
                        	questionValue = Boolean.valueOf(aq.question.Hardcoded_Value__c);
                        else if (aq.question.RecordType.DeveloperName == 'Currency' || aq.question.RecordType.DeveloperName == 'Number' || aq.question.RecordType.DeveloperName == 'Percent')
                        	questionValue = Decimal.valueOf(aq.question.Hardcoded_Value__c);
                        else if (aq.question.RecordType.DeveloperName == 'Date')
                        	questionValue = Date.valueOf(aq.question.Hardcoded_Value__c);
                        else if (aq.question.RecordType.DeveloperName == 'Datetime')
                        	questionValue = DateTime.valueOf(aq.question.Hardcoded_Value__c);
                        
                        newReferenceObject.put(aq.question.Related_Object_Field__c, questionValue);
                    }
                }
            }
            
            SObjectWrapper objW = relatedObjectsMap.get(newReferenceObjectSelectedWrapper);
            if (String.isNotBlank((String)newReferenceObject.get('Name'))) {
                objW.obj.put('Holding_Name__c',(String)newReferenceObject.get('Name'));
                for (ApplicationQuestion aq:questions) {
                    if (aq.fieldType == 'Reference') {
                        objW.obj.put(aq.question.Related_Object_Field__c,item.Holding_Record_Id__c);
                        break;
                    }
                }
            }
            
            newReferenceObject.Id = null;
            objW.obj.put('Related_Object_JSON__c', JSON.serialize(newReferenceObject));
            newReferenceObject = null;
            newReferenceObjectSelectedWrapper = null;
        }
        
        creatingNewRelatedRecord = false;
    }
    /*******************************************************************************
    * @description Tells the ApplicationQuestion to prepare to save, Saves updated Salesforce File data, save related object data
    ********************************************************************************/
    public void processValues() {
        processValues(null);
    }
    public void processValues(Map<String,Object> additionalData) {
        Savepoint sp = Database.setSavepoint();
        try{
            if(isEditable){
                if(relatedObject == true){

                    List<SObject> lstInsert = new List<SObject>();
                    List<SObject> lstUpdate = new List<SObject>();
                    List<SObject> lstDelete = new List<SObject>();
                    Integer childCount = 0;
                    if(relatedObjects != null){
                        for(SObjectWrapper objW : relatedObjects){
                            if(objW.isDeleted == false && ((Boolean)objW.obj.get('User_Created__c')) == true && objW.isValid == true){
                                if(objW.obj.Id != null){
                                    lstUpdate.add(objW.obj);
                                }else{
                                    objW.obj.put(item.Related_List_Object_Master_Field__c, item.Related_List_Object_Master__c == 'Contact' ? app.Contact__c : app.Id);
                                    lstInsert.add(objW.obj);
                                }
                            }
                            if(objW.isDeleted == false && objW.isValid == true){
                                childCount++;
                            }
                        }
                    }
                    
                    if (item.Required_Number_of_Children__c != null && item.Required_Number_of_Children__c > childCount) {
                        response.Has_Child_Requirement__c = false;
                        response.Child_Requirement_Fulfilled_On__c = null;
                    } else if (item.Required_Number_of_Children__c == null || item.Required_Number_of_Children__c <= childCount) {
                        if (!response.Has_Child_Requirement__c || response.Child_Requirement_Fulfilled_On__c == null)
                        	response.Child_Requirement_Fulfilled_On__c = System.NOW();
                        response.Has_Child_Requirement__c = true;
                    }
                    
                    if(relatedObjectsMapDelete != null){
                        for(SObjectWrapper objW : relatedObjectsMapDelete.values()){
                            if(((Boolean)objW.obj.get('User_Created__c')) == true && objW.obj.Id != null){
                                lstDelete.add(objW.obj);
                            }
                        }
                    }
                    if(lstInsert.size()>0){
                        insert lstInsert;
                    }
                    if(lstUpdate.size()>0){
                        update lstUpdate;
                    }
                    if(lstDelete.size()>0){
                        delete lstDelete;
                    }
                }
                if (questionGroup){
                    for (ApplicationQuestion q:questions){
                        if(q.isEditable == true || UserInfo.getUserType() == 'Standard'){
                            q.processValue();
                            if(q.question.External_Email_Field__c){
                                response.External_Email__c = q.response.ValueEmail__c;
                            }
                            
                            if (con != null && String.isNotBlank(q.question.Contact_Field__c)) {
                                try {
                                    
                                    if (q.fieldType.equals('Address') && (q.question.Contact_Field__c == 'MailingAddress' || q.question.Contact_Field__c == 'OtherAddress')) {
                						
                                        String prefix = q.question.Contact_Field__c.equals('MailingAddress') ? 'Mailing' : 'Other';
                                        con.put(prefix + 'Street', q.response.Street__c);
                                        con.put(prefix + 'City', q.response.City__c);
                                        con.put(prefix + 'PostalCode', q.response.PostalCode__c);
                                        con.put(prefix + (ApplicationQuestion.stateAndCountryPicklistEnabled ? 'StateCode' : 'State'), q.response.State__c);
                                        con.put(prefix + (ApplicationQuestion.stateAndCountryPicklistEnabled ? 'CountryCode' : 'Country'), q.response.Country__c);
                                    } else {
                                        con.put(q.question.Contact_Field__c, q.resp);
                                    }
                                } catch(Exception e) {
                                    system.debug(e.getMessage());
                                }
                            }
                            
                            if (app != null && String.isNotBlank(q.question.Application_Field__c)) {
                                try {
                                    app.put(q.question.Application_Field__c, q.resp);
                                } catch(Exception e) {
                                    system.debug(e.getMessage());
                                }
                            }
                        }
                    }
                }
                if(documentUpload == true && additionalData!= null && additionalData.containsKey('attData')){
                    Map<String,Object> attData = (Map<String,Object>)additionalData.get('attData');
                    if(attData.containsKey('fileName')){
                        att.Title = (String)attData.get('fileName');
                    }
                    System.debug('attData: ' + String.valueOf(attData));
                    if(attData.containsKey('data')){
                        att.VersionData = EncodingUtil.base64Decode(((String)attData.get('data')).substringAfter(','));
                    }
                }
                if (documentUpload == true && att != null && att.Title != null && att.VersionData != null && response != null) {
                    
                    att.PathOnClient = att.Title;
                    att.firstPublishLocationId = response.Id;
                    if(!Test.isRunningTest()){
                        att.put('NetworkId',Network.getNetworkId());
                    }
                    insert att;
                    att.VersionData = null;
                    if(oldAttLink != null && oldAttLink.ContentDocumentId != null){
                        delete new ContentDocument(Id=oldAttLink.ContentDocumentId);
                    }
                    response.HasDocument__c = true;
                    if (response.Document_Requirement_Fulfilled_On__c == null)
                        response.Document_Requirement_Fulfilled_On__c = System.NOW();
                }
                if (documentUpload == true && response != null && String.isNotBlank(response.ValueTextEntry__c)) {
                    response.HasDocument__c = true;
                    if (response.Document_Requirement_Fulfilled_On__c == null)
                        response.Document_Requirement_Fulfilled_On__c = System.NOW();
                }
                if (documentUpload == true && response != null && response.HasDocument__c == true && att.Title == null && String.isBlank(response.ValueTextEntry__c)){
                    response.HasDocument__c = false;
                    response.ValueTextEntry__c = null;
                    response.Document_Requirement_Fulfilled_On__c = null;
                }
            }
        }catch(DmlException e){
            if (att != null) {
            	att.VersionData = null;
            	att.Title = null;
            }
            throw e;
        }catch(Exception e){
            if (att != null) {
            	att.VersionData = null;
            	att.Title = null;
            }
            throw e;
        }
    }
}