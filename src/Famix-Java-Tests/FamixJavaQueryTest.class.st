Class {
	#name : #FamixJavaQueryTest,
	#superclass : #TestCase,
	#instVars : [
		'model',
		'p1',
		'p2',
		'c1',
		'c2',
		'c3',
		'm1',
		'm2',
		'm3',
		'm4',
		'v1',
		'pr1',
		'pr2',
		'at1',
		'at2'
	],
	#category : #'Famix-Java-Tests'
}

{ #category : #setup }
FamixJavaQueryTest class >> importModel [ 
	 
	| factory p1 p2 c1 c2 c3 m1 m2 m3 m4 |
	
	factory := self metamodelFactory.
	
	p1 := factory package new name: 'p1' ; yourself.
	p2 := factory package new name: 'p2' ; yourself.
	
	c1 := factory classEntity new
			name: 'c1' ;
			container: p1 ;
			yourself.
	c2 := factory classEntity new
			name: 'c2' ;
			container: p1 ;
			yourself.
	c3 := factory classEntity new
			name: 'c3' ;
			container: p2 ;
			yourself.

	m1 := factory method new
			name: 'm1' ;
			signature: 'm1()' ;
			container: c1 ;
			declaredType: c2 ;
			yourself.
	m2 := factory method new
			name: 'm2' ;
			signature: 'm2()' ;
			container: c2 ;
			declaredType: c3 ;
			yourself.
	m3 := factory method new
			name: 'm3' ;
			signature: 'm3()' ;
			container: c2 ;
			declaredType: c1 ;
			yourself.
	m4 := factory method new
			name: 'm4' ;
			signature: 'm4()' ;
			container: c3 ;
			declaredType: c3 ;
			yourself.
			
	self model
		add: p1 ;
		add: p2 ;
		add: c1 ;
		add: c2 ;
		add: c3 ;
		add: m1 ;
		add: m2 ;
		add: m3 ;
		add: m4.
]

{ #category : #accessing }
FamixJavaQueryTest >> model [
	^ model
]

{ #category : #accessing }
FamixJavaQueryTest >> model: anObject [
	model := anObject
]

{ #category : #running }
FamixJavaQueryTest >> setUp [
	super setUp.

	p1 := FamixJavaPackage new
		name: 'p1';
		stub: true;
		yourself.
	p2 := FamixJavaPackage new
		name: 'p2';
		stub: true;
		yourself.

	c1 := FamixJavaClass new
		stub: true;
		name: 'C1';
		parentPackage: p1;
		yourself.
	c2 := FamixJavaClass new
		stub: true;
		name: 'C2';
		parentPackage: p1;
		yourself.
	c3 := FamixJavaClass new
		stub: true;
		name: 'C3';
		parentPackage: p2;
		yourself.

	m1 := FamixJavaMethod new
		stub: true;
		name: 'm1';
		signature: 'm1()';
		parentType: c1;
		parentPackage: p1;
		declaredType: c2;
		yourself.
	m2 := FamixJavaMethod new
		stub: true;
		name: 'm2';
		signature: 'm2()';
		parentType: c2;
		parentPackage: p1;
		declaredType: c3;
		yourself.
	m3 := FamixJavaMethod new
		stub: true;
		name: 'm3';
		signature: 'm3(C2,C3)';
		parentType: c2;
		parentPackage: p1;
		declaredType: c1;
		yourself.
	m4 := FamixJavaMethod new
		stub: true;
		name: 'm4';
		signature: 'm4()';
		parentType: c3;
		parentPackage: p2;
		declaredType: c3;
		yourself.

	v1 := FamixJavaLocalVariable new
		stub: true;
		name: 'v1';
		parentBehaviouralEntity: m2;
		parentPackage: p1;
		declaredType: c1;
		yourself.

	pr1 := FamixJavaParameter new
		stub: true;
		name: 'pr1';
		parentBehaviouralEntity: m3;
		parentPackage: p1;
		declaredType: c2;
		yourself.
	pr2 := FamixJavaParameter new
		stub: true;
		name: 'pr2';
		parentBehaviouralEntity: m3;
		parentPackage: p1;
		declaredType: c3;
		yourself.

	at1 := FamixJavaAttribute new
		stub: true;
		name: 'at1';
		parentType: c1;
		parentPackage: p1;
		declaredType: c3;
		yourself.
	at2 := FamixJavaAttribute new
		stub: true;
		name: 'at2';
		parentType: c3;
		parentPackage: p2;
		declaredType: c2;
		yourself.

	self model: (FamixJavaMooseModel withAll: {p1 . p2 . c1 . c2 . c3 . m1 . m2 . m3 . m4 . v1 . at1 . at2 . pr1 . pr2})
]

{ #category : #'tests - class' }
FamixJavaQueryTest >> testFamixClassHasIncomingTypeDeclarations [
	self assert: c2 hasIncomingTypeDeclarations.
	self assert: c3 hasIncomingTypeDeclarations
]

{ #category : #'tests - class' }
FamixJavaQueryTest >> testFamixClassHasOutgoingTypeDeclarations [
	self assert: c2 hasOutgoingTypeDeclarations.
	self assert: c3 hasOutgoingTypeDeclarations
]

{ #category : #'tests - class' }
FamixJavaQueryTest >> testFamixClassHasTypeDeclarationsWithoutSelfLoops [
	self assert: c3 hasOutgoingTypeDeclarations.
	self assert: c3 hasOutgoingTypeDeclarations
]

{ #category : #'tests - class' }
FamixJavaQueryTest >> testFamixClassIncomingTypeDeclarations [
	self assertCollection: (c2 queryIncomingTypeDeclarations atScope: FamixTType) hasSameElements: {c1 . c2 . c3}.
	self assertCollection: (c3 queryIncomingTypeDeclarations atScope: FamixTType) hasSameElements: {c1 . c2 . c3}
]

{ #category : #'tests - class' }
FamixJavaQueryTest >> testFamixClassOutgoingTypeDeclarations [
	self assertCollection: c2 queryOutgoingTypeDeclarations opposites hasSameElements: {c1 . c2 . c3}.
	self assertCollection: c3 queryOutgoingTypeDeclarations opposites hasSameElements: {c2 . c3}
]

{ #category : #'tests - class' }
FamixJavaQueryTest >> testFamixClassTypeDeclarationsWithoutSelfLoops [
	self assertCollection: (c3 queryIncomingTypeDeclarations withoutSelfLoops atScope: FamixTType) hasSameElements: {c1 . c2}.
	self assertCollection: (c3 queryOutgoingTypeDeclarations withoutSelfLoops atScope: FamixTType) hasSameElements: {c2}
]

{ #category : #'tests - method' }
FamixJavaQueryTest >> testFamixMethodHasIncomingTypeDeclarations [
	self deny: m1 hasIncomingTypeDeclarations.
	self deny: m3 hasIncomingTypeDeclarations
]

{ #category : #'tests - method' }
FamixJavaQueryTest >> testFamixMethodHasOutgoingTypeDeclarations [
	self assert: m2 hasOutgoingTypeDeclarations.
	self assert: m3 hasOutgoingTypeDeclarations
]

{ #category : #'tests - method' }
FamixJavaQueryTest >> testFamixMethodHasTypeDeclarationsWithoutSelfLoops [
	self deny: m1 hasIncomingTypeDeclarations.
	self assert: m3 hasOutgoingTypeDeclarations
]

{ #category : #'tests - method' }
FamixJavaQueryTest >> testFamixMethodIncomingTypeDeclarations [
	self assert: m1 queryIncomingTypeDeclarations isEmpty.
	self assert: m3 queryIncomingTypeDeclarations isEmpty
]

{ #category : #'tests - method' }
FamixJavaQueryTest >> testFamixMethodOutgoingTypeDeclarations [
	self assertCollection: m2 queryOutgoingTypeDeclarations opposites hasSameElements: {c1 . c3}.
	self assertCollection: m3 queryOutgoingTypeDeclarations opposites hasSameElements: {c1 . c2 . c3}
]

{ #category : #'tests - method' }
FamixJavaQueryTest >> testFamixMethodTypeDeclarationsWithoutSelfLoops [
	self assert: m1 queryIncomingTypeDeclarations withoutSelfLoops isEmpty.
	self assertCollection: (m3 queryOutgoingTypeDeclarations withoutSelfLoops atScope: FamixTType) hasSameElements: {c1 . c2 . c3}
]

{ #category : #'tests - package' }
FamixJavaQueryTest >> testFamixPackageHasIncomingTypeDeclarations [
	self assert: p2 hasIncomingTypeDeclarations
]

{ #category : #'tests - package' }
FamixJavaQueryTest >> testFamixPackageHasOutgoingTypeDeclarations [
	self assert: p1 hasOutgoingTypeDeclarations
]

{ #category : #'tests - package' }
FamixJavaQueryTest >> testFamixPackageHasTypeDeclarationsWithoutSelfLoops [
	self assert: p2 hasIncomingTypeDeclarations.
	self assert: p1 hasOutgoingTypeDeclarations
]

{ #category : #'tests - package' }
FamixJavaQueryTest >> testFamixPackageIncomingTypeDeclarations [
	self assertCollection: (p2 queryIncomingTypeDeclarations atScope: FamixTPackage) hasSameElements: {p1 . p2}
]

{ #category : #'tests - package' }
FamixJavaQueryTest >> testFamixPackageOutgoingTypeDeclarations [
	self assertCollection: (p1 queryOutgoingTypeDeclarations atScope: FamixTPackage) hasSameElements: {p1 . p2}
]

{ #category : #'tests - package' }
FamixJavaQueryTest >> testFamixPackageTypeDeclarationsWithoutSelfLoops [
	self assertCollection: (p2 queryIncomingTypeDeclarations atScope: FamixTPackage) withoutSelfLoops hasSameElements: {p1}.
	self assertCollection: (p1 queryOutgoingTypeDeclarations atScope: FamixTPackage) withoutSelfLoops hasSameElements: {p2}
]