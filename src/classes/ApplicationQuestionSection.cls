/*******************************************************************************
@description This class holds a collection of Requirement Items named ApplicationQuestionGroup and filters these items using the ApplicationFilter logic
@author Huron Consulting Group

Revision (s): 
*******************************************************************************/
public class ApplicationQuestionSection {

    public List<ApplicationQuestionGroup> groups {get;private set;}
    
    public Contact con {
        get {
            if (con == null && groups != null) {
                for (ApplicationQuestionGroup g:groups) {
                    if (g.con != null) {
                        con = g.con;
                        break;
                    }
                }
            }
            return con;
        } set;
    }
    
    private Application__c application {
        get {
            if (application == null && groups != null) {
                for (ApplicationQuestionGroup g:groups) {
                    if (g.app != null) {
                        application = g.app;
                        break;
                    }
                }
            }
            return application;
        } set;
    }

    public ApplicationQuestionSection(List<ApplicationQuestionGroup> groups) {
        this.groups = groups;
        setProgress();
    }

    public ApplicationQuestionSection(Contact con, Application__c app, List<Requirement_Item__c> items, Map<Id, List<Question_Dependency__c>> dQuestions, Map<Id, Requirement_Response__c> responses, Map<Id, List<Question_Response__c>> dResponses, Map<String,Map<String,Schema.SObjectField>> fieldDescribeMap) {
        groups = new List<ApplicationQuestionGroup>();
        this.con = con;
        application = app;
        for (Requirement_Item__c i:items){
            if (ApplicationFilter.filter(app, i)) {
                groups.add(ApplicationQuestionSection.createQuestionGroup(con, app, i, dQuestions, responses.get(i.Id), dResponses.get(i.Id),fieldDescribeMap));
            }
        }
        
        addDependencies(dQuestions, dResponses);
        setProgress();
    }
    
    public void addDependencies(Map<Id, List<Question_Dependency__c>> dQuestions, Map<Id, List<Question_Response__c>> dResponses) {
        
        Map<Id, ApplicationQuestion> qMap = new Map<Id, ApplicationQuestion>();
        for (ApplicationQuestionGroup g:groups)
            if ((g.questionGroup || g.relatedObject) && g.questions != null && g.item != null)
                for (ApplicationQuestion aq:g.questions)
                    if (aq.question != null)
                        qMap.put(aq.question.Id, aq);
        
        for (ApplicationQuestionGroup g:groups)
            if ((g.questionGroup || g.relatedObject) && g.questions != null && g.item != null)
                g.addQuestionDependencies(qMap, dQuestions, dResponses == null ? null : dResponses.get(g.item.Id));
    }
    
    private void setProgress() {
        for (Integer n = 0; n < groups.size(); n++)
            groups[n].progress = (((Decimal)n + 1) / ((Decimal)groups.size())) * 100;
    }
    
    public static ApplicationQuestionGroup createQuestionGroup(Contact con, Application__c app, Requirement_Item__c i, Map<Id, List<Question_Dependency__c>> dQuestions, Requirement_Response__c response,  List<Question_Response__c> dResponses, Map<String,Map<String,Schema.SObjectField>> fieldDescribeMap){
        return createQuestionGroup(con, app, i, dQuestions, response, dResponses, fieldDescribeMap, false);
    }
    
    /*******************************************************************************
    * @description Creates a question group from a single requirement item
    ********************************************************************************/
    public static ApplicationQuestionGroup createQuestionGroup(Contact con, Application__c app, Requirement_Item__c i, Map<Id, List<Question_Dependency__c>> dQuestions, Requirement_Response__c response,  List<Question_Response__c> dResponses, Map<String,Map<String,Schema.SObjectField>> fieldDescribeMap, Boolean isAppCreate){
        Map<String,Schema.SObjectField> sObjectFields;
        if (String.isNotBlank(i.Related_List_Object__c) && fieldDescribeMap != null && fieldDescribeMap.containskey(i.Related_List_Object__c)){
            sObjectFields = fieldDescribeMap.get(i.Related_List_Object__c);
        }
        return new ApplicationQuestionGroup(con, app, i, dQuestions, response, dResponses,sObjectFields, isAppCreate);
    }
    /*******************************************************************************
    * @description Asks the QuestionGroup to prepare to be saved
    ********************************************************************************/
    public void processValues(){
        processValues(null);
    }
    public void processValues(Map<String,Object> additionalData) {
        for (ApplicationQuestionGroup g:groups){
            Map<String,Object> addData;
            if(g.item != null && g.item.Id != null && additionalData != null && additionalData.containsKey(g.item.Id)){
                addData = (Map<String,Object>)additionalData.get(g.item.Id);
            }
            g.processValues(addData);
        }
    }
    
    public void pushValuesToObjects() {
        
        if (con == null && application == null) return;
        
        Set<String> allContactFields = new Set<String>();
        Set<String> allApplicationFields = new Set<String>();
        Map<String, Object> contactValues = new Map<String, Object>();
        Map<String, Object> applicationValues = new Map<String, Object>();
        for (ApplicationQuestionGroup g:groups) {
            if (g.questionGroup && g.questions != null) {
                for (ApplicationQuestion q:g.questions) {
                    if (q.question != null && (String.isNotBlank(q.question.Contact_Field__c) || String.isNotBlank(q.question.Application_Field__c))) {
                        
                        if (con != null && String.isNotBlank(q.question.Contact_Field__c))
                            allContactFields.add(q.question.Contact_Field__c.toLowerCase());
                        if (application != null && String.isNotBlank(q.question.Application_Field__c))
                            allApplicationFields.add(q.question.Application_Field__c.toLowerCase());
                        q.getShowQuestion();
                        
                        if (q.resp != null) {
                            if (con != null && String.isNotBlank(q.question.Contact_Field__c))
                                contactValues.put(q.question.Contact_Field__c.toLowerCase(), q.resp);
                            if (application != null && String.isNotBlank(q.question.Application_Field__c))
                                applicationValues.put(q.question.Application_Field__c.toLowerCase(), q.resp);
                        }
                    }
                }
            }
        }
        
        for (ApplicationQuestionGroup g:groups)
            if (g.questionGroup && g.questions != null)
                for (ApplicationQuestion q:g.questions)
                    q.dependencyCalculated = false;
        
        for (String f:allContactFields) {
            try {
                con.put(f, contactValues.get(f));
            } catch (Exception e) {}
        }
        
        for (String f:allApplicationFields) {
            try {
                application.put(f, applicationValues.get(f));
            } catch (Exception e) {}
        }
    }

    public void updateGroupOptions() {
        System.debug(LoggingLevel.ERROR, 'updateOptions');
        //this code needed to cover case when we want to filter intended program options
        String TERM_QUESTION_FIELDNAME = 'Intended_Term_of_Entry__c';
        String PROGRAM_QUESTION_FIELDNAME = 'Intended_Program__c';
        String STARTDATE_QUESTION_FIELDNAME = 'Generic_Filter_1__c';
        String APPLICANT_TYPE_FIELDNAME = 'Applicant_Type__c';
        String selectedTerm = NULL;
        ApplicationQuestion programQuestion = NULL;
        String selectedProgram = NULL;
        ApplicationQuestion startDateQuestion = NULL;
        String selectedApplicantType = NULL;

        for (ApplicationQuestionGroup g : groups) {
            for (ApplicationQuestion q : g.questions) {
                if (q.fieldName == TERM_QUESTION_FIELDNAME) {
                    selectedTerm = q.response.ValueText__c;
                }
                if (q.fieldName == PROGRAM_QUESTION_FIELDNAME) {
                    programQuestion = q;
                    selectedProgram = q.response.ValueText__c;
                }
                if (q.fieldName == STARTDATE_QUESTION_FIELDNAME) {
                    startDateQuestion = q;
                }
                if (q.fieldName == APPLICANT_TYPE_FIELDNAME) {
                    selectedApplicantType = q.response.ValueText__c;
                }
            }
        }
        if (programQuestion != NULL) {
            programQuestion.updateOptions(selectedTerm, selectedApplicantType);
        }
        if (startDateQuestion != NULL) {
            if (String.isNotBlank(selectedTerm) && String.isNotBlank(selectedProgram)) {
                startDateQuestion.updateOptions(selectedTerm + ';' + selectedProgram, selectedApplicantType);
            } else {
                startDateQuestion.updateOptions('DEFAULT', selectedApplicantType);
            }

        }
    }
}