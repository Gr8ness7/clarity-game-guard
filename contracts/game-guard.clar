;; GameGuard - Main Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))

;; Data Maps
(define-map communities
  { community-id: uint }
  {
    name: (string-ascii 50),
    owner: principal,
    treasury: uint,
    member-count: uint,
    created-at: uint
  }
)

(define-map members
  { community-id: uint, member: principal }
  {
    reputation: uint,
    joined-at: uint,
    role: (string-ascii 20)
  }
)

;; Community Management
(define-public (create-community (name (string-ascii 50)))
  (let
    ((new-id (+ u1 (var-get next-community-id))))
    (try! (is-valid-name name))
    (map-insert communities
      { community-id: new-id }
      {
        name: name,
        owner: tx-sender,
        treasury: u0,
        member-count: u0,
        created-at: block-height
      }
    )
    (var-set next-community-id new-id)
    (ok new-id))
)

;; Member Management
(define-public (join-community (community-id uint))
  (let
    ((community (unwrap! (get-community community-id) err-not-found)))
    (try! (can-join community-id tx-sender))
    (map-insert members
      { community-id: community-id, member: tx-sender }
      {
        reputation: u0,
        joined-at: block-height,
        role: "member"
      }
    )
    (ok true))
)

;; Treasury Management
(define-public (deposit (community-id uint) (amount uint))
  (let
    ((community (unwrap! (get-community community-id) err-not-found)))
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set communities
      { community-id: community-id }
      (merge community { treasury: (+ amount (get treasury community)) })
    )
    (ok true))
)
