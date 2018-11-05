/*******************************************************************************
@description This class allows a student to fill out answers to questions and requirement items
@author Huron Consulting Group

Revision (s):
*******************************************************************************/
public class ApplicationRequirement {

    public List<Requirement_Item__c> items {get;set;}
    public String title { get { return items.isEmpty() ? '' : (String.isBlank(items[0].Requirement__r.Label__c) ? items[0].Requirement__r.Name : items[0].Requirement__r.Label__c); } }
    public ApplicationQuestionSection section {get;set;}
    public Contact con {get;set;}
    public Application__c app {get;set;}
    public List<Question_Response__c> qResponses {get;set;}
    public Id contactId {get;set;}
    public Id applicationId {get;set;}
    public Id requirementId{get;set;}
    private Boolean queryItems = true;
    List<Requirement_Response__c> requirementResponses{get;set;}
    List<Question_Response__c> questionResponses{get;set;}
    List<Question_Dependency__c> questionDependencies{get;set;}
    public Boolean preventUpdates {get;set;}
    public List<Requirement_Response__c> newResponses{get;set;}
    public Boolean showSuccess{get;set;}
    public Boolean isInvalid{get;set;}
    public Boolean isExternalUser{get;set;}

    //Added by Chris 5-15
    //public Id previousSectionID{get;set;}
    //public Id nextSectionID{get;set;}
    public Boolean allowSubmit{get;set;}

    public transient String additionalDataString{get;set;}
    public String redirectPage{get;set;}

    public Application_Control__c appControl {
        get {
            if (appControl == null)
                appControl = ApplicationUtilities.getApplicationControls(ApexPages.currentPage().getParameters().get('at'));
            
            return appControl;
        } set;
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
        allowSubmit = true;
        isExternalUser = false;
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
        
        if (String.isBlank(applicationId)) {
            if (ApexPages.currentPage().getParameters().containsKey('applicationId')) {
                applicationId = Id.valueOf(ApexPages.currentPage().getParameters().get('applicationId'));
				
                app = [SELECT Id, Intended_Program__c, Applicant_Type__c, Citizenship__c, Delivery_Type__c, Student_Type__c, Contact__c, School_College__c, Residency__c, Application_Status__c, Application_Control__c FROM Application__c WHERE Contact__c = :contactId AND Id = :applicationId];
                appControl = ApplicationUtilities.getApplicationControls(app.Application_Control__c);
            }
        }

        if (String.isBlank(requirementId))
            requirementId = Id.valueOf(ApexPages.currentPage().getParameters().get('requirementId'));
        
        if (queryItems == true) {
            
            String itemQuery = 'SELECT Id, Internal_Only__c, Requirement__r.Internal_Only__c, Internal_Only_Applicant_Instructions__c, Active__c, Required__c, Required_Number_of_Children__c, Maximum_Number_of_Children__c, Requirement__r.Name, Requirement__r.Label__c, Name, Label__c, Instructions__c, Intended_Program__c, Application_Status__c, Applicant_Type__c , Citizenship__c, Degree_Type__c, Delivery_Type__c, Residency__c, School_College__c, Student_Type__c, RecordType.DeveloperName, Allow_Text_Entry__c, Related_List_Object__c, Related_List_Object_Master__c, Related_List_Object_Master_Field__c, Related_List_Where_Clause__c, Internal_Requirement_Item__c, Editable_Application_Status__c, Holding_Record_Id__c, (SELECT Id, Active__c, Required__c, Label__c, Intended_Program__c, Application_Status__c, Applicant_Type__c, Citizenship__c, Degree_Type__c, Delivery_Type__c, Residency__c, School_College__c, Student_Type__c, RecordType.DeveloperName, Picklist_Values__c, Placeholder__c, Length__c, Help_Text__c, Dependency_Logic__c, Dependency_Behavior__c, Related_Object_Field__c, Lookup_Object__c, Lookup_Where_Clause__c, Name_Field_API_Name__c, Contact_Field__c, Application_Field__c, External_Email_Field__c,Hardcoded_Value__c, Editable_Application_Status__c, URL_Parameter__c, New_Reference_Field__c ,Static_Text__c, Display_as_Picklist__c FROM Questions__r WHERE Active__c = true ORDER BY Display_Order__c ASC NULLS LAST) FROM Requirement_Item__c WHERE Requirement__c = :requirementId AND Requirement__r.Show_on_Application_Creation__c = false AND Requirement__r.Active__c = true AND Active__c = true';
            
            if (isExternalUser)
                itemQuery += ' AND Internal_Requirement_Item__c=\''+ApexPages.currentPage().getParameters().get('r') + '\'';
            
            if (UserInfo.getUserType() != 'Standard')
                itemQuery += ' AND ((Internal_Only__c = FALSE AND Requirement__r.Internal_Only__c = FALSE) OR (Internal_Only_Show_on_Checklist__c = TRUE AND Requirement__r.Internal_Only_Show_on_Checklist__c = TRUE))';
            
            itemQuery += ' ORDER BY Display_Order__c ASC NULLS LAST';
            items = database.query(itemQuery);
        }
        
        Set<String> contactFields = new Set<String>();
        // Loop over questions and get contact fields
        contactFields = new Set<String>{'id', 'mailingstreet', 'mailingcity', 'mailingpostalcode', 'otherstreet', 'othercity', 'otherpostalcode'};
        if (Account.sObjectType.getDescribe().fields.getMap().containsKey('BillingCountryCode'))
            contactFields.addAll(new Set<String>{'mailingstatecode', 'mailingcountrycode', 'otherstatecode', 'othercountrycode'});
        else
            contactFields.addAll(new Set<String>{'mailingstate', 'mailingcountry', 'otherstate', 'othercountry'});
        for (Requirement_Item__c ri:items)
            for (Question__c q:ri.Questions__r)
            	if (String.isNotBlank(q.Contact_Field__c))
            		contactFields.add(q.Contact_Field__c.toLowerCase());
            
        // Query for contact
        Id contactId = app.Contact__c;
        String query = 'SELECT ' + String.join(new List<String>(contactFields), ',') + ' FROM Contact WHERE Id = :contactId';
        if (contactId != null)
        	con = ((List<Contact>)Database.query(query)).get(0);

        // Question Dependencies
        Map<Id, List<Question_Dependency__c>> dQuestions = new Map<Id, List<Question_Dependency__c>>();
        Map<Id, Set<Id>> dQuestionResponseMap = new Map<Id, Set<Id>>();
        if (questionDependencies == null)
            questionDependencies = [SELECT Id, Question__c, Question__r.Required__c, Question__r.Requirement_Item__c, Question__r.Requirement_Item__r.Requirement__c, Controlling_Question__c, Controlling_Question__r.Requirement_Item__r.Requirement__c, Value__c, ValueCheckbox__c, RecordType.DeveloperName FROM Question_Dependency__c WHERE Question__r.Requirement_Item__r.Requirement__c = :requirementId];
        
        for (Question_Dependency__c dq:questionDependencies) {
            
            if (!dQuestions.containsKey(dq.Question__c))
                dQuestions.put(dq.Question__c, new List<Question_Dependency__c>());
            
            if (dq.Question__r.Requirement_Item__r.Requirement__c != dq.Controlling_Question__r.Requirement_Item__r.Requirement__c) {
                
                if (!dQuestionResponseMap.containsKey(dq.Question__r.Requirement_Item__c))
                    dQuestionResponseMap.put(dq.Question__r.Requirement_Item__c,new Set<Id>());
                
                dQuestionResponseMap.get(dq.Question__r.Requirement_Item__c).add(dq.Controlling_Question__c);
            }
            
            dQuestions.get(dq.Question__c).add(dq);
        }

        Map<Id, Requirement_Response__c> responses = new Map<Id, Requirement_Response__c>();
        Map<Id, List<Question_Response__c>> dResponses = new Map<Id, List<Question_Response__c>>();
        if (requirementResponses == null && String.isNotBlank(applicationId))
            requirementResponses = [SELECT Id, Requirement_Item__c, Requirement_Item__r.Internal_Only__c, ValueTextEntry__c, Fulfilled_On__c, Incomplete_Questions__c, Question_Group_Requirement_Fulfilled_On__c, HasDocument__c, Document_Requirement_Fulfilled_On__c, Has_Child_Requirement__c, Child_Requirement_Fulfilled_On__c, Application__c, Application__r.Contact__c, External_Email__c, Hashcode__c, Send_Reminder__c, (SELECT Id, IsPopulated__c, PopulatedOn__c, Question__c, Question__r.Required__c, ValueText__c, ValueCheckbox__c, ValuePhone__c, ValueEmail__c, ValueCurrency__c, ValueDate__c, ValueDateTime__c, ValueNumber__c, ValuePercent__c, ValueTextArea__c, ValueTextEncrypted__c, ValueLongTextArea__c, ValueURL__c, Street__c, City__c, State__c, Country__c, PostalCode__c, Requirement_Response__c, Requirement_Response__r.Has_Child_Requirement__c FROM Question_Responses__r), (SELECT Id, LinkedEntityId, ContentDocumentId, ContentDocument.Title FROM ContentDocumentLinks) FROM Requirement_Response__c WHERE Requirement_Item__r.Requirement__c = :requirementId AND Application__c = :applicationId];
        else if (requirementResponses == null)
            requirementResponses = new List<Requirement_Response__c>();
        
        // Requirement Responses
        for (Requirement_Response__c r : requirementResponses) {
            if (r.Hashcode__c != null && String.isNotBlank(ApexPages.currentPage().getParameters().get('h')) && r.Hashcode__c == ApexPages.currentPage().getParameters().get('h') && r.Requirement_Item__c == ApexPages.currentPage().getParameters().get('r'))
                isInvalid = false;
            
            responses.put(r.Requirement_Item__c, r);
        }
        Set<Id> questionItemSet = new Set<Id>();
        for (Set<Id> setId:dQuestionResponseMap.values())
            questionItemSet.addAll(setId);
        
        if (questionResponses == null && String.isNotBlank(applicationId))
            questionResponses = [SELECT Id, IsPopulated__c, PopulatedOn__c, Question__c, Question__r.Required__c, ValueText__c, ValueCheckbox__c, ValuePhone__c, ValueEmail__c, ValueCurrency__c, ValueDate__c, ValueDateTime__c, ValueNumber__c, ValuePercent__c, ValueTextArea__c, ValueTextEncrypted__c, ValueLongTextArea__c, ValueURL__c, Street__c, City__c, State__c, Country__c, PostalCode__c, Requirement_Response__c, Requirement_Response__r.Has_Child_Requirement__c FROM Question_Response__c WHERE Question__c IN :questionItemSet AND Requirement_Response__r.Application__c = :applicationId];
        else if (questionResponses == null)
            questionResponses = new List<Question_Response__c>();
        
        for (Question_Response__c qr:questionResponses) {
            for (Id rId:dQuestionResponseMap.keySet()) {
                if (!dResponses.containsKey(rId))
                    dResponses.put(rId, new List<Question_Response__c>());
                
                dResponses.get(rId).add(qr);
            }
        }
        
        // Creates new responses for "new" requirements
        newResponses = new List<Requirement_Response__c>();
        Map<String, Map<String, Schema.SObjectField>> relatedFieldDescribes = new Map<String, Map<String, SObjectField>>();
        Set<String> relatedObjects = new Set<String>();
        List<Requirement_Item__c> riLst = new List<Requirement_Item__c>();
        for (Requirement_Item__c i:items) {
            if (ApplicationFilter.filter(app,i)) {
                
                if (!responses.containsKey(i.Id) && String.isNotBlank(applicationId)) {
                    Requirement_Response__c r = new Requirement_Response__c(Application__c = app.Id, Requirement_Item__c = i.Id);
                    newResponses.add(r);
                    responses.put(i.Id, r);
                }
                
                if (String.isNotBlank(i.Related_List_Object__c))
                    relatedObjects.add(i.Related_List_Object__c);
                
                // Filter out external requirements based on the hashcode
                if (!(i.Internal_Requirement_Item__c != null && UserInfo.getUserType() != 'Standard' && !ApexPages.currentPage().getParameters().containsKey('h')))
                    riLst.add(i);
            }
        }
        
        if (!relatedObjects.isEmpty())
            for (Schema.DescribeSObjectResult result:Schema.describeSObjects(new List<String>(relatedObjects)))
                relatedFieldDescribes.put(result.getName(),result.fields.getMap());
        
        if (preventUpdates == false)
            insert newResponses;
		
        section = new ApplicationQuestionSection(con, app, riLst, dQuestions, responses, dResponses, relatedFieldDescribes);
    }
    
    /*******************************************************************************
    * @description Allows the student to lookup existing records for related objects
    ********************************************************************************/
    @RemoteAction
    public static List<SObject> lookupSearch(String sObj, String sObjFilter, String sObjNameField, String term){

        return new ActionWithSharing().lookupSearchWithSharing(sObj,sObjFilter,sObjNameField,term);
    }
    public with sharing class ActionWithSharing{
        public List<SObject> lookupSearchWithSharing(String sObj, String sObjFilter, String sObjNameField, String term){
            if(Schema.getGlobalDescribe().get(sObj).getDescribe().isAccessible()){
                if(String.isBlank(sObjNameField)){
                    sObjNameField = 'Name';
                }
                String query = 'Select Id, '+sObjNameField+' FROM '+sObj+' WHERE '+sObjNameField+' like \'%'+String.escapeSingleQuotes(term)+'%\'';
                if(String.isNotBlank(sObjFilter)){
                    query += ' AND (' + sObjFilter + ')';
                }
                query += ' ORDER BY '+sObjNameField+' ASC';
                try{
                    return database.query(query);
                }catch(Exception e){
                    return new List<SObject>();
                }
            }
            return new List<SObject>();
        }
    }
    
    public class CustomReturn {
        public Boolean isSuccess {get;set;}
        public String message {get;set;}
    }
    
    /*******************************************************************************
    * @description Saves question responses, requirement responses and the application. Takes the student back to the application checklist
    ********************************************************************************/
    public PageReference submit() {
        try {
            
            Boolean hasError = false;
            for (ApplicationQuestionGroup g:section.groups) {
                if (g.relatedObject == true) {
                    if (g.creatingNewRelatedRecord == true) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Please finish editing all ' + (String.isBlank(g.item.Label__c) ? g.item.Name : g.item.Label__c) + ' records'));
                        hasError = true;
                    } else if (g.relatedObjects != null) {
                        for (ApplicationQuestionGroup.SObjectWrapper sow:g.relatedObjects) {
                            if (sow.isEditMode) {
                                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Please finish editing all ' + (String.isBlank(g.item.Label__c) ? g.item.Name : g.item.Label__c) + ' records'));
                        		hasError = true;
                            }
                        }
                    }
                }
            }
            
            if (hasError)
                return null;
            
            transient Map<String, Object> additionalData;
            if (String.isNotBlank(additionalDataString) && additionalDataString != '{}')
                additionalData = (Map<String,Object>)JSON.deserializeUntyped(additionalDataString);
            
            section.processValues(additionalData);
            List<Requirement_Response__c> rrLst = new List<Requirement_Response__c>();
            for (ApplicationQuestionGroup aqg:section.groups) {
                if (aqg.response != null && aqg.isEditable) {
                    aqg.response.Viewed__c = true;
                    rrLst.add(aqg.response);
                }
            }
            
            upsert rrLst;
            
            qResponses = new List<Question_Response__c>();
            for (ApplicationQuestionGroup g:section.groups)
                if (g.questionGroup == true && g.questions != null && g.isEditable)
                    for (ApplicationQuestion q : g.questions)
                        if ((q.isEditable || UserInfo.getUserType() == 'Standard') && q.response != null)
                            qResponses.add(q.response);
            
            upsert qResponses;
            
            section.pushValuesToObjects();
            
            update app;
            update con;

            if (String.isNotBlank(redirectPage)) {
                
                if (!UserInfo.getUserType().equals('Standard') && String.isNotBlank(ApexPages.currentPage().getParameters().get('h'))&& String.isNotBlank(ApexPages.currentPage().getParameters().get('r'))){
                    showSuccess = true;
                } else if (redirectPage == 'checklist') {
                    PageReference pr = new PageReference('/apex/ApplicationChecklist?applicationId=' + app.Id + '&contactId=' + contactId+(ApexPages.currentPage().getParameters().containsKey('at')?'&at='+ApexPages.currentPage().getParameters().get('at'):''));
                    pr.setRedirect(true);
                    return pr;
                } else if (redirectPage == 'submit') {
                    PageReference pr;
                    if (allowSubmit && app != null) {
                        if (appControl != null && String.isNotBlank(appControl.Submit_Status__c)) {
                            update new Application__c(Id = app.Id, Application_Status__c = appControl.Submit_Status__c);
                            pr = Page.ApplicationChecklist;
                            pr.setRedirect(true);
                            
                            for (String s:new Set<String>{'contactId', 'applicationId', 'at'})
                                pr.getParameters().put(s, ApexPages.currentPage().getParameters().get(s));
                        }
                    }
                    
                    return pr;
                    
                } else {
                    PageReference pr = new PageReference('/apex/ApplicationRequirement?requirementId=' + redirectPage + '&applicationId=' + applicationId + '&contactId=' + contactId + (String.isBlank(appControl.URL_Parameter__c) ? '' : ('&at=' + appControl.URL_Parameter__c)));
                    pr.setRedirect(true);
                    return pr;                   
                }
            }
            
            return null;
            
        } catch(DmlException e) {
            System.debug('DML error:' + e.getDMLMessage(0));
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, e.getDMLMessage(0)));
        } catch(Exception e) {
            System.debug('Error:' + e.getMessage());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, e.getMessage()));
        }
        
        return null;
    }
}