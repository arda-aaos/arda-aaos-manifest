# ARDA AAOS V49.7 — 2026-11-16-v49.7

This is a **new dated checkpoint**; the original 2026-09-17 bootstrap, pins, and
verification scripts are unchanged. Source files are recorded as:

* ArdaPlatform at GitHub: `3b29dabd92b09d444346f94703c1a61a2711b96d`.
* `external/libudev-zero` upstream `6f093b428ecae5138654b61d7f29871cef8739dc` plus the exact Android.bp patch.
* `packages/apps/Car/Cluster` upstream `7244742c0268e1a1f6e88f5b2e1df0c0ec2c825a` plus the V42 Cluster patch.
* `vendor/arda/ardaplatform` at GitHub: `f1339bf1294c63a6378e6d344b5177e65c0a3176`. Its SHA is recorded in
  `locks/independent-vendor-ardaplatform.sha` even if it is an independent
  clone rather than a Repo-managed project.
* All 1006 current project HEADs are inventoried in `locks/source-heads.tsv`,
  but **not all upstream/non-ARDA SHAs have been verified remotely**.

## Fresh-source integration

1. Start from the compatible ARDA AAOS checkout and install
   `manifests/30-v49.7-upstream-pins.xml` as a Repo local manifest **before its
   first source sync**. This overlay pins only the unmodified upstream bases.
2. After fetching source, run:
   `bash releases/2026-11-16-v49.7/scripts/apply-v49.7.sh /path/to/aosp-root`
3. The script refuses dirty or unexpected base trees, applies the patches,
   verifies exact resulting Git **tree** SHAs, then commits locally.
4. Set the vendor ARDA Platform checkout to the pinned GitHub SHA using the
   existing ARDA repo management workflow. Also verify the remaining pinned
   projects; this checkpoint alone is not a substitute for a full bootstrap.

Important: an XML manifest does **not** apply source patches itself. Do not use
this with the historical destructive `reapply.sh` without verifying compatibility.

## Non-goals and safety

* This persistence run does not perform `repo sync`, build, install, or reboot.
* This run does not modify device display settings or GPIO/HDMI policy.
* HDMI2 `wm lock 3` is recorded as a runtime choice, not yet proved after reboot.
* Private signing files remain local under `updater/signing/` and are excluded.
* The existing empty `Deadknight/android_external_libudev-zero` repository is not
  used; upstream Raspberry Vanilla is the reference for this patch-based release.
