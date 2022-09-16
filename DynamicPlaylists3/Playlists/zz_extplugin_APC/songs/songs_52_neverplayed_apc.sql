-- PlaylistName:PLUGIN_DYNAMICPLAYLISTS3_BUILTIN_PLAYLIST_SONGS_NEVERPLAYED_APC
-- PlaylistGroups:Songs
-- PlaylistCategory:songs
select distinct tracks.url from tracks
	left join library_track on
		library_track.track = tracks.id
	join alternativeplaycount on
		alternativeplaycount.urlmd5 = tracks.urlmd5 and (alternativeplaycount.playCount = 0 or alternativeplaycount.playCount is null)
	left join dynamicplaylist_history on
		dynamicplaylist_history.id=tracks.id and dynamicplaylist_history.client='PlaylistPlayer'
	where
		tracks.audio = 1
		and dynamicplaylist_history.id is null
		and tracks.secs >= 'PlaylistTrackMinDuration'
		and not exists (select * from tracks t2,genre_track,genres
						where
							t2.id=tracks.id and
							tracks.id=genre_track.track and 
							genre_track.genre=genres.id and
							genres.name in ('PlaylistExcludedGenres'))
		and
			case
				when ('PlaylistCurrentVirtualLibraryForClient'!='' and 'PlaylistCurrentVirtualLibraryForClient' is not null)
				then library_track.library = 'PlaylistCurrentVirtualLibraryForClient'
				else 1
			end
	group by tracks.id
	order by random()
	limit 'PlaylistLimit';