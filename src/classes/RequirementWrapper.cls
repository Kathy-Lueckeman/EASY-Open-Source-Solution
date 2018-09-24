public class RequirementWrapper {

        public Requirement__c req{get;set;}
        public Boolean reqStatus{get;set;}
        public Boolean viewed{get;set;}
        public Boolean display {
            get {
                return !req.Internal_Only__c || req.Internal_Only_Show_on_Checklist__c || UserInfo.getUserType().equals('Standard');
            }
        }
        public Map<Id,RequirementItemWrapper> reqItemMap{get;set;}
        public List<RequirementItemWrapper> reqItems{
            get{
                return reqItemMap.values();
            }
        }
        public RequirementWrapper(Requirement__c req){
            this.req = req;
            this.reqStatus = false;
            this.viewed = true;
            this.reqItemMap = new Map<Id,RequirementItemWrapper>();
        }
    
}