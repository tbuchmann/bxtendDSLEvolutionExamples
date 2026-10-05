package de.tbuchmann.gantt2cpm.bxtenddsl.rules;

import cpm.Activity
import cpm.Event
import de.tbuchmann.gantt2cpm.bxtenddsl.trafo.Gantt2Cpm

class Activity2ActivityImpl extends Activity2Activity {	
	new(Gantt2Cpm trafo) {
		super(trafo)
	}
	
	override protected onSrcEventCreation(Event srcEvent) {
		srcEvent.number = nextEventNumber++
		srcEvent.outgoingActivities += srcEvent.corr.target().target // DSL mapping possible, but has creation semantic
	}
	override protected onTrgEventCreation(Event trgEvent) {
		trgEvent.number = nextEventNumber++
		trgEvent.incomingActivities += trgEvent.corr.target().target
	}
	
	override protected filterTarget(Activity target) {
		!target.name.contains("->")
	}
	override protected filterSrcEvent(Event srcEvent, Activity target) {
		srcEvent == target.sourceEvent
	}
	override protected filterTrgEvent(Event trgEvent, Event srcEvent, Activity target) {
		trgEvent == target.targetEvent
	}
	
	int nextEventNumber = 1
}
