@isTest
public class ApplicationFilterTest {
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
		Program__c ap = new Program__c();
		insert ap;
	}
	public static TestMethod void appFilter1(){
		Contact student = [Select Id from Contact];
		Application__c app = new Application__c(Contact__c=student.Id);
		insert app;
		Program__c ap = [Select Id from Program__c];
		Requirement__c req = new Requirement__c(Name='Test',Intended_Program__c=ap.Id,Applicant_Type__c='Graduate',Application_Control__c=[Select Id from Application_Control__c limit 1].Id);
		insert req;
		//Null App
		System.assertEquals(true,ApplicationFilter.filter(null,req));
		//Req is not active
		System.assertEquals(false,ApplicationFilter.filter(app,req));
		req.Active__c = true;
		update req;
		//App does not have program
		System.assertEquals(false,ApplicationFilter.filter(app,req));
		Test.startTest();
		app.Intended_Program__c = ap.Id;
		update app;
		Test.stopTest();
		//App does not have applicantTypes
		System.assertEquals(false,ApplicationFilter.filter(app,req));
	}
	public static TestMethod void appFilter2(){
		Contact student = [Select Id from Contact];
		Application__c app = new Application__c(Contact__c = student.Id,Applicant_Type__c='Graduate');
		insert app;
		Requirement__c req = new Requirement__c(Active__c=true,Name='Test',Citizenship__c='Domestic',Degree_Type__c='Associate',Application_Control__c=[Select Id from Application_Control__c limit 1].Id);
		insert req;
		//App does not have citizenship
		System.assertEquals(false,ApplicationFilter.filter(app,req));
		Test.startTest();
		app.Citizenship__c = 'Domestic';
		update app;
		Test.stopTest();
	}
	public static TestMethod void appFilter3(){
		Contact student = [Select Id from Contact];
		Program__c ap = [Select Id from Program__c];
		Application__c app = new Application__c(Contact__c = student.Id,Applicant_Type__c='Graduate',Citizenship__c = 'Domestic');
		insert app;
		Requirement__c req = new Requirement__c(Active__c=true,Name='Test',Delivery_Type__c='Online', Student_Type__c='Traditional',Application_Status__c=Requirement__c.Application_Status__c.getDescribe().getPicklistValues()[0].getValue(),Application_Control__c=[Select Id from Application_Control__c limit 1].Id);
		insert req;
		//App does not have deliverytype
		System.assertEquals(false,ApplicationFilter.filter(app,req));
		app.Delivery_Type__c = 'Online';
		update app;
		System.assertEquals(false,ApplicationFilter.filter(app,req));
		req.Intended_Program__c = null;
		update req;
		//App does not have Student type
		System.assertEquals(false,ApplicationFilter.filter(app,req));
		Test.startTest();
			app.Student_Type__c = 'Traditional';
			update app;
		Test.stopTest();
		//App does not have appStatuses but we're internal
		System.assertEquals(true,ApplicationFilter.filter(app,req));
	}
	public static TestMethod void appFilter4(){
		Contact student = [Select Id from Contact];
		Application__c app = new Application__c(Contact__c = student.Id,Applicant_Type__c='Graduate',Citizenship__c = 'Domestic',Delivery_Type__c='Online', Student_Type__c='Traditional',Application_Status__c=Requirement__c.Application_Status__c.getDescribe().getPicklistValues()[0].getValue());
		insert app;
		Requirement__c req = new Requirement__c(Active__c=true,Name='Test',Application_Control__c=[Select Id from Application_Control__c limit 1].Id);
		insert req;
		System.assertEquals(true,ApplicationFilter.filter(app,req));

	}
	public static TestMethod void appFilter5(){
		Contact student = [Select Id from Contact];
		Application__c app = new Application__c(Contact__c = student.Id,Applicant_Type__c='Graduate',Citizenship__c = 'Domestic',Delivery_Type__c='Online', Student_Type__c='Traditional',Application_Status__c=Requirement__c.Application_Status__c.getDescribe().getPicklistValues()[0].getValue());
		insert app;
		Program__c ip = new Program__c(Active__c=true,Name='Test');
		insert ip;
		System.assertEquals(true,ApplicationFilter.filter(app,ip,false));

	}
}