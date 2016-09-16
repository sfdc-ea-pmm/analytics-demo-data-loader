global class WW_CopyCaseHistory implements Database.Batchable<sObject> {
	
	String query;

    global Integer recordsProcessed = 0;

	
	global WW_CopyCaseHistory() {
		this.query = 'SELECT Id, CaseId, CreatedDate, Field, OldValue, NewValue FROM CaseHistory';
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<CaseHistory> scope) {
		
		List<WW_CaseHistory__c> lstCopies = new List<WW_CaseHistory__c>();
		
		for(CaseHistory chObj: scope) {

			String oldValue = String.valueOf(chObj.OldValue);
			String newValue = String.valueOf(chObj.NewValue);
			Integer daysToSubstract = Randomizer.getRandomNumber(731); // Generates random integer taken from [0..731]

			lstCopies.add(new WW_CaseHistory__c(
				ExternalId__c = String.valueOf(chObj.Id),
				CaseId__c = chObj.CaseId,
				Field__c = chObj.Field,
				CreatedDate__c = Date.today().addDays(-daysToSubstract),
				OldValue__c = oldValue,
				NewValue__c = newValue
			));

			recordsProcessed = recordsProcessed + 1;
		}
		
		upsert lstCopies ExternalId__c;
	}
	
	global void finish(Database.BatchableContext BC) {
		
		System.debug(recordsProcessed + ' records processed.');
		List<Id> caseHistoriesIds = new List<Id>();
		
		for(CaseHistory ch: [SELECT Id FROM CaseHistory]) {
			caseHistoriesIds.add(ch.Id);
		}

		List<WW_CaseHistory__c> lstToDelete = [SELECT Id FROM WW_CaseHistory__c WHERE ExternalId__c NOT IN :caseHistoriesIds];
		System.debug(lstToDelete.size() + ' copy records to delete.');
		
		delete lstToDelete;
	}
	
}