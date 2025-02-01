;; GameGuard Traits

(define-trait community-manager
  (
    (create-community ((string-ascii 50)) (response uint uint))
    (update-community (uint (string-ascii 50)) (response bool uint))
    (dissolve-community (uint) (response bool uint))
  )
)

(define-trait member-manager
  (
    (join-community (uint) (response bool uint))
    (leave-community (uint) (response bool uint))
    (update-role (uint principal (string-ascii 20)) (response bool uint))
  )
)
