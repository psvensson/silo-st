Class {
	#name : #SiloDB,
	#superclass : #Object,
	#instVars : [
		'db'
	],
	#category : #'Silo-Core'
}

{ #category : #accessing }
SiloDB >> db [
	^ db
]

{ #category : #accessing }
SiloDB >> db: anObject [
	db := anObject
]

{ #category : #'as yet unclassified' }
SiloDB >> initialize [
	| env cert firebase |
	env := OSPlatform environment.
	cert := env
		at: #certificate
		ifAbsent: [ Transcript
				show: 'No service account found in certificate environment veriable. Reading from file. ';
				cr.
			('service_account.json' asFileReference) readStreamDo: [ :stream | stream contents ] ].
	firebase := Firebase new: cert.
	db := FirebaseRtdb new: firebase.
	Transcript
		show: 'SiloDB created firebaseRtdb ';
		cr
]
