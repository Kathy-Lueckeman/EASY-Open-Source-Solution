@isTest
public class RelatedDocumentUploadTest {
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
        rdu.additionalDataString = '{"":{"attData":{"fileName":"test","data":"test"}}}';
        Application_Control__c appControl = rdu.appControl;
        String objName = rdu.objName;
        rdu.aqg.att.Title = 'Test123';
        rdu.aqg.att.VersionData = Blob.valueOf('test2');
        rdu.submit();
        system.assertEquals(1,[Select count() from ContentDocumentLink Where LinkedEntityId = :con.Id]);
    }
}