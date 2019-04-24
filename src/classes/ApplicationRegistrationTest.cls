@isTest
private class ApplicationRegistrationTest {
    
    @isTest
    static void test_registration() {
        
        Id progId = [SELECT Id FROM Program__c WHERE Name = :'test'].Id;
        Id termId = [SELECT Id FROM Academic_Term__c WHERE Name = :'test'].Id;
        
        Application_Control__c appControl = [SELECT Id FROM Application_Control__c WHERE Name = :'test'];
        appControl.Default__c = false;
        appControl.URL_Parameter__c = 'test';
        update appControl;
        
        PageReference pr = Page.ApplicationRegistration;
        
        Test.startTest();
        
        ApplicationRegistration.lookupSearch('Program__c', 'Name != \'not_test\'', 'Name', 'test');
        
        Test.setCurrentPage(pr);
        ApplicationRegistration ar = new ApplicationRegistration();
        pr.getParameters().put('at', 'test');
        ar = new ApplicationRegistration();
        ar.submit();
        
        for (ApplicationQuestionGroup g:ar.appCreate.section.groups) {
            for (ApplicationQuestion q:g.questions) {
                if (q.fieldName != null && q.fieldName.equals('Intended_Program__c'))
                    q.response.ValueText__c = progId;
                else if (q.fieldName != null && q.fieldName.equals('Intended_Term_of_Entry__c'))
                    q.response.ValueText__c = termId;
                else if (q.fieldName != null && q.fieldName.equals('First_Name__c') && q.label.equals('First Name'))
                    q.response.ValueText__c = 'test';
                else if (q.fieldName != null && q.fieldName.equals('Last_Name__c') && q.label.equals('Last Name'))
                    q.response.ValueText__c = 'test';
                else if (q.fieldName != null && q.fieldName.equals('Email__c'))
                    q.response.ValueText__c = 'ApplicationRegistrationTest@test.com';
                else if (q.fieldName != null && q.fieldName.equals('First_Name__c'))
                    q.response.ValueText__c = 'testpass1';
                else if (q.fieldName != null && q.fieldName.equals('Last_Name__c'))
                    q.response.ValueText__c = 'testpass1';
            }
        }
        
        ar.submit();
        
        Contact con = [SELECT Id FROM Contact WHERE Email = :'ApplicationRegistrationTest@test.com'];
        con.Email = null;
        update con;
        
        ar.submit();
        
        con.Email = UserInfo.getUserName();
        update con;
        
        ar.submit();
        
        ar = new ApplicationRegistration();
        
        for (ApplicationQuestionGroup g:ar.appCreate.section.groups) {
            for (ApplicationQuestion q:g.questions) {
                if (q.fieldName != null && q.fieldName.equals('Intended_Program__c'))
                    q.response.ValueText__c = progId;
                else if (q.fieldName != null && q.fieldName.equals('Intended_Term_of_Entry__c'))
                    q.response.ValueText__c = termId;
                else if (q.fieldName != null && q.fieldName.equals('First_Name__c') && q.label.equals('First Name'))
                    q.response.ValueText__c = 'test2';
                else if (q.fieldName != null && q.fieldName.equals('Last_Name__c') && q.label.equals('Last Name'))
                    q.response.ValueText__c = 'test2';
                else if (q.fieldName != null && q.fieldName.equals('Email__c'))
                    q.response.ValueText__c = 'ApplicationRegistrationTest2@test.com';
                else if (q.fieldName != null && q.fieldName.equals('First_Name__c'))
                    q.response.ValueText__c = 'testpass1';
                else if (q.fieldName != null && q.fieldName.equals('Last_Name__c'))
                    q.response.ValueText__c = 'testpass1';
            }
        }
        
        delete appControl;
        
        ar.submit();
        
        Test.stopTest();
    }
    
    @testSetup
    static void setup() {
        
        Application_Control__c appControl = ApplicationTestUtilities.createApplicationControl();
        
        Academic_Term__c at = new Academic_Term__c(Name = 'test', Activate_Application_Date__c = Date.TODAY().addDays(-2), End_Application_Date__c = Date.TODAY().addDays(2));
        insert at;
        
        insert new Program__c(Name = 'test');
        
        Interaction_Mapping__c im1 = new Interaction_Mapping__c(Target_Object_API_Name__c = 'Contact', Target_Field_API_Name__c = 'FirstName', Interaction_Source_Field_API_Name__c = 'First_Name__c', Active__c = true);
        Interaction_Mapping__c im2 = new Interaction_Mapping__c(Target_Object_API_Name__c = 'Contact', Target_Field_API_Name__c = 'LastName', Interaction_Source_Field_API_Name__c = 'Last_Name__c', Active__c = true);
        Interaction_Mapping__c im3 = new Interaction_Mapping__c(Target_Object_API_Name__c = 'Contact', Target_Field_API_Name__c = 'Email', Interaction_Source_Field_API_Name__c = 'Email__c', Active__c = true);
        insert new List<Interaction_Mapping__c>{im1, im2, im3};
    }
}