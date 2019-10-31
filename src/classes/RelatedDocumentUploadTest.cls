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
        
        Requirement__c r = new Requirement__c(Name = 'test', Application_Control__c = appControl.Id);
        insert r;
        
        insert new Requirement_Item__c(Name = 'test', Requirement__c = r.Id, File_Types__c = 'pdf');
        
        Contact con =  new Contact(LastName='Test');
        insert con;
        insert new ContentVersion(firstPublishLocationId=con.Id,Title='Test',Description='Supporting Document',VersionData=Blob.valueOf('test'),PathOnClient='Test');

    }
    public static TestMethod void docUpload(){
        Contact con = [Select Id from Contact limit 1];
        Requirement_Item__c ri = [SELECT Id FROM Requirement_Item__c WHERE Name = :'test'];
        PageReference pr = Page.RelatedDocumentUpload;
        pr.getParameters().put('Id',con.Id);
        pr.getParameters().put('rId', ri.Id);
        Test.setCurrentPage(pr);
        RelatedDocumentUpload rdu = new RelatedDocumentUpload();
        Application_Control__c appControl = rdu.appControl;
        String objName = rdu.objName;
        rdu.additionalDataString = '{"":{"attData":{"fileName":"test","data":"test,test"}}}';
        rdu.aqg.att.Title = 'Test123';
        rdu.aqg.att.VersionData = Blob.valueOf('test2');
        rdu.submit();
        rdu.additionalDataString = '{"":{"attData":{"fileName":"test.pdf","data":"test,test"}}}';
        rdu.aqg.att.Title = 'Test123.pdf';
        rdu.aqg.att.VersionData = Blob.valueOf('test2');
        rdu.submit();
        system.assertEquals(1,[Select count() from ContentDocumentLink Where LinkedEntityId = :con.Id]);
    }
}