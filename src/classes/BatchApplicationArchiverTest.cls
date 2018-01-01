@isTest
public class BatchApplicationArchiverTest {
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
		Application__c app = new Application__c(Contact__c=student.Id);
		insert app;
        insert new Application_Review__c(Application__c = app.Id);
        Test.setCreatedDate(app.Id,Date.today().addYears(-3));
		Map<String,Id> rtMap = new Map<String,Id>();
		for(RecordType rt : [Select Id,DeveloperName from RecordType where sObjectType = 'Requirement_Item__c']){
			rtMap.put(rt.DeveloperName,rt.Id);
		}

		Requirement__c req = new Requirement__c(Active__c = true,Name='Test Req',Application_Control__c=appControl.Id);
		insert req;
		Requirement_Item__c riQG = new Requirement_Item__c(Requirement__c=req.Id,Name='Test RI',Active__c = true,RecordTypeId=rtMap.get('Question_Group'));
		insert riQG;
        Question__c q = new Question__c(Requirement_Item__c=riQG.Id);
        insert q;

        Requirement_Response__c rr = new Requirement_Response__c(Application__c=app.Id,Requirement_Item__c=riQG.Id);
        insert rr;
        insert new Question_Response__c(Requirement_Response__c=rr.Id,Question__c=q.Id);

	}
	public static TestMethod void standardTest(){
        Application__c app = [Select Id from Application__c limit 1];
        Test.startTest();
            Database.executeBatch(new BatchApplicationArchiver());
        Test.stopTest();
        System.assertEquals(1,[Select count() from ContentDocumentLink Where LinkedEntityId = :app.Id]);
        System.assertEquals(0,[Select count() from Requirement_Response__c]);
        System.assertEquals(0,[Select count() from Question_Response__c]);
        System.assertEquals(0,[Select count() from Application_Review__c]);
    }
}