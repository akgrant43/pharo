"
a MIME object, along with its type and the URL it was found at (if any)
"
Class {
	#name : #MIMEDocument,
	#superclass : #Object,
	#instVars : [
		'type',
		'contents',
		'contentStream',
		'uri',
		'fields',
		'legacyMessage',
		'body',
		'parts'
	],
	#category : #'Network-MIME-Base'
}

{ #category : #'instance creation' }
MIMEDocument class >> content: aString [
	^self contentType: self defaultContentType  content: aString
]

{ #category : #'instance creation' }
MIMEDocument class >> contentStream: aStream [
	^ self 
		contentStream: aStream 
		mimeType: self defaultMIMEType
]

{ #category : #'instance creation' }
MIMEDocument class >> contentStream: aStream mimeType: aMimeType [ 
	"create a MIMEDocument with the given content-type and contentStream"
	"MIMEDocument mimeType: 'text/plain' asMIMEType contentStream: (ReadStream on: 'This is a test')"
	
	^self contentStream: aStream mimeType: aMimeType uri: aStream uri
]

{ #category : #'instance creation' }
MIMEDocument class >> contentStream: aStream mimeType: aMimeType uri: aURI [
	"create a MIMEDocument with the given content-type and contentStream"
	"MIMEDocument mimeType: 'text/plain' asMIMEType contentStream: (ReadStream on: 'This is a test')"
	
	^self new contentStream: aStream mimeType: aMimeType uri: aURI
]

{ #category : #compatibility }
MIMEDocument class >> contentType: aMIMEType content: content [
	"create a MIMEDocument with the given content-type and content"
	"MIMEDocument contentType: 'text/plain' content: 'This is a test'"
	
	^ self new
		privateContent: content;
		type: aMIMEType asZnMimeType;
		yourself
]

{ #category : #compatibility }
MIMEDocument class >> contentType: type content: content url: url [
	^ self 
		contents: content 
		mimeType: type asZnMimeType 
		uri: url
]

{ #category : #'content-types' }
MIMEDocument class >> contentTypeFormData [
	^'application/x-www-form-urlencoded'
]

{ #category : #'content-types' }
MIMEDocument class >> contentTypeHtml [
	^'text/html'
]

{ #category : #'content-types' }
MIMEDocument class >> contentTypeMultipart [
	^'multipart/form-data'
]

{ #category : #'content-types' }
MIMEDocument class >> contentTypePlainText [
	^'text/plain'
]

{ #category : #'content-types' }
MIMEDocument class >> contentTypeXml [
	^'text/xml'
]

{ #category : #'instance creation' }
MIMEDocument class >> contents: aString [
	^ self 
		contents: aString 
		mimeType: self defaultMIMEType
]

{ #category : #'instance creation' }
MIMEDocument class >> contents: content mimeType: aMimeType [ 
	"create a MIMEDocument with the given content-type and content"
	"MIMEDocument mimeType: 'text/plain' asMIMEType content: 'This is a test'"
	
	^self contents: content mimeType: aMimeType uri: nil
]

{ #category : #'instance creation' }
MIMEDocument class >> contents: content mimeType: aMimeType uri: aURL [
	"create a MIMEDocument with the given content-type and content"
	"MIMEDocument mimeType: 'text/plain' asMIMEType content: 'This is a test'"
	
	^self new contents: content mimeType: aMimeType uri: aURL
]

{ #category : #compatibility }
MIMEDocument class >> defaultContentType [
	^self defaultMIMEType asString
]

{ #category : #accessing }
MIMEDocument class >> defaultMIMEType [
	^ ZnMimeType default
]

{ #category : #'instance creation' }
MIMEDocument class >> document: aStringOrStream [
	"Answer an instance of the receiver with the supplied contents.
	aStringOrStream is a full MIME document, i.e. begins with header fields specifying content-type, etc."

	^self new document: aStringOrStream
]

{ #category : #compatibility }
MIMEDocument class >> guessContentTypeFromExtension: ext [
	"guesses a content type from the extension"
	^(self guessTypeFromExtension: ext) asString
]

{ #category : #compatibility }
MIMEDocument class >> guessTypeFromExtension: ext [
	"guesses a content type from the extension"
	^self guessTypeFromName: ext
]

{ #category : #compatibility }
MIMEDocument class >> guessTypeFromName: url [
	"guesses a content type from the url"
	
	| extension |
	extension := url asString copyAfterLast: $..
	^ ZnMimeType
		forFilenameExtension: extension
		ifAbsent: [ nil ]
]

{ #category : #payload }
MIMEDocument >> applicationPayload [
	"Answer the decoded body"

	| encoding |

	self assert: self isApplication.
	encoding := (self fieldNamed: #'content-transfer-encoding' ifAbsent: [ self error: 'Unknown encoding' ]) mainValue.

	encoding = #'base64' ifTrue: [ ^self body base64Decoded ].
	encoding = #'quoted-printable' ifTrue: [ ^self body decodeQuotedPrintable ].
	self error: 'Unknown encoding'.
]

{ #category : #accessing }
MIMEDocument >> attachmentSeparator [
	^(self fieldNamed: 'content-type' ifAbsent: [^nil]) parameters
		at: 'boundary' ifAbsent: [^nil]
]

{ #category : #accessing }
MIMEDocument >> body [ 
	"Answer the body of the document, i.e. everything after the header fields.
	Decoded contents should be retrieved using the payload protocol"

	| stream |

	^body ifNil: 
		[ "Skip over the fields if necessary"
		stream := self contentStream.
		stream position = 1 ifTrue: [ self fields ].
		body := stream upToEnd trimBoth.
		self discardContents.
		body ]
]

{ #category : #compatibility }
MIMEDocument >> content [
	^self contents
]

{ #category : #private }
MIMEDocument >> contentStream [
	"Answer a RWBinaryOrTextStream on the contents."

	contentStream
		ifNil: [contentStream := contents
				ifNil: [self contentStreamOnURI]
				ifNotNil: [(RWBinaryOrTextStream with: self contents) reset]].
	^contentStream
]

{ #category : #private }
MIMEDocument >> contentStream: aStream mimeType: aMimeType uri: aUri [
	type := aMimeType.
	contentStream := aStream.
	uri := aUri
]

{ #category : #private }
MIMEDocument >> contentStreamOnURI [
	^self uri contentStream
]

{ #category : #compatibility }
MIMEDocument >> contentType [
	^self mimeType asString
]

{ #category : #private }
MIMEDocument >> contents [
	"Answer the receiver's raw data. If we have a stream to read from. Read in the data, cache it and discard the stream."

	contents ifNil: [contents := self getContentFromStream].
	^contents
]

{ #category : #private }
MIMEDocument >> contents: contentStringOrBytes mimeType: aMimeType uri: aURI [
	type := aMimeType.
	contents := contentStringOrBytes.
	uri := aURI
]

{ #category : #parsing }
MIMEDocument >> decodeEncodedWord: aString [
	"Check if the supplied string is a MIME encoded-word string, and if so, decode it.
	Otherwise return the supplied string
	See https://en.wikipedia.org/wiki/MIME#Encoded-Word"

	| regex stringEncoding string encoder |

	regex := '\=\?(iso-8859-.|utf-8)\?([QB])\?(.*)\?=' asRegex.
	(regex matches: aString) ifFalse: [ ^aString ].
	encoder := (regex subexpression: 2) = 'utf-8'
		ifTrue: [ ZnCharacterEncoder utf8 ]
		ifFalse: [ ZnCharacterEncoder iso88591 ].
	stringEncoding := regex subexpression: 3.
	string := regex subexpression: 4.
	^[ string := (stringEncoding = 'Q') 
			ifTrue: [string decodeQuotedPrintable]
			ifFalse: [string base64Decoded].
	 encoder decodeBytes: string asByteArray ]
		on: Error 
		do: [ aString ]
]

{ #category : #private }
MIMEDocument >> discardContentStream [
	contentStream ifNotNil: [contentStream close].
	contentStream := nil
]

{ #category : #actions }
MIMEDocument >> discardContents [
	contents := nil.
	self discardContentStream
]

{ #category : #accessing }
MIMEDocument >> document: aStringOrStream [

	aStringOrStream isStream ifTrue: 
		[ contentStream := aStringOrStream.
		uri := aStringOrStream uri ]
	ifFalse:
		[ contents := aStringOrStream ]
]

{ #category : #fields }
MIMEDocument >> fieldNamed: aString ifAbsent: aBlock [
	| matchingFields |
	"return the value of the field with the specified name.  If there is more than one field, then return the first one"
	matchingFields := self fields at: aString asLowercase ifAbsent: [ ^aBlock value ].
	^matchingFields first
]

{ #category : #accessing }
MIMEDocument >> fields [ 

	^fields ifNil: [ fields := self parseFields ]
]

{ #category : #parsing }
MIMEDocument >> fieldsFrom: aStream do: aBlock [ 
	"Invoke the given block with each of the header fields from the given stream. The block arguments are the field name and value. The streams position is left right after the empty line separating header and body."
	| savedLine line s |
	savedLine := self readStringLineFrom: aStream.
	[ aStream atEnd ] whileFalse: 
		[ line := savedLine.
		line isEmpty ifTrue: [ ^ self ].	"quit when we hit a blank line"
		
		[ savedLine := self readStringLineFrom: aStream.
		savedLine notEmpty and: [ savedLine first isSeparator ] ] whileTrue: 
			[ "lines starting with white space are continuation lines"
			s := savedLine readStream.
			s skipSeparators.
			line := line , ' ' , s upToEnd ].
		self 
			reportField: line trimBoth
			to: aBlock ].

	"process final header line of a body-less message"
	savedLine isEmpty ifFalse: 
		[ self 
			reportField: savedLine trimBoth
			to: aBlock ]
]

{ #category : #fields }
MIMEDocument >> fieldsNamed: aString ifAbsent: aBlock [
	"return a list of all fields with the given name"
	^self fields at: aString asLowercase ifAbsent: aBlock
]

{ #category : #fields }
MIMEDocument >> fieldsNamed: aString  separatedBy: separationString [
	"return all fields with the specified name, concatenated together with separationString between each element.  Return an empty string if no fields with the specified name are present"
	| matchingFields |
	matchingFields := self fieldsNamed: aString ifAbsent: [ ^'' ].
	^String streamContents: [ :str |
		matchingFields
			do: [ :field | str nextPutAll: field mainValue ]
			separatedBy: [ str nextPutAll: separationString ]].

]

{ #category : #private }
MIMEDocument >> getContentFromStream [
	| streamContents |
	streamContents := self contentStream contents.
	self discardContentStream.
	^streamContents
]

{ #category : #fields }
MIMEDocument >> hasFieldNamed: aString [
	^self fields includesKey: aString asLowercase
]

{ #category : #testing }
MIMEDocument >> isApplication [
	^ self mainType = 'application'
]

{ #category : #testing }
MIMEDocument >> isGif [
	^ self mainType = 'image'
		and: [self subType = 'gif']
]

{ #category : #testing }
MIMEDocument >> isJpeg [
	^ self mainType = 'image'
		and: [self subType = 'jpeg' | (self subType = 'jpg')]
]

{ #category : #testing }
MIMEDocument >> isMultipart [
	^self mainType = 'multipart'
]

{ #category : #testing }
MIMEDocument >> isMultipartAlternative [
	"whether the document is in a multipart format where the parts are alternates"
	^ self contentType = 'multipart/alternative'

]

{ #category : #testing }
MIMEDocument >> isOctetStream [
	^ self isApplication and: [ self subType = 'octet-stream' ]
]

{ #category : #testing }
MIMEDocument >> isPlainText [
	^ self mainType = 'text' and: [ self subType = 'plain' ]
]

{ #category : #testing }
MIMEDocument >> isPng [
	^ self mainType = 'image'
		and: [self subType = 'png']
]

{ #category : #testing }
MIMEDocument >> isPnm [
	^ self mainType = 'image'
		and: [self subType = 'pnm']
]

{ #category : #testing }
MIMEDocument >> isText [
	^ self mainType = 'text'
]

{ #category : #accessing }
MIMEDocument >> legacyMessage [
	"Answer the legacy message, if any"

	"legacyMessage can be nil, check parts to see if it has been parsed"
	parts ifNil: [ self parseParts ].
	^legacyMessage
]

{ #category : #accessing }
MIMEDocument >> mainType [
	^self mimeType main
]

{ #category : #accessing }
MIMEDocument >> mimeType [

	| field values |

	field := self fieldNamed: 'content-type' ifAbsent: [ self error: 'No document type' ].
	values := '/' split: field mainValue.
	^ZnMimeType main: values first sub: values second parameters: field parameters
]

{ #category : #parsing }
MIMEDocument >> parseFields [
	"Parse aString to initialize my header fields."
	| parseStream |

	parseStream := self contentStream.
	fields := Dictionary new.

	"Extract information out of the header fields"
	self 
		fieldsFrom: parseStream
		do: 
			[ :fName :fValue | 
			"NB: fName is all lowercase"
			(fields 
				at: fName
				ifAbsentPut: [ OrderedCollection new: 1 ]) add: (MIMEHeaderValue 
					forField: fName
					fromString: fValue) ].
	^fields
]

{ #category : #parsing }
MIMEDocument >> parseParts [
	"private -- parse the parts of the message and store them into a collection"
	"If this is not multipart, store an empty collection"
	| parseStream msgStream messages separator |
	self isMultipart ifFalse: 
		[ parts := #().
		^ self ].

	"If we can't find a valid separator, handle it as if the message is not multipart"
	separator := self attachmentSeparator.
	separator ifNil: 
		[ Transcript
			show: 'Ignoring bad attachment separater';
			cr.
		parts := #().
		^ self ].
	separator := '--' , separator trimRight.
	parseStream := self contentStream.
	msgStream := LimitingLineStreamWrapper 
		on: parseStream
		delimiter: separator.
	msgStream limitingBlock: 
		[ :aLine | 
		aLine trimRight = separator or: 
			[ "Match the separator"
			aLine trimRight = (separator , '--') ] ].	"or the final separator with --"

	"Throw away everything up to and including the first separator"
	legacyMessage := msgStream upToEnd trimBoth.
	legacyMessage ifEmpty: [ legacyMessage := nil ].
	msgStream skipThisLine.

	"Extract each of the multi-parts as strings"
	messages := OrderedCollection new.
	[ parseStream atEnd ] whileFalse: 
		[ messages add: msgStream upToEnd.
		msgStream skipThisLine ].
	parts := messages collect: [ :e | self class document: e ].
	self discardContents 
]

{ #category : #accessing }
MIMEDocument >> parts [
	"Return the parts of this message, i.e. embedded MIMEDocument's."

	parts ifNil: [self parseParts].
	^ parts
]

{ #category : #payload }
MIMEDocument >> payload [
	"Answer the body of the text decoded according to the content type and transfer encoding"

	"Horrible case statement for now"
	self isText ifTrue: [ ^self textPayload ].
	self isApplication ifTrue: [ ^self applicationPayload ].
	self isImage ifTrue: [ ^self imagePayload ].
	^self parts
]

{ #category : #printing }
MIMEDocument >> printOn: aStream [
	aStream nextPutAll: self class name;
		nextPutAll: ' (';
		print: self mimeType;
		nextPutAll: ', '.
	contents
		ifNotNil: [ aStream
			print: self contents size;
			nextPutAll: ' bytes)' ]
		ifNil: [ aStream nextPutAll: 'unknown size)' ].
]

{ #category : #private }
MIMEDocument >> privateContent: aString [
	contents := aString
]

{ #category : #parsing }
MIMEDocument >> readStringLineFrom: aStream [ 
	"Read and answer the next line from the given stream. Consume the carriage return but do not append it to the string."

	^aStream nextLine
]

{ #category : #fields }
MIMEDocument >> removeFieldNamed: name [
	"remove all fields with the specified name"
	self fields removeKey: name ifAbsent: []
]

{ #category : #parsing }
MIMEDocument >> reportField: aString to: aBlock [ 
	"Evaluate the given block with the field name a value in the given field. Do nothing if the field is malformed."
	| s fieldName fieldValue |
	(aString includes: $:) ifFalse: [ ^ self ].
	s := aString readStream.
	fieldName := (s upTo: $:) asLowercase.	"fieldname must be lowercase"
	fieldValue := s upToEnd trimBoth.
	fieldValue isEmpty ifFalse: 
		[ aBlock 
			value: fieldName
			value: fieldValue ]
]

{ #category : #files }
MIMEDocument >> saveToFile: pathString [
	pathString asFileReference 
		binaryWriteStreamDo: [ :out | 
			out nextPutAll: self contents ]
]

{ #category : #accessing }
MIMEDocument >> subType [
	^self mimeType sub
]

{ #category : #payload }
MIMEDocument >> textPayload [
	"Answer the decoded body for text types.
	This only decodes the body, e.g. from base64 or QP, it doesn't attempt to parse the text, e.g. html"

	| encoding |

	self assert: self isText.
	encoding := self fieldNamed: #'content-transfer-encoding' ifAbsent: [ ].
	encoding ifNotNil: [ encoding := encoding mainValue ].

	encoding ifNil: [ ^self body ].
	encoding = #'base64' ifTrue: [ ^self body base64Decoded ].
	encoding = #'quoted-printable' ifTrue: [ ^self body decodeQuotedPrintable ].
	self error: 'Unknown encoding'.
]

{ #category : #accessing }
MIMEDocument >> type: mimeType [
	type := mimeType
]

{ #category : #accessing }
MIMEDocument >> uri [
	"Answer the URL the receiver was downloaded from.  It may legitimately be nil."

	^uri
]

{ #category : #accessing }
MIMEDocument >> uri: aURI [
	uri := aURI
]

{ #category : #accessing }
MIMEDocument >> url [
	"Answer the URL the receiver was downloaded from.  It may legitimately be nil."

	^ uri ifNotNil:[uri asString asUrl]
]
