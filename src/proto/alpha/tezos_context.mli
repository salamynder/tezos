(**************************************************************************)
(*                                                                        *)
(*    Copyright (c) 2014 - 2017.                                          *)
(*    Dynamic Ledger Solutions, Inc. <contact@tezos.com>                  *)
(*                                                                        *)
(*    All rights reserved. No warranty, explicit or implicit, provided.   *)
(*                                                                        *)
(**************************************************************************)

module type BASIC_DATA = sig
  type t
  include Compare.S with type t := t
  val encoding: t Data_encoding.t
  val pp: Format.formatter -> t -> unit
end

type t
type context = t

module Contract_hash = Tezos_hash.Contract_hash

module Nonce_hash = Tezos_hash.Nonce_hash

type public_key = Ed25519.Public_key.t
type public_key_hash = Ed25519.Public_key_hash.t
type secret_key = Ed25519.Secret_key.t
type signature = Ed25519.Signature.t

module Tez : sig

  include BASIC_DATA
  type tez = t

  val zero: tez
  val one_cent : tez
  val fifty_cents : tez
  val one : tez

  val ( -? ) : tez -> tez -> tez tzresult
  val ( +? ) : tez -> tez -> tez tzresult
  val ( *? ) : tez -> int64 -> tez tzresult
  val ( /? ) : tez -> int64 -> tez tzresult

  val of_string: string -> tez option
  val to_string: tez -> string

  val of_cents: int64 -> tez option
  val to_cents: tez -> int64

end

module Period : sig

  include BASIC_DATA
  type period = t

  val of_seconds: int64 -> period tzresult
  val mult: int32 -> period -> period tzresult

  val one_second : period
  val one_minute : period
  val one_hour : period

end

module Timestamp : sig

  include BASIC_DATA with type t = Time.t
  type time = t
  val (+?) : time -> Period.t -> time tzresult

  val of_notation: string -> time option
  val to_notation: time -> string

  val of_seconds: string -> time option
  val to_seconds_string: time -> string

  val current : context -> time

end

module Raw_level : sig

  include BASIC_DATA
  type raw_level = t
  val arg: raw_level RPC.Arg.arg

  val diff: raw_level -> raw_level -> int32

  val root: raw_level
  val succ: raw_level -> raw_level
  val pred: raw_level -> raw_level option
  val to_int32: raw_level -> int32

end

module Cycle : sig

  include BASIC_DATA
  type cycle = t
  val arg: cycle RPC.Arg.arg

  val root: cycle
  val succ: cycle -> cycle
  val pred: cycle -> cycle option
  val to_int32: cycle -> int32

end

module Script_int : module type of Script_int_repr

module Script_timestamp : sig
  open Script_int
  type t
  val compare : t -> t -> int
  val to_string : t -> string
  val to_notation : t -> string option
  val to_num_str : t -> string
  val of_string : string -> t option
  val diff : t -> t -> z num
  val add_delta : t -> z num -> t
  val sub_delta : t -> z num -> t
  val now : context -> t
end

module Script : sig

  type prim = Michelson_v1_primitives.prim =
    | K_parameter
    | K_return
    | K_storage
    | K_code
    | D_False
    | D_Item
    | D_Left
    | D_List
    | D_Map
    | D_None
    | D_Pair
    | D_Right
    | D_Set
    | D_Some
    | D_True
    | D_Unit
    | I_H
    | I_ABS
    | I_ADD
    | I_AMOUNT
    | I_AND
    | I_BALANCE
    | I_CAR
    | I_CDR
    | I_CHECK_SIGNATURE
    | I_COMPARE
    | I_CONCAT
    | I_CONS
    | I_CREATE_ACCOUNT
    | I_CREATE_CONTRACT
    | I_DEFAULT_ACCOUNT
    | I_DIP
    | I_DROP
    | I_DUP
    | I_EDIV
    | I_EMPTY_MAP
    | I_EMPTY_SET
    | I_EQ
    | I_EXEC
    | I_FAIL
    | I_GE
    | I_GET
    | I_GT
    | I_HASH_KEY
    | I_IF
    | I_IF_CONS
    | I_IF_LEFT
    | I_IF_NONE
    | I_INT
    | I_LAMBDA
    | I_LE
    | I_LEFT
    | I_LOOP
    | I_LSL
    | I_LSR
    | I_LT
    | I_MANAGER
    | I_MAP
    | I_MEM
    | I_MUL
    | I_NEG
    | I_NEQ
    | I_NIL
    | I_NONE
    | I_NOT
    | I_NOW
    | I_OR
    | I_PAIR
    | I_PUSH
    | I_REDUCE
    | I_RIGHT
    | I_SIZE
    | I_SOME
    | I_SOURCE
    | I_STEPS_TO_QUOTA
    | I_SUB
    | I_SWAP
    | I_TRANSFER_TOKENS
    | I_UNIT
    | I_UPDATE
    | I_XOR
    | I_ITER
    | I_LOOP_LEFT
    | T_bool
    | T_contract
    | T_int
    | T_key
    | T_key_hash
    | T_lambda
    | T_list
    | T_map
    | T_nat
    | T_option
    | T_or
    | T_pair
    | T_set
    | T_signature
    | T_string
    | T_tez
    | T_timestamp
    | T_unit

  type location = Micheline.canonical_location

  type expr = prim Micheline.canonical

  type node = (location, prim) Micheline.node

  type t =
    { code : expr ;
      storage : expr }

  val location_encoding: location Data_encoding.t
  val expr_encoding: expr Data_encoding.t
  val prim_encoding: prim Data_encoding.t
  val encoding: t Data_encoding.t

  val hash_expr : expr -> string

end

module Bootstrap : sig
  type account = {
    public_key_hash: public_key_hash ;
    public_key: public_key ;
  }
  val accounts: context -> account list
  val account_encoding: account Data_encoding.t
  val refill: context -> context tzresult Lwt.t
end

module Constants : sig

  val proof_of_work_nonce_size: int
  val baking_reward: Tez.t
  val endorsement_reward: Tez.t
  val nonce_length: int
  val seed_nonce_revelation_tip: Tez.t
  val origination_burn: Tez.t
  val baking_bond_cost: Tez.t
  val endorsement_bond_cost: Tez.t
  val faucet_credit: Tez.t

  val cycle_length: context -> int32
  val voting_period_length: context -> int32
  val time_before_reward: context -> Period.t
  val slot_durations: context -> Period.t list
  val first_free_baking_slot: context -> int
  val max_signing_slot: context -> int
  val instructions_per_transaction: context -> int
  val proof_of_work_threshold: context -> int64
  val dictator_pubkey: context -> Ed25519.Public_key.t
  val max_number_of_operations: context -> int list
  val max_operation_data_length: context -> int
  val michelson_maximum_type_size: context -> int
end

(** Global storage for all delegates public keys *)
module Delegates_pubkey : sig

  val get:
    context -> public_key_hash -> public_key tzresult Lwt.t
  val get_option:
    context -> public_key_hash -> public_key option tzresult Lwt.t
  val reveal:
    context -> public_key_hash -> public_key -> context tzresult Lwt.t
  val remove:
    context -> public_key_hash -> context Lwt.t

  val list:
    context -> (public_key_hash * public_key) list Lwt.t

end

module Voting_period : sig

  include BASIC_DATA
  type voting_period = t
  val arg: voting_period RPC.Arg.arg

  val root: voting_period
  val succ: voting_period -> voting_period

  type kind =
    | Proposal
    | Testing_vote
    | Testing
    | Promotion_vote
  val kind_encoding: kind Data_encoding.encoding
  val to_int32: voting_period -> int32

end

module Level : sig

  type t = private {
    level: Raw_level.t ;
    level_position: int32 ;
    cycle: Cycle.t ;
    cycle_position: int32 ;
    voting_period: Voting_period.t ;
    voting_period_position: int32 ;
  }
  include BASIC_DATA with type t := t
  val pp_full: Format.formatter -> t -> unit
  type level = t

  val root: context -> level

  val succ: context -> level -> level
  val pred: context -> level -> level option

  val from_raw: context -> ?offset:int32 -> Raw_level.t -> level

  val diff: level -> level -> int32

  val current: context -> level

  val last_level_in_cycle: context -> Cycle.t -> level
  val levels_in_cycle: context -> Cycle.t -> level list

end

module Fitness : sig

  include (module type of Fitness)
  type fitness = t

  val increase: context -> context

  val current: context -> int64

  val to_int64: fitness -> int64 tzresult

end

module Nonce : sig

  type t
  type nonce = t
  val encoding: nonce Data_encoding.t

  val record_hash:
    context -> public_key_hash -> Tez.t -> Nonce_hash.t ->
    context tzresult Lwt.t

  val reveal:
    context -> Level.t -> nonce ->
    (context * public_key_hash * Tez.t) tzresult Lwt.t

  type status =
    | Unrevealed of {
        nonce_hash: Nonce_hash.t ;
        delegate_to_reward: public_key_hash ;
        reward_amount: Tez.t ;
      }
    | Revealed of nonce

  val get: context -> Level.t -> status tzresult Lwt.t

  val of_bytes: MBytes.t -> nonce tzresult
  val hash: nonce -> Nonce_hash.t
  val check_hash: nonce -> Nonce_hash.t -> bool

end

module Seed : sig

  val compute_for_cycle: context -> Cycle.t -> context tzresult Lwt.t
  val clear_cycle: context -> Cycle.t -> context tzresult Lwt.t

end

module Contract : sig

  include BASIC_DATA
  type contract = t
  val arg: contract RPC.Arg.arg

  val to_b58check: contract -> string
  val of_b58check: string -> contract tzresult

  val default_contract: public_key_hash -> contract
  val is_default: contract -> public_key_hash option

  val exists: context -> contract -> bool tzresult Lwt.t
  val must_exist: context -> contract -> unit tzresult Lwt.t

  val list: context -> contract list Lwt.t

  type origination_nonce

  val origination_nonce_encoding : origination_nonce Data_encoding.t
  val originated_contract : origination_nonce -> contract
  val originated_contracts : origination_nonce -> contract list

  val initial_origination_nonce : Operation_hash.t -> origination_nonce

  val get_manager:
    context -> contract -> public_key_hash tzresult Lwt.t
  val update_manager_key:
    context -> contract -> public_key option -> (context * public_key) tzresult Lwt.t

  val get_delegate_opt:
    context -> contract -> public_key_hash option tzresult Lwt.t
  val is_delegatable:
    context -> contract -> bool tzresult Lwt.t
  val is_spendable:
    context -> contract -> bool tzresult Lwt.t
  val get_script:
    context -> contract -> (Script.t option) tzresult Lwt.t
  val get_storage:
    context -> contract -> (Script.expr option) tzresult Lwt.t

  val get_counter: context -> contract -> int32 tzresult Lwt.t
  val get_balance:
    context -> contract -> Tez.t tzresult Lwt.t

  val set_delegate:
    context -> contract -> public_key_hash option -> context tzresult Lwt.t

  type error += Initial_amount_too_low of contract * Tez.t * Tez.t

  val originate:
    context ->
    origination_nonce ->
    balance: Tez.t ->
    manager: public_key_hash ->
    ?script: (Script.t * (Tez.t * Tez.t)) ->
    delegate: public_key_hash option ->
    spendable: bool ->
    delegatable: bool -> (context * contract * origination_nonce) tzresult Lwt.t

  type error += Balance_too_low of contract * Tez.t * Tez.t

  val spend:
    context -> contract -> Tez.t -> context tzresult Lwt.t
  val spend_from_script:
    context -> contract -> Tez.t -> context tzresult Lwt.t

  val credit:
    context -> contract -> Tez.t -> context tzresult Lwt.t

  val update_script_storage_and_fees:
    context -> contract -> Tez.t -> Script.expr -> context tzresult Lwt.t

  val increment_counter:
    context -> contract -> context tzresult Lwt.t

  val check_counter_increment:
    context -> contract -> int32 -> unit tzresult Lwt.t

end

module Vote : sig

  type proposal = Protocol_hash.t

  val record_proposal:
    context -> Protocol_hash.t -> public_key_hash ->
    context Lwt.t
  val get_proposals:
    context -> int32 Protocol_hash.Map.t Lwt.t
  val clear_proposals: context -> context Lwt.t

  val freeze_listings: context -> context tzresult Lwt.t
  val clear_listings: context -> context tzresult Lwt.t
  val listing_size: context -> int32 tzresult Lwt.t
  val in_listings: context -> public_key_hash -> bool Lwt.t

  type ballot = Yay | Nay | Pass

  type ballots = {
    yay: int32 ;
    nay: int32 ;
    pass: int32 ;
  }

  val record_ballot:
    context -> public_key_hash -> ballot -> context Lwt.t
  val get_ballots: context -> ballots tzresult Lwt.t
  val clear_ballots: context -> context Lwt.t

  val get_current_period_kind:
    context -> Voting_period.kind tzresult Lwt.t
  val set_current_period_kind:
    context -> Voting_period.kind -> context tzresult Lwt.t

  val get_current_quorum: context -> int32 tzresult Lwt.t
  val set_current_quorum: context -> int32 -> context tzresult Lwt.t

  val get_current_proposal:
    context -> proposal tzresult Lwt.t
  val init_current_proposal:
    context -> proposal -> context tzresult Lwt.t
  val clear_current_proposal:
    context -> context tzresult Lwt.t

end

type operation = {
  hash: Operation_hash.t ;
  shell: Operation.shell_header ;
  contents: proto_operation ;
  signature: signature option ;
}

and proto_operation =
  | Anonymous_operations of anonymous_operation list
  | Sourced_operations of sourced_operations

and anonymous_operation =
  | Seed_nonce_revelation of {
      level: Raw_level.t ;
      nonce: Nonce.t ;
    }
  | Faucet of {
      id: Ed25519.Public_key_hash.t ;
      nonce: MBytes.t ;
    }

and sourced_operations =
  | Manager_operations of {
      source: Contract.t ;
      public_key: public_key option ;
      fee: Tez.t ;
      counter: counter ;
      operations: manager_operation list ;
    }
  | Delegate_operations of {
      source: public_key ;
      operations: delegate_operation list ;
    }
  | Dictator_operation of dictator_operation

and manager_operation =
  | Transaction of {
      amount: Tez.t ;
      parameters: Script.expr option ;
      destination: Contract.contract ;
    }
  | Origination of {
      manager: public_key_hash ;
      delegate: public_key_hash option ;
      script: Script.t option ;
      spendable: bool ;
      delegatable: bool ;
      credit: Tez.t ;
    }
  | Delegation of public_key_hash option

and delegate_operation =
  | Endorsement of {
      block: Block_hash.t ;
      slot: int ;
    }
  | Proposals of {
      period: Voting_period.t ;
      proposals: Protocol_hash.t list ;
    }
  | Ballot of {
      period: Voting_period.t ;
      proposal: Protocol_hash.t ;
      ballot: Vote.ballot ;
    }

and dictator_operation =
  | Activate of Protocol_hash.t
  | Activate_testnet of Protocol_hash.t

and counter = Int32.t

module Operation : sig

  type raw = Operation.t = {
    shell: Operation.shell_header ;
    proto: MBytes.t ;
  }
  val raw_encoding: raw Data_encoding.t

  type t = operation
  val encoding: operation Data_encoding.t

  type error += Cannot_parse_operation (* `Branch *)
  val parse: Operation_hash.t -> Operation.t -> operation tzresult

  val parse_proto:
    MBytes.t -> (proto_operation * signature option) tzresult Lwt.t

  type error += Missing_signature (* `Permanent *)
  type error += Invalid_signature (* `Permanent *)

  val check_signature: public_key -> operation -> unit tzresult Lwt.t

  val forge: Operation.shell_header -> proto_operation -> MBytes.t

  val proto_operation_encoding: proto_operation Data_encoding.t

  val unsigned_operation_encoding:
    (Operation.shell_header * proto_operation) Data_encoding.t

end

module Block_header : sig

  type t = {
    shell: Block_header.shell_header ;
    proto: proto_header ;
    signature: Ed25519.Signature.t ;
  }

  and proto_header = {
    priority: int ;
    seed_nonce_hash: Nonce_hash.t ;
    proof_of_work_nonce: MBytes.t ;
  }

  type block_header = t

  type raw = Tezos_data.Block_header.t
  type shell_header = Tezos_data.Block_header.shell_header

  val hash: block_header -> Block_hash.t
  val hash_raw: raw -> Block_hash.t

  val encoding: block_header Data_encoding.encoding
  val raw_encoding: raw Data_encoding.t
  val proto_header_encoding: proto_header Data_encoding.encoding
  val shell_header_encoding: shell_header Data_encoding.encoding

  val max_header_length: int
  (** The maximum size of block headers in bytes *)

  val parse: Block_header.t -> block_header tzresult
  (** Parse the protocol-specific part of a block header. *)

  val parse_unsigned_proto_header: MBytes.t -> proto_header tzresult
  (** Parse the (unsigned) protocol-specific part of a block header. *)

  val forge_unsigned_proto_header: proto_header -> MBytes.t
  (** [forge_header proto_hdr] is the binary serialization
      (using [proto_header_encoding]) of the protocol-specific part
      of a block header, without the signature. *)

  val forge_unsigned:
    Block_header.shell_header -> proto_header -> MBytes.t
    (** [forge_header shell_hdr proto_hdr] is the binary serialization
        (using [unsigned_header_encoding]) of a block header,
        comprising both the shell and the protocol part of the header,
        without the signature. *)

end

module Roll : sig

  val value: context -> Tez.t
  val next: context -> Int32.t tzresult Lwt.t

  val freeze_rolls_for_cycle: context -> Cycle.t -> context tzresult Lwt.t
  val clear_cycle: context -> Cycle.t -> context tzresult Lwt.t

  val baking_rights_owner:
    context -> Level.t -> priority:int -> public_key_hash tzresult Lwt.t

  val endorsement_rights_owner:
    context -> Level.t -> slot:int -> public_key_hash tzresult Lwt.t

end

module Reward : sig

  val record:
    context -> public_key_hash -> Cycle.t -> Tez.t -> context tzresult Lwt.t

  val discard:
    context -> public_key_hash -> Cycle.t -> Tez.t -> context tzresult Lwt.t

  val set_reward_time_for_cycle:
    context -> Cycle.t -> Time.t -> context tzresult Lwt.t

  val pay_due_rewards: context -> context tzresult Lwt.t

end

val init:
  Context.t ->
  level:Int32.t ->
  timestamp:Time.t ->
  fitness:Fitness.t ->
  context tzresult Lwt.t
val finalize: ?commit_message:string -> context -> Updater.validation_result

val configure_sandbox:
  Context.t -> Data_encoding.json option -> Context.t tzresult Lwt.t

val activate: context -> Protocol_hash.t -> context Lwt.t
val fork_test_network: context -> Protocol_hash.t -> Time.t -> context Lwt.t

(**/**)

(* HACK alphanet *)
val faucet_count: context -> int
val incr_faucet_count: context -> context
