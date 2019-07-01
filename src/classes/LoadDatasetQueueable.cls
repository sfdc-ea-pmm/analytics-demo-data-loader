public with sharing class LoadDatasetQueueable implements Queueable, Database.AllowsCallouts{
    
    private Double apiVersion;
    private String sessionId;
    private String insightsAppName;
    private WaveApplicationDataset datasetToLoad;

    public LoadDatasetQueueable(WaveApplicationDataset dataset, String insightsAppId, Double apiVersion, String sessionId) {
        this.datasetToLoad = dataset;
		this.sessionId = sessionId;
        this.apiVersion = apiVersion;
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
        // Assumption: 1 character in string = 1 or 2 Bytes
        Integer bytesPerChunk = 1024 * 1024 * 9; // We want 9 MB chunks
        Integer charsPerChunk = bytesPerChunk;
        Integer maxBytesChar = 1;
        Integer currentFilePtr = 0;
        List<String> lstChunks = new List<String>();
        String currentInput = csvData;

        if (WaveConfiguratorUtils.containsDoubleByteCharacters(csvData)) {
            // There are some characters that span 2 bytes
            charsPerChunk = charsPerChunk / 2;
        }

        while(currentFilePtr < csvData.length()){
            String currentChunk = csvData.mid(currentFilePtr, charsPerChunk);
            lstChunks.add(currentChunk);
            currentFilePtr = currentFilePtr + currentChunk.length();
        }

        Integer dataPartIndex = 1;
        List<InsightsExternalDataPart> lstDataParts = new List<InsightsExternalDataPart>();
        
        for (String dataChunk : lstChunks) {
            InsightsExternalDataPart dataPart = new InsightsExternalDataPart();
            dataPart.InsightsExternalDataId = iedObj.Id;
            dataPart.PartNumber = dataPartIndex;
            Blob csvBlob = Blob.valueof(dataChunk);
            Integer size = csvBlob.size();
            dataPart.dataFile = csvBlob;
            dataPart.DataLength = size;

            dataPartIndex++;
            lstDataParts.add(dataPart);
        }
        
        insert lstDataParts;

        // Final Step: Manage the Upload
        iedObj.Action = 'Process';
        update iedObj;
    }

    public static String getDatasetUploadStatus(String datasetDevName){
        try {
            InsightsExternalData iedObj = [SELECT Status FROM InsightsExternalData WHERE EdgemartAlias = :datasetDevName ORDER BY CreatedDate DESC LIMIT 1];
            return iedObj.Status;
        } 
        catch (Exception ex) {
            return '';
        }
    }
}