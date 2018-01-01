@isTest
public class ApplicationRegistrationTest {
	@testSetup
	public static void testSetup(){
        Application_Control__c appControl = new Application_Control__c(
            Application_Start_Status__c=Application_Control__c.Application_Start_Status__c.getDescribe().getPicklistValues()[0].getValue(),
            Active__c=true,
            Allow_Cancel_From__c=Application_Control__c.Allow_Cancel_From__c.getDescribe().getPicklistValues()[0].getValue(),
            Allow_Withdraw_From__c=Application_Control__c.Allow_Withdraw_From__c.getDescribe().getPicklistValues()[0].getValue(),
            Allow_Submit_From__c=Application_Control__c.Allow_Submit_From__c.getDescribe().getPicklistValues()[0].getValue(),
            Cancel_Status__c=Application_Control__c.Cancel_Status__c.getDescribe().getPicklistValues()[0].getValue(),
            Default__c=true,
            URL_Parameter__c ='st',
            Submit_Status__c=Application_Control__c.Submit_Status__c.getDescribe().getPicklistValues()[0].getValue(),
            Withdraw_Status__c=Application_Control__c.Withdraw_Status__c.getDescribe().getPicklistValues()[0].getValue()
        );
        insert appControl;
        
		Account acc = new Account(Name='Test School');
		insert acc;

		insert new Program__c(Name='Test',Active__c=true);


		Map<String,Id> rtMap = new Map<String,Id>();
		for(RecordType rt : [Select Id,DeveloperName from RecordType where sObjectType = 'Requirement_Item__c']){
			rtMap.put(rt.DeveloperName,rt.Id);
		}

		Map<String,Id> rtQMap = new Map<String,Id>();
		for(RecordType rt : [Select Id,DeveloperName from RecordType where sObjectType = 'Question__c']){
			rtQMap.put(rt.DeveloperName,rt.Id);
		}

		Requirement__c req = new Requirement__c(Application_Control__c=appControl.Id,Active__c = true,Name='Test Req',Show_on_Application_Creation__c=true);
		insert req;
		Requirement_Item__c riQG = new Requirement_Item__c(Requirement__c=req.Id,Name='Test RI',Active__c = true,RecordTypeId=rtMap.get('Question_Group'));
		insert riQG;
		insert new Question__c(Requirement_Item__c=riQG.Id,Name='Test',RecordTypeId=rtQMap.get('Text'));

		insert new Program__c(Name='Test');
		insert new Academic_Term__c(Activate_Application_Date__c=Date.today().addDays(-2),End_Application_Date__c=Date.today().addDays(2));
	}
	public static TestMethod void testCreate(){
		Account acc = [Select Id from Account limit 1];
		Program__c ap = [Select id from Program__c limit 1];
		Academic_Term__c at = [Select id from Academic_Term__c limit 1];

		PageReference pr = Page.ApplicationRegistration;
		Test.setCurrentPage(pr);
		ApplicationRegistration ac = new ApplicationRegistration();

		for(ApplicationQuestionGroup aqg : ac.section.groups){
            for(ApplicationQuestion question : aqg.questions){
				List<SelectOption> options = question.options;
				Boolean isShown = question.showQuestion;
				
                if(String.isNotBlank(question.fieldName) && question.response != null){
					if(question.fieldType == 'Address'){
						question.response.Street__c = 'test street';
						question.response.City__c = 'test city';
						if(ApplicationQuestion.stateAndCountryPicklistEnabled == true){
							question.con.put('MailingCountryCode', 'US');
							question.con.put('MailingStateCode', 'AL');
						}else{
							question.con.put('MailingCountry', 'US');
							question.con.put('MailingState', 'AL');
						}
						question.response.PostalCode__c = '12345';
					}else if(question.fieldType == 'Checkbox'){
						question.response.ValueCheckbox__c = true;
					}else if(question.fieldType == 'Currency'){
						question.response.ValueCurrency__c = 100.23;
					}else if(question.fieldType == 'Date'){
						question.response.ValueDate__c = Date.today();
					}else if(question.fieldType == 'DateTime'){
						question.response.ValueDateTime__c = Datetime.now();
					}else if(question.fieldType == 'Decimal' || question.fieldType == 'Integer' || question.fieldType == 'Number'){
						question.response.ValueNumber__c = 10;
					}else if(question.fieldType == 'Email'){
						question.response.ValueEmail__c = 'abctest123@example.com';
					}else if(question.fieldType == 'TextEncrypted'){
						question.response.ValueTextEncrypted__c = '111111111';
					}else if(question.fieldType == 'MultiPicklist'){
						question.multiPicklistValues = new List<String>();
						if(question.options != null && question.options.size()>0){
							for(SelectOption so : question.options){
								question.multiPicklistValues.add(so.getValue());
							}
						}
					}else if(question.fieldType == 'Percent'){
						question.response.ValuePercent__c = 0.50;
					}else if(question.fieldType == 'Phone'){
						question.response.ValuePhone__c = '2121231234';
					}else if(question.fieldType == 'Picklist' || question.fieldType == 'Reference'){
						question.response.ValueText__c = 'Domestic';
						if(question.options != null && question.options.size()>0){
							question.response.ValueText__c = question.options[0].getValue();
						}
						if(question.options != null && question.options.size()>1){
							question.response.ValueText__c = question.options[1].getValue();
						}
					}else if(question.fieldType == 'Text'){
						question.response.ValueText__c = 'test text';
					}else if(question.fieldType == 'TextArea'){
						question.response.ValueTextArea__c = 'test text area';
					}else if(question.fieldType == 'LongTextArea'){
						question.response.ValueLongTextArea__c = 'test text area';
					}else if(question.fieldType == 'TextArea'){
						question.response.ValueURL__c = 'http://example.com';
					}
				}
				if(question.fieldName == 'Intended_Program__c'){
					question.response.ValueText__c = String.valueOf(ap.Id);
				}
				if(question.fieldName == 'Intended_Term_of_Entry__c'){
					question.response.ValueText__c = String.valueOf(at.Id);
				}
				if(String.isBlank(question.fieldName)){
					question.response.ValueText__c = 'Test';
				}
				if(question.fieldName == 'Educational_Background__c'){
					question.response.ValueText__c = 'Freshman';
				}
			}
			if(aqg.relatedObject == true && aqg.item != null){
				aqg.newRow();
				for(ApplicationQuestionGroup.SObjectWrapper sObjW : aqg.relatedObjects){
					sObjW.obj.put('School__c',acc.Id);
					sObjW.checkValid();
				}
			}
		}

		PageReference retPR = ac.submit();
	}
	public static TestMethod void testLookupSearch(){
		List<SObject> results = ApplicationRegistration.lookupSearch('Account',null,'Test');
		System.assertEquals(1,results.size());
	}
}