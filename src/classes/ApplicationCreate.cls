/*******************************************************************************
@description This controller is used to create a new application for a user who already has a community account
@author Huron Consulting Group

Revision (s): 
*******************************************************************************/
public class ApplicationCreate {

    public Id contactId {get;set;}
    public Application__c app {get;set;}
    public ApplicationQuestionSection section {get;set;}

    public List<Requirement_Item__c> items {get;set;}
    List<Question_Dependency__c> questionDependencies{get;set;}
    public List<Requirement_Response__c> newResponses{get;set;}
    public List<Question_Response__c> qResponses {get;set;}
    public Map<Id,Program__c> intendedPrograms;
    
    public Application_Control__c appControl{
        get{
            if(appControl == null){
                appControl = ApplicationUtilities.getApplicationControls(ApexPages.currentPage().getParameters().get('at'));
            }
            return appControl;
        }set;
    }

    public transient String additionalDataString{get;set;}

    public ApplicationCreate() {
        items = new List<Requirement_Item__c>();
    }
    /*******************************************************************************
    * @description Initialize the page - Sets up requirements
    ********************************************************************************/
    public void init() {

        app = new Application__c(Application_Status__c=appControl.Application_Start_Status__c);

        contactId = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId()].ContactId;
        if (UserInfo.getUserType().equals('Standard')){
            contactId = Id.valueOf(ApexPages.currentPage().getParameters().get('contactId'));
        }
        
        if(appControl == null){
            return ;
        }

        List<ApplicationQuestion> questions1 = new List<ApplicationQuestion>();

        ApplicationQuestion term = new ApplicationQuestion(app, 'What term are you applying for?', app, 'Intended_Term_of_Entry__c');
        Map<Id, String> termMap = new Map<Id, String>();
        for(Academic_Term__c at : [Select Id,Name from Academic_Term__c WHERE Application_Status__c = 'Active' ORDER BY Activate_Application_Date__c ASC]){
            termMap.put(at.Id,at.Name);
        }
        term.setReferenceOptions(termMap);
        questions1.add(term);
        questions1.get(questions1.size()-1).question = new Question__c(Required__c=app.Application_Status__c,Active__c=true);

        ApplicationQuestion program = new ApplicationQuestion(app, 'What program are you applying to?', app, 'Intended_Program__c');
        intendedPrograms = new Map<Id,Program__c>([SELECT Id, Name, Academic_Level__c,Program_Name_on_Application__c,Active__c,Applicant_Type__c, Citizenship__c, Degree_Type__c, Delivery_Type__c, Residency__c, School_College__c, Student_Type__c, Hide_Applicant_Type__c, Hide_Citizenship__c, Hide_Student_Type__c FROM Program__c WHERE Active__c = true ORDER BY Name ASC]);
        program.addIntendedProgramFilteringList(intendedPrograms.values());
        questions1.add(program);
        questions1.get(questions1.size()-1).question = new Question__c(Required__c=app.Application_Status__c,Active__c=true);
        ApplicationQuestionGroup group1 = new ApplicationQuestionGroup(questions1);

        List<ApplicationQuestionGroup> groups = new List<ApplicationQuestionGroup>{};
        if(appControl.Hide_Term_Program__c == false){
            groups.add(group1);
        }
        section = new ApplicationQuestionSection(groups);

        //Custom Requirements
        String appControlId = appControl.Id;
        String itemQuery = 'SELECT Id, Active__c,Required_Number_of_Children__c,Requirement__r.Name, Name, Instructions__c, Intended_Program__c, Application_Status__c, Applicant_Type__c , Citizenship__c, Degree_Type__c, Delivery_Type__c, Residency__c, School_College__c,Student_Type__c, RecordType.DeveloperName, Allow_Text_Entry__c, Related_List_Object__c,Related_List_Object_Master__c, Related_List_Object_Master_Field__c, Related_List_Where_Clause__c, Internal_Requirement_Item__c,(SELECT Id, Active__c,Required__c, Label__c, Intended_Program__c, Application_Status__c, Applicant_Type__c , Citizenship__c, Degree_Type__c, Delivery_Type__c, Residency__c, School_College__c, Student_Type__c, RecordType.DeveloperName, Picklist_Values__c, Placeholder__c, Length__c, Help_Text__c, Dependency_Logic__c, Dependency_Behavior__c, Related_Object_Field__c, Lookup_Object__c, Lookup_Where_Clause__c, Application_Field__c, External_Email_Field__c,Hardcoded_Value__c ,Static_Text__c FROM Questions__r ORDER BY Display_Order__c ASC NULLS LAST) FROM Requirement_Item__c WHERE Requirement__r.Application_Control__c = :appControlId AND Requirement__r.Show_on_Application_Creation__c = true ORDER BY Display_Order__c ASC NULLS LAST';
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
    * @description Saves a new application based on the answers from the VisualForce page
    ********************************************************************************/
    public PageReference save(){
        app = new Application__c();
        app.Contact__c = contactId;
        try{
            //Populates the application based on answers from the visualforce page
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
                        if(resp != null){
                            app.put(question.fieldName,resp);
                        }
                        if(question.question != null && String.isNotBlank(question.question.Required__c) && question.ShowQuestion == true && String.isBlank(String.valueOf(resp))){
                            throw new CustomException('Not all required fields have been filled out.',true, true);
                        }
                    }
                }
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
            if (String.isNotBlank(app.Educational_Background__c) && app.Educational_Background__c.contains('Freshman')){
                app.Applicant_Type__c = 'Freshman';
            } else {
                app.Applicant_Type__c = app.Educational_Background__c;
            }
            if (String.isNotBlank(app.Educational_Background__c) && app.Educational_Background__c.contains('Adult')){
                app.Student_Type__c = 'Adult';
            }else{
                app.Student_Type__c = 'Traditional';
            }
            app.Application_Status__c=appControl.Application_Start_Status__c;
            app.Application_Control__c = appControl.Id;
            insert app;
            //
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
            //
            return new PageReference('/apex/ApplicationChecklist?applicationId=' + app.Id + '&contactId=' + contactId);
        }catch(DmlException err){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,err.getDMLMessage(0)));
        }catch(CustomException err){
            if(err.isError){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,err.getMessage()));
            }else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Confirm,err.getMessage()));
            }
            if(err.doRollback){
                //Database.rollback(sp);
            }
        }catch(Exception err){
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
}