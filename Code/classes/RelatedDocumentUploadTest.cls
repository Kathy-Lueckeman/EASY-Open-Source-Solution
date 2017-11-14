@isTest
public class RelatedDocumentUploadTest {
	@testSetup
	public static void testSetup(){
		Application_Control__c appControl = new Application_Control__c(Application_Start_Status__c='Started',Active__c=true,Allow_Cancel_From__c='Started',Allow_Withdraw_From__c='Submitted', Allow_Submit_From__c='Started',Cancel_Status__c='Cancelled',Default__c=true,URL_Parameter__c ='st', Submit_Status__c='Submitted',Withdraw_Status__c='Started');
        insert appControl;
		Contact con =  new Contact(LastName='Test');
		insert con;
		insert new ContentVersion(firstPublishLocationId=con.Id,Title='Test',Description='Supporting Document',VersionData=Blob.valueOf('test'),PathOnClient='Test');

	}
	public static TestMethod void docUpload(){
		Contact con = [Select Id from Contact limit 1];
		PageReference pr = Page.RelatedDocumentUpload;
		pr.getParameters().put('Id',con.Id);
		Test.setCurrentPage(pr);
		RelatedDocumentUpload rdu = new RelatedDocumentUpload();
		Application_Control__c appControl = rdu.appControl;
		String objName = rdu.objName;
		rdu.aqg.att.Title = 'Test123';
		rdu.aqg.att.VersionData = Blob.valueOf('test2');
		rdu.submit();
		system.assertEquals(1,[Select count() from ContentDocumentLink Where LinkedEntityId = :con.Id]);
	}
}