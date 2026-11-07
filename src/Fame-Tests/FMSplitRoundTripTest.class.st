"
I check that a real FamixJava model (from VerveineJTestResource) exported in a split format and imported back is the same model. My subclasses say which format with #reimport:.

Entities are compared through an id-independent signature (class, primitive values, and for every reference property, both sides of relations included, the class and primitive values of the targets), because the entity order of a model is not stable.
"
Class {
	#name : 'FMSplitRoundTripTest',
	#superclass : 'TestCase',
	#category : 'Fame-Tests-Tests',
	#package : 'Fame-Tests',
	#tag : 'Tests'
}

{ #category : 'testing' }
FMSplitRoundTripTest class >> isAbstract [
	^ self == FMSplitRoundTripTest
]

{ #category : 'accessing' }
FMSplitRoundTripTest class >> resources [

	^ { VerveineJTestResource }
]

{ #category : 'helpers' }
FMSplitRoundTripTest >> comparedPropertiesOf: anEntity [
	"Every property, except computed attributes (derived without opposite)."

	^ (anEntity metadescription allProperties reject: [ :property | property isDerived and: [ property hasOpposite not ] ])
		  asSortedCollection: [ :a :b | a name <= b name ]
]

{ #category : 'helpers' }
FMSplitRoundTripTest >> localSignatureOf: anEntity [

	^ String streamContents: [ :stream |
			  stream nextPutAll: anEntity class name.
			  ((self comparedPropertiesOf: anEntity) select: [ :property | property type isPrimitive ]) do: [ :property |
					  (property getFrom: anEntity) ifNotNil: [ :value |
							  stream
								  space;
								  nextPutAll: property name;
								  nextPut: $=;
								  print: value ] ] ]
]

{ #category : 'running' }
FMSplitRoundTripTest >> reimport: aModel [
	"Export aModel in my format and import it back in a new model."

	^ self subclassResponsibility
]

{ #category : 'helpers' }
FMSplitRoundTripTest >> signatureOf: anEntity [

	^ String streamContents: [ :stream |
			  stream nextPutAll: (self localSignatureOf: anEntity).
			  ((self comparedPropertiesOf: anEntity) reject: [ :property | property type isPrimitive ]) do: [ :property |
					  | targets |
					  targets := (property getFrom: anEntity) ifNil: [ #(  ) ] ifNotNil: [ :value |
							             value isCollection
								             ifTrue: [ value ]
								             ifFalse: [ { value } ] ].
					  targets ifNotEmpty: [
							  stream
								  nextPutAll: ' | ';
								  nextPutAll: property name;
								  nextPutAll: '->';
								  print: (targets asArray collect: [ :target | self localSignatureOf: target ]) sorted ] ] ]
]

{ #category : 'helpers' }
FMSplitRoundTripTest >> signaturesOf: aModel [

	^ (aModel entities collect: [ :entity | self signatureOf: entity ]) asArray sorted
]

{ #category : 'tests' }
FMSplitRoundTripTest >> testRoundTripVerveineJModel [

	| original reimported |
	original := VerveineJTestResource current model.
	reimported := self reimport: original.

	self assert: reimported entities size equals: original entities size.
	self assert: (self signaturesOf: reimported) equals: (self signaturesOf: original)
]
