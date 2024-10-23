;; ScoreDAO Contract
;; A DAO for decentralized scoring and governance

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
(define-constant ERR-QUORUM-NOT-REACHED (err u111))
(define-constant ERR-SUPERMAJORITY-NOT-REACHED (err u112))
(define-constant ERR-CANNOT-DELEGATE-TO-SELF (err u113))
(define-constant ERR-INVALID-DELEGATE (err u114))

;; Governance parameters
(define-constant VOTING_PERIOD u144) ;; ~24 hours in blocks
(define-constant MIN_TITLE_LENGTH u4)
(define-constant MAX_TITLE_LENGTH u50)
(define-constant MIN_DESCRIPTION_LENGTH u10)
(define-constant MAX_DESCRIPTION_LENGTH u500)
(define-constant QUORUM_PERCENTAGE u30) ;; 30% of total members must vote
(define-constant SUPERMAJORITY_PERCENTAGE u67) ;; 67% yes votes needed for critical proposals

;; Proposal types
(define-constant PROPOSAL-TYPE-STANDARD u1)
(define-constant PROPOSAL-TYPE-CRITICAL u2) ;; Requires supermajority

;; Data maps for storing DAO state
(define-map members principal bool)
(define-data-var member-count uint u0)

;; New delegation map
(define-map delegations principal principal)

(define-map proposals
    uint
    {
        proposer: principal,
        title: (string-ascii 50),
        description: (string-utf8 500),
        proposal-type: uint,
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

(define-read-only (get-total-members)
    (var-get member-count)
)

;; New delegation read functions
(define-read-only (get-delegate (member principal))
    (map-get? delegations member)
)

;; Private helper functions
(define-private (is-valid-title (title (string-ascii 50)))
    (let
        ((length (len title)))
        (and
            (>= length MIN_TITLE_LENGTH)
            (<= length MAX_TITLE_LENGTH)
            (not (is-eq title ""))
        )
    )
)

(define-private (is-valid-description (description (string-utf8 500)))
    (let
        ((length (len description)))
        (and
            (>= length MIN_DESCRIPTION_LENGTH)
            (<= length MAX_DESCRIPTION_LENGTH)
            (not (is-eq description u""))
        )
    )
)

(define-private (calculate-vote-percentage (yes-votes uint) (total-votes uint))
    (if (is-eq total-votes u0)
        u0
        (/ (* yes-votes u100) total-votes)
    )
)

(define-private (has-reached-quorum (total-votes uint))
    (let
        ((required-votes (/ (* (var-get member-count) QUORUM_PERCENTAGE) u100)))
        (>= total-votes required-votes)
    )
)

(define-private (has-reached-supermajority (yes-votes uint) (total-votes uint))
    (>= (calculate-vote-percentage yes-votes total-votes) SUPERMAJORITY_PERCENTAGE)
)

;; Public functions
(define-public (add-member (new-member principal))
    (begin
        (asserts! (is-eq tx-sender (var-get admin)) ERR-NOT-AUTHORIZED)
        (asserts! (not (is-member new-member)) ERR-ALREADY-MEMBER)
        (var-set member-count (+ (var-get member-count) u1))
        (ok (map-set members new-member true))
    )
)

(define-public (remove-member (member principal))
    (begin
        (asserts! (is-eq tx-sender (var-get admin)) ERR-NOT-AUTHORIZED)
        (asserts! (is-member member) ERR-NOT-MEMBER)
        (var-set member-count (- (var-get member-count) u1))
        (map-delete delegations member)
        (ok (map-delete members member))
    )
)

;; New delegation function
(define-public (delegate-vote (delegate-to principal))
    (begin
        (asserts! (is-member tx-sender) ERR-NOT-AUTHORIZED)
        (asserts! (is-member delegate-to) ERR-NOT-MEMBER)
        (asserts! (not (is-eq tx-sender delegate-to)) ERR-CANNOT-DELEGATE-TO-SELF)
        (ok (map-set delegations tx-sender delegate-to))
    )
)

;; New function to remove delegation
(define-public (remove-delegation)
    (begin
        (asserts! (is-member tx-sender) ERR-NOT-AUTHORIZED)
        (ok (map-delete delegations tx-sender))
    )
)

(define-public (create-proposal 
    (title (string-ascii 50)) 
    (description (string-utf8 500))
    (proposal-type uint)
)
    (let
        ((proposal-id (var-get proposal-count)))
        (begin
            (asserts! (is-member tx-sender) ERR-NOT-AUTHORIZED)
            (asserts! (is-valid-title title) ERR-INVALID-TITLE)
            (asserts! (is-valid-description description) ERR-INVALID-DESCRIPTION)
            (asserts! (or (is-eq proposal-type PROPOSAL-TYPE-STANDARD)
                         (is-eq proposal-type PROPOSAL-TYPE-CRITICAL)) ERR-NOT-AUTHORIZED)
            
            (map-set proposals proposal-id
                {
                    proposer: tx-sender,
                    title: title,
                    description: description,
                    proposal-type: proposal-type,
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
        ((proposal (unwrap! (get-proposal proposal-id) ERR-PROPOSAL-NOT-FOUND))
         (delegate-check (get-delegate tx-sender)))
        (begin
            (asserts! (is-member tx-sender) ERR-NOT-AUTHORIZED)
            ;; Check if the voter hasn't delegated their vote
            (asserts! (is-none delegate-check) ERR-NOT-AUTHORIZED)
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

;; New function for delegated voting
(define-public (vote-for-delegator (delegator principal) (proposal-id uint) (vote-for bool))
    (let
        ((proposal (unwrap! (get-proposal proposal-id) ERR-PROPOSAL-NOT-FOUND))
         (delegate-check (get-delegate delegator)))
        (begin
            (asserts! (is-member tx-sender) ERR-NOT-AUTHORIZED)
            (asserts! (is-member delegator) ERR-NOT-MEMBER)
            ;; Check if the delegator has delegated to the sender
            (asserts! (and (is-some delegate-check) 
                          (is-eq (some tx-sender) delegate-check)) 
                     ERR-NOT-AUTHORIZED)
            (asserts! (not (has-voted proposal-id delegator)) ERR-ALREADY-VOTED)
            (asserts! (< (- block-height (get start-block proposal)) VOTING_PERIOD) ERR-PROPOSAL-EXPIRED)
            
            (map-set votes {proposal-id: proposal-id, voter: delegator} true)
            
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
        (
            (proposal (unwrap! (get-proposal proposal-id) ERR-PROPOSAL-NOT-FOUND))
            (total-votes (+ (get yes-votes proposal) (get no-votes proposal)))
        )
        (begin
            (asserts! (is-member tx-sender) ERR-NOT-AUTHORIZED)
            (asserts! (>= (- block-height (get start-block proposal)) VOTING_PERIOD) ERR-PROPOSAL-EXPIRED)
            (asserts! (not (get executed proposal)) ERR-ALREADY-EXECUTED)
            (asserts! (has-reached-quorum total-votes) ERR-QUORUM-NOT-REACHED)
            
            ;; Check if supermajority is required
            (if (is-eq (get proposal-type proposal) PROPOSAL-TYPE-CRITICAL)
                (asserts! (has-reached-supermajority (get yes-votes proposal) total-votes)
                         ERR-SUPERMAJORITY-NOT-REACHED)
                true
            )
            
            ;; For standard proposals, simple majority is enough
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