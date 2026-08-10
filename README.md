# Oblsk_characters Module

## Description
Character/CharacterAppearance identity-and-looks data layer on top of
oblsk_accounts: a slot-limited character-select system (create, list,
soft-delete) and a per-session active-character map. No gameplay state
(position, health, money) and no UI wiring, both are separate future work.

## Installation
This module loads as part of the `core` resource. After adding it under
`modules/`, run `obelisk registry:generate` from `core/` on the host, then
restart `core` (or the whole server). Requires oblsk_accounts to already be
installed (characters.account_id is a foreign key to accounts.id).

## Usage
`CharacterService.list(accountId)`, `CharacterService.create(accountId, attributes)`,
`CharacterService.delete(characterId)`, `CharacterService.setActiveCharacterId(source, characterId)`,
`CharacterService.getActiveCharacterId(source)`.
