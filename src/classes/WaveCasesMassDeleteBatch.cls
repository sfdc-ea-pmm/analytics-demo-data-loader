global class WaveCasesMassDeleteBatch implements Database.Batchable<sObject> {
	
	String query = 'SELECT Id FROM Case WHERE External_Id__c LIKE \'W_Case.%\'';
	
	global WaveCasesMassDeleteBatch() {
		
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) {
		delete scope;
	}
	
	global void finish(Database.BatchableContext BC) {
	
	}
	
}