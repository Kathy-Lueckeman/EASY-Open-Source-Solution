@isTest
public class ApplicationProgressBarTest {
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
        Application__c app = new Application__c(Contact__c=student.Id,Application_Status__c=Application__c.Application_Status__c.getDescribe().getPicklistValues()[0].getValue());
        insert app;

        Map<String,Id> rtMap = new Map<String,Id>();
        for(RecordType rt : [Select Id,DeveloperName from RecordType where sObjectType = 'Requirement_Item__c']){
            rtMap.put(rt.DeveloperName,rt.Id);
        }

        Requirement__c req = new Requirement__c(Active__c = true,Name='Test Req',Application_Control__c=appControl.Id);
        insert req;
        Requirement_Item__c riQG = new Requirement_Item__c(Requirement__c=req.Id,Name='Test RI QG',Active__c = true,RecordTypeId=rtMap.get('Question_Group'));
        Requirement_Item__c riDU = new Requirement_Item__c(Requirement__c=req.Id,Name='Test RI DU',Active__c = true,RecordTypeId=rtMap.get('Document_Upload'));
        Requirement_Item__c riRO = new Requirement_Item__c(Requirement__c=req.Id,Name='Test RI RO',Active__c = true,RecordTypeId=rtMap.get('Related_Object'));
        Requirement_Item__c riQG2 = new Requirement_Item__c(Requirement__c=req.Id,Name='Test RI QG 2',Active__c = true,RecordTypeId=rtMap.get('Question_Group'), Required__c = app.Application_Status__c);
        Requirement_Item__c riDU2 = new Requirement_Item__c(Requirement__c=req.Id,Name='Test RI DU 2',Active__c = true,RecordTypeId=rtMap.get('Document_Upload'), Required__c = app.Application_Status__c);
        Requirement_Item__c riRO2 = new Requirement_Item__c(Requirement__c=req.Id,Name='Test RI RO 2',Active__c = true,RecordTypeId=rtMap.get('Related_Object'), Required__c = app.Application_Status__c);
        insert new List<Requirement_Item__c>{riQG,riDU,riRO,riQG2,riDU2,riRO2};
    }
    public static TestMethod void check(){
        Application__c app = [Select Id from Application__c limit 1];
        Contact student = [Select Id from Contact limit 1];

        Map<String,Id> riMap = new Map<String,Id>();
        for(Requirement_Item__c ri : [Select Id, Name from Requirement_Item__c]){
            riMap.put(ri.Name, ri.Id);
        }

        Requirement_Response__c rrQG = new Requirement_Response__c(Application__c = app.Id,Requirement_Item__c = riMap.get('Test RI QG'), Viewed__c = true);
        Requirement_Response__c rrDU = new Requirement_Response__c(Application__c = app.Id,Requirement_Item__c = riMap.get('Test RI DU'), Viewed__c = true, ValueTextEntry__c='TEST');
        Requirement_Response__c rrRO = new Requirement_Response__c(Application__c = app.Id,Requirement_Item__c = riMap.get('Test RI RO'), Viewed__c = true, Has_Child_Requirement__c=true);
        Requirement_Response__c rrQG2 = new Requirement_Response__c(Application__c=app.Id,Requirement_Item__c=riMap.get('Test RI QG 2'));
        Requirement_Response__c rrDU2 = new Requirement_Response__c(Application__c=app.Id,Requirement_Item__c=riMap.get('Test RI DU 2'),HasDocument__c=false);
        Requirement_Response__c rrRO2 = new Requirement_Response__c(Application__c=app.Id,Requirement_Item__c=riMap.get('Test RI RO 2'),Has_Child_Requirement__c=false);
        insert new List<Requirement_Response__c>{rrQG,rrDU,rrRO,rrQG2,rrDU2,rrRO2};
        Question_Response__c qr = new Question_Response__c(Requirement_Response__c=rrQG.Id);
        Question_Response__c qr2 = new Question_Response__c(Requirement_Response__c=rrQG2.Id,IsRequired__c=true,IsShown__c=true);
        insert new List<Question_Response__c>{qr, qr2};
        
        Requirement__c req = [SELECT Id FROM Requirement__c WHERE Name = :'Test Req'];
        
        PageReference pr = Page.ApplicationRequirement;
        pr.getParameters().put('contactId', student.Id);
        pr.getParameters().put('applicationId', app.Id);
        pr.getParameters().put('requirementId', req.Id);
        Test.setCurrentPage(pr);
        
        ApplicationRequirement ar = new ApplicationRequirement();
        ar.init();
        ApplicationProgressBar pb = new ApplicationProgressBar(ar);
        pb.start();
        Map<Id,RequirementWrapper> reqMap = pb.reqMap;
        String requirementIdString = pb.requirementIdString;
        Id nextReqId = pb.nextReqId;
        Id prevReqId = pb.prevReqId;
        
    }
}