# BXtendDSL Examples (including csync)

Eight classic bidirectional transformation (BX) problems, solved with **BXtendDSL**, a rule-based DSL for
incremental, bidirectional model transformations on top of EMF and Xtend. Each example is an Eclipse
plug-in project that contains the declarative rule specification and the small amount of hand-written Xtend code that
the specification cannot express. All eight examples pass their synchronisation scenarios (initial transformation,
incremental changes on either side, and concurrent changes on both sides).

## The examples

| Project | Problem | Source model | Target model | Main difficulty |
|---|---|---|---|---|
| `de.tbuchmann.ast2dag.bxtenddsl` | Expression tree to DAG | `ast` (tree) | `dag` (shared nodes) | Equal sub-expressions are merged into one node; the tree is rebuilt from the parent links of the DAG. |
| `de.tbuchmann.bags2bags.bxtenddsl` | Bag with duplicates to bag with multiplicities | `bags1` (one element per occurrence) | `bags2` (value + count) | N source elements to one target element; concurrent changes of value and multiplicity. |
| `de.tbuchmann.ecore2sql.bxtenddsl` | Ecore to relational schema | Ecore | `sql` | Seven rules selected by filters; structure without counterpart (keys, root table, annotations). |
| `de.tbuchmann.f2p.bxtenddsl` | Families to Persons | `Families` | `Persons` | Gender from role, family name encoded in the person name; target-only data (birthday); options. |
| `de.tbuchmann.gantt2cpm.bxtenddsl` | Gantt chart to CPM network | `gantt` | `cpm` | Dependencies become activities between events; the dependency type is reconstructed from events. |
| `de.tbuchmann.pdb12pdb2.bxtenddsl` | Person database 1 to 2 | `pdb1` (first/last name) | `pdb2` (name) | Splitting a name is ambiguous; the option decides, hippocraticness must be kept. |
| `de.tbuchmann.pn2pnw.bxtenddsl` | Petri net to weighted Petri net | `pn` (transitions reference places) | `pnw` (explicit edge objects) | Edges are grouped per transition and created/deleted from the place lists. |
| `de.tbuchmann.set2oset.bxtenddsl` | Set to ordered set | `sets` | `osets` (linked list) | The list order has no source counterpart. |

## Project layout

Every project has the same structure:

```
de.tbuchmann.<name>.bxtenddsl/
├── src/                  HAND-WRITTEN (the part to read)
│   └── .../rules/
│       ├── <Name>.bxtend         the declarative rule specification (BXtendDSL)
│       └── <Rule>Impl.xtend      hand-written hooks for one rule
├── custom-src/           hand-written helpers outside the rule classes (only ecore2sql: SqlSupport.xtend)
├── BXtend/               generated, tracked: correspondence model (EMF), Elem2Elem base class, abstract trafo
├── src-gen/              generated from the .bxtend file, not tracked (rule base classes, trafo)
├── xtend-gen/, bin/      Xtend-to-Java output and class files, not tracked
├── model/                CorrModel.ecore / .genmodel: the correspondence model
└── BXtend.properties     project/package/trafo name used by the generator
```

Only `src/` (and `custom-src/`) are written by hand. Everything else is generated and can be ignored.

### How the generation works

1. The `.bxtend` file declares source and target metamodel, optional options, and the rules.
2. The BXtendDSL generator produces, per rule, an abstract class (`Member2Female`, `Operator2Operator`, ...) with the
   complete synchronisation logic, a trafo class that wires the rules together, and a correspondence model that records
   which source elements correspond to which target elements.
3. For each rule the user writes an `<Rule>Impl` class that extends the generated class and overrides only the hooks that
   are needed. An empty `Impl` class (for example `Net2NetImpl`) means that the DSL specification alone was sufficient.

## The rule language in a nutshell

```
sourcemodel "<nsURI>"            // metamodels
targetmodel "<nsURI>"

options                          // optional, switchable behaviour (here: f2p, pdb12pdb2)
	PREFER_USING_FIRST_SPACE_TO_LAST

rule Person2Person
	src Person s;                 // source element(s) of the rule
	trg Person t;                 // target element(s) of the rule
	s.birthday <--> t.birthday;   // bidirectional attribute mapping
	s.firstName s.lastName <--> s t.name;   // n:m mapping, needs hooks (see Impl class)
	{s.persons: Person2Person} <--> {t.persons: Person2Person};   // containment mapped by another rule
```

| Construct | Meaning |
|---|---|
| `<-->`, `-->`, `<--` | bidirectional / source-to-target only / target-to-source only mapping |
| `{x.ref: RuleA, RuleB}` | a reference whose elements are produced by the named rules |
| `\| filter` | the rule only applies to elements that satisfy `filterX(...)` |
| `\| creation`, `\| deletion` | hooks `onXCreation` / `onXDeletion` run when the element is created / deleted by the rule |
| `\| group` | several source elements are grouped (`groupXElem`) and map to one target element |
| `\| sort` | the groups are ordered (`compareSource` / `compareTarget`) |

For a multi-attribute mapping the generator expects functions such as `tNameFrom(...)` (source to target) and
`firstName_lastNameFrom(...)` (target to source) that return a generated `Type4...` tuple.

## What the hand-written code does

The comments in the sources explain each hook. Overview per example:

### ast2dag
* `Operator2Operator`, `Variable2Variable`, `Number2Number` group AST nodes by a **structural key** (`computeKey`), so
  identical sub-expressions share one DAG node. `leftInverse` / `rightInverse` are the parent links of a shared node.
* `Operator2OperatorImpl.compareSource/compareTarget` order groups so that sub-expressions are handled before the
  expressions that contain them.
* `sFrom` (DAG to AST) creates one AST node per parent reference, which unfolds the DAG back into a tree.
* `Model2ModelImpl` collects all DAG nodes of the root (`exprsFrom`) and finds the root of the AST again by walking up the
  inverse links (`exprFrom`).

### bags2bags
* The DSL specification is a group rule: elements with the same value are one group with `multiplicity` = group size.
* `Element2ElementImpl` additionally implements **concurrent synchronisation** by overriding `synch()`. It keeps a baseline
  (last value and multiplicity per group) to find out which side changed. A change on one side wins, the source wins when
  both changed. It also regroups drifted elements, creates source groups for new target elements, and deletes
  groups that vanished on one side.

### ecore2sql
* Seven rules are separated by filters: single-valued attribute (`Attribute2Column`), multi-valued attribute
  (`Attribute2Table`), class (`Class2Table`), cross reference (`Reference2Column`), containment (`Containment2Column`),
  bidirectional reference (`Reference2Relation`), package (`Package2Schema`).
* SQL constructs without an Ecore feature are added in the hooks: the `EObject` root table, primary and foreign keys,
  `abstract` / `concrete`, super-type keys, and annotations that record which Ecore construct a table or column came
  from (`filterT` evaluates them). They live in `custom-src/.../SqlSupport.xtend`.
* `dissolveOnFilterMismatch` lets an element move to another rule when its properties change (for example a reference
  that loses its opposite).
* `afterSynch` reconciles what is no mapping (generalisation, abstract flag, opposite ends, owner and name of a
  multi-valued attribute) using a *last known state*: the side that changed wins, the source if both changed.
* `onSCreation` hooks create the Ecore side from a table/column (names are encoded in the SQL names, for example
  `<class>_<attribute>` or `<name>_inverse_<opposite>`).

### f2p
* Persons are named `"<family>, <member>"`. `Member2Female` handles mothers and daughters, `Member2Male` fathers and sons.
* In the direction Persons to Families the hook `memNameFrom` finds or creates the family and chooses the member slot
  according to the options `PREFER_EXISTING_FAMILY_TO_NEW` and `PREFER_CREATING_PARENT_TO_CHILD`.
* `FamilyIndex` is a cache of the families by name; it avoids a quadratic scan when many persons are propagated.
* `birthdays` stores the birthday, which exists only in Persons, so it survives the member being re-created.
* `findMatchingFemale` / `findMatchingFamilyMember` (and the male counterparts) define the **equivalence** used to match
  existing, not yet corresponding elements of both models at initial synchronisation.
* `conflictPolicy() = DETECT_CHANGES` resolves every mapping against the baseline of the last synchronisation.

### gantt2cpm
* A Gantt activity maps to a CPM activity with a start and an end event. A Gantt dependency maps to a CPM activity whose
  name has the form `"<predecessor>-><successor>"`; `filterTarget` / `filterT` separate the two kinds.
* `Dependency2ActivityImpl` derives the connected events from the dependency type
  (`sourceEvent_targetEventFrom`) and, in the other direction, the type from whether the events are start events
  (`dependencyType_predecessor_successorFrom`).
* `Activity2ActivityImpl` numbers new events and restricts the candidate events of an activity to the ones it
  references (a performance measure).

### pdb12pdb2
* `Person2PersonImpl.nameFrom` joins first and last name. `firstName_lastNameFrom` splits the name at the first or last space
  depending on the option `PREFER_USING_FIRST_SPACE_TO_LAST`; a person that was not touched on the target keeps its
  previous split (**hippocraticness**).
* `findMatchingPerson` / `findMatchingDatabase` define the equivalence for initial synchronisation.

### pn2pnw
* Transition groups edge objects: `tpEdges` (outgoing) and `ptEdges` (incoming), grouped by their transition
  (`groupTpEdgesElem`, `groupPtEdgesElem`).
* `tpEdgesFrom` / `ptEdgesFrom` update the edge lists from the connected places (reuse, create, delete);
  `trgT2PFrom` / `srcP2TFrom` map back to places.
* `candidatesTpEdges` / `candidatesPtEdges` look up the group by key instead of testing all groups (performance).

### set2oset
* The target is an ordered set implemented as a doubly linked list (`previous`/`next`) that has no source counterpart.
  `onTCreation` appends a new element at the tail (with the tail cached in `lastTail`), `onTDeletion` unlinks it.

## Concepts that recur

* **Incremental synchronisation:** a correspondence model records source/target pairs, so later runs update, create or
  delete only what changed.
* **Conflict handling:** `conflictPolicy() = DETECT_CHANGES` compares both sides with the baseline of the last
  synchronisation. A change on one side is propagated; if both changed, the source wins (ecore2sql `Attribute2ColumnImpl`
  overrides this with `conflictWinner() = TARGET`).
* **Equivalence (`findMatching...`):** pairs elements that exist on both sides at the first synchronisation.
* **Hippocraticness:** unchanged elements are not rewritten (see pdb12pdb2).
* **Performance hooks:** `candidates...` and `FamilyIndex` replace linear searches by lookups.

## Building and running

The projects are Eclipse plug-in projects (Java SE 17) and need the BXtendDSL plug-in `de.ubt.ai1.m2m.bxtenddsl`, as
well as EMF, Xtext/Xtend and (for f2p) the metamodel plug-ins `Families` and `Persons`.

1. Install Eclipse with EMF, Xtext and Xtend and the BXtendDSL plug-in.
2. Import the projects (*File > Import > Existing Projects into Workspace*).
3. Let the generator process the `.bxtend` file of the project (it fills `src-gen/`, `BXtend/` and `model/`).
   The Xtend builder then fills `xtend-gen/`.
4. Instantiate the `trafo` class named in `BXtend.properties` (for example `de.tbuchmann.f2p.bxtenddsl.trafo.FamiliesToPersons`)
   and run its synchronisation methods on the source and target models.

The generated folders are not versioned (`src-gen/`, `xtend-gen/`, `bin/` are in `.gitignore`).

## License

See [LICENSE](LICENSE).
