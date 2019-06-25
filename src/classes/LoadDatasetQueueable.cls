public with sharing class LoadDatasetQueueable implements Queueable, Database.AllowsCallouts{
    
    private String sessionId;
    private String insightsAppName;
    private WaveApplicationDataset datasetToLoad;

    public LoadDatasetQueueable(WaveApplicationDataset dataset, String insightsAppId, String sessionId) {
        this.datasetToLoad = dataset;
		this.sessionId = sessionId;
        this.insightsAppName = 'SharedApp';

        if (String.isNotBlank(insightsAppId)) {
            List<InsightsApplication> insAppLst = [SELECT FolderId FROM InsightsApplication WHERE Id = :insightsAppId];
            if (insAppLst.size() > 0) {
                this.insightsAppName = insAppLst.get(0).FolderId;
            }
        }
    }

    public void execute(QueueableContext context) {
        // Process the load of the edgemart
        // This code is intented to work only for those csv files < 10MB
        HttpResponse res = WaveConfiguratorUtils.httpGetCallout(this.datasetToLoad.csvDataUrl);
        String csvData = res.getBody();

        res = WaveConfiguratorUtils.httpGetCallout(this.datasetToLoad.jsonSchemaUrl);
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

        // Add the Data
        InsightsExternalDataPart dataPart = new InsightsExternalDataPart();
        dataPart.InsightsExternalDataId = iedObj.Id;
        dataPart.PartNumber = 1;
        Blob csvBlob = Blob.valueof(csvData);
        Integer size = csvBlob.size();
        dataPart.dataFile = csvBlob;
        dataPart.DataLength = size;
        insert dataPart;

        // Final Step: Manage the Upload
        iedObj.Action = 'Process';
        update iedObj;
    }
}