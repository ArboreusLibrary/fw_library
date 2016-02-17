%%%-------------------------------------------------------------------
%%% @author Alexandr KIRILOV (http://alexandr.kirilov.me)
%%% @copyright (C) 2015, Arboreus, (http://arboreus.systems)
%%% @doc
%%%
%%% @end
%%% Created : 08. Aug 2015 18:48
%%%-------------------------------------------------------------------
-module(a_http_headers).
-author("Alexandr KIRILOV (http://alexandr.kirilov.me)").
-vsn("0.0.6.229").

%% Module API
-export([
	last_modified/1,
	expires/1,
	cache/1,
	json/2,
	csv/2,
	xml/2
]).

%% System include

%% Module Include Start
-include("../Handler/a.hrl").
%% Module Include End

%%-----------------------------------
%% @doc Return a list() within HTTP Header formated for Yaws out() function.
%% Example: "Last-Modified: Fri, 30 Oct 1998 14:19:41 GMT"
-spec last_modified(Time_in) -> list() | {error,_Reason}
	when Time_in :: pos_integer() | tuple() | current.

last_modified(Timestamp) when is_integer(Timestamp), Timestamp > 0 ->
	[{header,[
		"Last-Modified:",
		a:to_string(a_time:format(rfc822,{timestamp_tuple,a_time:timestamp_to_tuple(Timestamp)}))
	]}];
last_modified({{Year,Month,Day},{Hour,Minute,Second}})
	when
		is_integer(Year) == true, Year > 0,
		is_integer(Month) == true, Month > 0, Month =< 12,
		is_integer(Day) == true, Day > 0, Day =< 31,
		is_integer(Hour) == true, Hour >= 0, Hour =< 23,
		is_integer(Minute) == true, Minute >= 0, Minute =< 59,
		is_integer(Second) == true, Second >= 0, Second =< 59 ->
	[{header,[
		"Last-Modified:",
		a:to_string(a_time:format(rfc822,{date_tuple,{{Year,Month,Day},{Hour,Minute,Second}}}))
	]}];
last_modified(current) -> last_modified(erlang:localtime());
last_modified(_) -> a:error(?FUNCTION_NAME(),a000).

%%-----------------------------------
%% @doc Return a list() within HTTP Header formated for Yaws out() function.
%% Example: "Expires: Fri, 30 Oct 1998 14:19:41 GMT"
-spec expires(Time_in) -> list() | {error,_Reason}
	when Time_in :: pos_integer() | tuple() | current.

expires(Timestamp) when is_integer(Timestamp) == true, Timestamp > 0 ->
	[{header,[
		"Expires:",
		a:to_string(a_time:format(rfc822,{timestamp_tuple,a_time:timestamp_to_tuple(Timestamp)}))
	]}];
expires({{Year,Month,Day},{Hour,Minute,Second}})
	when
		is_integer(Year) == true, Year > 0,
		is_integer(Month) == true, Month > 0, Month =< 12,
		is_integer(Day) == true, Day > 0, Day =< 31,
		is_integer(Hour) == true, Hour >= 0, Hour =< 23,
		is_integer(Minute) == true, Minute >= 0, Minute =< 59,
		is_integer(Second) == true, Second >= 0, Second =< 59 ->
	[{header,[
		"Expires:",
		a:to_string(a_time:format(rfc822,{date_tuple,{{Year,Month,Day},{Hour,Minute,Second}}}))
	]}];
expires(current) -> expires(erlang:localtime());
expires(_) -> a:error(?FUNCTION_NAME(),a000).

%%-----------------------------------
%% @doc Return a list() within HTTP headers fromated for Yaws out() function.
-spec cache(Operation) -> list() | {error,_Reason}
	when Operation :: no.

cache(no) ->
	[
		{header,"Cache-Control: no-cache, no-store, must-revalidate"},
		{header,"Pragma: no-cache"},
		expires(1),
		last_modified(current)
	];
cache(_) -> a:error(?FUNCTION_NAME(),a000).

%%-----------------------------------
%% @doc Return a list within headers for JSON
-spec json(Type,File_name) -> list() | {error,_Reason}
	when
		Type :: no_cache | solid,
		File_name :: unicode:latin1_chardata().

json(Type,File_name) when is_atom(Type) ->
	case io_lib:char_list(File_name) of
		true -> json_set(Type,File_name);
		false -> a:error(?FUNCTION_NAME(),a000)
	end;
json(_,_) -> a:error(?FUNCTION_NAME(),a000).
json_set(no_cache,File_name) ->
	[
		cache(no),
		json(solid,File_name)
	];
json_set(solid,File_name) ->
	[
		{header,["Content-Type:","application/json; charset=utf-8"]},
		{header,["Content-Disposition:",lists:concat(["attachment; filename=",File_name])]}
	];
json_set(_,_) -> a:error(?FUNCTION_NAME(),a000).

%%-----------------------------------
%% @doc Return a list within HTTP headers for CSV file format
-spec csv(Type,File_name) -> list() | {error,_Reason}
	when
		Type :: no_cache | solid,
		File_name :: unicode:latin1_chardata().

csv(Type,File_name) when is_atom(Type) ->
	case io_lib:char_list(File_name) of
		true -> csv_set(Type,File_name);
		false -> a:error(?FUNCTION_NAME(),a000)
	end;
csv(_,_) -> a:error(?FUNCTION_NAME(),a000).
csv_set(no_cache,File_name) ->
	[
		cache(no),
		csv(solid,File_name)
	];
csv_set(solid,File_name) ->
	[
		{header,["Content-Type:","text/csv; charset=utf-8"]},
		{header,["Content-Disposition:",lists:concat(["attachment; filename=",File_name])]}
	];
csv_set(_,_) -> a:error(?FUNCTION_NAME(),a000).

%%-----------------------------------
%% @doc Return list within XML MIME type headers for Yaws out() function
-spec xml(Content_type,File_name) -> list() | {error,_Reason}
	when
		Content_type :: text_xml | application_xml,
		File_name :: unicode:latin1_chardata().

xml(Type,File_name) when is_atom(Type) ->
	case io_lib:char_list(File_name) of
		true -> xml_set(Type,File_name);
		false -> a:error(?FUNCTION_NAME(),a000)
	end;
xml(_,_) -> a:error(?FUNCTION_NAME(),a000).
xml_set(text,File_name) ->
	[
		{header,["Content-Type:","text/xml; charset=utf-8"]},
		{header,["Content-Disposition:",lists:concat(["attachment; filename=",File_name])]}
	];
xml_set(text_no_cache,File_name) -> [cache(no),xml_set(text,File_name)];
xml_set(application,File_name) ->
	[
		{header,["Content-Type:","application/xml; charset=utf-8"]},
		{header,["Content-Disposition:",lists:concat(["attachment; filename=",File_name])]}
	];
xml_set(application_no_cache,File_name) -> [cache(no),xml_set(application,File_name)];
xml_set(_,_) -> a:error(?FUNCTION_NAME(),a000).