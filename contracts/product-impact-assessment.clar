;; Product Impact Assessment Contract
;; Evaluates and tracks product sustainability metrics

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u200))
(define-constant err-product-exists (err u201))
(define-constant err-product-not-found (err u202))
(define-constant err-invalid-rating (err u203))

;; Product impact data
(define-map products (string-ascii 100) {
  carbon-footprint: uint,
  sustainability-rating: uint,
  ethical-score: uint,
  recyclability: uint,
  local-sourcing: bool,
  certification-level: uint,
  assessment-date: uint
})

;; Product categories and their impact weights
(define-map category-weights (string-ascii 50) {
  carbon-weight: uint,
  ethical-weight: uint,
  recyclability-weight: uint
})

;; Register a new product assessment
(define-public (register-product
  (product-id (string-ascii 100))
  (carbon-footprint uint)
  (sustainability-rating uint)
  (ethical-score uint)
  (recyclability uint)
  (local-sourcing bool)
  (certification-level uint))

  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-none (map-get? products product-id)) err-product-exists)
    (asserts! (<= sustainability-rating u100) err-invalid-rating)
    (asserts! (<= ethical-score u100) err-invalid-rating)
    (asserts! (<= recyclability u100) err-invalid-rating)

    (map-set products product-id {
      carbon-footprint: carbon-footprint,
      sustainability-rating: sustainability-rating,
      ethical-score: ethical-score,
      recyclability: recyclability,
      local-sourcing: local-sourcing,
      certification-level: certification-level,
      assessment-date: block-height
    })

    (ok true)
  )
)

;; Update product assessment
(define-public (update-product-assessment
  (product-id (string-ascii 100))
  (sustainability-rating uint)
  (ethical-score uint))

  (let ((product-data (unwrap! (map-get? products product-id) err-product-not-found)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= sustainability-rating u100) err-invalid-rating)
    (asserts! (<= ethical-score u100) err-invalid-rating)

    (map-set products product-id
      (merge product-data {
        sustainability-rating: sustainability-rating,
        ethical-score: ethical-score,
        assessment-date: block-height
      })
    )
    (ok true)
  )
)

;; Calculate overall impact score
(define-read-only (calculate-impact-score (product-id (string-ascii 100)))
  (let ((product-data (unwrap! (map-get? products product-id) err-product-not-found)))
    (let (
      (sustainability (* (get sustainability-rating product-data) u3))
      (ethical (* (get ethical-score product-data) u2))
      (recyclability-score (* (get recyclability product-data) u2))
      (local-bonus (if (get local-sourcing product-data) u10 u0))
      (cert-bonus (* (get certification-level product-data) u5))
    )
      (ok (/ (+ sustainability ethical recyclability-score local-bonus cert-bonus) u7))
    )
  )
)

;; Get product data
(define-read-only (get-product-data (product-id (string-ascii 100)))
  (map-get? products product-id)
)

;; Check if product meets sustainability threshold
(define-read-only (meets-sustainability-threshold (product-id (string-ascii 100)) (threshold uint))
  (match (calculate-impact-score product-id)
    score (ok (>= score threshold))
    error (err error)
  )
)
