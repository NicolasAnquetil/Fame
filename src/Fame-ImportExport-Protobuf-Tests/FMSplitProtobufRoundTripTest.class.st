"
I run the split round trip test (see FMSplitRoundTripTest) with the split protobuf format.
"
Class {
	#name : 'FMSplitProtobufRoundTripTest',
	#superclass : 'FMSplitRoundTripTest',
	#category : 'Fame-ImportExport-Protobuf-Tests-Tests',
	#package : 'Fame-ImportExport-Protobuf-Tests',
	#tag : 'Tests'
}

{ #category : 'running' }
FMSplitProtobufRoundTripTest >> reimport: aModel [

	^ FamixJavaModel new importFromSplitProtobufStream:
		  (ByteArray streamContents: [ :stream | aModel exportToSplitProtobufStream: stream ]) readStream
]
