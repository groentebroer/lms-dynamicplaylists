-- PlaylistName:PLUGIN_DYNAMICPLAYLISTS4_BUILTIN_PLAYLIST_YEARS_UNRATED
-- PlaylistGroups:Years
-- PlaylistCategory:years
-- PlaylistParameter1:list:PLUGIN_DYNAMICPLAYLISTS4_PARAMNAME_INCLUDESONGS:0:PLUGIN_DYNAMICPLAYLISTS4_PARAMVALUENAME_SONGS_ALL,1:PLUGIN_DYNAMICPLAYLISTS4_PARAMVALUENAME_SONGS_UNPLAYED,2:PLUGIN_DYNAMICPLAYLISTS4_PARAMVALUENAME_SONGS_PLAYED
drop table if exists dynamicplaylist_random_years;
create temporary table dynamicplaylist_random_years as
	select notrated.year as year, notrated.sumrating as sumrating from
		(select tracks.year as year, sum(ifnull(tracks_persistent.rating,0)) as sumrating from tracks
			left join library_track on
				library_track.track = tracks.id
			join tracks_persistent on
				tracks_persistent.urlmd5 = tracks.urlmd5
			left join dynamicplaylist_history on
				dynamicplaylist_history.id = tracks.id and dynamicplaylist_history.client = 'PlaylistPlayer'
			where
				tracks.audio = 1
				and dynamicplaylist_history.id is null
				and ifnull(tracks.year, 0) != 0
				and not exists (select * from tracks t2,genre_track,genres
								where
									t2.id = tracks.id and
									tracks.id = genre_track.track and
									genre_track.genre = genres.id and
									genres.name in ('PlaylistExcludedGenres'))
				and
					case
						when ('PlaylistCurrentVirtualLibraryForClient' != '' and 'PlaylistCurrentVirtualLibraryForClient' is not null)
						then library_track.library = 'PlaylistCurrentVirtualLibraryForClient'
						else 1
					end
			group by tracks.year
				having sumrating = 0
			order by sumrating asc, random()
			limit 30) as notrated
	where sumrating = 0
	order by random()
	limit 1;
select tracks.id, tracks.primary_artist from tracks
	join dynamicplaylist_random_years on
		tracks.year = dynamicplaylist_random_years.year
	join tracks_persistent on
		tracks_persistent.urlmd5 = tracks.urlmd5
	left join library_track on
		library_track.track = tracks.id
	left join dynamicplaylist_history on
		dynamicplaylist_history.id = tracks.id and dynamicplaylist_history.client = 'PlaylistPlayer'
	where
		tracks.audio = 1
		and dynamicplaylist_history.id is null
		and tracks.year = dynamicplaylist_random_years.year
		and tracks.secs >= 'PlaylistTrackMinDuration'
		and
			case
				when 'PlaylistParameter1' = 1 then ifnull(tracks_persistent.playCount, 0) = 0
				when 'PlaylistParameter1' = 2 then ifnull(tracks_persistent.playCount, 0) > 0
				else 1
			end
		and
			case
				when ('PlaylistCurrentVirtualLibraryForClient' != '' and 'PlaylistCurrentVirtualLibraryForClient' is not null)
				then library_track.library = 'PlaylistCurrentVirtualLibraryForClient'
				else 1
			end
		and not exists (select * from tracks t2, genre_track, genres
						where
							t2.id = tracks.id and
							tracks.id = genre_track.track and
							genre_track.genre = genres.id and
							genres.name in ('PlaylistExcludedGenres'))
	group by tracks.id
	order by random()
	limit 'PlaylistLimit';
drop table dynamicplaylist_random_years;
