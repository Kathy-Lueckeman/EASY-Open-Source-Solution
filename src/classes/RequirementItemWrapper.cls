public class RequirementItemWrapper {

    public Requirement_Item__c reqItem{get;set;}
    public Boolean reqItemStatus{get;set;}
    public Boolean display {
        get {
            return ((!reqItem.Internal_Only__c || reqItem.Internal_Only_Show_on_Checklist__c) && reqItem.Internal_Requirement_Item__c == null) || UserInfo.getUserType().equals('Standard');
        }
    }
    public RequirementItemWrapper(Requirement_Item__c reqItem){
        this.reqItem = reqItem;
        this.reqItemStatus = false;
    }   
    
}