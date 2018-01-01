/*******************************************************************************
@description This controller is used to filter a generic object, requirements, requirement items and questions against the application
@author Huron Consulting Group

Revision (s): 
*******************************************************************************/
public class ApplicationFilter {

    public static Boolean filter(Application__c app, Requirement__c req) {
        return filter(app, req.Active__c,req.Intended_Program__c, req.Applicant_Type__c, req.Citizenship__c, req.Degree_Type__c, req.Delivery_Type__c, req.Residency__c, req.School_College__c, req.Student_Type__c, req.Application_Status__c);
    }

    public static Boolean filter(Application__c app, Requirement_Item__c item) {
        return filter(app, item.Active__c,item.Intended_Program__c, item.Applicant_Type__c, item.Citizenship__c, item.Degree_Type__c, item.Delivery_Type__c, item.Residency__c, item.School_College__c, item.Student_Type__c, item.Application_Status__c);
    }

    public static Boolean filter(Application__c app, Question__c question) {
        return filter(app, question.Active__c,question.Intended_Program__c, question.Applicant_Type__c, question.Citizenship__c, question.Degree_Type__c, question.Delivery_Type__c, question.Residency__c, question.School_College__c, question.Student_Type__c, question.Application_Status__c);
    }

    public static Boolean filter(Application__c app, SObject obj, Boolean checkStatus) {
        Map<String,Object> objFields = obj.getSObjectType().getDescribe().fields.getMap();
        Boolean active = objFields.containsKey('active__c')?(Boolean)obj.get('active__c'):true;
        Id programId = objFields.containsKey('intended_program__c')?String.valueOf(obj.get('intended_program__c')):null;
        String applicantTypes = objFields.containsKey('applicant_type__c')?String.valueOf(obj.get('applicant_type__c')):null;
        String citizenship = objFields.containsKey('citizenship__c')?String.valueOf(obj.get('citizenship__c')):null;
        String degreeType = objFields.containsKey('degree_type__c')?String.valueOf(obj.get('degree_type__c')):null;
        String deliveryType = objFields.containsKey('delivery_type__c')?String.valueOf(obj.get('delivery_type__c')):null;
        String residency = objFields.containsKey('residency__c')?String.valueOf(obj.get('residency__c')):null;
        String schoolCollege = objFields.containsKey('school_college__c')?String.valueOf(obj.get('school_college__c')):null;
        String studentType = objFields.containsKey('student_type__c')?String.valueOf(obj.get('student_type__c')):null;
        String appStatus = (checkStatus == true && objFields.containsKey('application_status__c'))?String.valueOf(obj.get('application_status__c')):null;
        return filter(app, active, programId, applicantTypes, citizenship, degreeType, deliveryType, residency, schoolCollege, studentType, appStatus);
    }

    private static Boolean filter(Application__c app, Boolean active, Id programId, String applicantTypes, String citizenship, String degreeTypes, String deliveryTypes, String residency, String schoolCollege, String studentTypes, String appStatuses) {
        if (app == null)
            return true;
        if (active == false){
            return false;
        }
        if (programId != null && (app.Intended_Program__c == null || app.Intended_Program__c != programId))
            return false;

        if (String.isNotBlank(applicantTypes) && (String.isBlank(app.Applicant_Type__c) || !(new Set<String>(applicantTypes.split(';'))).contains(app.Applicant_Type__c)))
            return false;

        if (String.isNotBlank(citizenship) && (String.isBlank(app.Citizenship__c) || !citizenship.equals(app.Citizenship__c)))
            return false;

        if (String.isNotBlank(schoolCollege) && (String.isBlank(app.School_College__c) || !schoolCollege.equals(app.School_College__c)))
            return false;

        if (String.isNotBlank(deliveryTypes) && (String.isBlank(app.Delivery_Type__c) || !(new Set<String>(deliveryTypes.split(';'))).contains(app.Delivery_Type__c)))
            return false;

        if (String.isNotBlank(residency) && (String.isBlank(app.Residency__c) || !citizenship.equals(app.Residency__c)))
            return false;

        if (String.isNotBlank(studentTypes) && (String.isBlank(app.Student_Type__c) || !(new Set<String>(studentTypes.split(';'))).contains(app.Student_Type__c)))
            return false;
        if(UserInfo.getUserType() != 'Standard' && String.isNotBlank(appStatuses) && (String.isBlank(app.Application_Status__c) || !(new Set<String>(appStatuses.split(';'))).contains(app.Application_Status__c)))
            return false;
        return true;
    }
}