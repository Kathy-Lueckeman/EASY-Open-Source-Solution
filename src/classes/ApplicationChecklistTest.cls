@isTest
public class ApplicationChecklistTest {
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
        insert new List<Requirement_Item__c>{riQG,riDU,riRO};
    }
    public static TestMethod void checkSuccesses(){
        Application__c app = [Select Id from Application__c limit 1];
        Contact student = [Select Id from Contact limit 1];

        Map<String,Id> riMap = new Map<String,Id>();
        for(Requirement_Item__c ri : [Select Id,RecordType.DeveloperName from Requirement_Item__c]){
            riMap.put(ri.RecordType.DeveloperName,ri.Id);
        }

        Requirement_Response__c rrQG = new Requirement_Response__c(Application__c = app.Id,Requirement_Item__c = riMap.get('Question_Group'), Viewed__c = true);
        Requirement_Response__c rrDU = new Requirement_Response__c(Application__c = app.Id,Requirement_Item__c = riMap.get('Document_Upload'), Viewed__c = true, ValueTextEntry__c='TEST');
        Requirement_Response__c rrRO = new Requirement_Response__c(Application__c = app.Id,Requirement_Item__c = riMap.get('Related_Object'), Viewed__c = true, Has_Child_Requirement__c=true);
        insert new List<Requirement_Response__c>{rrQG,rrDU,rrRO};
        insert new Question_Response__c(Requirement_Response__c=rrQG.Id);

        PageReference pr = Page.ApplicationChecklist;
        pr.getParameters().put('contactId', student.Id);
        pr.getParameters().put('applicationId', app.Id);
        Test.setCurrentPage(pr);
        ApplicationChecklist ac = new ApplicationChecklist();
        ac.init();
        for(RequirementWrapper rw : ac.reqMap.values()){
            System.assertEquals(rw.reqStatus,true);
        }
    }
    public static TestMethod void checkFailures(){
        Application__c app = [Select Id from Application__c limit 1];
        Contact student = [Select Id from Contact limit 1];

        Map<String,Id> riMap = new Map<String,Id>();
        for(Requirement_Item__c ri : [Select Id,RecordType.DeveloperName from Requirement_Item__c]){
            riMap.put(ri.RecordType.DeveloperName,ri.Id);
        }

        Requirement_Response__c rrQG = new Requirement_Response__c(Application__c=app.Id,Requirement_Item__c=riMap.get('Question_Group'));
        Requirement_Response__c rrDU = new Requirement_Response__c(Application__c=app.Id,Requirement_Item__c=riMap.get('Document_Upload'),HasDocument__c=false);
        Requirement_Response__c rrRO = new Requirement_Response__c(Application__c=app.Id,Requirement_Item__c=riMap.get('Related_Object'),Has_Child_Requirement__c=false);
        insert new List<Requirement_Response__c>{rrQG,rrDU,rrRO};
        insert new Question_Response__c(Requirement_Response__c=rrQG.Id,IsRequired__c=true,IsShown__c=true);

        PageReference pr = Page.ApplicationChecklist;
        pr.getParameters().put('contactId', student.Id);
        pr.getParameters().put('applicationId', app.Id);
        Test.setCurrentPage(pr);
        ApplicationChecklist ac = new ApplicationChecklist();
        ac.init();
        for(RequirementWrapper rw : ac.reqMap.values()){
            System.assertEquals(rw.reqStatus,false);
        }
    }
    public static TestMethod void submitApp(){
        Application__c app = [Select Id from Application__c limit 1];
        Contact student = [Select Id from Contact limit 1];
        Application_Control__c appControl = [Select Id,Withdraw_Status__c,Cancel_Status__c,Submit_Status__c from Application_Control__c];
        Map<String,Id> riMap = new Map<String,Id>();
        for(Requirement_Item__c ri : [Select Id,RecordType.DeveloperName from Requirement_Item__c]){
            riMap.put(ri.RecordType.DeveloperName,ri.Id);
        }

        Requirement_Response__c rrQG = new Requirement_Response__c(Application__c=app.Id,Requirement_Item__c=riMap.get('Question_Group'));
        Requirement_Response__c rrDU = new Requirement_Response__c(Application__c=app.Id,Requirement_Item__c=riMap.get('Document_Upload'),ValueTextEntry__c='TEST');
        Requirement_Response__c rrRO = new Requirement_Response__c(Application__c=app.Id,Requirement_Item__c=riMap.get('Related_Object'),Has_Child_Requirement__c=true);
        insert new List<Requirement_Response__c>{rrQG,rrDU,rrRO};
        insert new Question_Response__c(Requirement_Response__c=rrQG.Id);

        PageReference pr = Page.ApplicationChecklist;
        pr.getParameters().put('contactId', student.Id);
        pr.getParameters().put('applicationId', app.Id);
        pr.getParameters().put('at', 'st');
        Test.setCurrentPage(pr);
        ApplicationChecklist ac = new ApplicationChecklist();
        ac.init();
        ac.submit();
        app = [Select id, Application_Status__c from Application__c where Id=:app.Id limit 1];
        System.assertEquals(app.Application_Status__c,appControl.Submit_Status__c);
        Test.startTest();
        ac.init();
        ac.withdrawApp();
        app = [Select id, Application_Status__c from Application__c where Id=:app.Id limit 1];
        System.assertEquals(app.Application_Status__c,appControl.Withdraw_Status__c);
        Test.stopTest();
    }
    public static TestMethod void cancelApp(){
        Application__c app = [Select Id from Application__c limit 1];
        Contact student = [Select Id from Contact limit 1];
        Application_Control__c appControl = [Select Id,Withdraw_Status__c,Cancel_Status__c,Submit_Status__c from Application_Control__c];
        Map<String,Id> riMap = new Map<String,Id>();
        for(Requirement_Item__c ri : [Select Id,RecordType.DeveloperName from Requirement_Item__c]){
            riMap.put(ri.RecordType.DeveloperName,ri.Id);
        }

        Requirement_Response__c rrQG = new Requirement_Response__c(Application__c=app.Id,Requirement_Item__c=riMap.get('Question_Group'));
        Requirement_Response__c rrDU = new Requirement_Response__c(Application__c=app.Id,Requirement_Item__c=riMap.get('Document_Upload'),ValueTextEntry__c='TEST');
        Requirement_Response__c rrRO = new Requirement_Response__c(Application__c=app.Id,Requirement_Item__c=riMap.get('Related_Object'),Has_Child_Requirement__c=true);
        insert new List<Requirement_Response__c>{rrQG,rrDU,rrRO};
        insert new Question_Response__c(Requirement_Response__c=rrQG.Id);

        PageReference pr = Page.ApplicationChecklist;
        pr.getParameters().put('contactId', student.Id);
        pr.getParameters().put('applicationId', app.Id);
        pr.getParameters().put('at', 'st');
        Test.setCurrentPage(pr);
        ApplicationChecklist ac = new ApplicationChecklist();
        ac.init();
        ac.cancelApp();
        app = [Select id, Application_Status__c from Application__c where Id=:app.Id limit 1];
        System.assertEquals(app.Application_Status__c,appControl.Cancel_Status__c);
    }
}