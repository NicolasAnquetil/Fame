"
I print a model in the split JSON format: one JSON object with an """"entities"""" section and a """"references"""" section, as produced by FMSplitModelExporter.
"
Class {
	#name : 'FMSplitJSONPrinter',
	#superclass : 'FMJSONPrinter',
	#category : 'Fame-ImportExport',
	#package : 'Fame-ImportExport'
}

{ #category : 'parsing' }
FMSplitJSONPrinter >> beginDocument [

	stream nextPut: ${
]

{ #category : 'private' }
FMSplitJSONPrinter >> crTabs [
	"The split JSON format is compact: no line breaks nor indentation."

	
]

{ #category : 'parsing' }
FMSplitJSONPrinter >> endDocument [

	self crTabs.
	stream nextPut: $}
]

{ #category : 'parsing' }
FMSplitJSONPrinter >> inReferencesOf: index do: aBlock [
	"Print the references entry of the entity with this id: {""id"":index, properties...}"

	indent := indent + 1.
	stream nextPut: ${.
	self crTabs.
	self serial: index.
	aBlock value.
	self endEntity: nil
]

{ #category : 'parsing' }
FMSplitJSONPrinter >> inSection: aString do: aBlock [

	self crTabs.
	stream
		nextPut: $";
		nextPutAll: aString;
		nextPutAll: '":['.
	aBlock value.
	self crTabs.
	stream nextPut: $]
]

{ #category : 'parsing' }
FMSplitJSONPrinter >> printSectionSeparator [

	stream nextPut: $,
]

{ #category : 'parsing' }
FMSplitJSONPrinter >> referenceName: name [

	stream
		nextPutAll: '{"ref":"';
		nextPutAll: name;
		nextPutAll: '"}'
]

{ #category : 'parsing' }
FMSplitJSONPrinter >> referenceNumber: index [

	stream
		nextPutAll: '{"ref":';
		print: index;
		nextPut: $}
]
