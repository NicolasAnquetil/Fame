"
I run the split round trip test (see FMSplitRoundTripTest) with the split MessagePack format.
"
Class {
	#name : 'FMSplitMessagePackRoundTripTest',
	#superclass : 'FMSplitRoundTripTest',
	#category : 'Fame-ImportExport-MessagePack-Tests-Tests',
	#package : 'Fame-ImportExport-MessagePack-Tests',
	#tag : 'Tests'
}

{ #category : 'running' }
FMSplitMessagePackRoundTripTest >> reimport: aModel [

	^ FamixJavaModel new importFromSplitMessagePackStream:
		  (ByteArray streamContents: [ :stream | aModel exportToSplitMessagePackStream: stream ]) readStream
]
