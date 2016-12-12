@isTest(seeAllData=true)
private class WW_CopyOpportunityHistory_test {
	
	@isTest static void test_method() {
		
		// Implement test code
		Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];

        User u = new User(
            FirstName = 'Guybrush',
            LastName = 'Threepwood',
            UserName = 'guybrush@example.com',
            Email = 'guybrush@example.com',
            Alias = 'guyb',
            CommunityNickname = 'guybrush',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US'
        );

        insert u;

        Opportunity op = new Opportunity(
            OwnerId = u.Id,
            Name = 'Test Opp',
            StageName = 'Open', 
            CloseDate = Date.today(),
            Amount = 1000
        );

        insert op;

		WW_OppHistory__c chToDelete = new WW_OppHistory__c(
			ExternalId__c = '19093903mkdkkckckA',
			OpportunityId__c = op.Id,
			CreatedDate__c = Date.today(),
			Amount__c = op.Amount,
			CloseDate__c = op.CloseDate,
			ExpectedRevenue__c = op.ExpectedRevenue,
			ForecastCategory__c = op.ForecastCategory,
			StageName__c = op.StageName,
			Probability__c = op.Probability
		);

		insert chToDelete;

		Test.startTest();
		WW_CopyOpportunityHistory batchObj = new WW_CopyOpportunityHistory();
        Id batchId = Database.executeBatch(batchObj);
    	Test.stopTest();
    	Integer cant1 = [SELECT count() FROM OpportunityHistory LIMIT 200];
    	Integer cant2 = [SELECT count() FROM WW_OppHistory__c];
    	System.assertEquals(cant1, cant2);

    	/*Integer badCount = 0;
        for(WW_OppHistory__c hist : [SELECT CreatedDate__c FROM WW_OppHistory__c LIMIT 1000]){
        	Date dateComponent = hist.CreatedDate__c.date();
        	if(dateComponent.daysBetween(Date.today()) > 730){
        		badCount++;
        	}
        }

        System.assertEquals(0, badCount);*/
	}
	
}