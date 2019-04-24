@isTest
public class ApplicationReviewTest {
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

        Requirement__c req = new Requirement__c(Active__c = true,Name='Test Req',Application_Control__c=appControl.Id);
        insert req;
        Requirement_Item__c riQG = new Requirement_Item__c(Requirement__c=req.Id,Name='Test RI',Active__c = true,RecordTypeId=rtMapRI.get('Question_Group'));
        Requirement_Item__c riDU = new Requirement_Item__c(Requirement__c=req.Id,Name='Test RI',Active__c = true,RecordTypeId=rtMapRI.get('Document_Upload'));
        Requirement_Item__c riRO = new Requirement_Item__c(Requirement__c=req.Id,Name='Test RI',Active__c = true,RecordTypeId=rtMapRI.get('Related_Object'),Related_List_Object__c='Application__c',Related_List_Object_Master__c='Contact',Related_List_Object_Master_Field__c='Contact__c');
        insert new List<Requirement_Item__c>{riQG,riDU,riRO};

        Requirement__c req2 = new Requirement__c(Active__c = true,Name='Test Req 2',Application_Control__c=appControl.Id);
        insert req2;
        Requirement_Item__c riQG2 = new Requirement_Item__c(Requirement__c=req2.Id,Name='Test RI',Active__c = true,RecordTypeId=rtMapRI.get('Question_Group'));
        insert riQG2;

        Question__c q1 = new Question__c(Active__c = true,RecordTypeId=rtMap.get('Text'),Name='Test',Label__c='Test',Requirement_Item__c=riQG.Id);
        Question__c q2 = new Question__c(Active__c = true,RecordTypeId=rtMap.get('Text'),Name='Test2',Label__c='Test2',Requirement_Item__c=riQG2.Id);
        Question__c q3 = new Question__c(Active__c = true,RecordTypeId=rtMap.get('Text'),Name='Test3',Label__c='Test3',Requirement_Item__c=riQG.Id);
        insert new List<Question__c>{q1,q2,q3};

        Question_Dependency__c qd1 = new Question_Dependency__c(Question__c=q1.Id,Controlling_Question__c=q2.Id,Value__c='Test');
        Question_Dependency__c qd2 = new Question_Dependency__c(Question__c=q1.Id,Controlling_Question__c=q3.Id,Value__c='Test;Test2;Test3',RecordTypeId=rtMapQD.get('Multi_Select_Picklist'));
        insert new List<Question_Dependency__c>{qd1,qd2};


        Requirement_Response__c rrQG = new Requirement_Response__c(Application__c=app.Id,Requirement_Item__c=riQG.Id);
        Requirement_Response__c rrDU = new Requirement_Response__c(Application__c=app.Id,Requirement_Item__c=riDU.Id,HasDocument__c=true);
        Requirement_Response__c rrRO = new Requirement_Response__c(Application__c=app.Id,Requirement_Item__c=riRO.Id,Has_Child_Requirement__c=true);
        insert new List<Requirement_Response__c>{rrQG,rrDU,rrRO};
        insert new Question_Response__c(Requirement_Response__c=rrQG.Id,Question__c=q2.Id);
    }
    public static TestMethod void appReview(){
        Application__c app = [Select Id from Application__c limit 1];
        Contact student = [Select Id from Contact limit 1];

        PageReference pr = Page.ApplicationReview;
        pr.getParameters().put('contactId', student.Id);
        pr.getParameters().put('applicationId', app.Id);
        Test.setCurrentPage(pr);
        ApplicationReview ar = new ApplicationReview();
        ar.init();
        System.assertEquals(1,[Select count() from Application_Review__c]);
        ar.review.Decision_Recommendation__c = 'Accepted';
        ar.submit();
    }
}