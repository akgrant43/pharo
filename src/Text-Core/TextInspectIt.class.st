Class {
	#name : #TextInspectIt,
	#superclass : #TextDoIt,
	#category : #'Text-Core'
}

{ #category : #'as yet unclassified' }
TextInspectIt >> actOnClick: anEvent for: anObject in: paragraph editor: editor [

	| result |
	result := Smalltalk compiler evaluate: evalString for: anObject logged: false.
	anObject glamourPresentation selection: result.
	^ true 
]

{ #category : #'as yet unclassified' }
TextInspectIt >> writeScanOn: strm [

	strm nextPut: $I; nextPutAll: evalString; nextPutAll: ';;'
]
