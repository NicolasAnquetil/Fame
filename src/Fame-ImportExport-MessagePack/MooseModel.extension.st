Extension { #name : 'MooseModel' }

{ #category : '*Fame-ImportExport-MessagePack' }
MooseModel >> exportToSplitMessagePackStream: aBinaryStream [
	"Export the model in the split MessagePack format (see FMSplitMessagePackPrinter)."

	self detectEncodingOfAllFileAnchors.
	(FMModel withMetamodel: self metamodel)
		addAll: self entities;
		exportWithPrinter: (FMSplitMessagePackPrinter on: aBinaryStream) usingExporter: FMSplitModelExporter
]

{ #category : '*Fame-ImportExport-MessagePack' }
MooseModel class >> importFromSplitMessagePack: aBinaryStream withMetamodel: aMetamodel [
	"I import a model written in the split MessagePack format with its metamodel and return a FMModel from it."

	| model areWarningsEnabled |
	model := FMModel withMetamodel: aMetamodel.
	areWarningsEnabled := Deprecation raiseWarning.
	[
		Deprecation raiseWarning: false.
		(FMSplitImporter model: model)
			parser: FMSplitMessagePackParser;
			stream: aBinaryStream;
			run ] ensure: [ Deprecation raiseWarning: areWarningsEnabled ].
	model updateCache.
	^ model
]

{ #category : '*Fame-ImportExport-MessagePack' }
MooseModel >> importFromSplitMessagePackStream: aBinaryStream [
	"Import a model written in the split MessagePack format (see #exportToSplitMessagePackStream:)."

	^ self
		  importFrom: (self class importFromSplitMessagePack: aBinaryStream withMetamodel: self metamodel)
		  named: (aBinaryStream localName withoutSuffix: '.msgpack')
]
