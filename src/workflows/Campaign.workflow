<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Campaign_Key_Set_to_ID</fullName>
        <description>Sets the Campaign Key field on Campaign to the Salesforce ID.</description>
        <field>Campaign_Key__c</field>
        <formula>CASESAFEID(Id)</formula>
        <name>Campaign Key: Set to ID</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Campaign%3A Update Campaign Key</fullName>
        <actions>
            <name>Campaign_Key_Set_to_ID</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Campaign.Campaign_Key__c</field>
            <operation>equals</operation>
        </criteriaItems>
        <description>Updates the Campaign Key on Campaign when it is blank.</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
