"
I test the split MessagePack import/export format (see FMSplitMessagePackPrinter) through the public MooseModel API (#exportToSplitMessagePackStream:, #importFromSplitMessagePackStream:) on small FamixJava models.

Exported bytes are decoded with MpDecoder only (see #decode:), independently of FMSplitMessagePackParser. Bytes to import are built by hand with MpEncoder.
"
Class {
	#name : 'FMSplitMessagePackTest',
	#superclass : 'TestCase',
	#instVars : [
		'model'
	],
	#category : 'Fame-ImportExport-MessagePack-Tests-Tests',
	#package : 'Fame-ImportExport-MessagePack-Tests',
	#tag : 'Tests'
}

{ #category : 'helpers' }
FMSplitMessagePackTest >> decode: aByteArray [

	| decoder names entities references entry |
	decoder := MpDecoder on: aByteArray readStream.
	names := OrderedCollection new.
	entities := OrderedCollection new.
	references := OrderedCollection new.
	[ decoder atEnd ] whileFalse: [
			entry := decoder next.
			entry first = 0 ifTrue: [ names add: entry second ].
			entry first = 1 ifTrue: [
					entities add: (Dictionary new
							 at: 'id' put: entry second;
							 at: 'type' put: (names at: entry third + 1);
							 at: 'properties' put: (self decodeProperties: entry fourth names: names);
							 yourself) ].
			entry first = 2 ifTrue: [
					references add: (Dictionary new
							 at: 'id' put: entry second;
							 at: 'properties' put: (self decodeProperties: entry third names: names);
							 yourself) ] ].
	^ Dictionary new
		  at: 'names' put: names asArray;
		  at: 'entities' put: entities asArray;
		  at: 'references' put: references asArray;
		  yourself
]

{ #category : 'helpers' }
FMSplitMessagePackTest >> decodeProperties: aFlatArray names: names [

	| properties |
	properties := Dictionary new.
	1 to: aFlatArray size by: 2 do: [ :i | properties at: (names at: (aFlatArray at: i) + 1) put: (aFlatArray at: i + 1) ].
	^ properties
]

{ #category : 'helpers' }
FMSplitMessagePackTest >> entryNamed: aString in: aSection of: document [

	| id |
	id := ((document at: 'entities') detect: [ :each | ((each at: 'properties') at: 'name' ifAbsent: [ nil ]) = aString ]) at: 'id'.
	^ (document at: aSection) detect: [ :each | (each at: 'id') = id ] ifNone: [ nil ]
]

{ #category : 'helpers' }
FMSplitMessagePackTest >> exported [
	"Decode the exported entries with MpDecoder only: a Dictionary with 'names', 'entities' and 'references'. Each entry is a Dictionary with 'id', 'type' (entities only, as the class name) and 'properties' (property name -> value as decoded: bare for single-valued, Array for multivalued)."

	^ self decode: self exportedBytes
]

{ #category : 'helpers' }
FMSplitMessagePackTest >> exportedBytes [

	^ ByteArray streamContents: [ :stream | model exportToSplitMessagePackStream: stream ]
]

{ #category : 'helpers' }
FMSplitMessagePackTest >> import: entries [
	"entries are the top-level MessagePack arrays of the format, encoded here with MpEncoder."

	model importFromSplitMessagePackStream: (ByteArray streamContents: [ :stream |
				 | encoder |
				 encoder := MpEncoder on: stream.
				 entries do: [ :each | encoder nextPut: each ] ]) readStream
]

{ #category : 'helpers' }
FMSplitMessagePackTest >> names [
	"Name table used by the import tests."

	^ #( 'Famix-Java-Entities.Method' 'name' 'cyclomaticComplexity' 'Famix-Java-Entities.Class' 'isAbstract' 'parentType'
	     'declaredExceptions' 'numberOfLinesOfCode' ) collect: [ :each |
			  {
				  0.
				  each } ]
]

{ #category : 'helpers' }
FMSplitMessagePackTest >> setUp [

	super setUp.
	model := FamixJavaModel new
]

{ #category : 'tests - export' }
FMSplitMessagePackTest >> testExportIntegerBeyond64BitsAsExt [

	| value |
	(model newMethodNamed: 'bar') numberOfLinesOfCode: (2 raisedTo: 70).
	value := ((self exported at: 'entities') first at: 'properties') at: 'numberOfLinesOfCode'.

	self assert: value typeCode equals: 1.
	self assert: value data asString equals: (2 raisedTo: 70) printString
]

{ #category : 'tests - export' }
FMSplitMessagePackTest >> testExportMultivaluedAsArray [

	| document method |
	method := model newMethodNamed: 'bar'.
	method addDeclaredException: (model newExceptionNamed: 'E1').
	method addDeclaredException: (model newExceptionNamed: 'E2').
	document := self exported.

	self
		assert: (((self entryNamed: 'bar' in: 'references' of: document) at: 'properties') at: 'declaredExceptions') asSet
		equals: ({ 'E1'. 'E2' } collect: [ :each | (self entryNamed: each in: 'entities' of: document) at: 'id' ]) asSet
]

{ #category : 'tests - export' }
FMSplitMessagePackTest >> testExportOneEntity [

	| document foo |
	(model newClassNamed: 'Foo') isAbstract: true.
	document := self exported.

	self assert: (document at: 'entities') size equals: 1.
	foo := (document at: 'entities') first.
	self assert: (foo at: 'type') equals: 'Famix-Java-Entities.Class'.
	self assert: ((foo at: 'properties') at: 'name') equals: 'Foo'.
	self assert: ((foo at: 'properties') at: 'isAbstract') equals: true.
	self assert: ((foo at: 'properties') at: 'isStub') equals: false.
	self assert: (document at: 'references') isEmpty.
	"each name is in the table once"
	self assert: (document at: 'names') asSet size equals: (document at: 'names') size
]

{ #category : 'tests - export' }
FMSplitMessagePackTest >> testExportReferencesOnSingleValuedSide [

	| document |
	(model newMethodNamed: 'bar') parentType: (model newClassNamed: 'Foo').
	document := self exported.

	"entities: primitive properties only"
	self deny: (((self entryNamed: 'Foo' in: 'entities' of: document) at: 'properties') includesKey: 'methods').
	self deny: (((self entryNamed: 'bar' in: 'entities' of: document) at: 'properties') includesKey: 'parentType').
	"references: the relation is written on the method side only, as a bare id"
	self assert: (self entryNamed: 'Foo' in: 'references' of: document) isNil.
	self
		assert: (((self entryNamed: 'bar' in: 'references' of: document) at: 'properties') at: 'parentType')
		equals: ((self entryNamed: 'Foo' in: 'entities' of: document) at: 'id')
]

{ #category : 'tests - import' }
FMSplitMessagePackTest >> testImportEntitiesAndReferences [

	| class method |
	"names: 0 Method, 1 name, 2 cyclomaticComplexity, 3 Class, 4 isAbstract, 5 parentType"
	self import: self names , {
			{
				1.
				1.
				0.
				{ 1. 'bar'. 2. -1 } }.
			{
				1.
				2.
				3.
				{ 1. 'Foo'. 4. true } }.
			{
				2.
				1.
				{ 5. 2 } } }.

	self assert: model entities size equals: 2.
	class := model allClasses anyOne.
	method := model allMethods anyOne.
	self assert: class name equals: 'Foo'.
	self assert: class isAbstract.
	self assert: method name equals: 'bar'.
	self assert: method cyclomaticComplexity equals: -1.
	self assert: method parentType identicalTo: class.
	self assert: class methods asArray equals: { method }
]

{ #category : 'tests - import' }
FMSplitMessagePackTest >> testImportIntegerBeyond64Bits [
	"names: 0 Method, 7 numberOfLinesOfCode"

	self import: self names , { {
			1.
			1.
			0.
			{
				7.
				(MpExtValue typeCode: 1 data: (2 raisedTo: 70) printString asByteArray) } } }.

	self assert: model allMethods anyOne numberOfLinesOfCode equals: (2 raisedTo: 70)
]

{ #category : 'tests - import' }
FMSplitMessagePackTest >> testImportUnknownIdsAreSkipped [

	| class method |
	"names: 0 Method, 1 name, 3 Class, 5 parentType, 6 declaredExceptions"
	self import: self names , {
			{
				1.
				1.
				0.
				{ 1. 'bar' } }.
			{
				1.
				2.
				3.
				{ 1. 'Foo' } }.
			{
				2.
				99.
				{ 5. 2 } }.
			{
				2.
				1.
				{
					6.
					{ 98 }.
					5.
					2 } } }.

	class := model allClasses anyOne.
	method := model allMethods anyOne.
	self assert: method parentType identicalTo: class.
	self assert: class methods asArray equals: { method }.
	self assert: method declaredExceptions isEmpty
]
