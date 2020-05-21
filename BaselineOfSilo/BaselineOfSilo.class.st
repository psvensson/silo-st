Class {
	#name : #BaselineOfSilo,
	#superclass : #BaselineOf,
	#category : #BaselineOfSilo
}

{ #category : #baselines }
BaselineOfSilo >> baseline: spec [
	<baseline>
	spec
		for: #common
		do: [ spec package: 'CloudConversations-Core'.
			spec
				baseline: 'NeoJSON'
				with: [ spec repository: 'github://svenvc/NeoJSON/repository' ].
			spec
				baseline: 'JSONWebToken'
				with: [ spec repository: 'github://noha/JSONWebToken:master/source' ].
			spec
				baseline: 'TaskIt'
				with: [ spec repository: 'github://sbragagnolo/taskit' ].			
			spec
				baseline: 'Firebase'
				with: [ spec repository: 'github://psvensson/firebase-st:master' ]		 ]
]
