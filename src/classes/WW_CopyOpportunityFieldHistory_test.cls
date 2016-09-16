@isTest
private class WW_CopyOpportunityFieldHistory_test {
	
	@testSetup static void setup() {
		
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

        op.Amount = 1500;
        update op;

		OpportunityFieldHistory oppFldHist = new OpportunityFieldHistory(
			OpportunityId = op.Id,
			Field = 'Amount'
		);

		insert oppFldHist;

		WW_OppFieldHistory__c ofhToDelete = new WW_OppFieldHistory__c(
			ExternalId__c = '1000338XYaYUxM',
			OpportunityId__c = op.Id,
			Field__c = 'Amount',
			CreatedDate__c = Date.today()
		);

		insert ofhToDelete;
	}
	
	@isTest static void test_method() {
		Test.startTest();
        WW_CopyOpportunityFieldHistory batchObj = new WW_CopyOpportunityFieldHistory();
        Id batchId = Database.executeBatch(batchObj);
        Test.stopTest();

        Integer badCount = 0;
        for(WW_OppFieldHistory__c hist : [SELECT CreatedDate__c FROM WW_OppFieldHistory__c LIMIT 1000]){
        	Date dateComponent = hist.CreatedDate__c.date();
        	if(dateComponent.daysBetween(Date.today()) > 730){
        		badCount++;
        	}
        }

        System.assertEquals(0, badCount);
	}

}