"
I stand for an entity that could not be found during an import (unknown id). I accept and drop all its property values so that the import can go on. See FMSplitImporter.
"
Class {
	#name : 'FMIgnoredFutureEntity',
	#superclass : 'FMFuture',
	#category : 'Fame-ImportExport',
	#package : 'Fame-ImportExport'
}

{ #category : 'parsing' }
FMIgnoredFutureEntity >> addToPropertyValues: anObject [
	"Values of an unknown entity are dropped."

	
]

{ #category : 'parsing' }
FMIgnoredFutureEntity >> beginProperty: aString [
	"Values of an unknown entity are dropped."

	
]

{ #category : 'parsing' }
FMIgnoredFutureEntity >> endProperty [
	"Values of an unknown entity are dropped."

	
]
