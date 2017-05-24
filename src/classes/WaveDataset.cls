public class WaveDataset extends WaveAsset {
	public String currentVersionId;
    public String currentVersionUrl;
    public String versionsUrl;
    
    public override String getAssetType(){
		return 'Dataset';
	}
}