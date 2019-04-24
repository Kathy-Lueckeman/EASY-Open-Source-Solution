@isTest
public class RelatedObjectReviewTest {
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

        insert new Related_Object_Review__c(Name='Application__c');

        Requirement__c req = new Requirement__c(Name='Test',Active__c=true,Application_Control__c=appControl.Id);
        insert req;

        Map<String,Id> rtMap = new Map<String,Id>();
        for(RecordType rt : [Select Id,DeveloperName from RecordType where sObjectType = 'Question__c']){
            rtMap.put(rt.DeveloperName,rt.Id);
        }

        Map<String,Id> riMap = new Map<String,Id>();
        for(RecordType rt : [Select Id,DeveloperName from RecordType where sObjectType = 'Requirement_Item__c']){
            riMap.put(rt.DeveloperName,rt.Id);
        }

        Requirement_Item__c ri = new Requirement_Item__c(Requirement__c=req.Id,RecordTypeId=riMap.get('Question_Group'),Related_List_Object__c='Application__c');
        insert ri;

        Question__c q1 = new Question__c(Active__c=true,Requirement_Item__c=ri.Id,RecordTypeId=rtMap.get('Reference'),Name='Test',Lookup_Object__c='Program__c',Related_Object_Field__c='Intended_Program__c');
        Question__c q2 = new Question__c(Active__c=true,Requirement_Item__c=ri.Id,RecordTypeId=rtMap.get('Text'),Name='Test',New_Reference_Field__c=true,Related_Object_Field__c='Name');
        insert new List<Question__c>{q1,q2};

        Contact con = new Contact(LastName='Test');
        Application__c app = new Application__c(Contact__c=con.Id,Holding_Name__c='Test Program',Related_Object_JSON__c=JSON.serialize(new Program__c(Name='Test Program')));
        Application__c app2 = new Application__c(Contact__c=con.Id,Holding_Name__c='Test Program2',Related_Object_JSON__c=JSON.serialize(new Program__c(Name='Test Program2')));
        Application__c app3 = new Application__c(Contact__c=con.Id,Holding_Name__c='Test Program3',Related_Object_JSON__c=JSON.serialize(new Program__c(Name='Test Program3')));
        insert new List<Application__c>{app,app2,app3};
    }
    public static TestMethod void relatedObjectReview(){
        Application__c app;
        Application__c app2;
        Application__c app3;
        for(Application__c application : [Select Id,Holding_Name__c from Application__c]){
            if(application.Holding_Name__c == 'Test Program'){
                app = application;
            }else if(application.Holding_Name__c == 'Test Program2'){
                app2 = application;
            }else{
                app3 = application;
            }
        }
        PageReference pr = Page.RelatedObjectReview;
        Test.setCurrentPage(pr);
        RelatedObjectReview rdu = new RelatedObjectReview();
        Application_Control__c appControl = rdu.appControl;

        rdu.createNewRecordType = 'Program__c';
        rdu.createNewRecordId = app.Id;
        rdu.createRec();
        System.assertEquals(1,[Select count() from Program__c]);
        for(RelatedObjectReview.SObjectWrapper obj : rdu.objWrappers.get('Program__c')){
            if(obj.obj.Id == app2.Id){
                obj.existingRecord=RelatedObjectReview.lookupSearch('Program__c','','Test Program')[0].Id;
            }else if(obj.obj.Id == app3.Id){
                obj.relatedSObj.put('Name','Test Program4');
            }
        }
        rdu.createNewRecordType = 'Program__c';
        rdu.saveTable();
        System.debug([Select Id,Name,Holding_Name__c,Related_Object_JSON__c from Application__c where Holding_Name__c != null]);
        System.assertEquals(1,[Select count() from Application__c where Holding_Name__c != null]);
    }
}