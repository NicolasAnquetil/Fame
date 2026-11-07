"
I parse the split MessagePack format (see FMSplitMessagePackPrinter) from a binary stream and send the parsing events to my importer, an FMSplitImporter.

I read the whole stream in memory, then decode its top-level entries one by one with MpDecoder.
"
Class {
	#name : 'FMSplitMessagePackParser',
	#superclass : 'Object',
	#instVars : [
		'stream',
		'importer',
		'names'
	],
	#category : 'Fame-ImportExport-MessagePack',
	#package : 'Fame-ImportExport-MessagePack'
}

{ #category : 'accessing' }
FMSplitMessagePackParser >> importer: anImporter [

	importer := anImporter
]

{ #category : 'private' }
FMSplitMessagePackParser >> nameAt: anIndex [
	"The name table is 0-based."

	^ names at: anIndex + 1
]

{ #category : 'parsing' }
FMSplitMessagePackParser >> parseDocument [

	| decoder |
	decoder := MpDecoder on: stream upToEnd readStream.
	names := OrderedCollection new.
	importer beginDocument.
	[ decoder atEnd ] whileFalse: [ self parseEntry: decoder next ].
	importer endDocument
]

{ #category : 'parsing' }
FMSplitMessagePackParser >> parseEntry: anArray [
	"[0, name] | [1, id, typeIndex, properties] | [2, id, properties]"

	| kind |
	kind := anArray first.
	kind = 0 ifTrue: [ ^ names add: anArray second ].
	kind = 1 ifTrue: [
			^ importer inEntity: (self nameAt: anArray third) do: [
					  importer serial: anArray second.
					  self parseProperties: anArray fourth inReferences: false ] ].
	kind = 2 ifTrue: [ ^ importer inReferencesOf: anArray second do: [ self parseProperties: anArray third inReferences: true ] ]
]

{ #category : 'parsing' }
FMSplitMessagePackParser >> parseProperties: aFlatArray inReferences: aBoolean [
	"aFlatArray is [nameIndex, value, nameIndex, value, ...]; a value is bare for a single-valued property, an Array for a multivalued one."

	1 to: aFlatArray size by: 2 do: [ :index |
			| value |
			value := aFlatArray at: index + 1.
			importer inProperty: (self nameAt: (aFlatArray at: index)) do: [
					value isArray
						ifTrue: [ value do: [ :each | self parseValue: each inReferences: aBoolean ] ]
						ifFalse: [ value ifNotNil: [ self parseValue: value inReferences: aBoolean ] ] ] ]
]

{ #category : 'parsing' }
FMSplitMessagePackParser >> parseValue: anObject inReferences: aBoolean [
	"In references entries, an integer is the id of an entity and a string the name of an FM3 constant. In entities, values are primitives; an ext value of type 1 is an integer beyond 64 bits, in decimal."

	aBoolean ifTrue: [
			^ anObject isString
				  ifTrue: [ importer referenceName: anObject ]
				  ifFalse: [ importer referenceNumber: anObject ] ].
	((anObject isKindOf: MpExtValue) and: [ anObject typeCode = 1 ]) ifTrue: [
		^ importer primitive: anObject data asString asInteger ].
	importer primitive: anObject
]

{ #category : 'parsing' }
FMSplitMessagePackParser >> run [
	"The exporter writes each relation once, so there are no duplicates in multivalued links: like FMMSEParser>>#basicRun, we disable the costly duplicate check."

	FMShouldCheckForDuplicatedEntitiesInMultivalueLinks value: false during: [ self parseDocument ]
]

{ #category : 'accessing' }
FMSplitMessagePackParser >> stream: aBinaryStream [

	stream := aBinaryStream
]
