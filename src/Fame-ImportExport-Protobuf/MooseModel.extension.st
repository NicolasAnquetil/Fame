Extension { #name : 'MooseModel' }

{ #category : '*Fame-ImportExport-Protobuf' }
MooseModel >> exportToSplitProtobufStream: aBinaryStream [
	"Export the model in the split protobuf format (see FMSplitProtobufPrinter class>>#protoSchema)."

	self detectEncodingOfAllFileAnchors.
	(FMModel withMetamodel: self metamodel)
		addAll: self entities;
		exportWithPrinter: (FMSplitProtobufPrinter on: aBinaryStream) usingExporter: FMSplitModelExporter
]

{ #category : '*Fame-ImportExport-Protobuf' }
MooseModel class >> importFromSplitProtobuf: aBinaryStream withMetamodel: aMetamodel [
	"I import a model written in the split protobuf format with its metamodel and return a FMModel from it."

	| model areWarningsEnabled |
	model := FMModel withMetamodel: aMetamodel.
	areWarningsEnabled := Deprecation raiseWarning.
	[
		Deprecation raiseWarning: false.
		(FMSplitImporter model: model)
			parser: FMSplitProtobufParser;
			stream: aBinaryStream;
			run ] ensure: [ Deprecation raiseWarning: areWarningsEnabled ].
	model updateCache.
	^ model
]

{ #category : '*Fame-ImportExport-Protobuf' }
MooseModel >> importFromSplitProtobufStream: aBinaryStream [
	"Import a model written in the split protobuf format (see #exportToSplitProtobufStream:)."

	^ self
		  importFrom: (self class importFromSplitProtobuf: aBinaryStream withMetamodel: self metamodel)
		  named: (aBinaryStream localName withoutSuffix: '.pb')
]
