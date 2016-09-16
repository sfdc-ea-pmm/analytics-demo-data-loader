global class WW_CopyHistory implements Schedulable, Database.Batchable<sObject> {

    global void execute (Database.BatchableContext BC, List<sObject> scope) {
        copyHistory('CaseHistory');
        copyHistory('OpportunityFieldHistory');
        copyWaterfallHistory();
    }   
    
    global void execute (SchedulableContext SC) {
        
        // ?
    
    }
    
    public void copyHistory (String sObjectType) {

       	String parentObject = (sObjectType == 'OpportunityFieldHistory' ? sObjectType.removeEnd('FieldHistory') : sObjectType.removeEnd('History'));
        String dbQuery = 'SELECT CreatedById, CreatedDate, Field, NewValue, OldValue, ' + parentObject + 'Id FROM ' + sObjectType;
        
		List<WaveHistory__c> oldHistory = [SELECT Id FROM WaveHistory__c WHERE sObjectType__c =: parentObject];
        List<WaveHistory__c> customHistory = new List<WaveHistory__c>();
        List<sObject> defaultHistory = Database.Query(dbQuery);
        
        for (sObject ch: defaultHistory) { 
            customHistory.add(
                new WaveHistory__c(
                    sObjectType__c = parentObject,
                    CreatedDate__c = Datetime.valueOf(ch.get('CreatedDate')), 
                    ParentId__c    = String.valueOf(ch.get(parentObject + 'Id')),
                    Field__c       = String.valueOf(ch.get('Field')),
                    NewValue__c    = String.valueOf(ch.get('NewValue')),
                    OldValue__c    = String.valueOf(ch.get('OldValue'))        
                )
            );
        }
        
        try {
            if (customHistory != null && customHistory.size() > 0) {
	            System.debug('INSERTED: ' + customHistory); insert customHistory;             
            }
        } catch (Exception e) {
            System.debug(e.getMessage());
        } finally {
            if (oldHistory != null && oldHistory.size() > 0) {
                System.debug('DELETED: ' + oldHistory); delete oldHistory;
            }
        }

        
    }
        
    public void copyWaterfallHistory () {
    
        List<WaterfallHistory__c> oldHistory = [SELECT Id FROM WaterfallHistory__c];
        List<WaterfallHistory__c> customHistory = new List<WaterfallHistory__c>();
        List<OpportunityHistory> defaultHistory = [SELECT Amount,CloseDate,CreatedById,CreatedDate,ExpectedRevenue,ForecastCategory,Id,OpportunityId,Probability,StageName 
                                                   FROM OpportunityHistory];
        for (OpportunityHistory oh: defaultHistory) {
            customHistory.add(
                new WaterfallHistory__c(
            		Amount__c 			= oh.Amount,
                    CloseDate__c 		= oh.CloseDate,
                    CreatedDate__c 		= oh.CreatedDate,
                    ExpectedRevenue__c 	= oh.ExpectedRevenue,
                    ForecastCategory__c = oh.ForecastCategory,
					Probability__c 		= oh.Probability,
                    StageName__c 		= oh.StageName
            	)
			); 
        }
        
        try {
            if (customHistory != null && customHistory.size() > 0) {
	            System.debug('INSERTED: ' + customHistory); insert customHistory;             
            }
        } catch (Exception e) {
            System.debug(e.getMessage());
        } finally {
            if (oldHistory != null && oldHistory.size() > 0) {
                System.debug('DELETED: ' + oldHistory); delete oldHistory;
            }
        }
        
    }
    
    public Iterable<sObject> start (Database.BatchableContext BC) {
        
        return null;
    }
    
    global void finish(Database.BatchableContext BC) {}
    
    
    
}