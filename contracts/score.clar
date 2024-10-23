;; Title: ScoreDAO - DAO Contribution Tracking System
;; File: dao-tracker.clar

;; Constants and Error Codes
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-score (err u103))

;; Define reputation token
(define-fungible-token dao-rep)

;; Data Structures
(define-map contributors
    { address: principal }
    {
        reputation-score: uint,
        total-contributions: uint,
        last-contribution: uint,
        level: uint
    }
)

(define-map contribution-types
    { type-id: uint }
    {
        name: (string-ascii 50),
        weight: uint,
        min-proof-required: uint
    }
)

(define-map contributions
    { contribution-id: uint }
    {
        contributor: principal,
        type-id: uint,
        timestamp: uint,
        proof: (string-ascii 256),
        verified: bool,
        score: uint
    }
)

;; Counters
(define-data-var contribution-counter uint u0)
(define-data-var type-counter uint u0)

;; Administrative Functions

(define-public (add-contribution-type 
    (name (string-ascii 50))
    (weight uint)
    (min-proof-required uint))
    (let ((type-id (var-get type-counter)))
        (if (is-eq tx-sender contract-owner)
            (begin
                (map-set contribution-types
                    { type-id: type-id }
                    {
                        name: name,
                        weight: weight,
                        min-proof-required: min-proof-required
                    })
                (var-set type-counter (+ type-id u1))
                (ok type-id))
            err-owner-only)))

;; Contribution Recording Functions

(define-public (submit-contribution 
    (type-id uint)
    (proof (string-ascii 256)))
    (let ((contribution-id (var-get contribution-counter)))
        (match (map-get? contribution-types { type-id: type-id })
            contribution-type
            (begin
                (map-set contributions
                    { contribution-id: contribution-id }
                    {
                        contributor: tx-sender,
                        type-id: type-id,
                        timestamp: block-height,
                        proof: proof,
                        verified: false,
                        score: u0
                    })
                (var-set contribution-counter (+ contribution-id u1))
                (ok contribution-id))
            err-not-found)))

;; Verification and Scoring

(define-public (verify-contribution 
    (contribution-id uint)
    (verified-score uint))
    (if (is-eq tx-sender contract-owner)
        (match (map-get? contributions { contribution-id: contribution-id })
            contribution
            (begin
                (try! (update-contributor-score (get contributor contribution) verified-score))
                (map-set contributions
                    { contribution-id: contribution-id }
                    (merge contribution 
                        { 
                            verified: true,
                            score: verified-score
                        }))
                (ok true))
            err-not-found)
        err-owner-only))

(define-private (update-contributor-score (contributor principal) (score uint))
    (match (map-get? contributors { address: contributor })
        existing-data
        (begin
            (map-set contributors
                { address: contributor }
                {
                    reputation-score: (+ (get reputation-score existing-data) score),
                    total-contributions: (+ (get total-contributions existing-data) u1),
                    last-contribution: block-height,
                    level: (calculate-level (+ (get reputation-score existing-data) score))
                })
            (try! (ft-mint? dao-rep score contributor))
            (ok true))
        (begin
            (map-set contributors
                { address: contributor }
                {
                    reputation-score: score,
                    total-contributions: u1,
                    last-contribution: block-height,
                    level: (calculate-level score)
                })
            (try! (ft-mint? dao-rep score contributor))
            (ok true))))

;; Helper Functions

(define-private (calculate-level (score uint))
    (if (< score u100)
        u1
        (if (< score u500)
            u2
            (if (< score u1000)
                u3
                u4))))

;; Read-only Functions

(define-read-only (get-contributor-info (address principal))
    (map-get? contributors { address: address }))

(define-read-only (get-contribution (contribution-id uint))
    (map-get? contributions { contribution-id: contribution-id }))

(define-read-only (get-contribution-type (type-id uint))
    (map-get? contribution-types { type-id: type-id }))

(define-read-only (get-reputation-balance (address principal))
    (ft-get-balance dao-rep address))

;; Initialize contract
(begin
    (try! (ft-mint? dao-rep u0 contract-owner)))
