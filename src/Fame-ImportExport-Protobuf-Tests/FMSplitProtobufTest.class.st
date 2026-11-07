"
I test the split protobuf import/export format (see FMSplitProtobufPrinter class>>#protoSchema) through the public MooseModel API (#exportToSplitProtobufStream:, #importFromSplitProtobufStream:) on small FamixJava models.

Exported bytes are decoded with PBWireReader only (see #decode:), independently of FMSplitProtobufParser. Bytes to import are built by hand with PBWireWriter.
"
Class {
	#name : 'FMSplitProtobufTest',
	#superclass : 'TestCase',
	#instVars : [
		'model'
	],
	#category : 'Fame-ImportExport-Protobuf-Tests-Tests',
	#package : 'Fame-ImportExport-Protobuf-Tests',
	#tag : 'Tests'
}

{ #category : 'helpers' }
FMSplitProtobufTest >> bytesWithEntities: entitySpecs references: referenceSpecs [
	"Build a Document by hand. An entity spec is { id. className. { propertyName -> { kind -> value } } }, a references spec is { id. { propertyName -> { kind -> value } } }. kind is the Value field number."

	| names writer nameIndex writeProperties |
	names := OrderedCollection new.
	writer := PBWireWriter new.
	nameIndex := [ :name |
		             (names includes: name) ifFalse: [
				             names add: name.
				             writer
					             writeTag: 1 wireType: PBWireType len;
					             writeString: name ].
		             (names indexOf: name) - 1 ].
	writeProperties := [ :entryWriter :field :properties |
		                   properties do: [ :property |
				                   | index |
				                   index := nameIndex value: property key.
				                   entryWriter
					                   writeTag: field wireType: PBWireType len;
					                   writeLengthDelimited: [ :p |
							                   p
								                   writeTag: 1 wireType: PBWireType varint;
								                   writeUInt32: index.
							                   property value do: [ :value |
									                   p
										                   writeTag: 2 wireType: PBWireType len;
										                   writeLengthDelimited: [ :v | self write: value on: v ] ] ] ] ].
	entitySpecs do: [ :spec |
			| type entry |
			type := nameIndex value: spec second.
			entry := PBWireWriter new.
			entry
				writeTag: 1 wireType: PBWireType varint;
				writeUInt64: spec first.
			entry
				writeTag: 2 wireType: PBWireType varint;
				writeUInt32: type.
			writeProperties value: entry value: 3 value: spec third.
			writer
				writeTag: 2 wireType: PBWireType len;
				writeBytes: entry contents ].
	referenceSpecs do: [ :spec |
			| entry |
			entry := PBWireWriter new.
			entry
				writeTag: 1 wireType: PBWireType varint;
				writeUInt64: spec first.
			writeProperties value: entry value: 2 value: spec second.
			writer
				writeTag: 3 wireType: PBWireType len;
				writeBytes: entry contents ].
	^ writer contents
]

{ #category : 'helpers' }
FMSplitProtobufTest >> decode: aByteArray [

	| reader names entities references tag |
	reader := PBWireReader on: aByteArray.
	names := OrderedCollection new.
	entities := OrderedCollection new.
	references := OrderedCollection new.
	[ reader atEnd ] whileFalse: [
			tag := reader readTag.
			tag fieldNumber = 1 ifTrue: [ names add: reader readString ].
			tag fieldNumber = 2 ifTrue: [ entities add: (self decodeEntry: reader readLengthDelimited names: names propertiesField: 3) ].
			tag fieldNumber = 3 ifTrue: [ references add: (self decodeEntry: reader readLengthDelimited names: names propertiesField: 2) ] ].
	^ Dictionary new
		  at: 'names' put: names asArray;
		  at: 'entities' put: entities asArray;
		  at: 'references' put: references asArray;
		  yourself
]

{ #category : 'helpers' }
FMSplitProtobufTest >> decodeEntry: reader names: names propertiesField: propertiesField [

	| entry properties tag |
	entry := Dictionary new.
	properties := Dictionary new.
	entry at: 'properties' put: properties.
	[ reader atEnd ] whileFalse: [
			tag := reader readTag.
			tag fieldNumber = 1 ifTrue: [ entry at: 'id' put: reader readUInt64 ].
			(propertiesField = 3 and: [ tag fieldNumber = 2 ]) ifTrue: [ entry at: 'type' put: (names at: reader readUInt32 + 1) ].
			tag fieldNumber = propertiesField ifTrue: [ self decodeProperty: reader readLengthDelimited names: names into: properties ] ].
	^ entry
]

{ #category : 'helpers' }
FMSplitProtobufTest >> decodeProperty: reader names: names into: properties [

	| name values tag |
	values := OrderedCollection new.
	[ reader atEnd ] whileFalse: [
			tag := reader readTag.
			tag fieldNumber = 1 ifTrue: [ name := names at: reader readUInt32 + 1 ].
			tag fieldNumber = 2 ifTrue: [ values add: (self decodeValue: reader readLengthDelimited) ] ].
	properties at: name put: values asArray
]

{ #category : 'helpers' }
FMSplitProtobufTest >> decodeValue: reader [

	| tag |
	tag := reader readTag.
	tag fieldNumber = 1 ifTrue: [ ^ 1 -> reader readString ].
	tag fieldNumber = 2 ifTrue: [ ^ 2 -> reader readSInt64 ].
	tag fieldNumber = 3 ifTrue: [ ^ 3 -> reader readDouble ].
	tag fieldNumber = 4 ifTrue: [ ^ 4 -> reader readBool ].
	tag fieldNumber = 5 ifTrue: [ ^ 5 -> reader readUInt64 ].
	tag fieldNumber = 6 ifTrue: [ ^ 6 -> reader readString ].
	tag fieldNumber = 7 ifTrue: [ ^ 7 -> reader readString ].
	^ self error: 'unknown Value field ' , tag fieldNumber printString
]

{ #category : 'helpers' }
FMSplitProtobufTest >> entryNamed: aString in: aSection of: document [

	| id |
	id := ((document at: 'entities') detect: [ :each | ((each at: 'properties') at: 'name' ifAbsent: [ nil ]) = { (1 -> aString) } ])
		      at: 'id'.
	^ (document at: aSection) detect: [ :each | (each at: 'id') = id ] ifNone: [ nil ]
]

{ #category : 'helpers' }
FMSplitProtobufTest >> exported [
	"Decode the exported Document with PBWireReader only: a Dictionary with 'names', 'entities' and 'references'. Each entry is a Dictionary with 'id', 'type' (entities only, as the class name) and 'properties' (property name -> Array of kind -> value, kind being the Value field number)."

	^ self decode: self exportedBytes
]

{ #category : 'helpers' }
FMSplitProtobufTest >> exportedBytes [

	^ ByteArray streamContents: [ :stream | model exportToSplitProtobufStream: stream ]
]

{ #category : 'helpers' }
FMSplitProtobufTest >> import: aByteArray [

	model importFromSplitProtobufStream: aByteArray readStream
]

{ #category : 'helpers' }
FMSplitProtobufTest >> setUp [

	super setUp.
	model := FamixJavaModel new
]

{ #category : 'tests - export' }
FMSplitProtobufTest >> testExportNumbers [

	| method properties |
	method := model newMethodNamed: 'bar'.
	method cyclomaticComplexity: -1.
	method numberOfLinesOfCode: 1000000.
	properties := (self exported at: 'entities') first at: 'properties'.

	self assert: (properties at: 'cyclomaticComplexity') equals: { (2 -> -1) }.
	self assert: (properties at: 'numberOfLinesOfCode') equals: { (2 -> 1000000) }
]

{ #category : 'tests - export' }
FMSplitProtobufTest >> testExportOneEntity [

	| document foo |
	(model newClassNamed: 'Foo') isAbstract: true.
	document := self exported.

	self assert: (document at: 'entities') size equals: 1.
	foo := (document at: 'entities') first.
	self assert: (foo at: 'type') equals: 'Famix-Java-Entities.Class'.
	self assert: ((foo at: 'properties') at: 'name') equals: { (1 -> 'Foo') }.
	self assert: ((foo at: 'properties') at: 'isAbstract') equals: { (4 -> true) }.
	self assert: ((foo at: 'properties') at: 'isStub') equals: { (4 -> false) }.
	self assert: (document at: 'references') isEmpty.
	"each name is in the table once"
	self assert: (document at: 'names') asSet size equals: (document at: 'names') size
]

{ #category : 'tests - export' }
FMSplitProtobufTest >> testExportReferencesOnSingleValuedSide [

	| document class method |
	class := model newClassNamed: 'Foo'.
	method := model newMethodNamed: 'bar'.
	method parentType: class.
	document := self exported.

	"entities: primitive properties only"
	self deny: (((self entryNamed: 'Foo' in: 'entities' of: document) at: 'properties') includesKey: 'methods').
	self deny: (((self entryNamed: 'bar' in: 'entities' of: document) at: 'properties') includesKey: 'parentType').
	"references: the relation is written on the method side only, the class has no entry"
	self assert: (self entryNamed: 'Foo' in: 'references' of: document) isNil.
	self
		assert: (((self entryNamed: 'bar' in: 'references' of: document) at: 'properties') at: 'parentType')
		equals: { (5 -> ((self entryNamed: 'Foo' in: 'entities' of: document) at: 'id')) }
]

{ #category : 'tests - import' }
FMSplitProtobufTest >> testImportEntitiesAndReferences [

	| class method |
	self import: (self
			 bytesWithEntities: {
					 {
						 1.
						 'Famix-Java-Entities.Method'.
						 {
							 ('name' -> { (1 -> 'bar') }).
							 ('cyclomaticComplexity' -> { (2 -> -1) }) } }.
					 {
						 2.
						 'Famix-Java-Entities.Class'.
						 {
							 ('name' -> { (1 -> 'Foo') }).
							 ('isAbstract' -> { (4 -> true) }) } } }
			 references: { {
					 1.
					 { ('parentType' -> { (5 -> 2) }) } } }).

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
FMSplitProtobufTest >> testImportUnknownIdsAreSkipped [

	| class method |
	self import: (self
			 bytesWithEntities: {
					 {
						 1.
						 'Famix-Java-Entities.Method'.
						 { ('name' -> { (1 -> 'bar') }) } }.
					 {
						 2.
						 'Famix-Java-Entities.Class'.
						 { ('name' -> { (1 -> 'Foo') }) } } }
			 references: {
					 {
						 99.
						 { ('parentType' -> { (5 -> 2) }) } }.
					 {
						 1.
						 {
							 ('declaredExceptions' -> { (5 -> 98) }).
							 ('parentType' -> { (5 -> 2) }) } } }).

	class := model allClasses anyOne.
	method := model allMethods anyOne.
	self assert: method parentType identicalTo: class.
	self assert: class methods asArray equals: { method }.
	self assert: method declaredExceptions isEmpty
]

{ #category : 'helpers' }
FMSplitProtobufTest >> write: aKindValue on: aWriter [

	aKindValue key = 1 ifTrue: [
			^ aWriter
				  writeTag: 1 wireType: PBWireType len;
				  writeString: aKindValue value ].
	aKindValue key = 2 ifTrue: [
			^ aWriter
				  writeTag: 2 wireType: PBWireType varint;
				  writeSInt64: aKindValue value ].
	aKindValue key = 3 ifTrue: [
			^ aWriter
				  writeTag: 3 wireType: PBWireType i64;
				  writeDouble: aKindValue value ].
	aKindValue key = 4 ifTrue: [
			^ aWriter
				  writeTag: 4 wireType: PBWireType varint;
				  writeBool: aKindValue value ].
	aKindValue key = 5 ifTrue: [
			^ aWriter
				  writeTag: 5 wireType: PBWireType varint;
				  writeUInt64: aKindValue value ].
	aKindValue key = 6 ifTrue: [
			^ aWriter
				  writeTag: 6 wireType: PBWireType len;
				  writeString: aKindValue value ].
	aKindValue key = 7 ifTrue: [
			^ aWriter
				  writeTag: 7 wireType: PBWireType len;
				  writeString: aKindValue value ]
]
