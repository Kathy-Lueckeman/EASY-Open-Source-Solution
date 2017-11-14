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
		app = [SELECT Id, Intended_Program__r.Name, Intended_Term_of_Entry__r.Name, Intended_Program__c, Applicant_Type__c , Citizenship__c, Delivery_Type__c, Student_Type__c, Application_Status__c, School_College__c FROM Application__c WHERE Id = :applicationId];

		requirementIds = new Set<Id>();
		for(Requirement_Response__c rr : [Select Id,Requirement_Item__r.Requirement__c,Send_Reminder__c ,External_Email__c from Requirement_Response__c where Application__c = :applicationId]){
			requirementIds.add(rr.Requirement_Item__r.Requirement__c);
		}

		//Requirement Items
		Map<Id,List<Requirement_Item__c>> riMap = new Map<Id,List<Requirement_Item__c>>();
		for(Requirement_Item__c ri : [SELECT Id, Active__c,Required_Number_of_Children__c,Requirement__r.Name, Name, Instructions__c, Intended_Program__c, Application_Status__c, Applicant_Type__c , Citizenship__c, Degree_Type__c, Delivery_Type__c, Residency__c, School_College__c, Student_Type__c, RecordType.DeveloperName, Allow_Text_Entry__c, Related_List_Object__c,Related_List_Object_Master__c, Related_List_Object_Master_Field__c, Related_List_Where_Clause__c, Internal_Requirement_Item__c,Editable_Application_Status__c, (SELECT Id, Active__c,Hardcoded_value__c,Required__c, Label__c, Intended_Program__c, Application_Status__c, Applicant_Type__c , Citizenship__c, Degree_Type__c, Delivery_Type__c, Residency__c, School_College__c, Student_Type__c, RecordType.DeveloperName, Picklist_Values__c, Placeholder__c, Length__c, Help_Text__c, Dependency_Logic__c, Dependency_Behavior__c, Related_Object_Field__c, Lookup_Object__c, Lookup_Where_Clause__c, Application_Field__c, External_Email_Field__c,Editable_Application_Status__c,New_Reference_Field__c,Static_Text__c FROM Questions__r ORDER BY Display_Order__c ASC NULLS LAST) FROM Requirement_Item__c WHERE Requirement__c in :requirementIds AND Requirement__r.Show_on_Application_Creation__c = false ORDER BY Display_Order__c ASC NULLS LAST]){
			if(!riMap.containsKey(ri.Requirement__c)){
				riMap.put(ri.Requirement__c,new List<Requirement_Item__c>());
			}
			riMap.get(ri.Requirement__c).add(ri);
		}

		//Requirement Responses
		Map<Id,List<Requirement_Response__c>> rrMap = new Map<Id,List<Requirement_Response__c>>();
		for(Requirement_Response__c rr : [SELECT Id, Requirement_Item__r.Requirement__c,Requirement_Item__c,ValueTextEntry__c,HasDocument__c,Application__c,Application__r.Contact__c,External_Email__c,Hashcode__c,Send_Reminder__c, (SELECT Id, Question__c, Question__r.Required__c, ValueText__c, ValueCheckbox__c, ValuePhone__c, ValueEmail__c, ValueCurrency__c, ValueDate__c, ValueDateTime__c, ValueNumber__c, ValuePercent__c, ValueTextArea__c, ValueTextEncrypted__c, ValueLongTextArea__c, ValueURL__c, Street__c, City__c, State__c, Country__c, PostalCode__c FROM Question_Responses__r), (SELECT Id, LinkedEntityId, ContentDocumentId, ContentDocument.Title FROM ContentDocumentLinks) FROM Requirement_Response__c WHERE Requirement_Item__r.Requirement__c in :requirementIds AND Application__c = :applicationId]){
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
		for(Question_Response__c qr : [SELECT Id, Question__r.Requirement_Item__r.Requirement__c,Question__c, Question__r.Required__c, ValueText__c, ValueCheckbox__c, ValuePhone__c, ValueEmail__c, ValueCurrency__c, ValueDate__c, ValueDateTime__c, ValueNumber__c, ValuePercent__c, ValueTextArea__c, ValueTextEncrypted__c, ValueLongTextArea__c, ValueURL__c, Street__c, City__c, State__c, Country__c, PostalCode__c FROM Question_Response__c WHERE Question__c IN :questionItemSet AND Requirement_Response__r.Application__c = :applicationId]){
			if(!qrMap.containsKey(qdReqMap.get(qr.Question__c))){
				qrMap.put(qdReqMap.get(qr.Question__c),new List<Question_Response__c>());
			}
			qrMap.get(qdReqMap.get(qr.Question__c)).add(qr);
		}
		arLst = new List<ApplicationRequirement>();
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
							system.debug(q.response);
                            questionToResponseMap.put(q.response,aqg.response);
                            qResponses.add(q.response);
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
	/*******************************************************************************
    * @description Returns a list of sobjects based on a search term
    * @return List of sobjects based on a search term.
    *******************************************************************************/
	@RemoteAction
    public static List<SObject> lookupSearch(String sObj, String sObjFilter, String term){

        return new ApplicationRequirement.ActionWithSharing().lookupSearchWithSharing(sObj,sObjFilter, term);
    }
}