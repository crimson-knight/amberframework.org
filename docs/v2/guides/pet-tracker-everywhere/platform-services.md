---
title: "Platform services"
section: "guides/pet-tracker-everywhere"
order: 30
description: "Keep Pet Tracker rules shared while each process chooses how to store and synchronize data"
---

# Platform services

> **Preview — planned work, not a released workflow.** Amber `2.0.0-beta.5` and `amber_cli` `2.0.6` support the web path in [Build a Pet Tracker](../pet-tracker/), but not the commands described here. This preview template pins pre-release Amber `2.0.0-beta.2+ab90eae910a4` at commit `ab90eae910a4bd3a74f3f52ba8dfe238817994c3` and `asset_pipeline` at commit `2aa345bb8f6254554775634d07053cbed09ffe91`; it is outside the [supported beta path](../../beta-support.md). Nothing on this page is a runnable public workflow.

Our screen should know how to show pets. It should not know where those pets
live.

The generated example puts its state shape and application rules in
`src/app/pets/pet_store.cr`. Web, iOS, and Android compile the same file.

## Where the examples go

The shared store code belongs in `src/app/pets/pet_store.cr`. Native storage
adapters belong in `src/platform/android/app.cr` and the generated iOS bridge.

## Start with one small shared store

```crystal
module PetTracker
  class Store
    @mutex = Mutex.new
    @pets : Array(PetSummary)

    def initialize(@pets = self.class.seed)
    end

    def snapshot(notice : String = "") : PetTrackerState
      @mutex.synchronize { PetTrackerState.new(@pets.dup, notice) }
    end

    def save(name : String, species : String) : PetSummary
      clean_name = name.strip
      clean_species = species.strip
      raise ArgumentError.new("Name is required") if clean_name.empty?
      raise ArgumentError.new("Species is required") if clean_species.empty?

      @mutex.synchronize do
        next_id = (@pets.max_of?(&.id) || 0_i64) + 1_i64
        pet = PetSummary.new(next_id, clean_name, clean_species)
        @pets << pet
        pet
      end
    end
  end
end
```

This is enough for a tutorial acceptance app. It gives every target the same
validation, identifiers, seed data, adoption behavior, and JSON snapshot
format.

The generated spec creates a fresh store, saves a pet, toggles adoption, then
round-trips the snapshot. That test runs without a browser, emulator, or native
host, which is exactly where shared application rules should be easiest to
check.

## Let each process choose durability

The tutorial uses three deliberately different adapters:

| Process | Current beta behavior | What it proves |
|---|---|---|
| Amber web server | one in-memory store for the running server | HTTP input and shared-view rendering |
| iOS app | JSON snapshot in `UserDefaults` through the generated bridge | native input, restoration, and a fresh-process rebuild |
| Android app | JSON snapshot in app-private native storage | asynchronous storage, restoration, and a fresh-process rebuild |

Shared state means a shared contract. It does not mean the browser server and
an installed phone share process memory.

Android starts with a loading screen, reads
`pet-tracker.snapshot.v1`, restores the store, and invalidates the native
application:

```crystal
@@storage.read("pet-tracker.snapshot.v1") do |result|
  case result
  when String
    @@notice = PetTracker.store.restore(result) ? "Restored from this device." : "The saved pet list was invalid; the starter pets are still here."
  when Amber::Native::ServiceError
    @@notice = "Local storage is unavailable: #{result.code}."
  else
    @@notice = "Your pets are ready."
  end

  @@ready = true
  UI::Android::Application.invalidate
end
```

The callback matters because native storage is asynchronous. It returns to the
application, updates state, and asks the UI to rebuild after the read finishes.

## Grow the adapter without moving the view

For a real synchronized Pet Tracker, keep `PetSummary` and the screen inputs
stable while you replace the tutorial store boundary:

- Amber web can use Grant with SQLite, PostgreSQL, or MySQL;
- installed apps can use a local database for offline work;
- an authenticated Amber API can synchronize records across devices;
- retries, cancellation, conflicts, migrations, and deletion become explicit
  application behavior.

Remote calls must stay off the native UI thread, and server credentials must
stay out of mobile binaries. Test local durability and server synchronization
as separate promises.

The beta generator does not claim that cross-device synchronization is already
present. It gives you a working shared screen and a visible seam where your
production repository belongs.
