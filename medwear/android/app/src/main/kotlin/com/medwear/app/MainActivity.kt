package com.medwear.app

import android.os.Bundle
import com.google.android.gms.wearable.Wearable
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val CHANNEL = "com.medwear/wear"

	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)

		flutterEngine?.dartExecutor?.let { executor ->
			MethodChannel(executor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
				when (call.method) {
					"getConnectedNodes" -> {
						Wearable.getNodeClient(this).connectedNodes
							.addOnSuccessListener { nodes ->
								val list = nodes.map { n ->
									mapOf(
										"id" to n.id,
										"displayName" to n.displayName,
										"isNearby" to n.isNearby
									)
								}
								result.success(list)
							}
							.addOnFailureListener { e ->
								result.error("WEAR_NODES_ERROR", e.message, null)
							}
					}
					"sendPing" -> {
						val path = call.argument<String>("path") ?: "/ping"
						val payload = (call.argument<String>("payload") ?: "ping").toByteArray()
						Wearable.getNodeClient(this).connectedNodes
							.addOnSuccessListener { nodes ->
								if (nodes.isEmpty()) {
									result.success(false)
								} else {
									val nodeId = nodes.first().id
									Wearable.getMessageClient(this)
										.sendMessage(nodeId, path, payload)
										.addOnSuccessListener { result.success(true) }
										.addOnFailureListener { e -> result.error("WEAR_MSG_ERROR", e.message, null) }
								}
							}
							.addOnFailureListener { e ->
								result.error("WEAR_NODES_ERROR", e.message, null)
							}
					}
					else -> result.notImplemented()
				}
			}
		}
	}
}
