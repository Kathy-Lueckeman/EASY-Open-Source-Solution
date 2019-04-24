@isTest
private class ApplicationCreateTest {
    
    @isTest
    static void test_application_create() {
        
        Program__c prog1 = [SELECT Id, Applicant_Type__c FROM Program__c WHERE Name = :'test1'];
        Program__c prog2 = [SELECT Id, Hide_Applicant_Type__c FROM Program__c WHERE Name = :'test2'];
        Program__c prog3 = [SELECT Id, Hide_Student_Type__c FROM Program__c WHERE Name = :'test3'];
        Program__c prog4 = [SELECT Id, Hide_Citizenship__c FROM Program__c WHERE Name = :'test4'];
        Program__c prog5 = [SELECT Id FROM Program__c WHERE Name = :'test5'];
        Id termId = [SELECT Id FROM Academic_Term__c WHERE Name = :'test'].Id;
        Intended_Program_Term__c ipt = [SELECT Id, Applicant_Type__c FROM Intended_Program_Term__c WHERE Academic_Term__c = :termId];
        
        Id conId = [SELECT Id FROM Contact WHERE LastName = :'test'].Id;
        PageReference pr = Page.ApplicationCreate;
        pr.getParameters().put('contactId', conId);
        
        Test.startTest();
        
        Test.setCurrentPage(pr);
        ApplicationCreate ac = new ApplicationCreate();
        ac.init();
        ac.save();
        
        Question_Response__c programResponse;
        
        for (ApplicationQuestionGroup g:ac.section.groups) {
            for (ApplicationQuestion q:g.questions) {
                if (q.fieldName != null && q.fieldName.equals('Intended_Program__c'))
                    programResponse = q.response;
                else if (q.fieldName != null && q.fieldName.equals('Intended_Term_of_Entry__c'))
                    q.response.ValueText__c = termId;
                else if (q.label.equals('test1'))
                    q.response.ValueText__c = 'One';
            }
        }
        
        programResponse.ValueText__c = prog1.Id;
        ac.save();
        ac.app.Applicant_Type__c = prog1.Applicant_Type__c;
        ac.save();
        delete [SELECT Id FROM Intended_Program_Term__c];
        ac.save();
        
        programResponse.ValueText__c = prog2.Id;
        ac.app.Applicant_Type__c = prog2.Hide_Applicant_Type__c;
        ac.save();
        ac.app.Applicant_Type__c = null;
        ac.save();
        
        programResponse.ValueText__c = prog3.Id;
        ac.app.Student_Type__c = prog3.Hide_Student_Type__c;
        ac.save();
        ac.app.Student_Type__c = null;
        ac.save();
        
        programResponse.ValueText__c = prog4.Id;
        ac.app.Citizenship__c = prog4.Hide_Citizenship__c;
        ac.save();
        
        programResponse.ValueText__c = prog5.Id;
        ac.save();
        
        Test.stopTest();
    }
    
    @isTest
    static void test_other() {
        
        Application_Control__c appControl = [SELECT Id FROM Application_Control__c WHERE Name = :'test'];
        appControl.Default__c = false;
        appControl.URL_Parameter__c = 'test';
        update appControl;
        
        Id conId = [SELECT Id FROM Contact WHERE LastName = :'test'].Id;
        PageReference pr = Page.ApplicationCreate;
        pr.getParameters().put('contactId', conId);
        
        Test.startTest();
        
        Test.setCurrentPage(pr);
        ApplicationCreate ac = new ApplicationCreate();
        ac.init();
        pr.getParameters().put('at', 'test');
        ac.setup(new ApplicationQuestionGroup(new List<ApplicationQuestion>()), new ApplicationQuestionGroup(new List<ApplicationQuestion>()));
        delete [SELECT Id FROM Requirement__c WHERE Application_Control__c = :appControl.Id];
        appControl.Hide_Term_Program__c = true;
        update appControl;
        ac = new ApplicationCreate();
        ac.init();
        ac.app.Contact__c = null;
        ac.save();
        ac = new ApplicationCreate();
        ac.additionalDataString = 'not json';
        ac.init();
        ac.save();
        
        Test.stopTest();
    }
    
    @testSetup
    static void setup() {
        
        Application_Control__c appControl = ApplicationTestUtilities.createApplicationControl();
        
        Contact con = new Contact(LastName = 'test');
        insert con;
        
        Academic_Term__c at = new Academic_Term__c(Name = 'test', Activate_Application_Date__c = Date.TODAY().addDays(-2), End_Application_Date__c = Date.TODAY().addDays(2));
        insert at;
        
        Program__c p1 = new Program__c(Name = 'test1', Number_of_Applications_Limit__c = 'One Application', Applicant_Type__c = Program__c.Applicant_Type__c.getDescribe().getPicklistValues()[0].getValue());
        Program__c p2 = new Program__c(Name = 'test2', Number_of_Applications_Limit__c = 'One Application Per Term', Hide_Applicant_Type__c = Program__c.Hide_Applicant_Type__c.getDescribe().getPicklistValues()[0].getValue());
        Program__c p3 = new Program__c(Name = 'test3', Number_of_Applications_Limit__c = 'One Application Per Program', Hide_Student_Type__c = Program__c.Hide_Student_Type__c.getDescribe().getPicklistValues()[0].getValue());
        Program__c p4 = new Program__c(Name = 'test4', Hide_Citizenship__c = Program__c.Hide_Citizenship__c.getDescribe().getPicklistValues()[0].getValue());
        Program__c p5 = new Program__c(Name = 'test5');
        insert new List<Program__c>{p1, p2, p3, p4, p5};
        
        Intended_Program_Term__c ipt = new Intended_Program_Term__c(Academic_Term__c = at.Id, Activate_Application_Date__c = Date.TODAY().addDays(-1), End_Application_Date__c = Date.TODAY().addDays(-1), Applicant_Type__c = Intended_Program_Term__c.Applicant_Type__c.getDescribe().getPicklistValues()[0].getValue());
        insert ipt;
        
        Application__c app2 = new Application__c(Contact__c = con.Id, Intended_Term_of_Entry__c = at.Id);
        Application__c app3 = new Application__c(Contact__c = con.Id, Intended_Program__c = p3.Id);
        insert new List<Application__c>{app2, app3};
        
        Requirement__c req1 = new Requirement__c(Application_Control__c = appControl.Id, Active__c = true, Name = 'test1', Show_on_Application_Creation__c = true, Application_Creation_Display_Order__c = 'Before Term/Program Questions');
        Requirement__c req2 = new Requirement__c(Application_Control__c = appControl.Id, Active__c = true, Name = 'test2', Show_on_Application_Creation__c = true, Application_Creation_Display_Order__c = 'After Term/Program Questions');
        insert new List<Requirement__c>{req1, req2};
        
        Requirement_Item__c item1 = new Requirement_Item__c(Requirement__c = req1.Id, Name = 'test1', Active__c = true, RecordTypeId = Schema.SObjectType.Requirement_Item__c.getRecordTypeInfosByName().get('Question Group').getRecordTypeId());
        Requirement_Item__c item2 = new Requirement_Item__c(Requirement__c = req2.Id, Name = 'test2', Active__c = true, RecordTypeId = Schema.SObjectType.Requirement_Item__c.getRecordTypeInfosByName().get('Question Group').getRecordTypeId());
        insert new List<Requirement_Item__c>{item1, item2};
        
        Question__c q1 = new Question__c(Requirement_Item__c = item1.Id, Name = 'test1', Label__c = 'test1', Active__c = true, Picklist_Values__c = 'One\nTwo', RecordTypeId = Schema.SObjectType.Question__c.getRecordTypeInfosByName().get('Picklist').getRecordTypeId());
        Question__c q2 = new Question__c(Requirement_Item__c = item2.Id, Name = 'test2', Label__c = 'test2', Active__c = true, Picklist_Values__c = 'One\nTwo', RecordTypeId = Schema.SObjectType.Question__c.getRecordTypeInfosByName().get('Picklist').getRecordTypeId());
        insert new List<Question__c>{q1, q2};
        
        insert new Question_Dependency__c(Question__c = q2.Id, Controlling_Question__c = q1.Id, Value__c = 'One', RecordTypeId = Schema.SObjectType.Question_Dependency__c.getRecordTypeInfosByName().get('Picklist').getRecordTypeId());
    }
}