@isTest
private class WW_CopyCaseHistory_test {
	
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

		Case c = new Case(OwnerId = u.Id);
		insert c;

		CaseHistory ch = new CaseHistory(
			CaseId = c.Id,
			Field = 'Description'
		);

		insert ch;

		WW_CaseHistory__c chToDelete = new WW_CaseHistory__c(
			ExternalId__c = '19093903mkdkkckckA',
			CaseId__c = c.Id,
			Field__c = 'Description',
			CreatedDate__c = Date.today()
		);

		insert chToDelete;
	}
	
	@isTest static void test_method() {
		Test.startTest();
        WW_CopyCaseHistory wch = new WW_CopyCaseHistory();
        Id batchId = Database.executeBatch(wch);
        Test.stopTest();

        Integer badCount = 0;
        for(WW_CaseHistory__c hist : [SELECT CreatedDate__c FROM WW_CaseHistory__c]){
        	Date dateComponent = hist.CreatedDate__c.date();
        	if(dateComponent.daysBetween(Date.today()) > 730){
        		badCount++;
        	}
        }

        System.assertEquals(0, badCount);
	}
	
}