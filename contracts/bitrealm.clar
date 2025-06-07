;; BitRealm Gaming Protocol
;; A Next-Generation Bitcoin Layer 2 Gaming Ecosystem
;;
;; Title: BitRealm - Decentralized Gaming Protocol on Stacks
;;
;; Summary:
;; BitRealm is a comprehensive gaming protocol built on Stacks that enables 
;; players to own, trade, and monetize in-game assets through Bitcoin-backed 
;; NFTs. The protocol features avatar progression, virtual worlds, competitive 
;; leaderboards, and Bitcoin reward distribution systems.
;;
;; Description:
;; This smart contract powers a complete gaming ecosystem where players can:
;; - Mint and trade unique game assets as NFTs with rarity-based mechanics
;; - Create customizable avatars with leveling and experience systems
;; - Access multiple virtual worlds with entry requirements and rewards
;; - Compete on global leaderboards for Bitcoin-denominated prizes
;; - Participate in a player-driven economy with transparent reward distribution
;;
;; The protocol ensures fair gameplay through admin controls while maintaining
;; decentralization through community governance and Bitcoin settlement finality.
;; Built for the future of blockchain gaming on Bitcoin's most advanced layer.
;;

;; ERROR CONSTANTS

(define-constant ERR-NOT-AUTHORIZED (err u1))
(define-constant ERR-INVALID-GAME-ASSET (err u2))
(define-constant ERR-INSUFFICIENT-FUNDS (err u3))
(define-constant ERR-TRANSFER-FAILED (err u4))
(define-constant ERR-LEADERBOARD-FULL (err u5))
(define-constant ERR-ALREADY-REGISTERED (err u6))
(define-constant ERR-INVALID-REWARD (err u7))
(define-constant ERR-INVALID-INPUT (err u8))
(define-constant ERR-INVALID-SCORE (err u9))
(define-constant ERR-INVALID-FEE (err u10))
(define-constant ERR-INVALID-ENTRIES (err u11))
(define-constant ERR-PLAYER-NOT-FOUND (err u12))
(define-constant ERR-INVALID-AVATAR (err u13))
(define-constant ERR-WORLD-NOT-FOUND (err u14))
(define-constant ERR-INVALID-NAME (err u15))
(define-constant ERR-INVALID-DESCRIPTION (err u16))
(define-constant ERR-INVALID-RARITY (err u17))
(define-constant ERR-INVALID-POWER-LEVEL (err u18))
(define-constant ERR-INVALID-ATTRIBUTES (err u19))
(define-constant ERR-INVALID-WORLD-ACCESS (err u20))
(define-constant ERR-INVALID-OWNER (err u21))
(define-constant ERR-MAX-LEVEL-REACHED (err u22))
(define-constant ERR-MAX-EXPERIENCE-REACHED (err u23))
(define-constant ERR-INVALID-LEVEL-UP (err u24))

;; GAME MECHANICS CONSTANTS

(define-constant MAX-LEVEL u100)
(define-constant MAX-EXPERIENCE-PER-LEVEL u1000)
(define-constant BASE-EXPERIENCE-REQUIRED u100)

;; PROTOCOL CONFIGURATION

(define-data-var protocol-fee uint u10)
(define-data-var max-leaderboard-entries uint u50)
(define-data-var total-prize-pool uint u0)
(define-data-var total-assets uint u0)
(define-data-var total-avatars uint u0)
(define-data-var total-worlds uint u0)

;; ACCESS CONTROL

(define-map protocol-admin-whitelist
  principal
  bool
)

;; VALIDATION FUNCTIONS

(define-private (is-valid-name (name (string-ascii 50)))
  (and
    (>= (len name) u1)
    (<= (len name) u50)
    (not (is-eq name ""))
  )
)

(define-private (is-valid-description (description (string-ascii 200)))
  (and
    (>= (len description) u1)
    (<= (len description) u200)
    (not (is-eq description ""))
  )
)

(define-private (is-valid-rarity (rarity (string-ascii 20)))
  (or
    (is-eq rarity "common")
    (is-eq rarity "uncommon")
    (is-eq rarity "rare")
    (is-eq rarity "epic")
    (is-eq rarity "legendary")
  )
)

(define-private (is-valid-power-level (power uint))
  (and (>= power u1) (<= power u1000))
)(define-private (is-valid-attributes (attributes (list 10 (string-ascii 20))))
  (and
    (>= (len attributes) u1)
    (<= (len attributes) u10)
  )
)

(define-private (is-valid-world-access (worlds (list 10 uint)))
  (and
    (>= (len worlds) u1)
    (<= (len worlds) u10)
    (fold check-world-exists worlds true)
  )
)

(define-private (check-world-exists
    (world-id uint)
    (valid bool)
  )
  (and valid (is-some (get-world-details world-id)))
)

;; NFT DEFINITIONS

(define-non-fungible-token bitrealm-asset uint)
(define-non-fungible-token bitrealm-avatar uint)

;; DATA STRUCTURES

;; Asset Metadata Storage
(define-map bitrealm-asset-metadata
  { token-id: uint }
  {
    name: (string-ascii 50),
    description: (string-ascii 200),
    rarity: (string-ascii 20),
    power-level: uint,
    world-id: uint,
    attributes: (list 10 (string-ascii 20)),
    experience: uint,
    level: uint,
  }
)

;; Avatar System Storage
(define-map avatar-metadata
  { avatar-id: uint }
  {
    name: (string-ascii 50),
    level: uint,
    experience: uint,
    achievements: (list 20 (string-ascii 50)),
    equipped-assets: (list 5 uint),
    world-access: (list 10 uint),
  }
)

;; Virtual Worlds Storage
(define-map game-worlds
  { world-id: uint }
  {
    name: (string-ascii 50),
    description: (string-ascii 200),
    entry-requirement: uint,
    active-players: uint,
    total-rewards: uint,
  }
)

;; Competitive Leaderboard Storage
(define-map leaderboard
  { player: principal }
  {
    score: uint,
    games-played: uint,
    total-rewards: uint,
    avatar-id: uint,
    rank: uint,
    achievements: (list 20 (string-ascii 50)),
  }
)

;; READ-ONLY UTILITY FUNCTIONS

(define-read-only (is-protocol-admin (sender principal))
  (default-to false (map-get? protocol-admin-whitelist sender))
)

(define-read-only (is-valid-principal (input principal))
  (and
    (not (is-eq input tx-sender))
    (not (is-eq input (as-contract tx-sender)))
  )
)

(define-read-only (is-safe-principal (input principal))
  (and
    (is-valid-principal input)
    (or
      (is-protocol-admin input)
      (is-some (map-get? leaderboard { player: input }))
    )
  )
)