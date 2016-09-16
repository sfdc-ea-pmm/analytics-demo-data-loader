global class CsvDataImportBatch implements Database.Batchable<List<String>> {
	
	private List<List<String>> csvData;
	private Map<Integer, String> fieldPositions;
	private SObjectType objectType;
	
	global CsvDataImportBatch(SObjectType objectType, List<List<String>> csvData, Map<Integer, String> fieldPositions) {
		this.objectType = objectType;
		this.csvData = csvData;
		this.fieldPositions = fieldPositions;
	}
	
	global Iterable<List<String>> start(Database.BatchableContext BC) {
		return this.csvData;
	}

   	global void execute(Database.BatchableContext BC, List<List<String>> scope) {
		
   		List<SObject> objectsBatch = new List<SObject>();
   		Map<String, Schema.SObjectField> objectFields = this.objectType.getDescribe().fields.getMap();

		for(List<String> sObjRow: scope) {

			SObject objToCreate = this.objectType.newSObject();

			for(Integer i = 0; i < sObjRow.size(); i++) {
				
				String fieldName = this.fieldPositions.get(i);
				String fieldValue = sObjRow[i];

				if(objectFields.containsKey(fieldName)){
					
					// Get field datatype
					Schema.DisplayType fieldType  = objectFields.get(fieldName).getDescribe().getType();

					System.debug(String.format('Setting ({0}) field of type ({1}) with value ({2})', new String[]{
							fieldName, String.valueOf(fieldType), fieldValue
						}));

					if(fieldType == Schema.DisplayType.Boolean){
						objToCreate.put(fieldName, Boolean.valueOf(fieldValue));
					}
					else if (fieldType == Schema.DisplayType.Currency || fieldType == Schema.DisplayType.Double || fieldType == Schema.DisplayType.Percent) {
						objToCreate.put(fieldName, Double.valueOf(fieldValue));
					}
					else if (fieldType == Schema.DisplayType.Integer) {
						objToCreate.put(fieldName, Integer.valueOf(fieldValue));
					}
					else if (fieldType == Schema.DisplayType.Date) {
						objToCreate.put(fieldName, Date.valueOf(fieldValue));	
					}
					else if (fieldType == Schema.DisplayType.DateTime) {
						objToCreate.put(fieldName, DateTime.valueOf(fieldValue));
					}
					else {
						objToCreate.put(fieldName, fieldValue);	
					}
				}
			}

			objectsBatch.add(objToCreate);
		}

		if(objectsBatch.size() > 0) {
			insert objectsBatch;
		}
	}
	
	global void finish(Database.BatchableContext BC) {
		
	}
	
}