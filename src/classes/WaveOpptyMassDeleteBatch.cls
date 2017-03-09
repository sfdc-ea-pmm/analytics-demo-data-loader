global class WaveOpptyMassDeleteBatch implements Database.Batchable<sObject> {
	
	String query = 'SELECT Id FROM Opportunity WHERE External_Id__c LIKE \'W_Opportunity.%\'';
	
	global WaveOpptyMassDeleteBatch() {
		
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator([SELECT Id FROM Opportunity WHERE External_Id__c LIKE 'W_Opportunity.%']);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) {
		delete scope;
	}
	
	global void finish(Database.BatchableContext BC) {
	
	}
	
}