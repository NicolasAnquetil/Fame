"
I test the split JSON import/export format: a JSON object with an """"entities"""" section (entities with their primitive properties) followed by a """"references"""" section (entity references only, each relation written once).

I test through the public MooseModel API (#exportToSplitJSONStream:, #importFromSplitJSONStream:) using small FamixJava models.
"
Class {
	#name : 'FMSplitJSONTest',
	#superclass : 'TestCase',
	#instVars : [
		'model'
	],
	#category : 'Fame-Tests-Tests',
	#package : 'Fame-Tests',
	#tag : 'Tests'
}

{ #category : 'tests - export' }
FMSplitJSONTest >> entryNamed: aString in: aSection of: json [

	| id |
	id := ((json at: 'entities') detect: [ :each | (each at: 'name' ifAbsent: [ nil ]) = aString ]) at: 'id'.
	^ (json at: aSection) detect: [ :each | (each at: 'id') = id ] ifNone: [ nil ]
]

{ #category : 'running' }
FMSplitJSONTest >> exportedJSON [

	^ STONJSON fromString: (String streamContents: [ :stream | model exportToSplitJSONStream: stream ])
]

{ #category : 'tests - import' }
FMSplitJSONTest >> import: aString [

	model importFromSplitJSONStream: aString readStream
]

{ #category : 'running' }
FMSplitJSONTest >> setUp [

	super setUp.
	model := FamixJavaModel new
]

{ #category : 'tests - export' }
FMSplitJSONTest >> testExportEmptyModel [

	| json |
	json := self exportedJSON.
	self assert: json keys asSet equals: #( 'entities' 'references' ) asSet.
	self assert: (json at: 'entities') isEmpty.
	self assert: (json at: 'references') isEmpty
]

{ #category : 'tests - export' }
FMSplitJSONTest >> testExportFormFeedIsEscaped [

	| exported |
	model newMethodNamed: 'a' , (String with: Character newPage) , 'b'.
	exported := String streamContents: [ :stream | model exportToSplitJSONStream: stream ].

	"Raw control characters are not allowed in JSON strings"
	self deny: (exported includes: Character newPage).
	self assert: (exported includesSubstring: '"name":"a\fb"')
]

{ #category : 'tests - export' }
FMSplitJSONTest >> testExportIsCompact [

	| exported |
	(model newMethodNamed: 'bar') parentType: (model newClassNamed: 'Foo').
	exported := String streamContents: [ :stream | model exportToSplitJSONStream: stream ].

	"No string of this model contains whitespace, so there must be none at all"
	self deny: (exported anySatisfy: [ :char | char isSeparator ]).
	self assert: (exported includesSubstring: '"parentType":{"ref":').
	self assert: (exported beginsWith: '{"entities":[{"FM3":')
]

{ #category : 'tests - export' }
FMSplitJSONTest >> testExportManyToManyOnlyOnOneSide [

	| json exception method |
	exception := model newExceptionNamed: 'MyException'.
	method := model newMethodNamed: 'bar'.
	method addDeclaredException: exception.
	json := self exportedJSON.

	"declaredExceptions sorts before its opposite declaringEntities: only the method side is written"
	self
		assert: ((self entryNamed: 'bar' in: 'references' of: json) at: 'declaredExceptions')
		equals: { (Dictionary with: 'ref' -> ((self entryNamed: 'MyException' in: 'entities' of: json) at: 'id')) }.
	self assert: (self entryNamed: 'MyException' in: 'references' of: json) isNil
]

{ #category : 'tests - export' }
FMSplitJSONTest >> testExportOneToManyOnlyOnSingleValuedSide [

	| json class method fooId |
	class := model newClassNamed: 'Foo'.
	method := model newMethodNamed: 'bar'.
	method parentType: class.
	json := self exportedJSON.
	fooId := (self entryNamed: 'Foo' in: 'entities' of: json) at: 'id'.

	"entities: primitive properties only"
	self assert: ((self entryNamed: 'Foo' in: 'entities' of: json) at: 'FM3') equals: 'Famix-Java-Entities.Class'.
	self deny: ((self entryNamed: 'Foo' in: 'entities' of: json) includesKey: 'methods').
	self deny: ((self entryNamed: 'bar' in: 'entities' of: json) includesKey: 'parentType').

	"references: the relation is written on the method side only, the class has no entry"
	self assert: (self entryNamed: 'Foo' in: 'references' of: json) isNil.
	self assert: ((self entryNamed: 'bar' in: 'references' of: json) at: 'parentType') equals: (Dictionary with: 'ref' -> fooId)
]

{ #category : 'tests - import' }
FMSplitJSONTest >> testImportEntitiesSection [

	| class |
	self import: '{"entities":[
		{"FM3":"Famix-Java-Entities.Class","id":1,"name":"Foo","isAbstract":true}],
	"references":[]}'.

	self assert: model entities size equals: 1.
	class := model entities anyOne.
	self assert: class class equals: FamixJavaClass.
	self assert: class name equals: 'Foo'.
	self assert: class isAbstract
]

{ #category : 'tests - import' }
FMSplitJSONTest >> testImportEscapedFormFeed [

	self import: '{"entities":[
		{"FM3":"Famix-Java-Entities.Method","id":1,"name":"a\fb"}],
	"references":[]}'.

	self assert: model entities anyOne name equals: 'a' , (String with: Character newPage) , 'b'
]

{ #category : 'tests - import' }
FMSplitJSONTest >> testImportReferencesSetBothSides [

	| class method |
	self import: '{"entities":[
		{"FM3":"Famix-Java-Entities.Method","id":1,"name":"bar"},
		{"FM3":"Famix-Java-Entities.Class","id":2,"name":"Foo"}],
	"references":[
		{"id":1,"parentType":{"ref":2}}]}'.

	class := model allClasses detect: [ :each | each name = 'Foo' ].
	method := model allMethods detect: [ :each | each name = 'bar' ].
	self assert: method parentType identicalTo: class.
	self assert: class methods asArray equals: { method }.
	self assert: model entities size equals: 2
]

{ #category : 'tests - import' }
FMSplitJSONTest >> testImportUnknownIdsAreSkipped [

	| class method |
	self import: '{"entities":[
		{"FM3":"Famix-Java-Entities.Method","id":1,"name":"bar"},
		{"FM3":"Famix-Java-Entities.Class","id":2,"name":"Foo"}],
	"references":[
		{"id":99,"parentType":{"ref":2}},
		{"id":1,"declaredExceptions":[{"ref":98}],"parentType":{"ref":2}}]}'.

	class := model allClasses detect: [ :each | each name = 'Foo' ].
	method := model allMethods detect: [ :each | each name = 'bar' ].
	self assert: method parentType identicalTo: class.
	self assert: class methods asArray equals: { method }.
	self assert: method declaredExceptions isEmpty
]
