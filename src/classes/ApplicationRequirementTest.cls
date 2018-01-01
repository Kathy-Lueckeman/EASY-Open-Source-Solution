@isTest
public class ApplicationRequirementTest {
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
        
		Account acc = new Account(Name='NewAcc');
		insert acc;
		Contact student = new Contact(LastName='TestStudent');
		insert student;
		Application__c app = new Application__c(Contact__c=student.Id,Application_Status__c=Application__c.Application_Status__c.getDescribe().getPicklistValues()[0].getValue());
		insert app;

		Map<String,Id> rtMap = new Map<String,Id>();
		for(RecordType rt : [Select Id,DeveloperName from RecordType where sObjectType = 'Requirement_Item__c']){
			rtMap.put(rt.DeveloperName,rt.Id);
		}
		
		Program__c ip = new Program__c(Name='Test');
		insert ip;

		Requirement__c req = new Requirement__c(Active__c = true,Name='Test Req',Application_Control__c=appControl.Id);
		insert req;
		Requirement_Item__c riQG = new Requirement_Item__c(Requirement__c=req.Id,Name='Test RI',Active__c = true,RecordTypeId=rtMap.get('Question_Group'));
		Requirement_Item__c riDU = new Requirement_Item__c(Requirement__c=req.Id,Name='Test RI',Active__c = true,RecordTypeId=rtMap.get('Document_Upload'));
		Requirement_Item__c riRO = new Requirement_Item__c(Requirement__c=req.Id,Name='Test RI',Active__c = true,RecordTypeId=rtMap.get('Related_Object'),Related_List_Object__c='Application__c',Related_List_Object_Master__c='Contact',Related_List_Object_Master_Field__c='Contact__c', Holding_Record_Id__c=ip.Id);
		insert new List<Requirement_Item__c>{riQG,riDU,riRO};

	}
	public static TestMethod void standardTest(){
		Application__c app = [Select Id from Application__c limit 1];
		Contact student = [Select Id from Contact limit 1];

		Requirement__c req = [Select Id from Requirement__c limit 1];

		Map<String,Id> riMap = new Map<String,Id>();
		for(Requirement_Item__c ri : [Select Id,RecordType.DeveloperName from Requirement_Item__c]){
			riMap.put(ri.RecordType.DeveloperName,ri.Id);
		}

		Requirement_Response__c rrQG = new Requirement_Response__c(Application__c=app.Id,Requirement_Item__c=riMap.get('Question_Group'));
		Requirement_Response__c rrDU = new Requirement_Response__c(Application__c=app.Id,Requirement_Item__c=riMap.get('Document_Upload'),HasDocument__c=true);
		Requirement_Response__c rrRO = new Requirement_Response__c(Application__c=app.Id,Requirement_Item__c=riMap.get('Related_Object'),Has_Child_Requirement__c=true);
		insert new List<Requirement_Response__c>{rrQG,rrDU,rrRO};
		insert new Question_Response__c(Requirement_Response__c=rrQG.Id);

		ContentVersion cv = new ContentVersion(Title='Test',PathOnClient='Test',VersionData=Blob.valueOf('test'));
		insert cv;
		cv = [Select Id,ContentDocumentId from ContentVersion Where id=:cv.Id];
		insert new ContentDocumentLink(LinkedEntityId= rrDU.Id,ContentDocumentId=cv.ContentDocumentId,Visibility='AllUsers', ShareType='I');

		PageReference pr = Page.ApplicationRequirement;
		pr.getParameters().put('contactId', student.Id);
		pr.getParameters().put('applicationId', app.Id);
		pr.getParameters().put('requirementId', req.Id);
		Test.setCurrentPage(pr);
		ApplicationRequirement ac = new ApplicationRequirement();
		ac.init();
		System.assertEquals(ac.title,'Test Req');
		ac.submit();
	}
	public static TestMethod void testDocumentUpload(){
		Application__c app = [Select Id from Application__c limit 1];
		Contact student = [Select Id from Contact limit 1];

		Requirement__c req = [Select Id from Requirement__c limit 1];

		Map<String,Id> riMap = new Map<String,Id>();
		for(Requirement_Item__c ri : [Select Id,RecordType.DeveloperName from Requirement_Item__c]){
			riMap.put(ri.RecordType.DeveloperName,ri.Id);
		}

		Requirement_Response__c rrDU = new Requirement_Response__c(Application__c=app.Id,Requirement_Item__c=riMap.get('Document_Upload'));
		insert new List<Requirement_Response__c>{rrDU};

		PageReference pr = Page.ApplicationRequirement;
		pr.getParameters().put('contactId', student.Id);
		pr.getParameters().put('applicationId', app.Id);
		pr.getParameters().put('requirementId', req.Id);
		Test.setCurrentPage(pr);
		ApplicationRequirement ac = new ApplicationRequirement();
		ac.init();
		System.assertEquals(ac.title,'Test Req');
		for(ApplicationQuestionGroup agq : ac.section.groups){
			if(agq.documentUpload == true){
				agq.att.Title = 'Test';
				agq.att.VersionData = Blob.valueOf('test');
			}
		}
		ac.submit();
		System.assertEquals(1,[Select count() from ContentDocumentLink where LinkedEntityId=:rrDU.Id]);
		Test.startTest();
			ac = new ApplicationRequirement();
			ac.init();
			for(ApplicationQuestionGroup agq : ac.section.groups){
				if(agq.documentUpload == true){
					agq.response.ValueTextEntry__c = 'Test';
				}
			}
			ac.submit();
			System.assertEquals(1,[Select count() from ContentDocumentLink where LinkedEntityId=:rrDU.Id]);
			System.assertEquals('Test',[Select Id,ValueTextEntry__c from Requirement_Response__c where Id=:rrDU.Id].ValueTextEntry__c);

		Test.stopTest();
	}
	public static TestMethod void testExternal(){
		Application__c app = [Select Id from Application__c limit 1];
		Contact student = [Select Id from Contact limit 1];

		Requirement__c req = [Select Id from Requirement__c limit 1];

		Map<String,Id> rtMap = new Map<String,Id>();
		for(RecordType rt : [Select Id,DeveloperName from RecordType where sObjectType = 'Question__c']){
			rtMap.put(rt.DeveloperName,rt.Id);
		}

		Map<String,Id> riMap = new Map<String,Id>();
		for(Requirement_Item__c ri : [Select Id,RecordType.DeveloperName from Requirement_Item__c]){
			riMap.put(ri.RecordType.DeveloperName,ri.Id);
		}
		Requirement_Item__c riQG = new Requirement_Item__c(Id=riMap.get('Question_Group'));
		Question__c q = new Question__c(RecordTypeId=rtMap.get('Email'),External_Email_Field__c=true,Name='Email',Label__c='Email',Requirement_Item__c=riQG.Id);
		insert q;
		Requirement_Item__c riDU = new Requirement_Item__c(Id=riMap.get('Document_Upload'),Internal_Requirement_Item__c=riQG.Id);
		update riDU;
		Requirement_Response__c rrDU = new Requirement_Response__c(Application__c=app.Id,Requirement_Item__c=riQG.Id,Hashcode__c='1234');
		insert new List<Requirement_Response__c>{rrDU};

		PageReference pr = Page.ApplicationRequirement;
		pr.getParameters().put('contactId', student.Id);
		pr.getParameters().put('applicationId', app.Id);
		pr.getParameters().put('requirementId', req.Id);
		Test.setCurrentPage(pr);
		ApplicationRequirement ac = new ApplicationRequirement();
		ac.init();
		for(ApplicationQuestionGroup agq : ac.section.groups){
			if(agq.documentUpload == true){
				System.assertEquals(null,agq.questions);
			}
		}
	}
	public static TestMethod void testRelatedObject(){
		Application__c app = [Select Id from Application__c limit 1];
		Contact student = [Select Id from Contact limit 1];
		Requirement__c req = [Select Id from Requirement__c limit 1];

		Map<String,Id> rtMap = new Map<String,Id>();
		for(RecordType rt : [Select Id,DeveloperName from RecordType where sObjectType = 'Question__c']){
			rtMap.put(rt.DeveloperName,rt.Id);
		}

		Map<String,Id> riMap = new Map<String,Id>();
		for(Requirement_Item__c ri : [Select Id,RecordType.DeveloperName from Requirement_Item__c]){
			riMap.put(ri.RecordType.DeveloperName,ri.Id);
		}
		Question__c q1 = new Question__c(Active__c=true,RecordTypeId=rtMap.get('Reference'),Related_Object_Field__c='Intended_Program__c',Required__c='Started',Lookup_Object__c='Program__c',Requirement_Item__c=riMap.get('Related_Object'));
		Question__c q2 = new Question__c(Active__c=true,RecordTypeId=rtMap.get('Checkbox'),Related_Object_Field__c='User_Created__c',Hardcoded_Value__c='true',Requirement_Item__c=riMap.get('Related_Object'));
		Question__c q3 = new Question__c(Active__c=true,RecordTypeId=rtMap.get('Text'),Related_Object_Field__c='Intended_Program__c',New_Reference_Field__c=true,Requirement_Item__c=riMap.get('Related_Object'));
		insert new List<Question__c>{q1,q2,q3};

		Requirement_Response__c rrRO = new Requirement_Response__c(Application__c=app.Id,Requirement_Item__c=riMap.get('Related_Object'),Has_Child_Requirement__c=true);
		insert new List<Requirement_Response__c>{rrRO};
	
		PageReference pr = Page.ApplicationRequirement;
		pr.getParameters().put('contactId', student.Id);
		pr.getParameters().put('applicationId', app.Id);
		pr.getParameters().put('requirementId', req.Id);
		Test.setCurrentPage(pr);
		ApplicationRequirement ac = new ApplicationRequirement();
		ac.init();
		System.assertEquals(ac.title,'Test Req');
		for(ApplicationQuestionGroup agq : ac.section.groups){
			if(agq.relatedObject == true){
				agq.newRow();
				agq.selectedRelatedId = 'new0';
				agq.enableEditMode();
				agq.selectedRelatedId = 'new0';
				agq.enableConfirmMode();
				agq.selectedRelatedId = 'new0';
				agq.enableViewMode();
				agq.selectedRelatedId = 'new0';
				agq.newRow();
				agq.selectedRelatedId = 'new1';
				agq.enableEditMode();
				Map<String,ApplicationQuestionGroup.SObjectWrapper> relatedObjectsMap = agq.relatedObjectsMap;
				ApplicationQuestionGroup.SObjectWrapper objWrapper = relatedObjectsMap.get('new1');
				SObject obj = objWrapper.obj;
				obj.put('Contact__c',[Select Id from Contact limit 1].Id);
				agq.selectedRelatedId = 'new1';
				agq.enableConfirmMode();
				agq.selectedRelatedId = 'new1';
				agq.enableEditMode();
				agq.newReferenceObjectSelectedWrapperName = 'Test Program';
				agq.createNewReferenceObject();
				agq.newReferenceObjectSelectedWrapper = 'new1';
				agq.addNewReferenceObject();
				agq.selectedRelatedId = 'new1';
				agq.enableViewMode();
				agq.selectedRelatedId = 'new1';
			}
		}
		

		ac.submit();
		// System.assertEquals(1,[Select count() from Enrollment_History__c]);
	}
	public static TestMethod void testMisc(){
		Application__c app = [Select Id from Application__c limit 1];
		Contact student = [Select Id from Contact limit 1];

		Requirement__c req = [Select Id from Requirement__c limit 1];

		Map<String,Id> riMap = new Map<String,Id>();
		for(Requirement_Item__c ri : [Select Id,RecordType.DeveloperName from Requirement_Item__c]){
			riMap.put(ri.RecordType.DeveloperName,ri.Id);
		}
		Map<String,Id> rtMap = new Map<String,Id>();
		for(RecordType rt : [Select Id,DeveloperName from RecordType where sObjectType = 'Question__c']){
			rtMap.put(rt.DeveloperName,rt.Id);
		}
		Question__c q1 = new Question__c(Active__c = true,RecordTypeId=rtMap.get('Text'),Name='Test',Label__c='Test',Requirement_Item__c=riMap.get('Question_Group'));
		insert q1;
		PageReference pr = Page.ApplicationRequirement;
		pr.getParameters().put('contactId', student.Id);
		pr.getParameters().put('applicationId', app.Id);
		pr.getParameters().put('requirementId', req.Id);
		Test.setCurrentPage(pr);
		ApplicationRequirement ac = new ApplicationRequirement();
		ac.init();
		for(ApplicationQuestionGroup agq : ac.section.groups){
			if(agq.questionGroup == true){
				agq.questions[0].getDatetimeValue();
				agq.questions[0].setDatetimeValue(Datetime.now());
				agq.questions[0].getDateValue();
				agq.questions[0].setDateValue(Date.today());
				agq.questions[0].getMultiPicklistValues();
				agq.questions[0].setMultiPicklistValues(new List<String>{'t1','t2','t3'});
			}
		}
	}
	public static TestMethod void testDependentQuestions(){
		Application__c app = [Select Id from Application__c limit 1];
		Contact student = [Select Id from Contact limit 1];

		Requirement__c req = [Select Id from Requirement__c limit 1];

		Map<String,Id> rtMap = new Map<String,Id>();
		for(RecordType rt : [Select Id,DeveloperName from RecordType where sObjectType = 'Question__c']){
			rtMap.put(rt.DeveloperName,rt.Id);
		}
		Map<String,Id> rtMapQD = new Map<String,Id>();
		for(RecordType rt : [Select Id,DeveloperName from RecordType where sObjectType = 'Question_Dependency__c']){
			rtMapQD.put(rt.DeveloperName,rt.Id);
		}
		Map<String,Id> rtMapRI = new Map<String,Id>();
		for(RecordType rt : [Select Id,DeveloperName from RecordType where sObjectType = 'Requirement_Item__c']){
			rtMapRI.put(rt.DeveloperName,rt.Id);
		}
		Map<String,Id> riMap = new Map<String,Id>();
		for(Requirement_Item__c ri : [Select Id,RecordType.DeveloperName from Requirement_Item__c]){
			riMap.put(ri.RecordType.DeveloperName,ri.Id);
		}
		Requirement__c req2 = new Requirement__c(Application_Control__c=[Select Id from Application_Control__c limit 1].Id,Active__c = true,Name='Test Req 2');
		insert req2;
		Requirement_Item__c riQG2 = new Requirement_Item__c(Requirement__c=req2.Id,Name='Test RI',Active__c = true,RecordTypeId=rtMapRI.get('Question_Group'));
		insert riQG2;
		Question__c q1 = new Question__c(Active__c = true,RecordTypeId=rtMap.get('Text'),Name='Test',Label__c='Test',Requirement_Item__c=riMap.get('Question_Group'));
		Question__c q2 = new Question__c(Active__c = true,RecordTypeId=rtMap.get('Text'),Name='Test2',Label__c='Test2',Requirement_Item__c=riQG2.Id);
		Question__c q3 = new Question__c(Active__c = true,RecordTypeId=rtMap.get('Text'),Name='Test3',Label__c='Test3',Requirement_Item__c=riMap.get('Question_Group'));
		insert new List<Question__c>{q1,q2,q3};

		Question_Dependency__c qd1 = new Question_Dependency__c(Question__c=q1.Id,Controlling_Question__c=q2.Id,Value__c='Test', RecordTypeId=rtMapQD.get('Picklist'));
		Question_Dependency__c qd2 = new Question_Dependency__c(Question__c=q1.Id,Controlling_Question__c=q3.Id,Value__c='Test;Test2;Test3',RecordTypeId=rtMapQD.get('Multi_Select_Picklist'));
		insert new List<Question_Dependency__c>{qd1,qd2};

		Requirement_Response__c rrQG = new Requirement_Response__c(Application__c=app.Id,Requirement_Item__c=riMap.get('Question_Group'));
		insert rrQG;
		Question_Response__c qr1 = new Question_Response__c(ValueText__c='Test',Question__c=q2.Id,Requirement_Response__c=rrQG.Id);
		Question_Response__c qr2 = new Question_Response__c(ValueText__c='Test',Question__c=q3.Id,Requirement_Response__c=rrQG.Id);
		insert new List<Question_Response__c>{qr1,qr2};


		PageReference pr = Page.ApplicationRequirement;
		pr.getParameters().put('contactId', student.Id);
		pr.getParameters().put('applicationId', app.Id);
		pr.getParameters().put('requirementId', req.Id);
		Test.setCurrentPage(pr);
		ApplicationRequirement ac = new ApplicationRequirement();
		ac.init();
		for(ApplicationQuestionGroup sectionGroup : ac.section.groups){
			if(sectionGroup.questionGroup == true && sectionGroup.item.Id != riQG2.Id){
				System.assert(sectionGroup.questions[0].dquestions != null && sectionGroup.questions[0].dquestions.size()==2);
				System.assertEquals(true,sectionGroup.questions[0].showQuestion);
			}
		}
		ac.submit();
		Test.startTest();
			q1.Dependency_Logic__c = 'OR';
			update q1;
			ac = new ApplicationRequirement();
			ac.init();
			ac.submit();
		Test.stopTest();
	}
	public static TestMethod void testQuestionGroup(){
		Application__c app = [Select Id from Application__c limit 1];
		Contact student = [Select Id from Contact limit 1];

		Requirement__c req = [Select Id from Requirement__c limit 1];

		Map<String,Id> rtMap = new Map<String,Id>();
		for(RecordType rt : [Select Id,DeveloperName from RecordType where sObjectType = 'Question__c']){
			rtMap.put(rt.DeveloperName,rt.Id);
		}
		Map<String,Id> rtMapRI = new Map<String,Id>();
		for(RecordType rt : [Select Id,DeveloperName from RecordType where sObjectType = 'Requirement_Item__c']){
			rtMapRI.put(rt.DeveloperName,rt.Id);
		}
		Map<String,Id> riMap = new Map<String,Id>();
		for(Requirement_Item__c ri : [Select Id,RecordType.DeveloperName from Requirement_Item__c]){
			riMap.put(ri.RecordType.DeveloperName,ri.Id);
		}
		Question__c q1 = new Question__c(Active__c = true,RecordTypeId=rtMap.get('Picklist'),Picklist_Values__c='test1\ntest2\ntest3',Name='Test',Label__c='Test',Requirement_Item__c=riMap.get('Question_Group'));
		insert new List<Question__c>{q1};


		PageReference pr = Page.ApplicationRequirement;
		pr.getParameters().put('contactId', student.Id);
		pr.getParameters().put('applicationId', app.Id);
		pr.getParameters().put('requirementId', req.Id);
		Test.setCurrentPage(pr);
		ApplicationRequirement ac = new ApplicationRequirement();
		ac.init();
		ac.submit();
	}
	public static TestMethod void testLookupSearch(){
		Test.startTest();
			insert new Account(Name='Example Account');
		Test.stopTest();
		List<SObject> results = ApplicationRequirement.lookupSearch('Account',null,'Example');
		system.debug(results);
		System.assertEquals(1,results.size());
	}
}