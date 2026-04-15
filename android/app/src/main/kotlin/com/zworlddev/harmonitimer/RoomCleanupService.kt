package com.zworlddev.harmonitimer

import android.app.Service
import android.content.Intent
import android.os.IBinder
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.FieldValue

class RoomCleanupService : Service() {
    private var roomId: String? = null
    private var userName: String? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val extraRoomId = intent?.getStringExtra("roomId")
        val extraUserName = intent?.getStringExtra("userName")
        
        if (extraRoomId != null) roomId = extraRoomId
        if (extraUserName != null) userName = extraUserName
        
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        
        // This is called when the user swipes the app away from recents
        if (roomId != null && userName != null) {
            val db = FirebaseFirestore.getInstance()
            db.collection("rooms").document(roomId!!)
                .update("participants", FieldValue.arrayRemove(userName!!))
                .addOnCompleteListener {
                    stopSelf()
                }
        } else {
            stopSelf()
        }
    }
}
