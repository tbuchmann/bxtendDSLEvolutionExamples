package de.tbuchmann.gantt2cpm.bxtenddsl.rules;

import cpm.Activity
import cpm.Event
import de.tbuchmann.gantt2cpm.bxtenddsl.trafo.Gantt2Cpm
import java.util.List

class Activity2ActivityImpl extends Activity2Activity {	
	new(Gantt2Cpm trafo) {
		super(trafo)
	}
	
	// new events get the next free number and are linked to the activity
	override protected onSrcEventCreation(Event srcEvent) {
		srcEvent.number = nextEventNumber++
		srcEvent.outgoingActivities += srcEvent.corr.target().target // DSL mapping possible, but has creation semantic
	}
	override protected onTrgEventCreation(Event trgEvent) {
		trgEvent.number = nextEventNumber++
		trgEvent.incomingActivities += trgEvent.corr.target().target
	}
	
	// The events of an activity are the ones it references: look them up instead of testing every event of the model.
	override protected candidatesSrcEvent(Activity target, List<Event> all) {
		if (target.sourceEvent === null) emptyList else #[target.sourceEvent]
	}
	override protected candidatesTrgEvent(Event srcEvent, Activity target, List<Event> all) {
		if (target.targetEvent === null) emptyList else #[target.targetEvent]
	}

	// "real" activities only; the ones named "a->b" represent dependencies
	override protected filterTarget(Activity target) {
		!target.name.contains("->")
	}
	// the start / end event is the one the activity references
	override protected filterSrcEvent(Event srcEvent, Activity target) {
		srcEvent == target.sourceEvent
	}
	override protected filterTrgEvent(Event trgEvent, Event srcEvent, Activity target) {
		trgEvent == target.targetEvent
	}
	
	// counter for event numbers
	int nextEventNumber = 1
}
