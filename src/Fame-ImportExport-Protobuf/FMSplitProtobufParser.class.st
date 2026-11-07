"
I parse the split protobuf format (see FMSplitProtobufPrinter class>>#protoSchema) from a binary stream and send the parsing events to my importer, an FMSplitImporter.

I read the whole stream in memory, then decode it with PBWireReader.
"
Class {
	#name : 'FMSplitProtobufParser',
	#superclass : 'Object',
	#instVars : [
		'stream',
		'importer',
		'names'
	],
	#category : 'Fame-ImportExport-Protobuf',
	#package : 'Fame-ImportExport-Protobuf'
}

{ #category : 'accessing' }
FMSplitProtobufParser >> importer: anImporter [

	importer := anImporter
]

{ #category : 'private' }
FMSplitProtobufParser >> nameAt: anIndex [
	"The name table is 0-based."

	^ names at: anIndex + 1
]

{ #category : 'parsing' }
FMSplitProtobufParser >> parseEntity: aReader [
	"Entity { uint64 id = 1; uint32 type = 2; repeated Property properties = 3; }"

	| id type properties tag |
	properties := OrderedCollection new.
	[ aReader atEnd ] whileFalse: [
			tag := aReader readTag.
			tag fieldNumber = 1
				ifTrue: [ id := aReader readUInt64 ]
				ifFalse: [
						tag fieldNumber = 2
							ifTrue: [ type := aReader readUInt32 ]
							ifFalse: [
									tag fieldNumber = 3
										ifTrue: [ properties add: aReader readLengthDelimited ]
										ifFalse: [ aReader skipField: tag ] ] ] ].
	importer inEntity: (self nameAt: type) do: [
			importer serial: id.
			properties do: [ :each | self parseProperty: each ] ]
]

{ #category : 'parsing' }
FMSplitProtobufParser >> parseProperty: aReader [
	"Property { uint32 name = 1; repeated Value values = 2; }"

	| name values tag |
	values := OrderedCollection new.
	[ aReader atEnd ] whileFalse: [
			tag := aReader readTag.
			tag fieldNumber = 1
				ifTrue: [ name := aReader readUInt32 ]
				ifFalse: [
						tag fieldNumber = 2
							ifTrue: [ values add: aReader readLengthDelimited ]
							ifFalse: [ aReader skipField: tag ] ] ].
	importer inProperty: (self nameAt: name) do: [ values do: [ :each | self parseValue: each ] ]
]

{ #category : 'parsing' }
FMSplitProtobufParser >> parseReferences: aReader [
	"References { uint64 id = 1; repeated Property properties = 2; }"

	| id properties tag |
	properties := OrderedCollection new.
	[ aReader atEnd ] whileFalse: [
			tag := aReader readTag.
			tag fieldNumber = 1
				ifTrue: [ id := aReader readUInt64 ]
				ifFalse: [
						tag fieldNumber = 2
							ifTrue: [ properties add: aReader readLengthDelimited ]
							ifFalse: [ aReader skipField: tag ] ] ].
	importer inReferencesOf: id do: [ properties do: [ :each | self parseProperty: each ] ]
]

{ #category : 'parsing' }
FMSplitProtobufParser >> parseValue: aReader [
	"Value { oneof kind { string string = 1; sint64 integer = 2; double float = 3; bool boolean = 4; uint64 ref = 5; string constant = 6; string bigInteger = 7; } }"

	| tag field |
	[ aReader atEnd ] whileFalse: [
			tag := aReader readTag.
			field := tag fieldNumber.
			field = 1
				ifTrue: [ importer primitive: aReader readString ]
				ifFalse: [
						field = 2
							ifTrue: [ importer primitive: aReader readSInt64 ]
							ifFalse: [
									field = 3
										ifTrue: [ importer primitive: aReader readDouble ]
										ifFalse: [
												field = 4
													ifTrue: [ importer primitive: aReader readBool ]
													ifFalse: [
															field = 5
																ifTrue: [ importer referenceNumber: aReader readUInt64 ]
																ifFalse: [
																		field = 6
																			ifTrue: [ importer referenceName: aReader readString ]
																			ifFalse: [
																					field = 7
																						ifTrue: [ importer primitive: aReader readString asInteger ]
																						ifFalse: [ aReader skipField: tag ] ] ] ] ] ] ] ]
]

{ #category : 'parsing' }
FMSplitProtobufParser >> run [

	| reader tag |
	reader := PBWireReader on: stream upToEnd.
	names := OrderedCollection new.
	importer beginDocument.
	[ reader atEnd ] whileFalse: [
			tag := reader readTag.
			tag fieldNumber = 1
				ifTrue: [ names add: reader readString ]
				ifFalse: [
						tag fieldNumber = 2
							ifTrue: [ self parseEntity: reader readLengthDelimited ]
							ifFalse: [
									tag fieldNumber = 3
										ifTrue: [ self parseReferences: reader readLengthDelimited ]
										ifFalse: [ reader skipField: tag ] ] ] ].
	importer endDocument
]

{ #category : 'accessing' }
FMSplitProtobufParser >> stream: aBinaryStream [

	stream := aBinaryStream
]
