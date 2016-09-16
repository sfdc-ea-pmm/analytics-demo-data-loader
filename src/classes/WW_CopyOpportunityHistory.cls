global class WW_CopyOpportunityHistory implements Database.Batchable<sObject> {
	
	String query;
	
	global WW_CopyOpportunityHistory() {
		this.query = 'SELECT Id, OpportunityId, CreatedDate, Amount, CloseDate, ExpectedRevenue, ForecastCategory, StageName, Probability FROM OpportunityHistory';
		if(Test.isRunningTest()){
			this.query = this.query + ' LIMIT 200';
		}
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<OpportunityHistory> scope) {
		List<WW_OppHistory__c> lstCopies = new List<WW_OppHistory__c>();
		
		for(OpportunityHistory oppHistObj: scope) {

			Integer daysToSubstract = Randomizer.getRandomNumber(731); // Generates random integer taken from [0..731]

			lstCopies.add(new WW_OppHistory__c(
				ExternalId__c = String.valueOf(oppHistObj.Id),
				OpportunityId__c = oppHistObj.OpportunityId,
				CreatedDate__c = Date.today().addDays(-daysToSubstract),
				Amount__c = oppHistObj.Amount,
				CloseDate__c = oppHistObj.CloseDate,
				ExpectedRevenue__c = oppHistObj.ExpectedRevenue,
				ForecastCategory__c = oppHistObj.ForecastCategory,
				StageName__c = oppHistObj.StageName,
				Probability__c = oppHistObj.Probability
			));
		}
		
		upsert lstCopies ExternalId__c;
	}
	
	global void finish(Database.BatchableContext BC) {
		List<Id> oppHistoriesIds = new List<Id>();
		
		for(OpportunityHistory oppH: [SELECT Id FROM OpportunityHistory]) {
			oppHistoriesIds.add(oppH.Id);	
		}

		List<WW_OppHistory__c> lstToDelete = [SELECT Id FROM WW_OppHistory__c WHERE ExternalId__c NOT IN :oppHistoriesIds];
		System.debug(lstToDelete.size() + ' copy records to delete.');

		delete lstToDelete;
	}
	
}