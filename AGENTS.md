# Project Overview

This project is all about making the best note-taking app for myself. My note-taking is not just writing down information, my note taking is not for that, but it is for helping me think. Because note-taking is a part of the process of my Learning. Currently the project is basically almost done with what I want, but I am pretty sure there will be a lot of features that you can think of or I will be able to think of in the future so we must continuously find more ideas to make this app better.

# A Letter from me to you

We are building this together, but to be frank, you are building this for me. I want you to be able to build what ever we come up with together. I want this app to be one of the best tool for my learning process.

# A Glossary of Relevant Parties

*   **you** - the agent reading this document and writing code.
*   **my/me/I** - the human developer, the sole user of this app, and the person you are talking to.
*   **us/we** - both you and me working together.

# Philosophical Guidelines and "Vibes"

## Boil the Ocean
Even though the app is basically almost done, do not be afraid to suggest a major refactor if a current implementation is fundamentally flawed or inherently buggy. If a feature or a block of code is causing constant friction, don't just patch it—tell me we need to tear it out and rebuild it from first principles. A buggy note app interrupts my learning; I'd rather rebuild a feature correctly than apply endless band-aids.

## Optimize for "Flow", Not Features
This app is a tool for thinking. Every micro-interaction that distracts me from my thoughts is a failure. When we are fixing bugs or tweaking the UI, always prioritize getting the app out of my way. We don't want a million complex menus; we want a seamless bridge between my brain and the screen. If a fix makes the app more complicated to use, it is the wrong fix.

## Root Causes Over Band-Aids
Since our primary focus going forward will be debugging, your job is to act as a detective. If the app crashes or the state desyncs, do not just give me a quick workaround to suppress the error. Dig deep, find the exact line and logic flaw causing the issue, and solve the root problem. 

# Some General Rules

These are meant to steer us in the right direction when we are writing code or fixing bugs:

*   **Data integrity is absolute:** Above all else, never write code or suggest fixes that could result in the loss, corruption, or accidental deletion of my notes. My learning process lives in this data.
*   **Explain the "Why":** When we squash a bug, briefly explain to me *why* it broke in the first place before you provide the code fix. I am a learner, and understanding the bugs helps me improve as a developer.
*   **Fight for the "obvious" solution:** Avoid being clever. Write code that is simple, readable, and predictable. 
*   **Keep the UI invisible:** Default to minimal styling. If you are fixing a UI bug, do not introduce new unnecessary borders, shadows, or colors. Keep it plain and focused on the text.
*   **When in doubt, ask:** If a bug fix requires changing how a core feature works, stop and ask me how I want it to behave before you write the code.
*   If done with a feature always build the app into arm-v8a and then ask the user if they want you to use computer use in order to use helium in order to upload the apk file into the authenticated google drive in the helium browser.
*   I give you permission to merge all of the PRs you are doing automatically after you are finished.
*   Always use "zenno" as the name of the apks.

## Lessons Learned

- [FAIL][canvas-layer-stamping]: Returning a newly placed element before assigning its layer causes equality/state splits with later hit-testing; stamp the active layer before running the add command.
- [FAIL][drift-web-runtime]: `driftDatabase` without `DriftWebOptions` works on native but throws on Flutter web; bundle `web/sqlite3.wasm` plus compiled `web/drift_worker.js` and pass those URIs.
- [FAIL][drift-web-shared-worker]: `driftDatabase` with the default web worker probe can hang forever in the in-app browser; use a conditional web connection that opens `WasmDatabase` directly with `IndexedDbFileSystem`.
- [FAIL][drift-schema-helper]: `drift_dev schema generate` can rewrite `test/generated_migrations/schema.dart` away from this project's `GeneratedHelper`; after generating version files, restore/update the helper index.
- [FAIL][flutter-web-server-detach]: Detaching `flutter run -d web-server` stops the preview server; keep it attached or serve `build/web` separately when Karl needs a stable URL.
