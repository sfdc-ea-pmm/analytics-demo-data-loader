public with sharing class WaveDataCleaner {
	
	public WaveDataCleaner() {
		
	}

	public static void clearData(){
		
		List<Event> eventstodel = [SELECT Id FROM Event WHERE External_ID__c LIKE '%W_Event%'];
		eventstodel.addAll([SELECT Id FROM Event WHERE External_ID__c LIKE '%W_Services_Event%']);
		List<Task> taskstodel = [SELECT Id FROM Task WHERE External_ID__c LIKE '%W_Task%'];
		taskstodel.addAll([SELECT Id FROM Task WHERE External_ID__c LIKE '%W_Sercices_Task%']);
		List<Case> casestodel = [SELECT Id FROM Case WHERE External_ID__c LIKE '%W_Case%'];
		List<Account> accstodel = [SELECT Id FROM Account WHERE External_ID__c LIKE '%W_Account%'];
		List<Opportunity> opptstodel = [SELECT Id FROM Opportunity WHERE External_ID__c LIKE '%W_Opportunity%'];

		delete eventstodel;
		delete taskstodel;
		delete opptstodel;
		delete casestodel;
		delete accstodel;
	}
}