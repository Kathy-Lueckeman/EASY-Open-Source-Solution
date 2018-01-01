/*******************************************************************************
@description This class holds a collection of Requirement Items named ApplicationQuestionGroup and filters these items using the ApplicationFilter logic
@author Huron Consulting Group

Revision (s): 
*******************************************************************************/
public class ApplicationQuestionSection {

    public List<ApplicationQuestionGroup> groups {get;private set;}

    public ApplicationQuestionSection(List<ApplicationQuestionGroup> groups) {
        this.groups = groups;
    }

    public ApplicationQuestionSection(Application__c app, List<Requirement_Item__c> items, Map<Id, List<Question_Dependency__c>> dQuestions, Map<Id, Requirement_Response__c> responses, Map<Id, List<Question_Response__c>> dResponses, Map<String,Map<String,Schema.SObjectField>> fieldDescribeMap) {
        groups = new List<ApplicationQuestionGroup>();

        for (Requirement_Item__c i:items){
            if(ApplicationFilter.filter(app,i)){
                groups.add(ApplicationQuestionSection.createQuestionGroup(app, i, dQuestions, responses.get(i.Id), dResponses.get(i.Id),fieldDescribeMap));
            }
        }
    }
    /*******************************************************************************
    * @description Creates a question group from a single requirement item
    ********************************************************************************/
    public static ApplicationQuestionGroup createQuestionGroup(Application__c app, Requirement_Item__c i, Map<Id, List<Question_Dependency__c>> dQuestions, Requirement_Response__c response,  List<Question_Response__c> dResponses, Map<String,Map<String,Schema.SObjectField>> fieldDescribeMap){
        Map<String,Schema.SObjectField> sObjectFields;
        if(String.isNotBlank(i.Related_List_Object__c) && fieldDescribeMap != null && fieldDescribeMap.containskey(i.Related_List_Object__c)){
            sObjectFields = fieldDescribeMap.get(i.Related_List_Object__c);
        }
        return new ApplicationQuestionGroup(app, i, dQuestions, response, dResponses,sObjectFields);
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
}