/*******************************************************************************
@description This class allows an administrator to review any related object such as Schools or employers that were not found in the system and approve new records/lookup existing records
@author Huron Consulting Group

Revision (s):
*******************************************************************************/
public class RelatedObjectReview {
	public Map<String, List<SObjectWrapper>> objWrappers{get;set;}
	public Map<String,Set<String>> objFieldMap{get;set;}
	public Map<String,String> objReferenceFieldMap{get;set;}

	public String createNewRecordId{get;set;}
	public String createNewRecordType{get;set;}

	public Application_Control__c appControl{
        get{
            if(appControl == null){
                appControl = ApplicationUtilities.getApplicationControls(ApexPages.currentPage().getParameters().get('at'));
            }
            return appControl;
        }set;
    }
	public RelatedObjectReview() {
		objWrappers = new Map<String, List<SObjectWrapper>>();
		objFieldMap = new Map<String, Set<String>>();
		objReferenceFieldMap = new Map<String,String>();
		Map<String,Set<String>> reqItemFieldMap = new Map<String,Set<String>>();
		Map<String,String> reqItemLookupObjMap = new Map<String,String>();
		Map<String,String> reqItemRelatedObjMap = new Map<String,String>();
		//Find all relevant fields based on questions asked
		for(Question__c q : [SELECT Id, Lookup_Object__c, Related_Object_Field__c, Requirement_Item__c, Requirement_Item__r.Related_List_Object__c, RecordType.DeveloperName, New_Reference_Field__c ,Static_Text__c FROM Question__c WHERE (Lookup_Object__c != null OR New_Reference_Field__c = true) AND Active__c = :true AND Requirement_Item__r.Active__c = :true AND Requirement_Item__r.Requirement__r.Active__c = :true AND Requirement_Item__r.Requirement__r.Application_Control__c = :appControl.Id ORDER BY New_Reference_Field__c, Display_Order__c ASC NULLS LAST]){
			if(q.New_Reference_Field__c == false && q.RecordType.DeveloperName == 'Reference' && String.isNotBlank(q.Lookup_Object__c)){
				reqItemLookupObjMap.put(q.Requirement_Item__c,q.Lookup_Object__c);
				reqItemRelatedObjMap.put(q.Requirement_Item__r.Related_List_Object__c,q.Lookup_Object__c);
				if(!objFieldMap.containsKey(q.Lookup_Object__c)){
					objFieldMap.put(q.Lookup_Object__c,new Set<String>());
				}
				if(reqItemFieldMap.containsKey(q.Requirement_Item__c)){
					objFieldMap.get(q.Lookup_Object__c).addAll(reqItemFieldMap.get(q.Requirement_Item__c));
					reqItemFieldMap.remove(q.Requirement_Item__c);
				}
				objReferenceFieldMap.put(q.Requirement_Item__r.Related_List_Object__c,q.Related_Object_Field__c);
			}else if(q.New_Reference_Field__c == true){
				if(reqItemLookupObjMap.containsKey(q.Requirement_Item__c)){
					objFieldMap.get(reqItemLookupObjMap.get(q.Requirement_Item__c)).add(q.Related_Object_Field__c);
				}else{
					if(!reqItemFieldMap.containsKey(q.Requirement_Item__c)){
						reqItemFieldMap.put(q.Requirement_Item__c,new Set<String>());
					}
					reqItemFieldMap.get(q.Requirement_Item__c).add(q.Related_Object_Field__c);
				}
			}
		}
		Set<String> reviewObjs = Related_Object_Review__c.getAll().keySet();
		for(String s : reviewObjs){
			if(reqItemRelatedObjMap.containsKey(s)){
				String query = 'Select Id, Related_Object_JSON__c FROM ' + s + ' WHERE Holding_Name__c != null';
				if(!objWrappers.containsKey(reqItemRelatedObjMap.get(s))){
					objWrappers.put(reqItemRelatedObjMap.get(s),new List<SObjectWrapper>());
				}
				objWrappers.get(reqItemRelatedObjMap.get(s)).addAll(convertList(database.query(query),reqItemRelatedObjMap.get(s)));
			}
		}
	}
	/*******************************************************************************
    * @description Creates a new record based on the JSON record + updates by the administrator
    ********************************************************************************/
	public void createRec(){
		if(objWrappers.containsKey(createNewRecordType)){

			for(Integer i = 0;i<objWrappers.get(createNewRecordType).size();i++){
				SObjectWrapper obj = objWrappers.get(createNewRecordType)[i];
				if(obj.obj.Id == createNewRecordId){
					objWrappers.get(createNewRecordType).remove(i);
					insert obj.relatedSObj;
					obj.obj.put(objReferenceFieldMap.get(obj.obj.getSObjectType().getDescribe().getName()),obj.relatedSObj.Id);
					obj.obj.put('Holding_Name__c',null);
					obj.obj.put('Related_Object_JSON__c',null);
					update obj.obj;
					break;
				}
			}
		}
		createNewRecordType = null;
		createNewRecordId = null;
	}
	/*******************************************************************************
    * @description Saves the entire table. If the administrator had linked an existing record, the record is removed from the table, and its JSON is cleared
    ********************************************************************************/
	public void saveTable(){
		List<SObject> objsToUpdate = new List<SObject>();
		if(objWrappers.containsKey(createNewRecordType)){
			for(Integer i = 0;i<objWrappers.get(createNewRecordType).size();i++){
				SObjectWrapper obj = objWrappers.get(createNewRecordType)[i];
				if(String.isNotBlank(obj.existingRecord)){
					objWrappers.get(createNewRecordType).remove(i);
					obj.obj.put(objReferenceFieldMap.get(obj.obj.getSObjectType().getDescribe().getName()),obj.existingRecord);
					obj.obj.put('Holding_Name__c',null);
					obj.obj.put('Related_Object_JSON__c',null);
				}else{
					obj.obj.put('Related_Object_JSON__c', JSON.serialize(obj.relatedSObj));
				}
				objsToUpdate.add(obj.obj);
			}
		}
		if(objsToUpdate.size()>0){
			update objsToUpdate;
		}
		createNewRecordType = null;
	}

	/*******************************************************************************
    * @description Converts a list of sObjects to a wrapper for ease of use
    ********************************************************************************/
	public List<SObjectWrapper> convertList(List<SObject> objList, String typeToConvert){
		List<SObjectWrapper> retLst = new List<SObjectWrapper>();
		for(SObject obj : objList){
			if(String.isNotBlank((String)obj.get('Related_Object_JSON__c'))){
				retLst.add(new SObjectWrapper(obj,this,typeToConvert));
			}
		}
		return retLst;
	}
	/*******************************************************************************
    * @description Allows the administrator to lookup existing records to tie to.
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
                query += ' ORDER BY Name ASC';
                try{
                    return database.query(query);
                }catch(Exception e){
                    return new List<SObject>();
                }
            }
            return new List<SObject>();
        }
    }
	public class SObjectWrapper{
		public SObject obj{get;set;}
		public SObject relatedSObj{get;set;}
		public Map<String,ApplicationQuestion> relatedObjMap{get;set;}
		private RelatedObjectReview cls;
		public String fieldKeys{get;set;}
		public String existingRecord{get;set;}
		public SObjectWrapper(SObject obj, RelatedObjectReview cls, String typeOfRecord){
			this.obj = obj;
			this.cls = cls;
			Map<String, Object> cObjMap = (Map<String, Object>) JSON.deserializeUntyped((String)obj.get('Related_Object_JSON__c'));
			relatedSObj = (SObject)JSON.deserialize(JSON.serialize(cObjMap), Sobject.class);
			relatedObjMap = new Map<String,ApplicationQuestion>();
			Map<String,Object> fieldMap = relatedSObj.getPopulatedFieldsAsMap();
			for(String s : cls.objFieldMap.get(typeOfRecord)){
				Question__c q = new Question__c(New_Reference_Field__c=true,Related_Object_Field__c=s,RecordType=new RecordType(DeveloperName=ApplicationQuestion.fieldTypes.get(relatedSObj.getSObjectType().getDescribe().fields.getMap().get(s.toLowerCase()).getDescribe().getType())));
				if(q.RecordType.DeveloperName == 'Picklist' || q.RecordType.DeveloperName == 'MultiPicklist' || q.RecordType.DeveloperName == 'Radio'){
					List<String> options = new List<String>();
					for(PicklistEntry ple : relatedSObj.getSObjectType().getDescribe().fields.getMap().get(s).getDescribe().getPicklistValues()){
						options.add(ple.getValue());
					}
					q.Picklist_Values__c = String.join(options,'\n');
				}
				relatedObjMap.put(s,new ApplicationQuestion(relatedSObj,q,null));
			}
			fieldKeys = '';
			for(String s : relatedObjMap.keySet()){
				fieldKeys += s + ',';
			}
		}
	}
}