global class ScheduledTimeShifting implements Schedulable{

	global void execute(SchedulableContext sc) {
		System.enqueueJob(new CheckTimeShiftingQueue(true));
	}
	
}