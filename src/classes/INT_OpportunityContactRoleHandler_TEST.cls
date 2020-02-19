/*****************************************
* File: INT_OpportunityContactRoleHandler_TEST
* Author: Kyle Schmid, Huron Consulting Group
* Description: Unit tests for INT_OpportunityContactRoleHandler.cls.
* Re-worked from Sierra-Cedar's implementation included in the Interactions for Student Recruitment package.
******************************************/
@isTest
private class INT_OpportunityContactRoleHandler_TEST {
	
    @isTest
    static void test_insert() {
        
        Id contact1Id = [SELECT Id FROM Contact WHERE LastName = :'test1'].Id;
        
        Opportunity opp = new Opportunity(Name = 'test', CloseDate = Date.today(), StageName = 'Prospect', Contact__c = contact1Id);
        
        Test.startTest();
        
        insert opp;
        
        Test.stopTest();
        
        List<OpportunityContactRole> role = [SELECT Id, ContactId, IsPrimary, Role FROM OpportunityContactRole WHERE OpportunityId = :opp.Id];
        
        System.assertEquals(1, role.size(), 'One Opportunity Contact Role should exist for Opportunity');
        System.assertEquals(contact1Id, role[0].ContactId, 'Role should be \'Opportunity Contact\'');
        System.assertEquals(true, role[0].IsPrimary, 'Role should be primary');
        System.assertEquals(INT_OpportunityContactRoleHandler.ROLE_NAME, role[0].Role);
    }
    
    @isTest
    static void test_update() {
        
        Id contact1Id = [SELECT Id FROM Contact WHERE LastName = :'test1'].Id;
        Id contact2Id = [SELECT Id FROM Contact WHERE LastName = :'test2'].Id;
        
        Opportunity opp1 = new Opportunity(Name = 'test1', CloseDate = Date.today(), StageName = 'Prospect', Contact__c = contact1Id);
        Opportunity opp2 = new Opportunity(Name = 'test2', CloseDate = Date.today(), StageName = 'Prospect', Contact__c = contact2Id);
        insert new List<Opportunity>{opp1, opp2};
        
        delete [SELECT Id FROM OpportunityContactRole WHERE OpportunityId = :opp1.Id];
        
        OpportunityContactRole role1 = new OpportunityContactRole(OpportunityId = opp1.Id, ContactId = contact1Id, IsPrimary = false, Role = 'not_role_name');
        OpportunityContactRole role2 = new OpportunityContactRole(OpportunityId = opp1.Id, ContactId = contact1Id, IsPrimary = false, Role = 'not_role_name');
        OpportunityContactRole role3 = new OpportunityContactRole(OpportunityId = opp1.Id, ContactId = contact2Id, IsPrimary = false, Role = 'not_role_name');
        insert new List<OpportunityContactRole>{role1, role2, role3};
        
        opp2.Contact__c = null;
        
        Test.startTest();
        
        update new List<Opportunity>{opp1, opp2};
        
        Test.stopTest();
        
        List<OpportunityContactRole> opp1Role = [SELECT Id, ContactId, IsPrimary, Role FROM OpportunityContactRole WHERE OpportunityId = :opp1.Id];
        List<OpportunityContactRole> opp2Role = [SELECT Id, ContactId, IsPrimary, Role FROM OpportunityContactRole WHERE OpportunityId = :opp2.Id];
        
        System.assertEquals(1, opp1Role.size(), 'One Opportunity Contact Role should exist for Opportunity');
        System.assertEquals(0, opp2Role.size(), 'No Opportunity Contact Roles should exist for Opportunity');
        System.assert(opp1Role[0].Id == role1.Id || opp1Role[0].Id == role2.Id, 'Existing role should have been updated');
        System.assertEquals(contact1Id, opp1Role[0].ContactId, 'Role should be \'Opportunity Contact\'');
        System.assertEquals(true, opp1Role[0].IsPrimary, 'Role should be primary');
        System.assertEquals(INT_OpportunityContactRoleHandler.ROLE_NAME, opp1Role[0].Role, 'Role should have a Role value of ' + INT_OpportunityContactRoleHandler.ROLE_NAME);
    }
    
    @isTest
    static void test_exclusion() {
        
        Id contact1Id = [SELECT Id FROM Contact WHERE LastName = :'test1'].Id;
        
        Schema.RecordTypeInfo recordType;
        for (Schema.RecordTypeInfo rt:Opportunity.SObjectType.getDescribe().getRecordTypeInfos()) {
            if (!rt.isMaster() && rt.isAvailable()) {
            	recordType = rt;
                break;
            }
        }
        
        Opportunity opp = new Opportunity(Name = 'test', CloseDate = Date.today(), StageName = 'Prospect', Contact__c = contact1Id);
        
        if (recordType != null) {
            insert new OpportunityContactRoleExclusion__c(Name = recordType.getName());
            opp.RecordTypeId = recordType.getRecordTypeId();
        }
        
        Test.startTest();
        
        insert opp;
        
        Test.stopTest();
    }
    
    @testSetup
    static void setup() {
        
        Contact contact1 = new Contact(LastName = 'test1');
        Contact contact2 = new Contact(LastName = 'test2');
        insert new List<Contact>{contact1, contact2};
    }
}