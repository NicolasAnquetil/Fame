"
I print a model in the split MessagePack format, driven by FMSplitModelExporter, on a binary stream. The file is a sequence of top-level MessagePack arrays:
- [0, name]: declares the next name of the name table (0-based index = order of appearance), written before its first use;
- [1, id, typeIndex, properties]: an entity with its primitive properties (all entities come first);
- [2, id, properties]: the references of an entity to other entities.

properties is a flat array [nameIndex, value, nameIndex, value, ...]. A single-valued property has a bare value, a multivalued one an array of values. In entities, values are primitives; in references entries, an integer is the id of an entity and a string the name of an FM3 constant. An integer beyond 64 bits is written as an ext value of type 1 holding its decimal digits.
"
Class {
	#name : 'FMSplitMessagePackPrinter',
	#superclass : 'FMDataStructurePrinter',
	#instVars : [
		'encoder',
		'names',
		'entryKind',
		'entryId',
		'entryType',
		'properties',
		'values',
		'isMultivalued'
	],
	#category : 'Fame-ImportExport-MessagePack',
	#package : 'Fame-ImportExport-MessagePack'
}

{ #category : 'parsing' }
FMSplitMessagePackPrinter >> beginDocument [

	encoder := MpEncoder on: stream.
	names := Dictionary new
]

{ #category : 'parsing' }
FMSplitMessagePackPrinter >> beginEntity: aString [

	entryType := self indexOfName: aString.
	properties := OrderedCollection new
]

{ #category : 'parsing' }
FMSplitMessagePackPrinter >> beginMultivalue: aProperty [

	isMultivalued := true
]

{ #category : 'parsing' }
FMSplitMessagePackPrinter >> beginProperty: aString [

	properties add: (self indexOfName: aString).
	values := OrderedCollection new.
	isMultivalued := false
]

{ #category : 'parsing' }
FMSplitMessagePackPrinter >> endDocument [

	
]

{ #category : 'parsing' }
FMSplitMessagePackPrinter >> endEntity: aString [

	encoder nextPut: (entryKind = 1
			 ifTrue: [
					 {
						 1.
						 entryId.
						 entryType.
						 properties asArray } ]
			 ifFalse: [
					 {
						 2.
						 entryId.
						 properties asArray } ]).
	properties := nil
]

{ #category : 'parsing' }
FMSplitMessagePackPrinter >> endMultivalue: aProperty [

	
]

{ #category : 'parsing' }
FMSplitMessagePackPrinter >> endProperty: aString [

	properties add: (isMultivalued
			 ifTrue: [ values asArray ]
			 ifFalse: [ values ifEmpty: [ nil ] ifNotEmpty: [ values first ] ]).
	values := nil
]

{ #category : 'parsing' }
FMSplitMessagePackPrinter >> inReferencesOf: anInteger do: aBlock [

	properties := OrderedCollection new.
	entryId := anInteger.
	aBlock value.
	self endEntity: nil
]

{ #category : 'parsing' }
FMSplitMessagePackPrinter >> inSection: aString do: aBlock [

	entryKind := aString = 'entities'
		             ifTrue: [ 1 ]
		             ifFalse: [ 2 ].
	aBlock value
]

{ #category : 'private' }
FMSplitMessagePackPrinter >> indexOfName: aString [
	"Answer the index of aString in the name table. A new name is declared right away ([0, name]), so it comes before its first use."

	^ names at: aString ifAbsent: [
			  encoder nextPut: {
					  0.
					  aString }.
			  names at: aString put: names size ]
]

{ #category : 'parsing' }
FMSplitMessagePackPrinter >> primitive: anObject [
	"Integers beyond 64 bits are not supported by MpEncoder: they are written as an ext value of type 1 with their decimal digits."

	values add: ((anObject isInteger and: [ (anObject between: -9223372036854775808 and: 18446744073709551615) not ])
			 ifTrue: [ MpExtValue typeCode: 1 data: anObject printString asByteArray ]
			 ifFalse: [ anObject ])
]

{ #category : 'parsing' }
FMSplitMessagePackPrinter >> printEntitySeparator [

	
]

{ #category : 'parsing' }
FMSplitMessagePackPrinter >> printPropertySeparator [

	
]

{ #category : 'parsing' }
FMSplitMessagePackPrinter >> printSectionSeparator [

	
]

{ #category : 'parsing' }
FMSplitMessagePackPrinter >> referenceName: aString [

	values add: aString
]

{ #category : 'parsing' }
FMSplitMessagePackPrinter >> referenceNumber: anInteger [

	values add: anInteger
]

{ #category : 'parsing' }
FMSplitMessagePackPrinter >> serial: anInteger [

	entryId := anInteger
]
