"
I import the split format (see FMSplitModelExporter). All entities are created by the """"entities"""" section, so the """"references"""" section never meets a forward reference: an unknown id there is logged on the Transcript and skipped, and the import goes on.
"
Class {
	#name : 'FMSplitImporter',
	#superclass : 'FMImporter',
	#category : 'Fame-ImportExport',
	#package : 'Fame-ImportExport'
}

{ #category : 'parsing' }
FMSplitImporter >> entityAt: aSerial ifPresent: aPresentBlock ifAbsent: anAbsentBlock [

	^ serialDict at: aSerial ifPresent: aPresentBlock ifAbsent: anAbsentBlock
]

{ #category : 'parsing' }
FMSplitImporter >> inReferencesOf: serial do: aBlock [
	"Reopen the entity created in the entities section with this serial, to set its references. An unknown serial is logged and its references are dropped."

	stack push: (self entityAt: serial ifPresent: [ :entity | FMExistingFutureEntity in: self on: entity ] ifAbsent: [
				 self logError: 'unknown entity id ' , serial printString , ' in the references section, entry skipped'.
				 FMIgnoredFutureEntity new ]).
	aBlock value.
	stack pop
]

{ #category : 'private' }
FMSplitImporter >> logError: aString [

	Transcript crShow: 'Split JSON import: ' , aString
]

{ #category : 'parsing' }
FMSplitImporter >> referenceNumber: serial [
	"All entities exist once the entities section is read: an unknown serial is logged and skipped instead of becoming a dangling reference."

	self
		entityAt: serial
		ifPresent: [ :entity | self currentEntity addToPropertyValues: entity ]
		ifAbsent: [ self logError: 'unknown entity id ' , serial printString , ' in a reference, value skipped' ]
]
