public virtual class WaveFolder extends WaveAsset {
	public String applicationStatus;
	public String templateSourceId;

	public override String getAssetType(){
		return 'Folder';
	}
}