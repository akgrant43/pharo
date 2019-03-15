Class {
	#name : #MIMEDocumentTest,
	#superclass : #TestCase,
	#category : #'Network-MIME'
}

{ #category : #'test documents' }
MIMEDocumentTest class >> document1 [

	^'MIME-Version: 1.0
Content-Type: multipart/mixed; boundary=frontier

This is a message with multiple parts in MIME format.
--frontier
Content-Type: text/plain

This is the body of the message.
--frontier
Content-Type: application/octet-stream
Content-Transfer-Encoding: base64

PGh0bWw+CiAgPGhlYWQ+CiAgPC9oZWFkPgogIDxib2R5PgogICAgPHA+VGhpcyBpcyB0aGUg
Ym9keSBvZiB0aGUgbWVzc2FnZS48L3A+CiAgPC9ib2R5Pgo8L2h0bWw+Cg==
--frontier--'
]

{ #category : #'test documents' }
MIMEDocumentTest class >> document2 [

	^'MIME-Version: 1.0
Content-Type: multipart/mixed; boundary=frontier

--frontier
Content-Type: text/plain

This is the body of the message.
--frontier
Content-Type: application/octet-stream
Content-Transfer-Encoding: base64

PGh0bWw+CiAgPGhlYWQ+CiAgPC9oZWFkPgogIDxib2R5PgogICAgPHA+VGhpcyBpcyB0aGUg
Ym9keSBvZiB0aGUgbWVzc2FnZS48L3A+CiAgPC9ib2R5Pgo8L2h0bWw+Cg==
--frontier--'
]

{ #category : #'test documents' }
MIMEDocumentTest class >> document3 [

	^String streamContents: [ :stream |
		stream << '' ]
]

{ #category : #tests }
MIMEDocumentTest >> testDocument1 [

	| document part1 part2 payload |

	document := MIMEDocument document: self class document1.

	self assert: document parts size equals: 2.

	part1 := document parts first.
	self assert: part1 isText.
	self assert: part1 isPlainText.
	self assert: part1 body size equals: 32.
	self assert: part1 payload size equals: 32.

	part2 := document parts second.
	payload := part2 payload.
	self assert: part2 isApplication.
	self assert: part2 isOctetStream.
	self assert: payload class equals: ByteArray.
	self assert: payload size equals: 97
]

{ #category : #tests }
MIMEDocumentTest >> testLegacyMessage [
	"Test that the legacy message is parsed correctly in a simple document, 
	and that it is nil if there is no message"

	| document |

	document := MIMEDocument document: self class document1.
	self
		assert: document legacyMessage
		equals: 'This is a message with multiple parts in MIME format.'.

	document := MIMEDocument document: self class document2.
	self
		assert: document legacyMessage isNil.

]

{ #category : #tests }
MIMEDocumentTest >> testParseFieldsOnly [
	"Create a MIMEDocument, request the fields and ensure that the parts haven't been parsed"

	| document fields |

	document := MIMEDocument document: self class document1.
	fields := document fields.
	self assert: fields isDictionary.
	self assert: (document instVarNamed: 'parts') isNil.
]
