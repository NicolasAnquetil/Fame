"
I export a model in two sections so that importing never meets a forward reference:
- an """"entities"""" section, with each entity and its primitive properties only;
- a """"references"""" section, with, for each entity, its references to other entities.

Each relation with an opposite is written once: for one-to-many relations, on the single-valued side; otherwise the derived side is skipped, and if none or both are derived, the side whose name sorts first is written.

My printer must understand the section protocol (#inSection:do:, #printSectionSeparator), see FMSplitJSONPrinter.
"
Class {
	#name : 'FMSplitModelExporter',
	#superclass : 'FMModelExporter',
	#category : 'Fame-ImportExport',
	#package : 'Fame-ImportExport'
}

{ #category : 'exporting' }
FMSplitModelExporter >> export: aCollectionOfEntities [

	printer inDocumentDo: [
			printer
				inSection: 'entities'
				do: [ aCollectionOfEntities do: [ :entity | self exportEntity: entity ] separatedBy: [ printer printEntitySeparator ] ].
			printer printSectionSeparator.
			printer inSection: 'references' do: [ self exportReferencesOfAll: aCollectionOfEntities ] ]
]

{ #category : 'exporting' }
FMSplitModelExporter >> exportEntity: anEntity [
	"Export the entity with its primitive properties only."

	| meta |
	meta := model metaDescriptionOf: anEntity.
	printer inEntity: meta fullName do: [
			printer serial: (self indexOf: anEntity).
			self
				exportProperties: ((self sortedPropertiesOf: meta) select: [ :property |
						 property type isPrimitive and: [ self shouldExportProperty: property for: anEntity ] ])
				for: anEntity ].
	self incrementProgressBar
]

{ #category : 'exporting' }
FMSplitModelExporter >> exportProperties: aCollectionOfProperties for: anEntity [

	aCollectionOfProperties ifEmpty: [ ^ self ].
	printer printPropertySeparator.
	aCollectionOfProperties
		do: [ :property | self exportProperty: property for: anEntity ]
		separatedBy: [ printer printPropertySeparator ]
]

{ #category : 'exporting' }
FMSplitModelExporter >> exportReferencesOfAll: aCollectionOfEntities [
	"Export, for each entity that has some, its references to other entities. Entities without references are skipped."

	| first |
	first := true.
	aCollectionOfEntities do: [ :entity |
			| meta properties |
			meta := model metaDescriptionOf: entity.
			properties := (self sortedPropertiesOf: meta) select: [ :property |
				              property type isPrimitive not and: [ self shouldExportReference: property for: entity ] ].
			properties ifNotEmpty: [
					first ifFalse: [ printer printEntitySeparator ].
					first := false.
					printer inReferencesOf: (self indexOf: entity) do: [ self exportProperties: properties for: entity ] ] ]
]

{ #category : 'testing' }
FMSplitModelExporter >> isWrittenSide: property [
	"A relation with an opposite is written on one side only:
	- one-to-many: the single-valued side;
	- otherwise: the non-derived side if exactly one side is derived, else the side whose name sorts first."

	property isOneToManyRelation ifTrue: [ ^ property isMultivalued not ].
	property isDerived = property opposite isDerived ifFalse: [ ^ property isDerived not ].
	^ property name <= property opposite name
]

{ #category : 'testing' }
FMSplitModelExporter >> shouldExportReference: property for: anEntity [

	(self shouldIgnoreProperty: property) ifTrue: [ ^ false ].
	(model get: property element: anEntity) isEmptyOrNil ifTrue: [ ^ false ].
	property hasOpposite ifFalse: [ ^ true ].
	^ self isWrittenSide: property
]
