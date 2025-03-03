;; GameGuard - Main Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-input (err u103))
(define-constant err-reentrancy (err u104))
(define-constant err-arithmetic (err u105))
(define-constant max-communities u1000)

;; Data Variables
(define-data-var next-community-id uint u0)
(define-data-var treasury-locked bool false)

;; Data Maps
(define-map communities
  { community-id: uint }
  {
    name: (string-ascii 50),
    owner: principal,
    treasury: uint,
    member-count: uint,
    created-at: uint,
    settings: {
      private: bool,
      max-members: uint
    }
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

;; Events
(define-data-var last-event-id uint u0)
(define-map events 
  { event-id: uint }
  {
    event-type: (string-ascii 20),
    community-id: uint,
    actor: principal,
    timestamp: uint
  }
)

;; Private Functions
(define-private (emit-event (event-type (string-ascii 20)) (community-id uint))
  (let ((new-id (+ u1 (var-get last-event-id))))
    (map-set events
      { event-id: new-id }
      {
        event-type: event-type,
        community-id: community-id,
        actor: tx-sender,
        timestamp: block-height
      }
    )
    (var-set last-event-id new-id)
    (ok true))
)

(define-private (is-valid-name (name (string-ascii 50)))
  (if (> (len name) u0)
      (ok true)
      (err err-invalid-input))
)

(define-private (is-community-owner (community-id uint) (caller principal))
  (let ((community (unwrap! (get-community community-id) err-not-found)))
    (ok (is-eq (get owner community) caller)))
)

;; Getter Functions
(define-read-only (get-community (community-id uint))
  (map-get? communities { community-id: community-id })
)

(define-read-only (get-member (community-id uint) (member principal))
  (map-get? members { community-id: community-id, member: member })
)

;; Community Management
(define-public (create-community (name (string-ascii 50)))
  (let
    ((new-id (+ u1 (var-get next-community-id))))
    (try! (is-valid-name name))
    (asserts! (<= new-id max-communities) (err err-invalid-input))
    (map-insert communities
      { community-id: new-id }
      {
        name: name,
        owner: tx-sender,
        treasury: u0,
        member-count: u0,
        created-at: block-height,
        settings: {
          private: false,
          max-members: u1000
        }
      }
    )
    (var-set next-community-id new-id)
    (try! (emit-event "community-created" new-id))
    (ok new-id))
)

;; ... [Previous community management functions remain unchanged]

;; Enhanced Treasury Management with Reentrancy Protection
(define-public (deposit (community-id uint) (amount uint))
  (let
    ((community (unwrap! (get-community community-id) err-not-found)))
    (asserts! (not (var-get treasury-locked)) err-reentrancy)
    (var-set treasury-locked true)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set communities
      { community-id: community-id }
      (merge community { treasury: (+ amount (get treasury community)) })
    )
    (var-set treasury-locked false)
    (try! (emit-event "deposit" community-id))
    (ok true))
)

(define-public (withdraw (community-id uint) (amount uint))
  (let ((community (unwrap! (get-community community-id) err-not-found)))
    (asserts! (is-eq (get owner community) tx-sender) err-unauthorized)
    (asserts! (<= amount (get treasury community)) err-invalid-input)
    (asserts! (not (var-get treasury-locked)) err-reentrancy)
    (var-set treasury-locked true)
    (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
    (map-set communities
      { community-id: community-id }
      (merge community { treasury: (- (get treasury community) amount) })
    )
    (var-set treasury-locked false)
    (try! (emit-event "withdraw" community-id))
    (ok true))
)

;; Role Management
(define-public (update-member-role (community-id uint) (member principal) (new-role (string-ascii 20)))
  (let ((community (unwrap! (get-community community-id) err-not-found))
        (member-data (unwrap! (get-member community-id member) err-not-found)))
    (asserts! (is-eq (get owner community) tx-sender) err-unauthorized)
    (map-set members
      { community-id: community-id, member: member }
      (merge member-data { role: new-role })
    )
    (try! (emit-event "role-updated" community-id))
    (ok true))
)
