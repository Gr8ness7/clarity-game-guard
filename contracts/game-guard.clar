;; GameGuard - Main Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-input (err u103))
(define-constant max-communities u1000)

;; Data Variables
(define-data-var next-community-id uint u0)

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

;; Private Functions
(define-private (is-valid-name (name (string-ascii 50)))
  (if (> (len name) u0)
      (ok true)
      (err err-invalid-input))
)

(define-private (is-community-owner (community-id uint) (caller principal))
  (let ((community (unwrap! (get-community community-id) err-not-found)))
    (ok (is-eq (get owner community) caller)))
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
    (ok new-id))
)

(define-public (update-community (community-id uint) (name (string-ascii 50)))
  (let ((community (unwrap! (get-community community-id) err-not-found)))
    (asserts! (is-eq (get owner community) tx-sender) err-unauthorized)
    (try! (is-valid-name name))
    (map-set communities
      { community-id: community-id }
      (merge community { name: name })
    )
    (ok true))
)

(define-public (dissolve-community (community-id uint))
  (let ((community (unwrap! (get-community community-id) err-not-found)))
    (asserts! (is-eq (get owner community) tx-sender) err-unauthorized)
    (map-delete communities { community-id: community-id })
    (ok true))
)

;; Member Management
(define-public (join-community (community-id uint))
  (let
    ((community (unwrap! (get-community community-id) err-not-found)))
    (asserts! (< (get member-count community) (get max-members (get settings community))) err-unauthorized)
    (map-insert members
      { community-id: community-id, member: tx-sender }
      {
        reputation: u0,
        joined-at: block-height,
        role: "member"
      }
    )
    (map-set communities
      { community-id: community-id }
      (merge community { member-count: (+ u1 (get member-count community)) })
    )
    (ok true))
)

(define-public (leave-community (community-id uint))
  (let ((community (unwrap! (get-community community-id) err-not-found)))
    (map-delete members { community-id: community-id, member: tx-sender })
    (map-set communities
      { community-id: community-id }
      (merge community { member-count: (- (get member-count community) u1) })
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

(define-public (withdraw (community-id uint) (amount uint))
  (let ((community (unwrap! (get-community community-id) err-not-found)))
    (asserts! (is-eq (get owner community) tx-sender) err-unauthorized)
    (asserts! (<= amount (get treasury community)) err-invalid-input)
    (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
    (map-set communities
      { community-id: community-id }
      (merge community { treasury: (- (get treasury community) amount) })
    )
    (ok true))
)
