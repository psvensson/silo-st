Class {
	#name : #SiloServer,
	#superclass : #Object,
	#instVars : [
		'teapot',
		'firebasedb',
		'jsonEntityBuilder',
		'disallowed'
	],
	#category : #'Silo-Core'
}

{ #category : #initialization }
SiloServer >> containsDisallowedCharacters: request [ 
	| uri |
	uri := request uri pathPrintString.
	^ (uri asArray select: [ :each | each asString matchesRegex: disallowed ]) isNotEmpty
]

{ #category : #initialization }
SiloServer >> getUrlMapper [
	^ {
	([ :request | 
	self containsDisallowedCharacters: request ] -> [ :request | ZnResponse notFound: request uri ]).
	"----------------------------------------------------------------"
	([ :request | request uri isSlash and: [ request method = #GET ] ]
		-> [ :request | ZnResponse notFound: request uri ]).
	"----------------------------------------------------------------"
	([ :request | request uri pathSegments isNotEmpty  and: [ request method = #GET ] ]
		-> [ :request | 
			| uri |
			uri := request uri pathPrintString.
			self handleGet: uri ]).
	"----------------------------------------------------------------"
	([ :request | request uri pathSegments isNotEmpty  and: [ request method = #PUT ] ]
		-> [ :request | 
			| uri |
			uri := request uri pathPrintString.
			self handlePut: request ]).
	"----------------------------------------------------------------"
	([ :request | request uri pathSegments isNotEmpty  and: [ request method = #DELETE ] ]
		-> [ :request | 
			| uri |
			uri := request uri pathPrintString.
			self handleDelete: uri ])}
]

{ #category : #initialization }
SiloServer >> handleDelete: req [
	| proc sem rv path |
	path := '/' , (req at: #id).
	sem := Semaphore new.
	proc := [ (firebasedb db deletePath: '/' , (req at: #id))
		onSuccessDo: [ :res | 
			Transcript
				show: 'delete handler for ' , path , ' returning ' , res asString;
				cr.
			rv := ZnResponse ok: res.
			sem signal ] ] fork.
	sem wait.
	rv
]

{ #category : #initialization }
SiloServer >> handleGet: path [
	| proc sem rv |
	sem := Semaphore new.
	proc := [ (firebasedb db getPath: path)
		onSuccessDo: [ :result | 
			result
				ifNil: [ rv := ZnResponse notFound: path.
					sem signal ]
				ifNotNil: [ rv := ZnResponse ok: (jsonEntityBuilder value: (result at: #data)).
					(self headersFromString: (result at: #meta))
						keysAndValuesDo: [ :key :value | rv headers at: key put: value ].
					sem signal ] ] ] fork.
	sem wait.
	^ rv
]

{ #category : #initialization }
SiloServer >> handlePut: request [
	| proc sem rv path |
	sem := Semaphore new.
	path := request uri asString.
	(self containsDisallowedCharacters: request)
		ifTrue: [ rv := ZnResponse notFound: path.
			sem signal ]
		ifFalse: [ proc := [ (firebasedb db getPath: path)
				onSuccessDo: [ :getres | 
					| status |
					status := getres isNil
						ifTrue: [ 200 ]
						ifFalse: [ 201 ].
					(firebasedb db
						putPath: path , '/meta'
						obj: (self headersToString: request headers))
						onSuccessDo: [ :res | 
							(firebasedb db putPath: path , '/data' obj: request contents)
								onSuccessDo: [ :dres | 
									rv := ZnResponse statusCode: status.
									rv entity: (jsonEntityBuilder value: res).
									sem signal ] ] ] ] fork ].
	sem wait.
	^ rv
]

{ #category : #initialization }
SiloServer >> headersFromString: string [
	| headers tokens |
	headers := Dictionary new.
	tokens := string findTokens: '$$$'.
	tokens
		do: [ :token | 
			token
				ifNotNil: [ | parts |
					parts := token findTokens: ':'.
					headers at: (parts at: 1) put: (parts at: 2) ] ].
	^ headers
]

{ #category : #initialization }
SiloServer >> headersToString: headers [
	| str |
	str := ''.
	headers
		keysAndValuesDo: [ :key :value | 
			((key includesSubstring: 'Content-Type') or: (key includesSubstring: 'X-Secondlife-'))
				ifTrue: [ 
					str := str , key , ':' , value, '$$$'  ] ].
	^ str
]

{ #category : #initialization }
SiloServer >> initialize [
	| mapper |
	disallowed := '[.~:@!$&''()*,;=#?]'.
	mapper := self getUrlMapper.
	firebasedb := SiloDB new.
	jsonEntityBuilder := [ :object | 
	ZnEntity
		with:
			((String
				streamContents: [ :stream | 
					STON jsonWriter
						on: stream;
						prettyPrint: true;
						nextPut: object.
					stream cr ]) replaceAll: Character cr with: Character lf)
		type: ZnMimeType applicationJson ].
	Transcript
		show: '--- Silo starting';
		cr.
	(ZnServer startDefaultOn: 8080)
		"logToTranscript;"
		onRequestRespond: [ :request | 
			(mapper detect: [ :each | each key value: request ] ifNone: [ nil ])
				ifNil: [ ZnResponse badRequest: request ]
				ifNotNil: [ :handler | handler value value: request ] ]
]
