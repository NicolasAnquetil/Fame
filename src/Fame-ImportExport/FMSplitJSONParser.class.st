"
I parse the split JSON format produced by FMSplitJSONPrinter:

{ """"entities"""": [ {""""FM3"""":..., """"id"""":n, primitive properties...}, ... ],
  """"references"""": [ {""""id"""":n, reference properties...}, ... ] }

Entries of the references section reopen an entity of the entities section by its id (see FMSplitImporter>>#inReferencesOf:do:).
"
Class {
	#name : 'FMSplitJSONParser',
	#superclass : 'FMJSONParser',
	#category : 'Fame-ImportExport',
	#package : 'Fame-ImportExport'
}

{ #category : 'parsing' }
FMSplitJSONParser >> Document [
	"Document := EOF | { entities-Section , references-Section }"

	self tWHITESPACE.
	importer beginDocument.
	self atEnd ifFalse: [
			self tOPEN ifFalse: [ ^ self syntaxError ].
			self Section: 'entities' of: [ self Entity ].
			self tPropertySeparator ifFalse: [ ^ self syntaxError ].
			self Section: 'references' of: [ self ReferencesEntry ].
			self tCLOSE ifFalse: [ ^ self syntaxError ] ].
	importer endDocument.
	self tWHITESPACE.
	^ true
]

{ #category : 'parsing' }
FMSplitJSONParser >> ReferencesEntry [
	"ReferencesEntry := { id : Identifier (, Property)* }"

	| pos serial |
	pos := self position.
	self tOPEN ifFalse: [ ^ self backtrack: pos ].
	self tID ifFalse: [ ^ self syntaxError ].
	self tPropertyNameSeparator ifFalse: [ ^ self syntaxError ].
	serial := self Identifier.
	serial ifNil: [ ^ self syntaxError ].
	self tPropertySeparator.
	importer inReferencesOf: serial do: [
			[ self Property ] whileTrue.
			self tCLOSE ifFalse: [ ^ self syntaxError ] ].
	self tWHITESPACE.
	self incrementProgressBar.
	^ true
]

{ #category : 'parsing' }
FMSplitJSONParser >> Section: aString of: anEntryBlock [
	"Section := aString-as-JSON-key : [ (Entry (, Entry)*)? ]"

	(self matchesWord: '"' , aString , '"') ifFalse: [ ^ self syntaxError ].
	self tPropertyNameSeparator ifFalse: [ ^ self syntaxError ].
	self tMultiOPEN ifFalse: [ ^ self syntaxError ].
	[ anEntryBlock value and: [ self tPropertySeparator ] ] whileTrue.
	self tMultiCLOSE ifFalse: [ ^ self syntaxError ].
	^ true
]
