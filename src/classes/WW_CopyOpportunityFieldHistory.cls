global class WW_CopyOpportunityFieldHistory implements Database.Batchable<sObject> {
	
	String query;

	public WW_CopyOpportunityFieldHistory() {
		this.query = 'SELECT Id, OpportunityId, CreatedDate, Field, OldValue, NewValue FROM OpportunityFieldHistory';
	}

	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<OpportunityFieldHistory> scope) {
		
		List<WW_OppFieldHistory__c> lstCopies = new List<WW_OppFieldHistory__c>();
		
		for(OpportunityFieldHistory ofhObj: scope) {

			String oldValue = String.valueOf(ofhObj.OldValue);
			String newValue = String.valueOf(ofhObj.NewValue);
			Integer daysToSubstract = Randomizer.getRandomNumber(731); // Generates random integer taken from [0..731]

			lstCopies.add(new WW_OppFieldHistory__c(
				ExternalId__c = String.valueOf(ofhObj.Id),
				OpportunityId__c = ofhObj.OpportunityId,
				Field__c = ofhObj.Field,
				CreatedDate__c = Date.today().addDays(-daysToSubstract),
				OldValue__c = oldValue,
				NewValue__c = newValue
			));
		}
		
		upsert lstCopies ExternalId__c;
	}
	
	global void finish(Database.BatchableContext BC) {
		List<Id> oppFieldHistoriesIds = new List<Id>();
		
		for(OpportunityFieldHistory ch: [SELECT Id FROM OpportunityFieldHistory]) {
			oppFieldHistoriesIds.add(ch.Id);	
		}

		List<WW_OppFieldHistory__c> lstToDelete = [SELECT Id FROM WW_OppFieldHistory__c WHERE ExternalId__c NOT IN :oppFieldHistoriesIds];
		System.debug(lstToDelete.size() + ' copy records to delete.');
		
		delete lstToDelete;
	}

}