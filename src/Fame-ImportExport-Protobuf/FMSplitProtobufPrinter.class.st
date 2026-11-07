"
I print a model in the split protobuf format, driven by FMSplitModelExporter, on a binary stream. The schema is in #protoSchema (class side).

The document is a sequence of top-level fields that I write to the stream one by one:
- a name (field 1) the first time a class or property name is used; its index is its order of appearance;
- an entity (field 2) or a references entry (field 3), each encoded in its own PBWireWriter and then copied to the stream.
"
Class {
	#name : 'FMSplitProtobufPrinter',
	#superclass : 'FMDataStructurePrinter',
	#instVars : [
		'names',
		'sectionField',
		'propertiesField',
		'entityWriter',
		'propertyWriter',
		'pendingType'
	],
	#category : 'Fame-ImportExport-Protobuf',
	#package : 'Fame-ImportExport-Protobuf'
}

{ #category : 'schema' }
FMSplitProtobufPrinter class >> protoSchema [
	"The protobuf schema of the split format, to save as a .proto file for protoc or other protobuf tools:
	(FileSystem workingDirectory / 'fame.proto') writeStreamDo: [ :s | s nextPutAll: FMSplitProtobufPrinter protoSchema ]"

	^ 'syntax = "proto3";
package fame;

// A Fame model in the split format: all entities with their primitive properties,
// then the references between entities. Each relation with an opposite is written on one side only.
message Document {
  repeated string     names      = 1;  // name table: index = order of appearance (0-based); a name is written before its first use
  repeated Entity     entities   = 2;  // all entities come before any references entry
  repeated References references = 3;
}

message Entity {
  uint64 id = 1;
  uint32 type = 2;                     // index of the FM3 class full name
  repeated Property properties = 3;    // primitive properties only
}

message References {
  uint64 id = 1;                       // id of an entity of the entities section
  repeated Property properties = 2;    // references to other entities only
}

message Property {
  uint32 name = 1;                     // index of the property name
  repeated Value values = 2;
}

message Value {
  oneof kind {
    string string     = 1;
    sint64 integer    = 2;
    double float      = 3;
    bool   boolean    = 4;
    uint64 ref        = 5;             // id of an entity
    string constant   = 6;             // FM3 constant, by name
    string bigInteger = 7;             // integer beyond 64 bits, in decimal
  }
}
'
]

{ #category : 'parsing' }
FMSplitProtobufPrinter >> beginDocument [

	names := Dictionary new
]

{ #category : 'parsing' }
FMSplitProtobufPrinter >> beginEntity: aString [

	entityWriter := PBWireWriter new.
	pendingType := self indexOfName: aString
]

{ #category : 'parsing' }
FMSplitProtobufPrinter >> beginMultivalue: aProperty [

	
]

{ #category : 'parsing' }
FMSplitProtobufPrinter >> beginProperty: aString [

	propertyWriter := PBWireWriter new.
	propertyWriter
		writeTag: 1 wireType: PBWireType varint;
		writeUInt32: (self indexOfName: aString)
]

{ #category : 'parsing' }
FMSplitProtobufPrinter >> endDocument [

	
]

{ #category : 'parsing' }
FMSplitProtobufPrinter >> endEntity: aString [

	self writeTopLevelField: sectionField bytes: entityWriter contents.
	entityWriter := nil
]

{ #category : 'parsing' }
FMSplitProtobufPrinter >> endMultivalue: aProperty [

	
]

{ #category : 'parsing' }
FMSplitProtobufPrinter >> endProperty: aString [

	entityWriter
		writeTag: propertiesField wireType: PBWireType len;
		writeBytes: propertyWriter contents.
	propertyWriter := nil
]

{ #category : 'parsing' }
FMSplitProtobufPrinter >> inReferencesOf: anInteger do: aBlock [

	entityWriter := PBWireWriter new.
	self serial: anInteger.
	aBlock value.
	self endEntity: nil
]

{ #category : 'parsing' }
FMSplitProtobufPrinter >> inSection: aString do: aBlock [
	"Entities are Document field 2 (their properties: Entity field 3), references entries are Document field 3 (their properties: References field 2)."

	aString = 'entities'
		ifTrue: [
				sectionField := 2.
				propertiesField := 3 ]
		ifFalse: [
				sectionField := 3.
				propertiesField := 2 ].
	aBlock value
]

{ #category : 'private' }
FMSplitProtobufPrinter >> indexOfName: aString [
	"Answer the index of aString in the name table. A new name is written to the stream (Document field 1) right away, so it comes before its first use."

	^ names at: aString ifAbsent: [
			  | writer |
			  writer := PBWireWriter new.
			  writer
				  writeTag: 1 wireType: PBWireType len;
				  writeString: aString.
			  stream nextPutAll: writer contents.
			  names at: aString put: names size ]
]

{ #category : 'parsing' }
FMSplitProtobufPrinter >> primitive: anObject [

	anObject isString ifTrue: [
			^ self writeValue: [ :writer |
					  writer
						  writeTag: 1 wireType: PBWireType len;
						  writeString: anObject ] ].
	anObject isInteger ifTrue: [
			^ (anObject between: -9223372036854775808 and: 9223372036854775807)
				  ifTrue: [
						  self writeValue: [ :writer |
								  writer
									  writeTag: 2 wireType: PBWireType varint;
									  writeSInt64: anObject ] ]
				  ifFalse: [
						  self writeValue: [ :writer |
								  writer
									  writeTag: 7 wireType: PBWireType len;
									  writeString: anObject printString ] ] ].
	anObject isNumber ifTrue: [
			^ self writeValue: [ :writer |
					  writer
						  writeTag: 3 wireType: PBWireType i64;
						  writeDouble: anObject asFloat ] ].
	(anObject == true or: [ anObject == false ]) ifTrue: [
			^ self writeValue: [ :writer |
					  writer
						  writeTag: 4 wireType: PBWireType varint;
						  writeBool: anObject ] ].
	"Any other primitive value is written as its print string."
	self writeValue: [ :writer |
			writer
				writeTag: 1 wireType: PBWireType len;
				writeString: anObject printString ]
]

{ #category : 'parsing' }
FMSplitProtobufPrinter >> printEntitySeparator [

	
]

{ #category : 'parsing' }
FMSplitProtobufPrinter >> printPropertySeparator [

	
]

{ #category : 'parsing' }
FMSplitProtobufPrinter >> printSectionSeparator [

	
]

{ #category : 'parsing' }
FMSplitProtobufPrinter >> referenceName: aString [

	self writeValue: [ :writer |
			writer
				writeTag: 6 wireType: PBWireType len;
				writeString: aString ]
]

{ #category : 'parsing' }
FMSplitProtobufPrinter >> referenceNumber: anInteger [

	self writeValue: [ :writer |
			writer
				writeTag: 5 wireType: PBWireType varint;
				writeUInt64: anInteger ]
]

{ #category : 'parsing' }
FMSplitProtobufPrinter >> serial: anInteger [

	entityWriter
		writeTag: 1 wireType: PBWireType varint;
		writeUInt64: anInteger.
	pendingType ifNotNil: [
			entityWriter
				writeTag: 2 wireType: PBWireType varint;
				writeUInt32: pendingType.
			pendingType := nil ]
]

{ #category : 'private' }
FMSplitProtobufPrinter >> writeTopLevelField: anInteger bytes: aByteArray [

	| writer |
	writer := PBWireWriter new.
	writer
		writeTag: anInteger wireType: PBWireType len;
		writeBytes: aByteArray.
	stream nextPutAll: writer contents
]

{ #category : 'private' }
FMSplitProtobufPrinter >> writeValue: aBlock [
	"Add a Value message (Property field 2) to the current property."

	propertyWriter
		writeTag: 2 wireType: PBWireType len;
		writeLengthDelimited: aBlock
]
