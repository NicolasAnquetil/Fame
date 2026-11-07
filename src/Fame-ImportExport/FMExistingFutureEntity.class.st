"
I am a future on an entity that already exists (created earlier in the import). FMSplitImporter uses me to add the references of an entity in the """"references"""" section.
"
Class {
	#name : 'FMExistingFutureEntity',
	#superclass : 'FMFutureEntity',
	#category : 'Fame-ImportExport',
	#package : 'Fame-ImportExport'
}

{ #category : 'instance creation' }
FMExistingFutureEntity class >> in: anImporter on: anEntity [

	^ self new in: anImporter on: anEntity
]

{ #category : 'initialization' }
FMExistingFutureEntity >> in: anImporter on: anEntity [

	importer := anImporter.
	instance := anEntity.
	metaDescription := anImporter model metaDescriptionOf: anEntity
]
