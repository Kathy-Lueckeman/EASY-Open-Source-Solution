@isTest
private class UserApplicationTriggerHandlerTest {
	
    @isTest
    private static void test_application_trigger_handler() {
		
        Test.startTest();
        
        new UserApplicationTriggerHandler();
        Database.insert(new List<User>{new User()}, false);
        
        Test.stopTest();
	}
}