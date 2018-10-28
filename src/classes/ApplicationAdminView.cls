/*******************************************************************************
@description This controller is used to allow internal users the ability to edit an application.
@author Huron Consulting Group

Revision (s):
*******************************************************************************/
public class ApplicationAdminView {

	public List<Requirement__c> reqs {get;set;}
    public Id contactId {get;set;}
    public Id applicationId {get;set;}
    public Application__c app {get;set;}
	public Set<Id> requirementIds {get;set;}
	public List<ApplicationRequirement> arLst {get;set;}
	public transient String additionalDataString{get;set;}
	
    public Contact con {
        get {
            if (con == null) {
                for (ApplicationRequirement ar:arLst) {
                    if (ar.section.con != null) {
                        con = ar.section.con;
                        break;
                    }
                }
            }
            return con;
        } set;
    }
    
	public Application_Control__c appControl{
        get{
            if(appControl == null){
                appControl = ApplicationUtilities.getApplicationControls(ApexPages.currentPage().getParameters().get('at'));
            }
            return appControl;
        }set;
    }

	public ApplicationAdminView(){}

	/*******************************************************************************
    * @description Initialize the page - Creates ApplicationRequirement for each requirement that is applicible to this application
    ********************************************************************************/
	public void init() {

		applicationId = Id.valueOf(ApexPages.currentPage().getParameters().get('applicationId'));
		contactId = [Select Contact__c from Application__c where Id =:applicationId limit 1].Contact__c;
		ApexPages.currentPage().getParameters().put('contactId',contactId);
		app = [SELECT Id, Intended_Program__r.Name, Intended_Term_of_Entry__r.Name, Intended_Program__c, Applicant_Type__c , Citizenship__c, Delivery_Type__c, Student_Type__c, Application_Status__c, School_College__c, Residency__c, Application_Control__c FROM Application__c WHERE Id = :applicationId];
		appControl = ApplicationUtilities.getApplicationControls(app.Application_Control__c);

		requirementIds = new Set<Id>();
		for (Requirement_Response__c rr:[SELECT Id, Requirement_Item__r.Requirement__c FROM Requirement_Response__c WHERE Application__c = :applicationId AND Requirement_Item__r.Active__c = :true AND Requirement_Item__r.Requirement__r.Active__c = :true])
			requirementIds.add(rr.Requirement_Item__r.Requirement__c);

		//Requirement Items
		Map<Id,List<Requirement_Item__c>> riMap = new Map<Id,List<Requirement_Item__c>>();
		for(Requirement_Item__c ri : [SELECT Id, Internal_Only__c, Requirement__r.Internal_Only__c, Internal_Only_Applicant_Instructions__c, Active__c, Required__c, Required_Number_of_Children__c, Maximum_Number_of_Children__c, Requirement__r.Name, Requirement__r.Label__c, Name, Label__c, Instructions__c, Intended_Program__c, Application_Status__c, Applicant_Type__c , Citizenship__c, Degree_Type__c, Delivery_Type__c, Residency__c, School_College__c, Student_Type__c, RecordType.DeveloperName, Allow_Text_Entry__c, Related_List_Object__c,Related_List_Object_Master__c, Related_List_Object_Master_Field__c, Related_List_Where_Clause__c, Holding_Record_ID__c, Internal_Requirement_Item__c,Editable_Application_Status__c, (SELECT Id, Active__c,Hardcoded_value__c,Required__c, Label__c, Intended_Program__c, Application_Status__c, Applicant_Type__c , Citizenship__c, Degree_Type__c, Delivery_Type__c, Residency__c, School_College__c, Student_Type__c, RecordType.DeveloperName, Picklist_Values__c, Placeholder__c, Length__c, Help_Text__c, Dependency_Logic__c, Dependency_Behavior__c, Related_Object_Field__c, Lookup_Object__c, Lookup_Where_Clause__c, Name_Field_API_Name__c, Contact_Field__c, Application_Field__c, External_Email_Field__c,Editable_Application_Status__c,URL_Parameter__c,New_Reference_Field__c,Static_Text__c, Display_as_Picklist__c FROM Questions__r WHERE Active__c = :true ORDER BY Display_Order__c ASC NULLS LAST) FROM Requirement_Item__c WHERE Requirement__c in :requirementIds AND Requirement__r.Show_on_Application_Creation__c = false AND Active__c = :true AND Requirement__r.Active__c = :true ORDER BY Display_Order__c ASC NULLS LAST]){
			if(!riMap.containsKey(ri.Requirement__c)){
				riMap.put(ri.Requirement__c,new List<Requirement_Item__c>());
			}
			riMap.get(ri.Requirement__c).add(ri);
		}

		//Requirement Responses
		Map<Id,List<Requirement_Response__c>> rrMap = new Map<Id,List<Requirement_Response__c>>();
		for(Requirement_Response__c rr : [SELECT Id, Requirement_Item__r.Requirement__c,Requirement_Item__c,ValueTextEntry__c,Fulfilled_On__c,Incomplete_Questions__c,Question_Group_Requirement_Fulfilled_On__c,HasDocument__c,Document_Requirement_Fulfilled_On__c,Has_Child_Requirement__c,Child_Requirement_Fulfilled_On__c,Application__c,Application__r.Contact__c,External_Email__c,Hashcode__c,Send_Reminder__c, (SELECT Id, IsPopulated__c, PopulatedOn__c, Question__c, Question__r.Required__c, ValueText__c, ValueCheckbox__c, ValuePhone__c, ValueEmail__c, ValueCurrency__c, ValueDate__c, ValueDateTime__c, ValueNumber__c, ValuePercent__c, ValueTextArea__c, ValueTextEncrypted__c, ValueLongTextArea__c, ValueURL__c, Street__c, City__c, State__c, Country__c, PostalCode__c FROM Question_Responses__r WHERE Question__r.Active__c = :true), (SELECT Id, LinkedEntityId, ContentDocumentId, ContentDocument.Title FROM ContentDocumentLinks) FROM Requirement_Response__c WHERE Requirement_Item__r.Requirement__c in :requirementIds AND Application__c = :applicationId AND Requirement_Item__r.Active__c = :true AND Requirement_Item__r.Requirement__r.Active__c = :true]){
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
		for (Question_Response__c qr:[SELECT Id, IsPopulated__c, PopulatedOn__c, Question__r.Requirement_Item__r.Requirement__c,Question__c, Question__r.Required__c, ValueText__c, ValueCheckbox__c, ValuePhone__c, ValueEmail__c, ValueCurrency__c, ValueDate__c, ValueDateTime__c, ValueNumber__c, ValuePercent__c, ValueTextArea__c, ValueTextEncrypted__c, ValueLongTextArea__c, ValueURL__c, Street__c, City__c, State__c, Country__c, PostalCode__c FROM Question_Response__c WHERE Question__c IN :questionItemSet AND Requirement_Response__r.Application__c = :applicationId AND Question__r.Active__c = :true AND Question__r.Requirement_Item__r.Active__c = :true AND Question__r.Requirement_Item__r.Requirement__r.Active__c = :true]){
			if (!qrMap.containsKey(qdReqMap.get(qr.Question__c)))
				qrMap.put(qdReqMap.get(qr.Question__c),new List<Question_Response__c>());
			
			qrMap.get(qdReqMap.get(qr.Question__c)).add(qr);
		}
		arLst = new List<ApplicationRequirement>();
		for (Id rid:requirementIds) {
			
			//Requirement Items
			List<Requirement_Item__c> items = riMap.containsKey(rid) ? riMap.get(rid) : new List<Requirement_Item__c>();

			//Requirement Responses
			List<Requirement_Response__c> requirementResponses = rrMap.containsKey(rid) ? rrMap.get(rid) : new List<Requirement_Response__c>();

			//Question Dependencies
			List<Question_Dependency__c> questionDependencies = qdMap.containsKey(rid) ? qdMap.get(rid) : new List<Question_Dependency__c>();

			//Question Responses
			List<Question_Response__c> questionResponses = qrMap.containsKey(rid) ? qrMap.get(rid) : new List<Question_Response__c>();
			
			ApplicationRequirement ar = new ApplicationRequirement(contactId, applicationId, rid,items, requirementResponses, questionResponses, questionDependencies);
			ar.preventUpdates = true;
			arLst.add(ar);
			ar.init();
		}
	}

	/*******************************************************************************
    * @description Updates all of the Question_Response__c, Requirement_Response__c and Application__c based on what is populated on the VisualForce page
    * @return The application record to return to when the page is saved, null if there is an error.
    *******************************************************************************/
	public PageReference submit(){
		List<Requirement_Response__c> responses = new List<Requirement_Response__c>();
		for(ApplicationRequirement ar : arLst){
			if(ar.newResponses != null && ar.newResponses.size()>0){
				responses.addAll(ar.newResponses);
			}
		}
		if(responses.size()>0){
            insert responses;
        }
        try{
            Map<Question_Response__c,Requirement_Response__c> questionToResponseMap = new Map<Question_Response__c,Requirement_Response__c>();
            List<Requirement_Response__c> rrLst = new List<Requirement_Response__c>();
            List<Question_Response__c> qResponses = new List<Question_Response__c>();
			transient Map<String,Object> additionalData;
			if(String.isNotBlank(additionalDataString)){
				additionalData = (Map<String,Object>)JSON.deserializeUntyped(additionalDataString);
			}
            for(ApplicationRequirement r : arLst){
				r.section.processValues(additionalData);
                for(ApplicationQuestionGroup aqg : r.section.groups){
                    if(aqg.response != null){
                        rrLst.add(aqg.response);
                    }
                    if (aqg.questionGroup == true && aqg.questions != null){
                        for (ApplicationQuestion q : aqg.questions){
                            if (q.response != null) {
								system.debug(q.response);
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
            
            pushValuesToObjects();
            
            if (con != null) update con;
            update app;
            PageReference pr = new PageReference('/'+applicationId);
			pr.setRedirect(true);
			return pr;
        }catch(DmlException e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,e.getDMLMessage(0)));
        }catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,e.getMessage()));
        }
		return null;
	}
    
    public void pushValuesToObjects() {
        
        if (con == null && app == null) return;
        
        Set<String> allContactFields = new Set<String>();
        Set<String> allApplicationFields = new Set<String>();
        Map<String, Object> contactValues = new Map<String, Object>();
        Map<String, Object> applicationValues = new Map<String, Object>();
        for (ApplicationRequirement ar:arLst) {
            for (ApplicationQuestionGroup g:ar.section.groups) {
                if (g.questionGroup) {
                    for (ApplicationQuestion q:g.questions) {
                        if (q.question != null && (String.isNotBlank(q.question.Contact_Field__c) || String.isNotBlank(q.question.Application_Field__c))) {
                            
                            if (con != null && String.isNotBlank(q.question.Contact_Field__c))
                                allContactFields.add(q.question.Contact_Field__c.toLowerCase());
                            if (app != null && String.isNotBlank(q.question.Application_Field__c))
                                allApplicationFields.add(q.question.Application_Field__c.toLowerCase());
                            
                            Boolean shown = q.getShowQuestion();
                            
                            if (shown && q.fieldType.equals('Address') && (q.question.Contact_Field__c == 'MailingAddress' || q.question.Contact_Field__c == 'OtherAddress')) {
                				
                                String prefix = q.question.Contact_Field__c.equals('MailingAddress') ? 'Mailing' : 'Other';
                                con.put(prefix + 'Street', q.response.Street__c);
                                con.put(prefix + 'City', q.response.City__c);
                                con.put(prefix + 'PostalCode', q.response.PostalCode__c);
                                con.put(prefix + (ApplicationQuestion.stateAndCountryPicklistEnabled ? 'StateCode' : 'State'), q.response.State__c);
                                con.put(prefix + (ApplicationQuestion.stateAndCountryPicklistEnabled ? 'CountryCode' : 'Country'), q.response.Country__c);
                                
                            } else if (q.resp != null) {
                                if (con != null && String.isNotBlank(q.question.Contact_Field__c))
                                    contactValues.put(q.question.Contact_Field__c.toLowerCase(), q.resp);
                                if (app != null && String.isNotBlank(q.question.Application_Field__c))
                                    applicationValues.put(q.question.Application_Field__c.toLowerCase(), q.resp);
                            }
                        }
                    }
                }
            }
        }
        
        for (String f:allContactFields) {
            try {
                con.put(f, contactValues.get(f));
            } catch (Exception e) {}
        }
        
        for (String f:allApplicationFields) {
            try {
                app.put(f, applicationValues.get(f));
            } catch (Exception e) {}
        }
    }
    
	/*******************************************************************************
    * @description Returns a list of sobjects based on a search term
    * @return List of sobjects based on a search term.
    *******************************************************************************/
	@RemoteAction
    public static List<SObject> lookupSearch(String sObj, String sObjFilter, String sObjNameField, String term){

        return new ApplicationRequirement.ActionWithSharing().lookupSearchWithSharing(sObj,sObjFilter,sObjNameField, term);
    }
}