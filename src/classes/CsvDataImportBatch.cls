global class CsvDataImportBatch implements Database.Batchable<List<String>>, Database.Stateful {
	
	private List<List<String>> csvData;
	private Map<Integer, String> fieldPositions;
	private Map<String, Integer> fieldIndexes;
	private List<WaveApplicationObjectRelation> relations;
	private SObjectType objectType;
	private List<SmartLookup> smartLookups;
	private List<String> debugMessages;
	
	global CsvDataImportBatch(SObjectType objectType, List<List<String>> csvData, Map<Integer, String> fieldPositions, List<WaveApplicationObjectRelation> relations) {
		this.objectType = objectType;
		this.csvData = csvData;
		this.fieldPositions = fieldPositions;
		this.relations = relations;
		this.debugMessages = new List<String>();

		// Then we get the table of <fieldName, columnIndexInCSV
		this.fieldIndexes = new Map<String, Integer>();
		for(Integer columnNumber: this.fieldPositions.keySet()) {
    		
    		// Gets the column name
    		String headerValue = this.fieldPositions.get(columnNumber);

    		this.fieldIndexes.put(headerValue, columnNumber);
    	}
	}
	
	global Iterable<List<String>> start(Database.BatchableContext BC) {
		
		// Prepare headers and return all data
		this.prepareSmartLookups();

		return this.csvData;
	}

   	global void execute(Database.BatchableContext BC, List<List<String>> scope) {

   		System.debug('About to process ' + scope.size() + ' records of type ' + this.objectType.getDescribe().getName());
		
   		// First handle smart lookups
   		this.processSmartLookupForBatch(scope);

   		List<SObject> objectsBatch = new List<SObject>();
   		List<String> lstExternalIds = new List<String>();
   		Map<String, Schema.SObjectField> objectFields = this.objectType.getDescribe().fields.getMap();

   		// For each row of data in the CSV
		for(List<String> sObjRow: scope) {

			// Will create an object
			SObject objToCreate = this.objectType.newSObject();

			// For each column in the CSV row
			for(Integer i = 0; i < sObjRow.size(); i++) {
				
				// We get the name using the position and then its value
				String fieldName = this.fieldPositions.get(i);
				String fieldValue = sObjRow[i];

				if(objectFields.containsKey(fieldName)){
					
					// Get field datatype
					Schema.DisplayType fieldType  = objectFields.get(fieldName).getDescribe().getType();

					if(fieldType == Schema.DisplayType.Boolean){
						// Boolean
						objToCreate.put(fieldName, Boolean.valueOf(fieldValue));
					}
					else if (fieldType == Schema.DisplayType.Currency || fieldType == Schema.DisplayType.Double || fieldType == Schema.DisplayType.Percent) {
						// Real number
						objToCreate.put(fieldName, Double.valueOf(fieldValue));
					}
					else if (fieldType == Schema.DisplayType.Integer) {
						// Integer
						objToCreate.put(fieldName, Integer.valueOf(fieldValue));
					}
					else if (fieldType == Schema.DisplayType.Date) {
						// Date
						objToCreate.put(fieldName, Date.valueOf(fieldValue));	
					}
					else if (fieldType == Schema.DisplayType.DateTime) {
						// Datetime
						objToCreate.put(fieldName, DateTime.valueOf(fieldValue));
					}
					else {
						// String
						if(!(this.objectType.getDescribe().getName() == 'User' && fieldName == 'Name')){
							objToCreate.put(fieldName, fieldValue);	
						}
					}

					if(fieldName.equalsIgnoreCase('External_Id__c')){
						lstExternalIds.add(fieldValue);
					}
				}
			}

			objectsBatch.add(objToCreate);
		}

		if(objectsBatch.size() > 0) {
			
			// We must determine which objects to insert, and which to update
			String genQuery = 'SELECT Id, External_Id__c FROM ' + this.objectType.getDescribe().getName() + ' WHERE External_Id__c IN :lstExternalIds';
	        List<SObject> alreadyThere = Database.query(genQuery);
	        Map<String, String> sfIdsByExternalId = new Map<String, String>();
	        
	        for(SObject sObj: alreadyThere) {
	        	sfIdsByExternalId.put(String.valueOf(sObj.get('External_Id__c')), String.valueOf(sObj.get('Id')));
	        }

	        List<SObject> lstToInsert = new List<SObject>();
	        List<SObject> lstToUpdate = new List<SObject>();

	        for(SObject sObj: objectsBatch) {
	        	if(sfIdsByExternalId.containsKey(String.valueOf(sObj.get('External_Id__c')))){
	        		sObj.put('Id', sfIdsByExternalId.get(String.valueOf(sObj.get('External_Id__c'))));
	        		lstToUpdate.add(sObj);
	        	}
	        	else {
	        		lstToInsert.add(sObj);
	        	}
	        }

	        System.debug(lstToInsert.size() + ' objects to insert.');
	        System.debug(lstToUpdate.size() + ' objects to update.');

	        // DML
	        update lstToUpdate; // For now, only inserts
			insert lstToInsert;
		}
	}
	
	global void finish(Database.BatchableContext BC) {
		
	}

	private void prepareSmartLookups(){
		
    	this.smartLookups = new List<SmartLookup>();

    	// Now we traverse relations of the object
    	for(WaveApplicationObjectRelation relObj: this.relations) {
    		
    		SmartLookup smLookUp = new SmartLookup();

    		String csvColumnName = relObj.csvColumnName;
    		smLookUp.columnNumber = this.fieldIndexes.get(csvColumnName);
    		smLookUp.SObjectType = relObj.targetSObject;
    		smLookUp.targetField = relObj.targetSObjectLookupField;

    		this.fieldPositions.put(smLookUp.columnNumber, relObj.foreignKeyField);
    		this.smartLookups.add(smLookUp);
    	}
	}

	private void processSmartLookupForBatch(List<List<String>> scope){
		
		if(scope != null) {

        	// Get all possible unique values to be replaced with IDs
        	// For each smart lookup
	        for (SmartLookup smLookUp : this.smartLookups) {

	        	// For each row we collect the values in the set
	            for (List<String> row : scope) {
	                smLookUp.plainTextValues.add(row[smLookUp.columnNumber]);
	            }
	        }

	        // Get mapping of id to name, and add to lookup object
	        for (SmartLookup s : this.smartLookups) {	        	
	            
	            List<String> relevantValues = new List<String>(s.plainTextValues);
	            String sObjToQuery = s.SObjectType;
	            String sFieldToQuery = s.targetField;
				String generatedQuery = 'SELECT Id, ' + sFieldToQuery + ' FROM ' + sObjToQuery + ' WHERE ' + sFieldToQuery + ' IN :relevantValues';
	            List<SObject> temp = Database.query(generatedQuery);
	            
	            for (SObject t: temp) {
	                s.replaceValues.put(String.valueOf(t.get(sFieldToQuery)), String.valueOf(t.get('Id')));
	            }

	            // Search whether there are Extenal_Id__c with not found id
	            for(String relVal: relevantValues) {
	            	if(!s.replaceValues.containsKey(relVal)){
	            		// Log Ids that weren't found for the name
	            		//System.debug(String.format('Id not found for {0} = "{1}" in SObject: {2}. This may cause an exception.', new String[]{ sFieldToQuery, relVal, sObjToQuery }));
	            		// This time: Throw exception
	            		throw new CsvDataImportException(String.format('Id not found for {0} = "{1}" in SObject: {2}. This may cause an exception.', new String[]{ sFieldToQuery, relVal, sObjToQuery }));
	            	}
	            	else {
	            		//System.debug('Successful lookup in ' + sObjToQuery + ' object. Id for ' + sFieldToQuery + ' = ' + relVal + ': ' + s.replaceValues.get(relVal));
	            	}
	            }
	        }
	        
	        // Replace name values with Id equivalent
	        for (List<String> row : scope) {
	            for (SmartLookup s: this.smartLookups) {
	            	row[s.ColumnNumber] = s.replaceValues.get(row[s.ColumnNumber]);
	            }
	        }
		}
	}

	global class CsvDataImportException extends Exception {
		
	}
}