@isTest
private class RequirementWrapperTest {
    
    @isTest
    static void test_requirement_wrapper() {
        
        Requirement__c r = new Requirement__c();
        Requirement_Item__c ri = new Requirement_Item__c();
        
        Test.startTest();
        
        RequirementWrapper rw = new RequirementWrapper(r);
        Boolean display = rw.display;
        List<RequirementItemWrapper> reqItems = rw.reqItems;
        
        RequirementItemWrapper riw = new RequirementItemWrapper(ri);
        Boolean riDisplay = riw.display;
        
        Test.stopTest();
    }
}