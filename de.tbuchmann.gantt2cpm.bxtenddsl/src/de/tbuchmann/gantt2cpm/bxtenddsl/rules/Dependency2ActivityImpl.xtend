package de.tbuchmann.gantt2cpm.bxtenddsl.rules;

import cpm.Event
import de.tbuchmann.gantt2cpm.bxtenddsl.trafo.Gantt2Cpm
import gantt.Activity
import gantt.DependencyType

class Dependency2ActivityImpl extends Dependency2Activity {	
	new(Gantt2Cpm trafo) {
		super(trafo)
	}
	
	// activities named "a->b" represent dependencies
	override protected filterT(cpm.Activity t) {
		t.name.contains("->")
	}
	
	// name of the connecting activity: "<predecessor>-><successor>"
	override protected nameFrom(Activity successor, Activity predecessor) {
		new Type4name(predecessor.name + "->" + successor.name)
	}
	
	// Gantt -> CPM: the dependency type selects start or end event of predecessor (source) and successor (target)
	override protected sourceEvent_targetEventFrom(DependencyType dependencyType, Event preSrcEvent, Event preTrgEvent,
			Event sucSrcEvent, Event sucTrgEvent) {
		val sourceStart = #{DependencyType.START_START, DependencyType.START_END}.contains(dependencyType)
		val sourceEvent = if (sourceStart) preSrcEvent else preTrgEvent
		val targetStart = #{DependencyType.START_START, DependencyType.END_START}.contains(dependencyType)
		val targetEvent = if (targetStart) sucSrcEvent else sucTrgEvent
		
		new Type4sourceEvent_targetEvent(sourceEvent, targetEvent)
	}
	
	// CPM -> Gantt: reconstruct the dependency type from whether the connected events are start events,
	// and the predecessor/successor from the activities that own these events
	override protected dependencyType_predecessor_successorFrom(Event sourceEvent, Event targetEvent) {
		val isStartEvent = [Event event | event.outgoingActivities.exists[!name.contains("->")]]
		val dependencyType = if (isStartEvent.apply(sourceEvent) && isStartEvent.apply(targetEvent)) {
			DependencyType.START_START
		} else if (isStartEvent.apply(sourceEvent)) {
			DependencyType.START_END
		} else if (isStartEvent.apply(targetEvent)) {
			DependencyType.END_START
		} else {
			DependencyType.END_END
		}
		
		val predecessor = Activity2Activity.source(sourceEvent.corr).source // or additional method param
		val successor = Activity2Activity.source(targetEvent.corr).source
		
		return new Type4dependencyType_predecessor_successor(dependencyType, predecessor, successor)
	}
}
