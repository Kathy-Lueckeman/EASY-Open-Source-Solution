/*******************************************************************************
@description This class will collapse question responses, application reviews and requirement responses onto the Requirement Response record. This is used to clean up the large number of records.
@author Huron Consulting Group

Revision (s): 
*******************************************************************************/
public class BatchApplicationArchiver implements Database.Batchable<SObject>{

    public String applicationId;
    public BatchApplicationArchiver(){
    }
    public BatchApplicationArchiver(String appId){
        applicationId = appId;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'SELECT '+getFields('Application__c')+'  FROM Application__c WHERE CreatedDate < LAST_YEAR';
        if(String.isNotBlank(applicationId)){
            query+= ' AND Id = :applicationId';
        }
        return database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Application__c> scope){
        Map<Id,ApplicationWrapper> appMap = new Map<Id,ApplicationWrapper>();
        Set<Id> appIds = new Set<Id>();
        List<Question_Response__c> qrLstDelete = new List<Question_Response__c>();
        List<Application_Review__c> arLstDelete = new List<Application_Review__c>();
        List<Requirement_Response__c> rrLstDelete = new List<Requirement_Response__c>();
        for(Application__c app : scope){
            appIds.add(app.Id);
            appMap.put(app.Id, new ApplicationWrapper(app));
        }
        for(Question_Response__c qr : database.query('SELECT '+getFields('Question_Response__c')+', Requirement_Response__r.Application__c FROM Question_Response__c WHERE Requirement_Response__r.Application__c IN :appIds')){
            qrLstDelete.add(qr);
            appMap.get(qr.Requirement_Response__r.Application__c).questionResponses.add(qr);
        }
        for(Application_Review__c ar : database.query('SELECT '+getFields('Application_Review__c')+' FROM Application_Review__c WHERE Application__c IN :appIds')){
            arLstDelete.add(ar);
            appMap.get(ar.Application__c).applicationReviews.add(ar);
        }
        for(Requirement_Response__c rr : database.query('SELECT '+getFields('Requirement_Response__c')+' FROM Requirement_Response__c WHERE Application__c IN :appIds')){
            rrLstDelete.add(rr);
            appMap.get(rr.Application__c).requirementResponses.add(rr);
        }
        Map<Id,ContentVersion> cvMap = new Map<Id,ContentVersion>();
        List<ContentDocumentLink> cdlLst = new List<ContentDocumentLink>();
        for(ApplicationWrapper wrap : appMap.values()){
            cvMap.put(wrap.app.Id,new ContentVersion(PathOnClient='ApplicationBackup.txt',Title='ApplicationBackup.txt',VersionData=Blob.valueOf(JSON.serialize(wrap))));
        }
        insert cvMap.values();
        Map<Id,ContentVersion> cvNewMap = new Map<Id,ContentVersion>([SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id in :cvMap.values()]);
        for(Id appId : cvMap.keySet()){
            ContentVersion cv = cvMap.get(appId);
            if(cvNewMap.containsKey(cv.Id)){
                cdlLst.add(new ContentDocumentLink(ContentDocumentId=cvNewMap.get(cv.Id).ContentDocumentId,LinkedEntityId=appId,ShareType='I'));
            }
        }
        insert cdlLst;
        delete qrLstDelete;
        delete arLstDelete;
        delete rrLstDelete;
    }

    public void finish(Database.BatchableContext bc){

    }
    private class ApplicationWrapper{
        public Application__c app;
        public List<Question_Response__c> questionResponses;
        public List<Application_Review__c> applicationReviews;
        public List<Requirement_Response__c> requirementResponses;
        public ApplicationWrapper(Application__c app){
            this.app = app;
            questionResponses = new List<Question_Response__c>();
            applicationReviews = new List<Application_Review__c>();
            requirementResponses = new List<Requirement_Response__c>();
        }
    }
    private String getFields(String sObjectName){
        String fieldStr = '';
        for(Schema.SObjectField sof : Schema.getGlobalDescribe().get(sObjectName.toLowerCase()).getDescribe().fields.getMap().values()){
            Schema.DescribeFieldResult dfr = sof.getDescribe();
            if(dfr.isAccessible() || Test.isRunningTest()){
                fieldStr += dfr.getName() + ', ';
            }
        }
        fieldStr = fieldStr.removeEnd(', ');
        return fieldStr;
    }
}