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
	cert := env at: #certificate.	
	firebase := Firebase new: cert.
	db := FirebaseRtdb new: firebase.
	Transcript show:'SiloDB created firebaseRtdb ';cr.
]
