<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Email_External_Reminder</fullName>
        <description>Email External Reminder</description>
        <protected>false</protected>
        <recipients>
            <field>External_Email__c</field>
            <type>email</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Application_Email_Templates/External_Response_Reminder</template>
    </alerts>
    <alerts>
        <fullName>Email_External_Response</fullName>
        <description>Email External Response</description>
        <protected>false</protected>
        <recipients>
            <field>External_Email__c</field>
            <type>email</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Application_Email_Templates/External_Response_Requested</template>
    </alerts>
</Workflow>
