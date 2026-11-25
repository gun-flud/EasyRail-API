## Що зроблено
- Короткий опис змін і номер задачі/фази.

## Як перевірити
- Команди запуску (наприклад: `pnpm --dir backend test`), curl або сценарій у Swagger `/docs`.

## Definition of Done (DoD)
- [ ] `pnpm --dir backend typecheck` проходить без помилок
- [ ] `pnpm --dir backend lint` проходить без помилок
- [ ] `pnpm --dir backend test` зелений (включно з інтеграційними тестами)
- [ ] Розмір PR не перевищує ~400 рядків (або обґрунтовано)
- [ ] Для змін у SQL-запитах додано `EXPLAIN` / `EXPLAIN (ANALYZE, BUFFERS)`