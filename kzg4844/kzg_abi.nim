# nim-kzg4844
# Copyright (c) 2023 Status Research & Development GmbH
# Licensed under either of
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE))
#  * MIT license ([LICENSE-MIT](LICENSE-MIT))
# at your option.
# This file may not be copied, modified, or distributed except according to
# those terms.

import
  std/strformat,
  strutils

from os import DirSep

const FIELD_ELEMENTS_PER_BLOB*{.strdefine.} = 4096

const
  ckzgPath = currentSourcePath.rsplit(DirSep, 1)[0] & "/csources/"
  blstPath = ckzgPath & "blst/"
  srcPath  = ckzgPath & "src/"
  bindingsPath = blstPath & "bindings"

when not defined(externalBlst):
  {.compile: blstPath & "build/assembly.S".}
  {.compile: blstPath & "src/server.c"}

{.compile: srcPath & "c_kzg_4844.c"}

{.passc: "-I" & bindingsPath &
  " -DFIELD_ELEMENTS_PER_BLOB=" &
  fmt"{FIELD_ELEMENTS_PER_BLOB}".}
{.passc: "-I" & srcPath .}

const
  BYTES_PER_FIELD_ELEMENT* = 32
  KzgBlobSize* = FIELD_ELEMENTS_PER_BLOB*BYTES_PER_FIELD_ELEMENT

type
  KZG_RET* = distinct cint

const
  KZG_OK*      = (0).KZG_RET
  KZG_BADARGS* = (1).KZG_RET
  KZG_ERROR*   = (2).KZG_RET
  KZG_MALLOC*  = (3).KZG_RET

proc `$`*(x: KZG_RET): string =
  case x
  of KZG_OK: "ok"
  of KZG_BADARGS: "kzg badargs"
  of KZG_ERROR: "kzg error"
  of KZG_MALLOC: "kzg malloc"
  else: "kzg unknown error"

proc `==`*(a, b: KZG_RET): bool =
  a.cint == b.cint

type
  KzgBlob* = array[KzgBlobSize, byte]

  KzgSettings* {.importc: "KZGSettings",
    header: "c_kzg_4844.h", byref.} = object

  Bytes48 = array[48, byte]
  Bytes32 = array[32, byte]

  KzgCommitment* = Bytes48
  KzgProof* = Bytes48

{.pragma: kzg_abi, cdecl, header: "c_kzg_4844.h".}

proc load_trusted_setup*(res: KzgSettings,
                         g1Bytes: ptr byte, # n1 * 48 bytes
                         n1: csize_t,
                         g2Bytes: ptr byte, # n2 * 96 bytes
                         n2: csize_t): KZG_RET {.kzg_abi,
                         importc: "load_trusted_setup".}

proc load_trusted_setup_file*(res: KzgSettings,
                         input: File): KZG_RET {.kzg_abi,
                         importc: "load_trusted_setup_file" .}

proc free_trusted_setup*(s: KzgSettings) {.kzg_abi,
                         importc: "free_trusted_setup" .}

proc blob_to_kzg_commitment*(res: var KzgCommitment,
                         blob: KzgBlob,
                         s: KzgSettings): KZG_RET {.kzg_abi,
                         importc: "blob_to_kzg_commitment" .}

proc compute_aggregate_kzg_proof*(res: var KzgProof,
                         blobs: ptr KzgBlob,
                         n: csize_t,
                         s: KzgSettings): KZG_RET {.kzg_abi,
                         importc: "compute_aggregate_kzg_proof" .}

proc verify_aggregate_kzg_proof*(re: var bool,
                         blobs: ptr KzgBlob,
                         commitmentsBytes: ptr KzgCommitment,
                         n: csize_t,
                         aggregatedProofBytes: KzgProof,
                         s: KzgSettings): KZG_RET {.kzg_abi,
                         importc: "verify_aggregate_kzg_proof" .}

proc compute_kzg_proof*(res: var KzgProof,
                         blob: KzgBlob,
                         zBytes: Bytes32,
                         s: KzgSettings): KZG_RET {.kzg_abi,
                         importc: "compute_kzg_proof" .}

proc verify_kzg_proof*(res: var bool,
                         commitmentBytes: KzgCommitment,
                         zBytes: Bytes32,
                         yBytes: Bytes32,
                         proofBytes: KzgProof,
                         s: KzgSettings): KZG_RET {.kzg_abi,
                         importc: "verify_kzg_proof" .}
