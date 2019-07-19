/*******************************************************************************
@description This controller is used to show which requirements/requirement items have been completed for this application
@author Huron Consulting Group

Revision (s): 
*******************************************************************************/
public class ApplicationProgressBar  {

    // public List<Requirement__c> reqs {get;set;}
    public Map<Id,RequirementWrapper> reqMap {get{
        if (reqMap == null) {
            start();
        }
        return reqMap;
    }
        set;}
    public List<RequirementWrapper> reqs{
        get{
            return reqMap.values();
        }set;
    }
    public String requirementIdString {
        get{
            if (requirementIdString == null){
                requirementIdString = ApexPages.currentPage().getParameters().get('requirementId');
            }
            return requirementIdString;
            }set;
    }
    public Id requirementId {
        get{
            if (requirementId == null && requirementIdString != null) {
                requirementId = requirementIdString;
            }
            return requirementId;
        }set;
    }    public Id contactId {get;set;}
    public Id nextReqId {
        get{
            if(nextReqId == null && ApexPages.currentPage().getParameters().containsKey('requirementId')){
                for(Integer i=0; i < reqs.size()-1; i++) {
                    if(reqs[i].req.Id == ApexPages.currentPage().getParameters().get('requirementId')){
                        nextReqId = reqs[i+1].req.Id;
                        return nextReqId;
                    }
                }
            }
            return null;
        }set;
    }
    public Id prevReqId {
        get{
            if(prevReqId == null && ApexPages.currentPage().getParameters().containsKey('requirementId')){
                for(Integer i=1; i < reqs.size(); i++) {
                    if(reqs[i].req.Id == ApexPages.currentPage().getParameters().get('requirementId')){
                        prevReqId = reqs[i-1].req.Id;
                        return prevReqId;
                    }
                }
            }
            return null;
        }set;
    }
    public Id applicationId {get;set;}
    public Contact con {get;set;}
    public Application__c app {get;set;}
    public Boolean allowSubmit{get;set;}
    public Boolean allowCancel{get;set;}
    public Boolean allowWithdraw{get;set;}
    public List<Requirement_Item__c> riList {get;set;}
    public Long progress {get;set;}
    public Boolean isExternalUserPb {get;set;}

    public Application_Control__c appControl{
        get{
            if(appControl == null){
                appControl = ApplicationUtilities.getApplicationControls(ApexPages.currentPage().getParameters().get('at'));
            }
            return appControl;
        }set;
    }
    public ApplicationProgressBar (ApplicationRequirement appReqmt){} 

    /*******************************************************************************
    * @description Initialize the page - Checks if requirements have been completed
    ********************************************************************************/
    public void start() {
        allowSubmit = true;
        allowCancel = false;
        allowWithdraw = false;
        isExternalUserPb = false;
        
        contactId = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId()].ContactId;
        
        if (UserInfo.getUserType().equals('Standard')) {
            if (ApexPages.currentPage().getParameters().containsKey('contactId'))
                contactId = Id.valueOf(ApexPages.currentPage().getParameters().get('contactId'));
                
        } else if (String.isNotBlank(ApexPages.currentPage().getParameters().get('h')) && String.isNotBlank(ApexPages.currentPage().getParameters().get('r'))) {
            isExternalUserPb = true;
            contactId = Id.valueOf(ApexPages.currentPage().getParameters().get('contactId'));
        }
        
        applicationId = Id.valueOf(ApexPages.currentPage().getParameters().get('applicationId'));
		
        app = [SELECT Id, Contact__c, Intended_Program__r.Program_Name_on_Application__c, Intended_Program__r.Name, Intended_Term_of_Entry__r.Name, Intended_Term_of_Entry__r.Term_Start_Date__c, Intended_Program__c, Applicant_Type__c, Citizenship__c, Delivery_Type__c, Student_Type__c, Residency__c, Application_Status__c, School_College__c, Degree_Type__c, Application_Control__c, Generic_Filter_1__c, Generic_Filter_2__c, Generic_Filter_3__c, Generic_Filter_4__c FROM Application__c WHERE Id = :applicationId];
        appControl = ApplicationUtilities.getApplicationControls(app.Application_Control__c);
        
        if(String.isNotBlank(appControl.Allow_Cancel_From__c) && new Set<String>(appControl.Allow_Cancel_From__c.split(';')).contains(app.Application_Status__c)){
            allowCancel = true;
        }
        if(String.isNotBlank(appControl.Allow_Withdraw_From__c) && new Set<String>(appControl.Allow_Withdraw_From__c.split(';')).contains(app.Application_Status__c)){
            allowWithdraw = true;
        }
        
        reqMap = new Map<Id,RequirementWrapper>();
        Set<Id> reqIds = new Set<Id>();
        for (Requirement__c r:[SELECT Id, Internal_Only__c, Name, Active__c, Intended_Program__c, Application_Status__c, Applicant_Type__c, Citizenship__c, Degree_Type__c, Delivery_Type__c, Residency__c, School_College__c, Student_Type__c, Generic_Filter_1__c, Generic_Filter_2__c, Generic_Filter_3__c, Generic_Filter_4__c FROM Requirement__c WHERE Application_Control__c = :appControl.Id AND Active__c = :true and Show_On_Application_Creation__c = false ORDER BY Display_Order__c ASC NULLS LAST]){
            if (ApplicationFilter.filter(app, r)) {
                reqIds.add(r.Id);
                reqMap.put(r.Id,new RequirementWrapper(r));
            }
        }

        Map<Id,Boolean> completedRequirement = new Map<Id,Boolean>();
        Map<Id,Boolean> viewedRequirement = new Map<Id,Boolean>();
        
        Set<Id> riIds = new Set<Id>();
        Set<Id> reqIdsToKeep = new Set<Id>();
        riList = [SELECT Id, Required__c,Requirement__c, Internal_Only__c, Active__c, Required_Number_of_Children__c, Requirement__r.Name, Name, Instructions__c, Intended_Program__c, Application_Status__c, Applicant_Type__c, Citizenship__c, Degree_Type__c, Delivery_Type__c, Residency__c, School_College__c, Student_Type__c, RecordType.DeveloperName, Allow_Text_Entry__c, Related_List_Object__c, Related_List_Object_Master__c, Related_List_Object_Master_Field__c, Related_List_Where_Clause__c, Internal_Requirement_Item__c, Editable_Application_Status__c, Allow_Supporting_Documentation_Upload__c, Required_Supporting_Documentation__c, Generic_Filter_1__c, Generic_Filter_2__c, Generic_Filter_3__c, Generic_Filter_4__c, (SELECT Id, Active__c,Hardcoded_value__c,Required__c, Label__c, Intended_Program__c, Application_Status__c, Applicant_Type__c , Citizenship__c, Degree_Type__c, Delivery_Type__c, Residency__c, School_College__c, Student_Type__c, RecordType.DeveloperName, Picklist_Values__c, Placeholder__c, Length__c, Help_Text__c, Dependency_Logic__c, Dependency_Behavior__c, Related_Object_Field__c, Lookup_Object__c, Lookup_Where_Clause__c, Contact_Field__c, Application_Field__c, External_Email_Field__c, Editable_Application_Status__c, New_Reference_Field__c, URL_Parameter__c,Static_Text__c, Name_Field_API_Name__c, Display_as_Picklist__c, Generic_Filter_1__c, Generic_Filter_2__c, Generic_Filter_3__c, Generic_Filter_4__c FROM Questions__r ORDER BY Display_Order__c ASC NULLS LAST) FROM Requirement_Item__c WHERE Requirement__c in :reqIds ORDER BY Display_Order__c ASC NULLS LAST];
        for(Requirement_Item__c ri : riList){
            Boolean isValid = (!isExternalUserPb || ri.Internal_Requirement_Item__c == Id.valueOf(ApexPages.currentPage().getParameters().get('r'))) && ApplicationFilter.filter(app, ri);
            if (isValid) {
                reqIdsToKeep.add(ri.Requirement__c);
                reqMap.get(ri.Requirement__c).reqItemMap.put(ri.Id,new RequirementItemWrapper(ri));
                riIds.add(ri.Id);
            }
        }
        
        Set<String> appFields = new Set<String>{'id', 'contact__c', 'intended_program__r.program_name_on_application__c', 'intended_program__r.name', 'intended_term_of_entry__r.name', 'intended_term_of_entry__r.term_start_date__c', 'intended_program__c', 'applicant_type__c', 'citizenship__c', 'delivery_type__c', 'student_type__c', 'residency__c', 'application_status__c', 'school_college__c', 'degree_type__c', 'application_control__c', 'generic_filter_1__c', 'generic_filter_2__c', 'generic_filter_3__c', 'generic_filter_4__c'};
        for (Requirement_Item__c ri:riList)
            for (Question__c q:ri.Questions__r)
            	if (String.isNotBlank(q.Application_Field__c))
            		appFields.add(q.Application_Field__c.toLowerCase());
        
        String appQuery = 'SELECT ' + String.join(new List<String>(appFields), ',') + ' FROM Application__c WHERE Contact__c = :contactId AND Id = :applicationId';
        
        app = ((List<Application__c>)Database.query(appQuery)).get(0);
        
        Set<String> contactFields = new Set<String>();
        // Loop over questions and get contact fields
        contactFields = new Set<String>{'id', 'mailingstreet', 'mailingcity', 'mailingpostalcode', 'otherstreet', 'othercity', 'otherpostalcode'};
        if (Account.sObjectType.getDescribe().fields.getMap().containsKey('BillingCountryCode'))
            contactFields.addAll(new Set<String>{'mailingstatecode', 'mailingcountrycode', 'otherstatecode', 'othercountrycode'});
        else
            contactFields.addAll(new Set<String>{'mailingstate', 'mailingcountry', 'otherstate', 'othercountry'});
        for (Requirement_Item__c ri:riList)
            for (Question__c q:ri.Questions__r)
            	if (String.isNotBlank(q.Contact_Field__c))
            		contactFields.add(q.Contact_Field__c.toLowerCase());
            
        // Query for contact
        String query = 'SELECT ' + String.join(new List<String>(contactFields), ',') + ' FROM Contact WHERE Id = :contactId';
        if (contactId != null)
        	con = ((List<Contact>)Database.query(query)).get(0);
        
        checkRequirementCompletion();
        for(Requirement_Response__c rr : [Select Id, Requirement_Item__r.Required__c,Has_Child_Requirement__c,Requirement_Item__c,Requirement_Item__r.RecordType.DeveloperName,Requirement_Item__r.Requirement__c,Incomplete_Questions__c, HasDocument__c,Send_Reminder__c,External_Email__c,Viewed__c,Requirement_Item__r.Viewing_Requirement_Formula__c from Requirement_Response__c WHERE Application__c = :applicationId and Requirement_Item__r.Requirement__c in :reqIds]){
            if(riIds.contains(rr.Requirement_Item__c)){
                Boolean itemCompleted = true;
                if(!completedRequirement.containsKey(rr.Requirement_Item__r.Requirement__c)){
                    completedRequirement.put(rr.Requirement_Item__r.Requirement__c,true);
                }
                if(!rr.Viewed__c && rr.Requirement_Item__r.Viewing_Requirement_Formula__c){
                    completedRequirement.put(rr.Requirement_Item__r.Requirement__c,false);
                    viewedRequirement.put(rr.Requirement_Item__r.Requirement__c,false);
                    itemCompleted = false;                    
                }
                if(rr.Incomplete_Questions__c > 0){
                    completedRequirement.put(rr.Requirement_Item__r.Requirement__c,false);
                    itemCompleted = false;
                }
                if(rr.Requirement_Item__r.RecordType.DeveloperName == 'Document_Upload' && rr.HasDocument__c == false && String.isNotBlank(rr.Requirement_Item__r.Required__c) && new Set<String>(rr.Requirement_Item__r.Required__c.split(';')).contains(app.Application_Status__c)){
                    completedRequirement.put(rr.Requirement_Item__r.Requirement__c,false);
                    itemCompleted = false;
                }
                if(rr.Requirement_Item__r.RecordType.DeveloperName == 'Related_Object' && rr.Has_Child_Requirement__c == false){
                    completedRequirement.put(rr.Requirement_Item__r.Requirement__c,false);
                    itemCompleted = false;
                }
                reqMap.get(rr.Requirement_Item__r.Requirement__c).reqItemMap.get(rr.Requirement_Item__c).reqItemStatus = itemCompleted;
            }
        }
        for(Id rId : completedRequirement.keySet()){
            if(completedRequirement.get(rId) == true && reqMap.containsKey(rId)){
                reqMap.get(rId).reqStatus = true;
            }
        }
        for(Id rId : viewedRequirement.keySet()){
            if(viewedRequirement.get(rId) == false && reqMap.containsKey(rId)){
                reqMap.get(rId).viewed = false;
            }
        }
        for(RequirementWrapper rw : reqMap.values()){
            if(rw.reqStatus == false){
                allowSubmit = false;
                break;
            }
        }
        if(appControl != null && String.isNotBlank(appControl.Allow_Submit_From__c)){
            if(!new Set<String>(appControl.Allow_Submit_From__c.split(';')).contains(app.Application_Status__c)){
                allowSubmit = false;
            }
        }else if(appControl != null && String.isBlank(appControl.Allow_Submit_From__c) && String.isNotBlank(appControl.Submit_Status__c)){
           
        }else{
            allowSubmit = false;
        }
        
        Decimal total = (Decimal)reqs.size();
        Decimal complete = 0;
        
        for (RequirementWrapper req:reqs) {
            if (req.reqStatus) complete++;
        }
        
        progress = ((complete / total) * 100).round(System.RoundingMode.HALF_EVEN);
        
        reqMap.keySet().retainAll(reqIdsToKeep);
        reqIds.retainAll(reqIdsToKeep);
    }
    /*******************************************************************************
    * @description Checks to see if requirements have been completed. Checks related list items too (Even if they are not marked completed on the Requirement Response)
    ********************************************************************************/
    public void checkRequirementCompletion(){
        
        Set<Id> requirementIds = new Set<Id>();

        //Requirement Items
        Map<Id,List<Requirement_Item__c>> riMap = new Map<Id,List<Requirement_Item__c>>();
        
        for(Requirement_Item__c ri : riList){
            if(ApplicationFilter.filter(app,ri)){
                requirementIds.add(ri.Requirement__c);
                if(!riMap.containsKey(ri.Requirement__c)){
                    riMap.put(ri.Requirement__c,new List<Requirement_Item__c>());
                }
                riMap.get(ri.Requirement__c).add(ri);
            }
        }

        //Requirement Responses
        Map<Id,List<Requirement_Response__c>> rrMap = new Map<Id,List<Requirement_Response__c>>();
        for(Requirement_Response__c rr : [SELECT Id, Requirement_Item__r.Requirement__c,Requirement_Item__c,ValueTextEntry__c, Has_Child_Requirement__c, Child_Requirement_Fulfilled_On__c, HasDocument__c,Application__c,Application__r.Contact__c,External_Email__c,Hashcode__c,Send_Reminder__c,Viewed__c, (SELECT Id, Question__c, Question__r.Required__c, ValueText__c, ValueCheckbox__c, ValuePhone__c, ValueEmail__c, ValueCurrency__c, ValueDate__c, ValueDateTime__c, ValueNumber__c, ValuePercent__c, ValueTextArea__c, ValueTextEncrypted__c, ValueLongTextArea__c, ValueURL__c, Street__c, City__c, State__c, Country__c, PostalCode__c,Requirement_Response__c FROM Question_Responses__r), (SELECT Id, LinkedEntityId, ContentDocumentId, ContentDocument.Title FROM ContentDocumentLinks) FROM Requirement_Response__c WHERE Requirement_Item__r.Requirement__c in :requirementIds AND Application__c = :applicationId]){
            if(!rrMap.containsKey(rr.Requirement_Item__r.Requirement__c)){
                rrMap.put(rr.Requirement_Item__r.Requirement__c,new List<Requirement_Response__c>());
            }
            rrMap.get(rr.Requirement_Item__r.Requirement__c).add(rr);
        }

        //Question Dependencies
        Set<Id> questionItemSet = new Set<Id>();
        Map<Id,Id> qdReqMap = new Map<Id,Id>(); //Maps Question Dependencies to their original Requirement
        Map<Id,List<Question_Dependency__c>> qdMap = new Map<Id,List<Question_Dependency__c>>();
        for(Question_Dependency__c qd : [SELECT Id, Question__c, Question__r.Required__c, Question__r.Requirement_Item__c,Question__r.Requirement_Item__r.Requirement__c, Controlling_Question__c, Controlling_Question__r.Requirement_Item__r.Requirement__c, Value__c, ValueCheckbox__c, RecordType.DeveloperName FROM Question_Dependency__c WHERE Question__r.Requirement_Item__r.Requirement__c in :requirementIds]){
            if(!qdMap.containsKey(qd.Question__r.Requirement_Item__r.Requirement__c)){
                qdMap.put(qd.Question__r.Requirement_Item__r.Requirement__c,new List<Question_Dependency__c>());
            }
            qdMap.get(qd.Question__r.Requirement_Item__r.Requirement__c).add(qd);
            if(qd.Question__r.Requirement_Item__r.Requirement__c != qd.Controlling_Question__r.Requirement_Item__r.Requirement__c){
                questionItemSet.add(qd.Controlling_Question__c);
                qdReqMap.put(qd.Controlling_Question__c,qd.Question__r.Requirement_Item__r.Requirement__c);
            }
        }

        //Question responses
        Map<Id,List<Question_Response__c>> qrMap = new Map<Id,List<Question_Response__c>>();
        for(Question_Response__c qr : [SELECT Id, Question__r.Requirement_Item__r.Requirement__c,Question__c, Question__r.Required__c, ValueText__c, ValueCheckbox__c, ValuePhone__c, ValueEmail__c, ValueCurrency__c, ValueDate__c, ValueDateTime__c, ValueNumber__c, ValuePercent__c, ValueTextArea__c, ValueTextEncrypted__c, ValueLongTextArea__c, ValueURL__c, Street__c, City__c, State__c, Country__c, PostalCode__c,Requirement_Response__c FROM Question_Response__c WHERE Question__c IN :questionItemSet AND Requirement_Response__r.Application__c = :applicationId]){
            if(!qrMap.containsKey(qdReqMap.get(qr.Question__c))){
                qrMap.put(qdReqMap.get(qr.Question__c),new List<Question_Response__c>());
            }
            qrMap.get(qdReqMap.get(qr.Question__c)).add(qr);
        }
        List<ApplicationRequirement> arLst = new List<ApplicationRequirement>();
        List<Requirement_Response__c> responses = new List<Requirement_Response__c>();
        for(Id rid : requirementIds){
            //Requirement Items
            List<Requirement_Item__c> items;
            if(riMap.containsKey(rid)){
                items = riMap.get(rid);
            }else{
                items = new List<Requirement_Item__c>();
            }

            //Requirement Responses
            List<Requirement_Response__c> requirementResponses;
            if(rrMap.containsKey(rid)){
                requirementResponses = rrMap.get(rid);
            }else{
                requirementResponses = new List<Requirement_Response__c>();
            }

            //Question Dependencies
            List<Question_Dependency__c> questionDependencies;
            if(qdMap.containsKey(rid)){
                questionDependencies = qdMap.get(rid);
            }else{
                questionDependencies = new List<Question_Dependency__c>();
            }

            //Question Responses
            List<Question_Response__c> questionResponses;
            if(qrMap.containsKey(rid)){
                questionResponses = qrMap.get(rid);
            }else{
                questionResponses = new List<Question_Response__c>();
            }
            ApplicationRequirement ar = new ApplicationRequirement(contactId, applicationId, rid, items, requirementResponses, questionResponses, questionDependencies);
            ar.con = con;
            ar.app = app;
            ar.preventUpdates = true;
            arLst.add(ar);
            ar.init();
            responses.addAll(ar.newResponses);
        }
        if(responses.size()>0){
            insert responses;
        }
        try{
            Map<Question_Response__c,Requirement_Response__c> questionToResponseMap = new Map<Question_Response__c,Requirement_Response__c>();
            List<Requirement_Response__c> rrLst = new List<Requirement_Response__c>();
            List<Question_Response__c> qResponses = new List<Question_Response__c>();
            for(ApplicationRequirement r : arLst){
                r.section.processValues();
                for(ApplicationQuestionGroup aqg : r.section.groups){
                    if(aqg.response != null){
                        rrLst.add(aqg.response);
                    }
                    if (aqg.questionGroup == true && aqg.questions != null){
                        for (ApplicationQuestion q : aqg.questions){
                            if(q.response != null){
                                questionToResponseMap.put(q.response,aqg.response);
                                qResponses.add(q.response);
                            }
                        }
                    }
                }
            }
            if(rrLst.size()>0){
                update rrLst;
            }
            for(Question_Response__c qr : questionToResponseMap.keySet()){
                if(qr.Requirement_Response__c == null){
                    qr.Requirement_Response__c = questionToResponseMap.get(qr).Id;
                }
            }
            upsert qResponses;
            update app;
            
        }catch(DmlException e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,e.getDMLMessage(0)));
        }catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,e.getMessage()));
        }

    }
}