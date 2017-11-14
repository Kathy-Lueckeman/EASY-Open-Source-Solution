@isTest
public class ApplicationPortalTest {
	@testSetup
	public static void testSetup(){
		Application_Control__c appControl = new Application_Control__c(Application_Start_Status__c='Started',Active__c=true,Allow_Cancel_From__c='Started',Allow_Withdraw_From__c='Submitted', Allow_Submit_From__c='Started',Cancel_Status__c='Cancelled',Default__c=true,URL_Parameter__c ='st', Submit_Status__c='Submitted',Withdraw_Status__c='Started');
        insert appControl;
		Contact student = new Contact(LastName='TestStudent');
		insert student;
		Application__c app = new Application__c(Contact__c=student.Id);
		insert app;
	}
	public static TestMethod void loadApps(){
		Contact student = [Select Id from Contact limit 1];

		PageReference pr = Page.ApplicationPortal;
		pr.getParameters().put('contactId', student.Id);
		Test.setCurrentPage(pr);
		ApplicationPortal ap = new ApplicationPortal();
		Application_Control__c appControl = ap.appControl;
		System.assertNotEquals(null,appControl);
		System.assertEquals(1,ap.apps.size());
	}
}