@isTest
public class ApplicationPortalTest {
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
        
        Contact student = new Contact(LastName='TestStudent');
        insert student;
        Application__c app = new Application__c(Contact__c=student.Id, Application_Control__c = appControl.Id);
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