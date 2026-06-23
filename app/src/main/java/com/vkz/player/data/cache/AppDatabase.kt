package com.vkz.player.data.cache

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase

@Database(
    entities = [
        CachedTrackEntity::class,
        CachedPlaylistEntity::class,
        DownloadQueueEntity::class,
        FavoriteTrackEntity::class
    ],
    version = 2,
    exportSchema = false
)
abstract class AppDatabase : RoomDatabase() {

    abstract fun cacheDao(): CacheDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        private const val DB_NAME = "vkz_cache.db"

        fun getInstance(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: buildDatabase(context).also { INSTANCE = it }
            }
        }

        private fun buildDatabase(context: Context): AppDatabase {
            return Room.databaseBuilder(
                context.applicationContext,
                AppDatabase::class.java,
                DB_NAME
            )
                .fallbackToDestructiveMigration()
                .build()
        }
    }
}