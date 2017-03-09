global class WaveAccountsMassDeleteBatch implements Database.Batchable<sObject> {
	
	String query = 'SELECT Id FROM Account WHERE External_Id__c LIKE \'W_Account.%\'';
	
	global WaveAccountsMassDeleteBatch() {
		
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator([SELECT Id FROM Account WHERE External_Id__c LIKE 'W_Account.%']);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) {
		delete scope;
	}
	
	global void finish(Database.BatchableContext BC) {
		
	}
	
}