"
Visit any RBCommentNode in the syntax tree and evaluate a generic block.

The block  has two optional parameters:  
	aCommentArray (the collection of 1 or more RBComment's)
	aNode (the node which containts the comment)
"
Class {
	#name : #RBCommentNodeVisitor,
	#superclass : #RBAbstractBlockVisitor,
	#category : #'AST-Core-Visitors'
}

{ #category : #accessing }
RBCommentNodeVisitor >> visitNode: aNode [
	aNode comments ifNotEmpty: [ :commentNodes |
		commentNodes do: [ :commentNode |
			self visitBlock cull: commentNode cull: aNode ] ].
	
	super visitNode: aNode
]
