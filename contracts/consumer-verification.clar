;; Consumer Verification Contract
;; Validates and manages conscious shoppers

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-already-verified (err u101))
(define-constant err-not-verified (err u102))
(define-constant err-invalid-score (err u103))

;; Consumer verification data
(define-map verified-consumers principal {
  verification-date: uint,
  sustainability-score: uint,
  purchases-count: uint,
  impact-points: uint,
  status: (string-ascii 20)
})

;; Verification requirements
(define-map verification-criteria (string-ascii 50) uint)

;; Initialize verification criteria
(map-set verification-criteria "min-sustainability-score" u70)
(map-set verification-criteria "min-impact-points" u100)

;; Verify a consumer
(define-public (verify-consumer (consumer principal) (sustainability-score uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-none (map-get? verified-consumers consumer)) err-already-verified)
    (asserts! (>= sustainability-score u70) err-invalid-score)

    (map-set verified-consumers consumer {
      verification-date: block-height,
      sustainability-score: sustainability-score,
      purchases-count: u0,
      impact-points: u0,
      status: "verified"
    })

    (ok true)
  )
)

;; Update consumer impact points
(define-public (update-impact-points (consumer principal) (points uint))
  (let ((consumer-data (unwrap! (map-get? verified-consumers consumer) err-not-verified)))
    (map-set verified-consumers consumer
      (merge consumer-data { impact-points: (+ (get impact-points consumer-data) points) })
    )
    (ok true)
  )
)

;; Check if consumer is verified
(define-read-only (is-verified-consumer (consumer principal))
  (is-some (map-get? verified-consumers consumer))
)

;; Get consumer data
(define-read-only (get-consumer-data (consumer principal))
  (map-get? verified-consumers consumer)
)

;; Get verification criteria
(define-read-only (get-verification-criteria (criteria (string-ascii 50)))
  (map-get? verification-criteria criteria)
)
