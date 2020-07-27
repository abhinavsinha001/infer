(*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

(** Definition and parsing of command line arguments *)

open! IStd

val warnf : ('a, Format.formatter, unit) format -> 'a
(** Print to stderr in case of error, fails in strict mode *)

type parse_mode =
  | InferCommand  (** parse arguments as arguments for infer *)
  | Javac  (** parse arguments passed to the Java compiler *)
  | NoParse  (** all arguments are anonymous arguments, no parsing is attempted *)
[@@deriving compare]

val is_originator : bool

val init_work_dir : string

(** The [mk_*] functions declare command line options, while [parse] parses then according to the
    declared options.

    The arguments of the declaration functions are largely treated uniformly:

    - [long] declares the option [--long]
    - [short] declares the option [-short] as an alias
    - [deprecated] declares the option [-key] as an alias, for each [key] in [deprecated]
    - [default] specifies the default value
    - [default_to_string] is used to document the default value
    - [f] specifies a transformation to be performed on the parsed value before setting the config
      variable
    - [symbols] is an association list sometimes used in place of [f]
    - [parse_mode] declares which parse mode the option is for
    - [in_help] indicates the man pages in which the command should be documented, as generated by
      calling infer with --help. Otherwise it appears only in --help-full.
    - [meta] is a meta-variable naming the parsed value for documentation purposes
    - a documentation string *)
type 'a t =
     ?deprecated:string list
  -> long:string
  -> ?short:char
  -> ?parse_mode:parse_mode
  -> ?in_help:(InferCommand.t * string) list
  -> ?meta:string
  -> string
  -> 'a

val mk_set : 'a ref -> 'a -> unit t
(** [mk_set variable value] defines a command line option which sets [variable] to [value]. *)

val mk_bool : ?deprecated_no:string list -> ?default:bool -> ?f:(bool -> bool) -> bool ref t
(** [mk_bool long short doc] defines a [bool ref] set by the command line flag [--long] (and [-s]),
    and cleared by the flag [--no-long] (and [-S]). If [long] already has a "no-" prefix, or [s] is
    capital, then the existing prefixes will instead be removed. The default value is [false] unless
    overridden by [~default:true]. The [doc] string will be prefixed with either "Activates:" or
    "Deactivates:", so should be phrased accordingly. *)

val mk_bool_group :
     ?deprecated_no:string list
  -> ?default:bool
  -> ?f:(bool -> bool)
  -> (bool ref list -> bool ref list -> bool ref) t
(** [mk_bool_group children not_children] behaves as [mk_bool] with the addition that all the
    [children] are also set and the [no_children] are unset. A child can be unset by including
    "--no-child" later in the arguments. *)

val mk_int : default:int -> ?default_to_string:(int -> string) -> ?f:(int -> int) -> int ref t

val mk_int_opt :
  ?default:int -> ?default_to_string:(int option -> string) -> ?f:(int -> int) -> int option ref t

val mk_float_opt :
  ?default:float -> ?default_to_string:(float option -> string) -> float option ref t

val mk_string :
  default:string -> ?default_to_string:(string -> string) -> ?f:(string -> string) -> string ref t

val mk_string_opt :
     ?default:string
  -> ?default_to_string:(string option -> string)
  -> ?f:(string -> string)
  -> ?mk_reset:bool
  -> string option ref t
(** An option "--[long]-reset" is automatically created that resets the reference to None when found
    on the command line, unless [mk_reset] is false. *)

val mk_string_list :
     ?default:string list
  -> ?default_to_string:(string list -> string)
  -> ?f:(string -> string)
  -> string list ref t
(** [mk_string_list] defines a [string list ref], initialized to [\[\]] unless overridden by
    [~default]. Each argument of an occurrence of the option will be prepended to the list, so the
    final value will be in the reverse order they appeared on the command line.

    An option "--[long]-reset" is automatically created that resets the list to [] when found on the
    command line. *)

val mk_string_map :
     ?default:string String.Map.t
  -> ?default_to_string:(string String.Map.t -> string)
  -> string String.Map.t ref t

val mk_path :
  default:string -> ?default_to_string:(string -> string) -> ?f:(string -> string) -> string ref t
(** like [mk_string] but will resolve the string into an absolute path so that children processes
    agree on the absolute path that the option represents *)

val mk_path_opt :
  ?default:string -> ?default_to_string:(string option -> string) -> string option ref t
(** analogous of [mk_string_opt] with the extra feature of [mk_path] *)

val mk_path_list :
  ?default:string list -> ?default_to_string:(string list -> string) -> string list ref t
(** analogous of [mk_string_list] with the extra feature of [mk_path] *)

val mk_symbol :
  default:'a -> symbols:(string * 'a) list -> eq:('a -> 'a -> bool) -> ?f:('a -> 'a) -> 'a ref t
(** [mk_symbol long symbols] defines a command line flag [--long <symbol>] where [(<symbol>,_)] is
    an element of [symbols]. *)

val mk_symbol_opt : symbols:(string * 'a) list -> ?f:('a -> 'a) -> ?mk_reset:bool -> 'a option ref t
(** [mk_symbol_opt] is similar to [mk_symbol] but defaults to [None]. If [mk_reset] is false then do
    not create an additional --[long]-reset option to reset the value of the option to [None]. *)

val mk_symbol_seq :
  ?default:'a list -> symbols:(string * 'a) list -> eq:('a -> 'a -> bool) -> 'a list ref t
(** [mk_symbol_seq long symbols] defines a command line flag [--long <symbol sequence>] where
    [<symbol sequence>] is a comma-separated sequence of [<symbol>]s such that [(<symbol>,_)] is an
    element of [symbols]. *)

val mk_json : Yojson.Basic.t ref t

val mk_anon : unit -> string list ref
(** [mk_anon ()] defines a [string list ref] of the anonymous command line arguments, in the reverse
    order they appeared on the command line. *)

val mk_rest_actions :
     ?parse_mode:parse_mode
  -> ?in_help:(InferCommand.t * string) list
  -> string
  -> usage:string
  -> (string -> parse_mode)
  -> string list ref
(** [mk_rest_actions doc ~usage command_to_parse_mode] defines a [string list ref] of the command
    line arguments following ["--"], in the reverse order they appeared on the command line. [usage]
    is the usage message in case of parse errors or if --help is passed. For example, calling
    [mk_action] and parsing [exe -opt1 -opt2 -- arg1 arg2] will result in the returned ref
    containing [arg2; arg1]. Additionally, the first arg following ["--"] is passed to
    [command_to_parse_mode] to obtain the parse action that will be used to parse the remaining
    arguments. *)

type command_doc

val mk_command_doc :
     title:string
  -> section:int
  -> version:string
  -> date:string
  -> short_description:string
  -> synopsis:Cmdliner.Manpage.block list
  -> description:Cmdliner.Manpage.block list
  -> ?options:[`Prepend of Cmdliner.Manpage.block list | `Replace of Cmdliner.Manpage.block list]
  -> ?exit_status:Cmdliner.Manpage.block list
  -> ?environment:Cmdliner.Manpage.block list
  -> ?files:Cmdliner.Manpage.block list
  -> ?notes:Cmdliner.Manpage.block list
  -> ?bugs:Cmdliner.Manpage.block list
  -> ?examples:Cmdliner.Manpage.block list
  -> ?see_also:Cmdliner.Manpage.block list
  -> string
  -> command_doc
(** [mk_command_doc ~title ~section ~version ~short_description ~synopsis ~description ~see_also
    command_exe] records information about a command that is used to create its man page. A lot of
    the concepts are taken from man-pages(7).

    - [command_exe] is the name of the command, preferably an executable that selects the command
    - [title] will be the title of the manual
    - [section] will be the section of the manual (the number 7 in man-pages(7))
    - [version] is the version string of the command
    - [date] is the date of the last modification of the manual
    - [short_description] is a one-line description of the command
    - [options] can be either [`Replace blocks], which populates the OPTIONS section with [blocks],
      or [`Prepend blocks], in which case the options from the command are used, prepended by
      [blocks]. If unspecified it defaults to [`Prepend \[\]].
    - All the other [section_name] options correspond to the contents of the section [section_name].
      Some are mandatory and some are not. *)

val mk_subcommand :
     InferCommand.t
  -> ?on_unknown_arg:[`Add | `Skip | `Reject]
  -> name:string
  -> ?deprecated_long:string
  -> ?parse_mode:parse_mode
  -> ?in_help:(InferCommand.t * string) list
  -> command_doc option
  -> unit
(** [mk_subcommand command ~long command_doc] defines the subcommand [command]. A subcommand is
    activated by passing [name], and by passing [--deprecated_long] if specified. A man page is
    automatically generated for [command] based on the information in [command_doc], if available
    (otherwise the command is considered internal). [on_unknown_arg] is the action taken on unknown
    anonymous arguments; it is `Reject by default. *)

val args_env_var : string
(** environment variable use to pass arguments from parent to child processes *)

val strict_mode_env_var : string

val env_var_sep : char
(** separator of argv elements when encoded into environment variables *)

val extend_env_args : string list -> unit
(** [extend_env_args args] appends [args] to those passed via [args_env_var] *)

val parse :
     ?config_file:string
  -> usage:Arg.usage_msg
  -> parse_mode
  -> InferCommand.t option
  -> InferCommand.t option * (int -> 'a)
(** [parse ~usage parse_mode command] parses command line arguments as specified by preceding calls
    to the [mk_*] functions, and returns:

    - the command selected by the user on the command line, except if [command] is not None in which
      case it is considered "pre-selected" for the user;
    - a function that prints the usage message and help text then exits with the code passed as
      argument.

    The decoded values of the inferconfig file [config_file], if provided, are parsed, followed by
    the decoded values of the environment variable [args_env_var], followed by [Sys.argv] if
    [parse_mode] is one that should parse command line arguments (this is defined in the
    implementation of this module). Therefore arguments passed on the command line supersede those
    specified in the environment variable, which themselves supersede those passed via the config
    file.

    WARNING: An argument will be interpreted as many times as it appears in all of the config file,
    the environment variable, and the command line. The [args_env_var] is set to the set of options
    parsed in [args_env_var] and on the command line. *)

val is_env_var_set : string -> bool
(** [is_env_var_set var] is true if $[var]=1 *)

val show_manual :
     ?scrub_defaults:bool
  -> ?internal_section:string
  -> Cmdliner.Manpage.format
  -> command_doc
  -> InferCommand.t option
  -> unit
(** Display the manual of [command] to the user, or [command_doc] if [command] is None. [format] is
    used as for [Cmdliner.Manpage.print]. If [internal_section] is specified, add a section titled
    [internal_section] about internal (hidden) options. If [scrub_defaults] then do not print
    default values for options. *)

val keep_args_file : bool ref
