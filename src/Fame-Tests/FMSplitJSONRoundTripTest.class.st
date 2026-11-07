"
I run the split round trip test (see FMSplitRoundTripTest) with the split JSON format.
"
Class {
	#name : 'FMSplitJSONRoundTripTest',
	#superclass : 'FMSplitRoundTripTest',
	#category : 'Fame-Tests-Tests',
	#package : 'Fame-Tests',
	#tag : 'Tests'
}

{ #category : 'running' }
FMSplitJSONRoundTripTest >> reimport: aModel [
	^ FamixJavaModel new importFromSplitJSONStream: (String streamContents: [ :stream | aModel exportToSplitJSONStream: stream ]) readStream
]
