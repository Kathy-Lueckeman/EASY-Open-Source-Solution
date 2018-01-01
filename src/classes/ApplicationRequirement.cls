/*******************************************************************************
@description This class allows a student to fill out answers to questions and requirement items
@author Huron Consulting Group

Revision (s): 
*******************************************************************************/
public class ApplicationRequirement {

    public List<Requirement_Item__c> items {get;set;}
    public String title { get { return items.isEmpty() ? '' : items[0].Requirement__r.Name; } }
    public ApplicationQuestionSection section {get;set;}
    public Application__c app {get;set;}
    public List<Question_Response__c> qResponses {get;set;}
    public Id contactId {get;set;}
    public Id applicationId {get;set;}
    public Id requirementId{get;set;}
    private Boolean queryItems = true;
    List<Requirement_Response__c> requirementResponses{get;set;}
    List<Question_Response__c> questionResponses{get;set;}
    List<Question_Dependency__c> questionDependencies{get;set;}
    public Boolean preventUpdates{get;set;}
    public List<Requirement_Response__c> newResponses{get;set;}
    public Boolean showSuccess{get;set;}
    public Boolean isInvalid{get;set;}

    public transient String additionalDataString{get;set;}

    public Application_Control__c appControl{
        get{
            if(appControl == null){
                appControl = ApplicationUtilities.getApplicationControls(ApexPages.currentPage().getParameters().get('at'));
            }
            return appControl;
        }set;
    }
    public ApplicationRequirement(Id requirementId, Application__c app, Boolean preventUpdates){
        this();
        this.requirementId = requirementId;
        this.preventUpdates = preventUpdates;
        this.app = app;
    }
    public ApplicationRequirement(){
        items = new List<Requirement_Item__c>();
    }
    public ApplicationRequirement(Id contactId, Id applicationId, Id requirementId,List<Requirement_Item__c> items, List<Requirement_Response__c> requirementResponses, List<Question_Response__c> questionResponses, List<Question_Dependency__c> questionDependencies){
        this.requirementId = requirementId;
        this.items = items;
        this.requirementResponses = requirementResponses;
        this.questionResponses = questionResponses;
        this.questionDependencies = questionDependencies;
        this.preventUpdates = true;
        queryItems = false;
        isInvalid = false;
    }
    /*******************************************************************************
    * @description Initializes the page - Pulls relevant requirement items, requirement responses, etc.
    ********************************************************************************/
    public void init() {
        Boolean isExternalUser = false;
        if(String.isBlank(contactId)){
            contactId = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId()].ContactId;
            if (UserInfo.getUserType().equals('Standard')){
                if(ApexPages.currentPage().getParameters().containsKey('contactId')){
                    contactId = Id.valueOf(ApexPages.currentPage().getParameters().get('contactId'));
                }
            }else if(String.isNotBlank(ApexPages.currentPage().getParameters().get('h'))&& String.isNotBlank(ApexPages.currentPage().getParameters().get('r'))){
                isExternalUser = true;
                contactId = Id.valueOf(ApexPages.currentPage().getParameters().get('contactId'));
                isInvalid = true;
            }
        }
        if(String.isBlank(applicationId)){
            if(ApexPages.currentPage().getParameters().containsKey('applicationId')){
                applicationId = Id.valueOf(ApexPages.currentPage().getParameters().get('applicationId'));

                app = [SELECT Id, Intended_Program__c, Applicant_Type__c , Citizenship__c, Delivery_Type__c, Student_Type__c,Contact__c, School_College__c, Application_Status__c FROM Application__c WHERE Contact__c = :contactId AND Id = :applicationId];
            }
        }

        if(String.isBlank(requirementId)){
            requirementId = Id.valueOf(ApexPages.currentPage().getParameters().get('requirementId'));
        }
        if(queryItems == true){
            String itemQuery = 'SELECT Id, Active__c,Required_Number_of_Children__c,Requirement__r.Name, Name, Instructions__c, Intended_Program__c, Application_Status__c, Applicant_Type__c , Citizenship__c, Degree_Type__c, Delivery_Type__c, Residency__c, School_College__c,Student_Type__c, RecordType.DeveloperName, Allow_Text_Entry__c, Related_List_Object__c,Related_List_Object_Master__c, Related_List_Object_Master_Field__c, Related_List_Where_Clause__c, Internal_Requirement_Item__c, Editable_Application_Status__c, Holding_Record_Id__c, (SELECT Id, Active__c,Required__c, Label__c, Intended_Program__c, Application_Status__c, Applicant_Type__c , Citizenship__c, Degree_Type__c, Delivery_Type__c, Residency__c, School_College__c, Student_Type__c, RecordType.DeveloperName, Picklist_Values__c, Placeholder__c, Length__c, Help_Text__c, Dependency_Logic__c, Dependency_Behavior__c, Related_Object_Field__c, Lookup_Object__c, Lookup_Where_Clause__c, Application_Field__c, External_Email_Field__c,Hardcoded_Value__c, Editable_Application_Status__c, New_Reference_Field__c ,Static_Text__c FROM Questions__r ORDER BY Display_Order__c ASC NULLS LAST) FROM Requirement_Item__c WHERE Requirement__c = :requirementId AND Requirement__r.Show_on_Application_Creation__c = false ';
            if(isExternalUser){
                itemQuery += ' AND Internal_Requirement_Item__c=\''+ApexPages.currentPage().getParameters().get('r')+'\'';
            }
            if(UserInfo.getUserType() != 'Standard'){
                itemQuery += ' AND Internal_Only__c = FALSE ';
            }
            itemQuery += 'ORDER BY Display_Order__c ASC NULLS LAST';
            items = database.query(itemQuery);
        }

        //Question Dependencies
        Map<Id, List< Question_Dependency__c >> dQuestions = new Map<Id, List<Question_Dependency__c>>();
        Map<Id,Set<Id>> dQuestionResponseMap = new Map<Id,Set<Id>>();
        if(questionDependencies == null){
            questionDependencies = [SELECT Id, Question__c, Question__r.Required__c, Question__r.Requirement_Item__c,Question__r.Requirement_Item__r.Requirement__c, Controlling_Question__c, Controlling_Question__r.Requirement_Item__r.Requirement__c, Value__c, ValueCheckbox__c, RecordType.DeveloperName FROM Question_Dependency__c WHERE Question__r.Requirement_Item__r.Requirement__c = :requirementId];
        }
        for (Question_Dependency__c dq: questionDependencies) {
            if (!dQuestions.containsKey(dq.Question__c)){
                dQuestions.put(dq.Question__c, new List<Question_Dependency__c>());
            }
            if(dq.Question__r.Requirement_Item__r.Requirement__c != dq.Controlling_Question__r.Requirement_Item__r.Requirement__c){
                if(!dQuestionResponseMap.containsKey(dq.Question__r.Requirement_Item__c)){
                    dQuestionResponseMap.put(dq.Question__r.Requirement_Item__c,new Set<Id>());
                }
                dQuestionResponseMap.get(dq.Question__r.Requirement_Item__c).add(dq.Controlling_Question__c);
            }
            dQuestions.get(dq.Question__c).add(dq);
        }

        Map<Id, Requirement_Response__c> responses = new Map<Id, Requirement_Response__c>();
        Map<Id, List<Question_Response__c>> dResponses = new Map<Id, List<Question_Response__c>>();
        if(requirementResponses == null && String.isNotBlank(applicationId)){
            requirementResponses = [SELECT Id, Requirement_Item__c,ValueTextEntry__c,HasDocument__c,Application__c,Application__r.Contact__c, External_Email__c,Hashcode__c,Send_Reminder__c , (SELECT Id, Question__c, Question__r.Required__c, ValueText__c, ValueCheckbox__c, ValuePhone__c, ValueEmail__c, ValueCurrency__c, ValueDate__c, ValueDateTime__c, ValueNumber__c, ValuePercent__c, ValueTextArea__c, ValueTextEncrypted__c, ValueLongTextArea__c, ValueURL__c, Street__c, City__c, State__c, Country__c, PostalCode__c, Requirement_Response__c FROM Question_Responses__r), (SELECT Id, LinkedEntityId, ContentDocumentId, ContentDocument.Title FROM ContentDocumentLinks) FROM Requirement_Response__c WHERE Requirement_Item__r.Requirement__c = :requirementId AND Application__c = :applicationId];
        }else if(requirementResponses == null){
            requirementResponses = new List<Requirement_Response__c>();
        }
        //Requirement Responses
        for (Requirement_Response__c r : requirementResponses){
            if(r.Hashcode__c != null && String.isNotBlank(ApexPages.currentPage().getParameters().get('h')) && r.Hashcode__c == ApexPages.currentPage().getParameters().get('h') && r.Requirement_Item__c == ApexPages.currentPage().getParameters().get('r')){
                isInvalid = false;
            }
            responses.put(r.Requirement_Item__c, r);
        }
        Set<Id> questionItemSet = new Set<Id>();
        for(Set<Id> setId : dQuestionResponseMap.values()){
            questionItemSet.addAll(setId);
        }
        if(questionResponses == null && String.isNotBlank(applicationId)){
            questionResponses = [SELECT Id, Question__c, Question__r.Required__c, ValueText__c, ValueCheckbox__c, ValuePhone__c, ValueEmail__c, ValueCurrency__c, ValueDate__c, ValueDateTime__c, ValueNumber__c, ValuePercent__c, ValueTextArea__c, ValueTextEncrypted__c, ValueLongTextArea__c, ValueURL__c, Street__c, City__c, State__c, Country__c, PostalCode__c, Requirement_Response__c FROM Question_Response__c WHERE Question__c IN :questionItemSet AND Requirement_Response__r.Application__c = :applicationId];
        }else if(questionResponses == null){
            questionResponses = new List<Question_Response__c>();
        }
        for (Question_Response__c qr : questionResponses){
            for(Id rId : dQuestionResponseMap.keySet()){
                if(!dResponses.containsKey(rId)){
                    dResponses.put(rId,new List<Question_Response__c>());
                }
                dResponses.get(rId).add(qr);
            }
        }
        //Creates new responses for "new" requirements 
        newResponses = new List<Requirement_Response__c>();
        Map<String,Map<String,Schema.SObjectField>> relatedFieldDescribes = new Map<String,Map<String,SObjectField>>();
        Set<String> relatedObjects = new Set<String>();
        List<Requirement_Item__c> riLst = new List<Requirement_Item__c>();
        for (Requirement_Item__c i:items) {
            if(ApplicationFilter.filter(app,i)){
                if (!responses.containsKey(i.Id) && String.isNotBlank(applicationId)) {
                    Requirement_Response__c r = new Requirement_Response__c(Application__c = app.Id, Requirement_Item__c = i.Id);
                    newResponses.add(r);
                    responses.put(i.Id, r);
                }
                if(String.isNotBlank(i.Related_List_Object__c)){
                    relatedObjects.add(i.Related_List_Object__c);
                }
                //Filter out external requirements based on the hashcode
                if(!(i.Internal_Requirement_Item__c != null && UserInfo.getUserType() != 'Standard' && !ApexPages.currentPage().getParameters().containsKey('h'))){
                    riLst.add(i);
                }
            }
        }
        if(relatedObjects.size()>0){
            for(Schema.DescribeSObjectResult result : Schema.describeSObjects(new List<String>(relatedObjects))){
                relatedFieldDescribes.put(result.getName(),result.fields.getMap());
            }
        }
        if(preventUpdates != true){
            insert newResponses;
        }
        
        
        section = new ApplicationQuestionSection(app,riLst, dQuestions, responses,dResponses,relatedFieldDescribes);

        
    }
    /*******************************************************************************
    * @description Allows the student to lookup existing records for related objects
    ********************************************************************************/
    @RemoteAction
    public static List<SObject> lookupSearch(String sObj, String sObjFilter, String term){

        return new ActionWithSharing().lookupSearchWithSharing(sObj,sObjFilter, term);
    }
    public with sharing class ActionWithSharing{
        public List<SObject> lookupSearchWithSharing(String sObj, String sObjFilter, String term){
            if(Schema.getGlobalDescribe().get(sObj).getDescribe().isAccessible()){
                String query = 'Select Id, Name FROM '+sObj+' WHERE Name like \'%'+String.escapeSingleQuotes(term)+'%\'';
                if(String.isNotBlank(sObjFilter)){
                    query += ' AND ' + sObjFilter;
                }
                query += ' ORDER BY NAME ASC';
                try{
                    return database.query(query);
                }catch(Exception e){
                    return new List<SObject>();
                }
            }
            return new List<SObject>();
        }
    }
    public class CustomReturn{
        public Boolean isSuccess{get;set;}
        public String message{get;set;}
    }
    /*******************************************************************************
    * @description Saves question responses, requirement responses and the application. Takes the student back to the application checklist
    ********************************************************************************/
    public PageReference submit() {
        try{
            transient Map<String,Object> additionalData;
            if(String.isNotBlank(additionalDataString)){
                additionalData = (Map<String,Object>)JSON.deserializeUntyped(additionalDataString);
            } 
            section.processValues(additionalData);
            List<Requirement_Response__c> rrLst = new List<Requirement_Response__c>();
            for(ApplicationQuestionGroup aqg : section.groups){
                if(aqg.response != null && aqg.isEditable){
                    rrLst.add(aqg.response);
                }
            }
            if(rrLst.size()>0){
                update rrLst;
            }
            qResponses = new List<Question_Response__c>();
            for (ApplicationQuestionGroup g:section.groups){
                if (g.questionGroup == true && g.questions != null && g.isEditable){
                    for (ApplicationQuestion q : g.questions){
                        if((q.isEditable || UserInfo.getUserType() == 'Standard') && q.response != null){
                            qResponses.add(q.response);
                        }
                    }
                }
            }
            upsert qResponses;
            update app;
            PageReference pr = new PageReference('/apex/ApplicationChecklist?applicationId=' + app.Id + '&contactId=' + contactId+(ApexPages.currentPage().getParameters().containsKey('at')?'&at='+ApexPages.currentPage().getParameters().get('at'):''));
            if (!UserInfo.getUserType().equals('Standard') && String.isNotBlank(ApexPages.currentPage().getParameters().get('h'))&& String.isNotBlank(ApexPages.currentPage().getParameters().get('r'))){
                pr = null;
                showSuccess = true;
            }
            return pr;
        }catch(DmlException e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,e.getDMLMessage(0)));
        }catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,e.getMessage()));
        }
        return null;
    }
}