global class LoadDatasetBatch implements Database.Batchable<Integer>, Database.Stateful, Database.AllowsCallouts {

    private String insightsAppId;
    private String insightsAppName;
    private WaveApplicationDataset datasetToLoad;
    private String insightsExternalDataId;

    global LoadDatasetBatch(WaveApplicationDataset dataset, String insightsAppId){
        this.datasetToLoad = dataset;
        this.insightsAppId = insightsAppId;
    }

    global Iterable<Integer> start(Database.BatchableContext BC) {
		
        List<Integer> lstIndexes = new List<Integer>();
        for (Integer i = 1; i <= this.datasetToLoad.dataParts; i++) {
            lstIndexes.add(i);
        }

        this.insightsAppName = 'SharedApp';

        if (String.isNotBlank(insightsAppId)) {
            List<InsightsApplication> insAppLst = [SELECT FolderId FROM InsightsApplication WHERE Id = :insightsAppId];
            if (insAppLst.size() > 0) {
                this.insightsAppName = insAppLst.get(0).FolderId;
            }
        }

        HttpResponse res = WaveConfiguratorUtils.httpGetCallout(this.datasetToLoad.jsonSchemaUrl);
        String schemaData = res.getBody();

        InsightsExternalData iedObj = new InsightsExternalData();
        iedObj.EdgemartAlias = this.datasetToLoad.name;
        iedObj.EdgemartContainer = this.insightsAppName;
        iedObj.MetadataJson = EncodingUtil.base64Decode(EncodingUtil.base64Encode(Blob.valueOf(schemaData)));
        iedObj.Format = 'Csv';
        iedObj.Operation = 'Overwrite';
        iedObj.EdgemartLabel = this.datasetToLoad.label;
        iedObj.Action = 'None';

        insert iedObj;
        this.insightsExternalDataId = iedObj.Id;

		return lstIndexes;
	}

    global void execute(Database.BatchableContext BC, List<Integer> scope) {
        if (scope.size() > 0) {
            // Data is chunked or only one file?
            Integer dataIndex = 1;
            String dataUrl = this.datasetToLoad.csvDataUrl;

            if (this.datasetToLoad.dataParts != null && this.datasetToLoad.dataParts > 0) {
                
                dataIndex = scope.get(0);
                dataUrl = this.datasetToLoad.csvDataUrl + this.datasetToLoad.name + '-dataPart-' + dataIndex + '.csv';                            
            }

            HttpResponse resData = WaveConfiguratorUtils.httpGetCallout(dataUrl);
            String csvData = resData.getBody();
            InsightsExternalDataPart dataPart = new InsightsExternalDataPart();
            dataPart.PartNumber = dataIndex;
            Blob csvBlob = Blob.valueof(csvData);
            dataPart.dataFile = csvBlob;
            dataPart.DataLength = csvBlob.size();
            
            insert dataPart;
        }
    }

    global void finish(Database.BatchableContext BC) {		
		InsightsExternalData iedObj = [SELECT Id, Action FROM InsightsExternalData WHERE Id = :this.insightsExternalDataId];
        iedObj.Action = 'Process';
        update iedObj;
	}
}