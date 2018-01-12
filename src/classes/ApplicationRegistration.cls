/*******************************************************************************
@description This controller is used to create a new contact,account and application for a user without community access
@author Huron Consulting Group

Revision (s): 
*******************************************************************************/
public class  ApplicationRegistration {

    public Contact con {get;set;}
    public Contact extraFields {get;set;}
    public Application__c app {get;set;}
    public ApplicationQuestionSection section {get;set;}

    public static final Set<String> contactFields = new Set<String>{'FirstName', 'MiddleName', 'LastName', 'Preferred_First_Name__c', 'Suffix', 'Birthdate', 'Gender__c', 'Social_Security_Number__c', 'Ethnicity__c', 'Race__c',
                                                                    'Email','MobilePhone', 'Text_OptIn__c', 'HomePhone', 'Preferred_Phone__c', 'Mobile', 'MailingAddress'};
    public static final Set<String> applicationFields = new Set<String>{'Educational_Background__c', 'Delivery_Type__c', 'Intended_Program__c', 'Intended_Term_of_Entry__c', 'Citizenship__c','Applicant_Type__c'};

    public List<Requirement_Item__c> items {get;set;}
    List<Question_Dependency__c> questionDependencies{get;set;}
    public List<Requirement_Response__c> newResponses{get;set;}
    public List<Question_Response__c> qResponses {get;set;}
    public Map<Id,Program__c> intendedPrograms;

    public transient String additionalDataString{get;set;}

    public Application_Control__c appControl{
        get{
            if(appControl == null){
                appControl = ApplicationUtilities.getApplicationControls(ApexPages.currentPage().getParameters().get('at'));
            }
            return appControl;
        }set;
    }

    public ApplicationRegistration() {
        items = new List<Requirement_Item__c>();
        loadApplication();
    }
    /*******************************************************************************
    * @description Initialize the page - Sets up all of the requirements and pulls Requirements with the flag (Show on Application Creation)
    ********************************************************************************/
    public void loadApplication(){
        con = new Contact();
        extraFields = new Contact();
        app = new Application__c(Application_Status__c=appControl.Application_Start_Status__c);

        if(appControl == null){
            return ;
        }

        List<ApplicationQuestion> questions1 = new List<ApplicationQuestion>();
        questions1.add(new ApplicationQuestion(app, 'First Name', con, 'FirstName'));
        questions1.get(questions1.size()-1).question = new Question__c(Required__c=app.Application_Status__c,Active__c=true);
        questions1.add(new ApplicationQuestion(app, 'Last Name', con, 'LastName'));
        questions1.get(questions1.size()-1).question = new Question__c(Required__c=app.Application_Status__c,Active__c=true);
		questions1.add(new ApplicationQuestion(app, 'Email', con, 'Email'));
        questions1.get(questions1.size()-1).question = new Question__c(Required__c=app.Application_Status__c,Active__c=true);
		
        if (Test.isRunningTest()) {
            questions1.add(new ApplicationQuestion(app, 'Mailing', con, 'MailingAddress'));
            questions1.get(questions1.size()-1).question = new Question__c(Required__c=app.Application_Status__c,Active__c=true);
        }
        
        List<ApplicationQuestion> questions2 = new List<ApplicationQuestion>();

        ApplicationQuestion term = new ApplicationQuestion(app, 'What term are you applying for?', app, 'Intended_Term_of_Entry__c');
        Map<Id, String> termMap = new Map<Id, String>();
        for(Academic_Term__c at : [Select Id,Name from Academic_Term__c WHERE Application_Status__c = 'Active' ORDER BY Activate_Application_Date__c ASC]){
            termMap.put(at.Id,at.Name);
        }
        term.setReferenceOptions(termMap);
        questions2.add(term);
        questions2.get(questions2.size()-1).question = new Question__c(Required__c=app.Application_Status__c,Active__c=true);

        ApplicationQuestion program = new ApplicationQuestion(app, 'What program are you applying to?', app, 'Intended_Program__c');
        intendedPrograms = new Map<Id,Program__c>([SELECT Id, Name, Academic_Level__c,Program_Name_on_Application__c,Active__c,Applicant_Type__c, Citizenship__c, Degree_Type__c, Delivery_Type__c, Residency__c, School_College__c, Student_Type__c, Hide_Applicant_Type__c, Hide_Citizenship__c, Hide_Student_Type__c FROM Program__c WHERE Active__c = true ORDER BY Name ASC]);
        program.addIntendedProgramFilteringList(intendedPrograms.values());
        questions2.add(program);
        questions2.get(questions2.size()-1).question = new Question__c(Required__c=app.Application_Status__c,Active__c=true);
        
        List<ApplicationQuestion> questions3 = new List<ApplicationQuestion>();
        ApplicationQuestion portalPassword = new ApplicationQuestion(app, 'What password would you like to use for saving your application?',extraFields, 'LastName',Schema.DisplayType.ENCRYPTEDSTRING,true);
        questions3.add(portalPassword);
        questions3.get(questions3.size()-1).question = new Question__c(Required__c=app.Application_Status__c,Active__c=true);
        ApplicationQuestion portalPasswordConfirmation = new ApplicationQuestion(app, 'Please enter your password again.',extraFields, 'FirstName',Schema.DisplayType.ENCRYPTEDSTRING,true);
        questions3.add(portalPasswordConfirmation);
        questions3.get(questions3.size()-1).question = new Question__c(Required__c=app.Application_Status__c,Active__c=true);

        Map<String,RecordType> questionRTMap = new Map<String,RecordType>();
        for(RecordType rt : [Select Id,DeveloperName from RecordType where sObjectType = 'Question__c']){
            questionRTMap.put(rt.DeveloperName,rt);
        }

        ApplicationQuestionGroup group1 = new ApplicationQuestionGroup(questions1);
        ApplicationQuestionGroup group2 = new ApplicationQuestionGroup(questions2);
        ApplicationQuestionGroup group3 = new ApplicationQuestionGroup(questions3);
		
        List<ApplicationQuestionGroup> groups = new List<ApplicationQuestionGroup>{group1};
        if(appControl.Hide_Term_Program__c == false){
            groups.add(group2);
        }
        groups.add(group3);


        //Custom Requirements
        String appControlId = appControl.Id;
        String itemQuery = 'SELECT Id, Active__c,Required_Number_of_Children__c,Requirement__r.Name, Name, Instructions__c, Intended_Program__c, Application_Status__c, Applicant_Type__c , Citizenship__c, Degree_Type__c, Delivery_Type__c, Residency__c, School_College__c,Student_Type__c, RecordType.DeveloperName, Allow_Text_Entry__c, Related_List_Object__c,Related_List_Object_Master__c, Related_List_Object_Master_Field__c, Related_List_Where_Clause__c, Internal_Requirement_Item__c, Editable_Application_Status__c, (SELECT Id, Active__c,Required__c, Label__c, Intended_Program__c, Application_Status__c, Applicant_Type__c , Citizenship__c, Degree_Type__c, Delivery_Type__c, Residency__c, School_College__c, Student_Type__c, RecordType.DeveloperName, Picklist_Values__c, Placeholder__c, Length__c, Help_Text__c, Dependency_Logic__c, Dependency_Behavior__c, Related_Object_Field__c, Lookup_Object__c, Lookup_Where_Clause__c, Application_Field__c, External_Email_Field__c,Hardcoded_Value__c ,Static_Text__c, Editable_Application_Status__c FROM Questions__r ORDER BY Display_Order__c ASC NULLS LAST) FROM Requirement_Item__c WHERE Requirement__r.Application_Control__c = :appControlId AND Requirement__r.Show_on_Application_Creation__c = true ORDER BY Display_Order__c ASC NULLS LAST';
        items = database.query(itemQuery);

        Map<Id, List< Question_Dependency__c >> dQuestions = new Map<Id, List<Question_Dependency__c>>();
        Map<Id,Set<Id>> dQuestionResponseMap = new Map<Id,Set<Id>>();
        if(questionDependencies == null){
            questionDependencies = [SELECT Id, Question__c, Question__r.Required__c, Question__r.Requirement_Item__c,Question__r.Requirement_Item__r.Requirement__c, Controlling_Question__c, Controlling_Question__r.Requirement_Item__r.Requirement__c, Value__c, ValueCheckbox__c, RecordType.DeveloperName FROM Question_Dependency__c WHERE Question__r.Requirement_Item__r.Requirement__r.Application_Control__c = :appControl.Id];
        }
        for (Question_Dependency__c dq: questionDependencies) {
            if (!dQuestions.containsKey(dq.Question__c)){
                dQuestions.put(dq.Question__c, new List<Question_Dependency__c>());
            }
            if(dq.Question__r.Requirement_Item__r.Requirement__c != dq.Controlling_Question__r.Requirement_Item__r.Requirement__c){
                if(!dQuestionResponseMap.containsKey(dq.Question__r.Requirement_Item__c)){
                    dQuestionResponseMap.put(dq.Question__r.Requirement_Item__c,new Set<Id>());
                }
                dQuestionResponseMap.get(dq.Question__r.Requirement_Item__c).add(dq.Controlling_Question__c);
            }
            dQuestions.get(dq.Question__c).add(dq);
        }

        Map<Id, Requirement_Response__c> responses = new Map<Id, Requirement_Response__c>();
        Map<Id, List<Question_Response__c>> dResponses = new Map<Id, List<Question_Response__c>>();
        Set<Id> questionItemSet = new Set<Id>();
        for(Set<Id> setId : dQuestionResponseMap.values()){
            questionItemSet.addAll(setId);
        }
        newResponses = new List<Requirement_Response__c>();
        Map<String,Map<String,Schema.SObjectField>> relatedFieldDescribes = new Map<String,Map<String,SObjectField>>();
        Set<String> relatedObjects = new Set<String>();
        for (Requirement_Item__c i:items) {
            if (!responses.containsKey(i.Id)) {
                Requirement_Response__c r = new Requirement_Response__c(Requirement_Item__c = i.Id);
                newResponses.add(r);
                responses.put(i.Id, r);
            }
            if(String.isNotBlank(i.Related_List_Object__c)){
                relatedObjects.add(i.Related_List_Object__c);
            }
        }
        if(relatedObjects.size()>0){
            for(Schema.DescribeSObjectResult result : Schema.describeSObjects(new List<String>(relatedObjects))){
                relatedFieldDescribes.put(result.getName(),result.fields.getMap());
            }
        }
        List<Requirement_Item__c> riLst = new List<Requirement_Item__c>();
        for(Requirement_Item__c ri : items){
            if(ApplicationFilter.filter(app,ri)){
                riLst.add(ri);
                groups.add(ApplicationQuestionSection.createQuestionGroup(app, ri, dQuestions, responses.get(ri.Id), dResponses.get(ri.Id),relatedFieldDescribes));
            }
        }
        section = new ApplicationQuestionSection(groups);

    }
    /*******************************************************************************
    * @description populates fields on the contact and application through the interactions object.
    ********************************************************************************/
    public PageReference submit() {
        app = new Application__c();
        con = new Contact();
        extraFields = new Contact();
        System.SavePoint sp = Database.setSavepoint();
        try{
            //Populate contact and application fields
            for(ApplicationQuestionGroup aqg : section.groups){
                for(ApplicationQuestion question : aqg.questions){
                    if(String.isNotBlank(question.fieldName) && question.response != null){
                        Object resp;
                        if(String.isNotBlank(question.response.ValueText__c)){
                            resp = question.response.ValueText__c;
                        }
                        if(question.displayType == Schema.DisplayType.BOOLEAN){
                            resp = question.response.ValueCheckbox__c?question.response.ValueCheckbox__c:false;
                        }
                        if(String.isNotBlank(question.response.ValuePhone__c)){
                            resp = question.response.ValuePhone__c;
                        }
                        if(String.isNotBlank(question.response.ValueEmail__c)){
                            resp = question.response.ValueEmail__c;
                        }
                        if(question.response.ValueCurrency__c != null){
                            resp = question.response.ValueCurrency__c;
                        }
                        if(question.response.ValueDate__c != null){
                            resp = question.response.ValueDate__c;
                        }
                        if(question.response.ValueDateTime__c != null){
                            resp = question.response.ValueDateTime__c;
                        }
                        if(question.response.ValueNumber__c != null){
                            resp = question.response.ValueNumber__c;
                        }
                        if(question.response.ValuePercent__c != null){
                            resp = question.response.ValuePercent__c;
                        }
                        if(String.isNotBlank(question.response.ValueTextArea__c)){
                            resp = question.response.ValueTextArea__c;
                        }
                        if(String.isNotBlank(question.response.ValueLongTextArea__c)){
                            resp = question.response.ValueLongTextArea__c;
                        }
                        if(String.isNotBlank(question.response.ValueURL__c)){
                            resp = question.response.ValueURL__c;
                        }
                        if(String.isNotBlank(question.response.ValueTextEncrypted__c)){
                            resp = question.response.ValueTextEncrypted__c;
                        }
                        if(resp != null && question.placeholderQuestion == true && question.displayType != Schema.DisplayType.ADDRESS){
                                extraFields.put(question.fieldName,resp);
                        }
                        if(resp != null && question.placeholderQuestion != true && question.displayType != Schema.DisplayType.ADDRESS){
                            if(contactFields.contains(question.fieldName)){
                                con.put(question.fieldName,resp);
                            }
                            if(applicationFields.contains(question.fieldName)){
                                app.put(question.fieldName,resp);
                            }
                        }else if(question.displayType == Schema.DisplayType.ADDRESS){
                            SObject obj;
                            if(contactFields.contains(question.fieldName)){
                                obj = con;
                            }
                            if(obj != null){
                                if(String.isNotBlank(question.response.City__c)){
                                    obj.put(question.fieldName.replace('Address','City'),question.response.City__c);
                                }
                                if(ApplicationQuestion.stateAndCountryPicklistEnabled == true){
                                    if(question.con != null && question.con.get('MailingCountryCode') != null){
                                        obj.put(question.fieldName.replace('Address','CountryCode'),question.con.get('MailingCountryCode'));

                                    }
                                    if(question.con != null && question.con.get('MailingStateCode') != null){
                                        obj.put(question.fieldName.replace('Address','StateCode'),question.con.get('MailingStateCode'));
                                        
                                    }
                                }else{
                                    if(question.con != null && question.con.get('MailingCountry') != null){
                                        obj.put(question.fieldName.replace('Address','Country'),question.con.get('MailingCountry'));

                                    }
                                    if(question.con != null && question.con.get('MailingState') != null){
                                        obj.put(question.fieldName.replace('Address','State'),question.con.get('MailingState'));
                                        
                                    }
                                }
                                if(String.isNotBlank(question.response.PostalCode__c)){
                                    obj.put(question.fieldName.replace('Address','PostalCode'),question.response.PostalCode__c);
                                }
                                if(String.isNotBlank(question.response.Street__c)){
                                    resp = question.response.Street__c;
                                    obj.put(question.fieldName.replace('Address','Street'),question.response.Street__c);
                                }
                            }

                        }
                        if(question.question != null && String.isNotBlank(question.question.Required__c) && question.ShowQuestion == true && String.isBlank(String.valueOf(resp))){
                            system.debug(question.fieldName);
                            system.debug(question.fieldType);
                            system.debug(question.response);
                            throw new CustomException('Not all required fields have been filled out.',true, true);
                        }
                    }
                }
            }
        

            Interaction__c i = new Interaction__c();
            
            i.First_Name__c = con.FirstName;
            if(Contact.SObjectType.getDescribe().fields.getMap().containsKey('middlename')){
                i.Middle_Name__c = (String)con.get('MiddleName');
            }
            i.Last_Name__c = con.LastName;
            i.Birthdate__c = con.Birthdate;
            i.Email__c = con.Email;
            i.Mobile_Phone__c = con.MobilePhone;
            i.Home_Phone__c = con.HomePhone;
            i.Mailing_Street__c = con.MailingStreet;
            i.Mailing_City__c = con.MailingCity;
            if(ApplicationQuestion.stateAndCountryPicklistEnabled == true){
                i.Mailing_Country__c = (String)con.get('MailingCountryCode');
                i.Mailing_State__c = (String)con.get('MailingStateCode');
            }else{
                i.Mailing_Country__c = (String)con.get('MailingCountry');
                i.Mailing_State__c = (String)con.get('MailingState');
            }
            i.Mailing_Postal_Code__c = con.MailingPostalCode;

        
            //Basic validation
            if(String.isBlank(con.Email)){
                throw new CustomException('Email is required in order to complete your applicaiton.',true, true);
            }
            if(String.isBlank(extraFields.LastName) || String.isBlank(extraFields.FirstName)){
                throw new CustomException('Password is required in order to complete your applicaiton.',true, true);
            }
            if(appControl.Hide_Term_Program__c == false){
                if(String.isBlank(app.Intended_Program__c)){
                    throw new CustomException('An intended program is required in order to complete your applicaiton.',true, true);
                }
                if(String.isBlank(app.Intended_Term_of_Entry__c)){
                    throw new CustomException('An intended term of entry is required in order to complete your applicaiton',true, true);
                }
                Boolean programLocked = false;
                Program__c ip = intendedPrograms.get(app.Intended_Program__c);
                if (String.isNotBlank(ip.Applicant_Type__c) && (String.isBlank(app.Applicant_Type__c) || !(new Set<String>(ip.Applicant_Type__c.split(';'))).contains(app.Applicant_Type__c))){
                    programLocked = true;
                }
                if (String.isNotBlank(ip.Citizenship__c) && (String.isBlank(app.Citizenship__c) || !(new Set<String>(ip.Citizenship__c.split(';'))).contains(app.Citizenship__c))){
                    programLocked = true;
                }
                if(programLocked){
                    throw new CustomException('The selected program is not available.',true, true);
                }
                Boolean termLocked = false;
                for(Intended_Program_Term__c ipt : [Select Id,Applicant_Type__c,Application_Status__c,Citizenship__c, Degree_Type__c,Delivery_Type__c,Residency__c,School_College__c,Student_Type__c,Intended_Program__c from Intended_Program_Term__c where Application_Status__c = 'Inactive' and (Intended_Program__c =:app.Intended_Program__c or Intended_Program__c = null) and Academic_Term__c = :app.Intended_Term_of_Entry__c and (Activate_Application_Date__c = null OR End_Application_Date__c = null OR (Activate_Application_Date__c <= TODAY and End_Application_Date__c >= TODAY))]){
                    if(ApplicationFilter.filter(app,ipt,false)){
                        termLocked = true;
                    }
                }
                if(termLocked){
                    throw new CustomException('The selected program is not available for this term.',true, true);
                }
            }
            //Create basic user info
            User u = new User();
            u.FirstName = con.FirstName;
            u.LastName = con.LastName;
            u.Email = con.Email;
            u.UserName = con.Email;
            u.CommunityNickname = con.Email;
            insert i;
            i = [Select Id,Contact__c from Interaction__c where Id = :i.Id];

            Contact c = [SELECT Id, Email,AccountId FROM Contact WHERE Id = :i.Contact__c];
            if(c.AccountId == null && !Test.isRunningTest()){
                Id siteId = Network.getNetworkId();
                if(siteId != null){
                    SObject nsr = database.query('Select Id,AccountId from NetworkSelfRegistration Where NetworkId=:siteId limit 1');
                    c.AccountId = (String)nsr.get('AccountId');
                }
            }else if(c.AccountId != null){
                Id siteId = Network.getNetworkId();
                Account acc = [SELECT Id,OwnerId FROM Account WHERE Id=:c.AccountId limit 1];
                if(acc.OwnerId == UserInfo.getUserId()){
                    if(siteId != null){
                        Id adminId = Site.getAdminId();
                        update new Account(Id=c.AccountId,OwnerId=adminId);
                    }
                }
            }

            u.contactId = c.Id;

            app.Contact__c = c.Id;
            app.Application_Status__c = appControl.Application_Start_Status__c;
            app.Application_Control__c = appControl.Id;
            insert app;
            
            //For custom requirement items, save the question responses
            transient Map<String,Object> additionalData;
            if(String.isNotBlank(additionalDataString)){
                additionalData = (Map<String,Object>)JSON.deserializeUntyped(additionalDataString);
            } 
            section.processValues(additionalData);
            List<Requirement_Response__c> rrLst = new List<Requirement_Response__c>();
            for(ApplicationQuestionGroup aqg : section.groups){
                system.debug(aqg);
                if(aqg.response != null){
                    aqg.response = aqg.response.clone(false,true,false,false); //Clone to allow popuplating m-d relationship
                    aqg.response.Application__c = app.Id;
                    rrLst.add(aqg.response);
                }
            }
            if(rrLst.size()>0){
                upsert rrLst;
            }
            qResponses = new List<Question_Response__c>();
            for (ApplicationQuestionGroup g:section.groups){
                if (g.questionGroup == true && g.questions != null){
                    for (ApplicationQuestion q : g.questions){
                        if(g.response != null){
                            q.response = q.response.clone(false,true,false,false); //Clone to allow popuplating m-d relationship
                            q.response.Requirement_Response__c = g.response.Id;
                            qResponses.add(q.response);
                        }
                    }
                }
            }
            upsert qResponses;
            
            List<User> uList = [Select Id from User where ContactId=:c.Id limit 1];
            if(uList.size()>0){
                loadApplication();
                throw new CustomException('Your application has been saved, however an account with this email already exists.',false, false);
            }else{
                String pass = extraFields.LastName;
                String passConfirm = extraFields.FirstName;
                if(!Test.isRunningTest()){
                    Site.validatePassword(u, pass, passConfirm);
                    Id uId = Site.createPortalUser(u,c.AccountId,pass,true);
                    if(uId == null){
                        throw new CustomException('',true,true);
                    }
                }
                Id appId = app.Id;
                loadApplication();
                return Site.login(u.Username, pass, '/apex/ApplicationChecklist?applicationId='+appId+'&contactId='+c.Id+'&at='+appControl.URL_Parameter__c);
            }
        }catch(DmlException err){
            Database.rollback(sp);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,err.getDMLMessage(0)));
        }catch(CustomException err){
            if(err.isError){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,err.getMessage()));
            }else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Confirm,err.getMessage()));
            }
            if(err.doRollback){
                Database.rollback(sp);
            }
        }catch(Exception err){
            Database.rollback(sp);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,err.getMessage()));
        }
        return null;
    }
    public class CustomException extends Exception{
        public Boolean doRollback = false;
        public Boolean isError = true;
        public CustomException(String e, Boolean doRollback){
            this(e);
            this.doRollback = doRollback;
        }
        public CustomException(String e, Boolean doRollback, Boolean isError){
            this(e,doRollback);
            this.isError = isError;
        }
    }
    /*******************************************************************************
    * @description Allows looking up records for related object requirement items
    ********************************************************************************/
    @RemoteAction
    public static List<SObject> lookupSearch(String sObj, String sObjFilter, String term){

        return new ActionWithSharing().lookupSearchWithSharing(sObj,sObjFilter, term);
    }
    public with sharing class ActionWithSharing{
        public List<SObject> lookupSearchWithSharing(String sObj, String sObjFilter, String term){
            if(Schema.getGlobalDescribe().get(sObj).getDescribe().isAccessible()){
                String query = 'Select Id, Name FROM '+sObj+' WHERE Name like \'%'+String.escapeSingleQuotes(term)+'%\'';
                if(String.isNotBlank(sObjFilter)){
                    query += ' AND ' + sObjFilter;
                }
                query += ' ORDER BY NAME ASC';
                try{
                    return database.query(query);
                }catch(Exception e){
                    return new List<SObject>();
                }
            }
            return new List<SObject>();
        }
    }
    public class CustomReturn{
        public Boolean isSuccess{get;set;}
        public String message{get;set;}
    }
}