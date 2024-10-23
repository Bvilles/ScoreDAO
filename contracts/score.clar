;; DAO Contract
;; Constants for configuration
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ALREADY-MEMBER (err u101))
(define-constant ERR-NOT-MEMBER (err u102))
(define-constant ERR-PROPOSAL-NOT-FOUND (err u103))
(define-constant ERR-ALREADY-VOTED (err u104))
(define-constant ERR-PROPOSAL-EXPIRED (err u105))
(define-constant ERR-ALREADY-EXECUTED (err u106))
(define-constant ERR-NOT-ENOUGH-VOTES (err u107))
(define-constant ERR-PROPOSAL-REJECTED (err u108))
(define-constant ERR-INVALID-TITLE (err u109))
(define-constant ERR-INVALID-DESCRIPTION (err u110))
(define-constant VOTING_PERIOD u144) ;; ~24 hours in blocks
(define-constant MINIMUM_VOTES u3)
(define-constant MIN_TITLE_LENGTH u4)
(define-constant MAX_TITLE_LENGTH u50)
(define-constant MIN_DESCRIPTION_LENGTH u10)
(define-constant MAX_DESCRIPTION_LENGTH u500)

;; Data maps for storing DAO state
(define-map members principal bool)
(define-map proposals
    uint
    {
        proposer: principal,
        title: (string-ascii 50),
        description: (string-utf8 500),
        yes-votes: uint,
        no-votes: uint,
        start-block: uint,
        executed: bool
    }
)
(define-map votes {proposal-id: uint, voter: principal} bool)

;; Data variables
(define-data-var proposal-count uint u0)
(define-data-var admin principal tx-sender)

;; Read-only functions
(define-read-only (is-member (user principal))
    (default-to false (map-get? members user))
)

(define-read-only (get-proposal (proposal-id uint))
    (map-get? proposals proposal-id)
)

(define-read-only (has-voted (proposal-id uint) (user principal))
    (default-to false (map-get? votes {proposal-id: proposal-id, voter: user}))
)

;; Validation functions
(define-private (is-valid-title (title (string-ascii 50)))
    (let
        (
            (length (len title))
        )
        (and
            (>= length MIN_TITLE_LENGTH)
            (<= length MAX_TITLE_LENGTH)
            (not (is-eq title ""))
        )
    )
)

(define-private (is-valid-description (description (string-utf8 500)))
    (let
        (
            (length (len description))
        )
        (and
            (>= length MIN_DESCRIPTION_LENGTH)
            (<= length MAX_DESCRIPTION_LENGTH)
            (not (is-eq description u""))
        )
    )
)

;; Public functions
(define-public (add-member (new-member principal))
    (begin
        (asserts! (is-eq tx-sender (var-get admin)) ERR-NOT-AUTHORIZED)
        (asserts! (not (is-member new-member)) ERR-ALREADY-MEMBER)
        (ok (map-set members new-member true))
    )
)

(define-public (remove-member (member principal))
    (begin
        (asserts! (is-eq tx-sender (var-get admin)) ERR-NOT-AUTHORIZED)
        (asserts! (is-member member) ERR-NOT-MEMBER)
        (ok (map-delete members member))
    )
)

(define-public (create-proposal (title (string-ascii 50)) (description (string-utf8 500)))
    (let
        ((proposal-id (var-get proposal-count)))
        (begin
            (asserts! (is-member tx-sender) ERR-NOT-AUTHORIZED)
            ;; Validate input data
            (asserts! (is-valid-title title) ERR-INVALID-TITLE)
            (asserts! (is-valid-description description) ERR-INVALID-DESCRIPTION)
            
            (map-set proposals proposal-id
                {
                    proposer: tx-sender,
                    title: title,
                    description: description,
                    yes-votes: u0,
                    no-votes: u0,
                    start-block: block-height,
                    executed: false
                }
            )
            (var-set proposal-count (+ proposal-id u1))
            (ok proposal-id)
        )
    )
)

(define-public (vote (proposal-id uint) (vote-for bool))
    (let
        ((proposal (unwrap! (get-proposal proposal-id) ERR-PROPOSAL-NOT-FOUND)))
        (begin
            (asserts! (is-member tx-sender) ERR-NOT-AUTHORIZED)
            (asserts! (not (has-voted proposal-id tx-sender)) ERR-ALREADY-VOTED)
            (asserts! (< (- block-height (get start-block proposal)) VOTING_PERIOD) ERR-PROPOSAL-EXPIRED)
            
            (map-set votes {proposal-id: proposal-id, voter: tx-sender} true)
            
            (if vote-for
                (map-set proposals proposal-id 
                    (merge proposal {yes-votes: (+ (get yes-votes proposal) u1)}))
                (map-set proposals proposal-id 
                    (merge proposal {no-votes: (+ (get no-votes proposal) u1)}))
            )
            (ok true)
        )
    )
)

(define-public (execute-proposal (proposal-id uint))
    (let
        ((proposal (unwrap! (get-proposal proposal-id) ERR-PROPOSAL-NOT-FOUND)))
        (begin
            (asserts! (is-member tx-sender) ERR-NOT-AUTHORIZED)
            (asserts! (>= (- block-height (get start-block proposal)) VOTING_PERIOD) ERR-PROPOSAL-EXPIRED)
            (asserts! (not (get executed proposal)) ERR-ALREADY-EXECUTED)
            (asserts! (>= (+ (get yes-votes proposal) (get no-votes proposal)) MINIMUM_VOTES) ERR-NOT-ENOUGH-VOTES)
            
            (if (> (get yes-votes proposal) (get no-votes proposal))
                (begin
                    (map-set proposals proposal-id (merge proposal {executed: true}))
                    (ok true)
                )
                ERR-PROPOSAL-REJECTED
            )
        )
    )
)