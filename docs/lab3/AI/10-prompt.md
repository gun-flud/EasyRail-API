# Промпт 10. Точкові правки в model_1.mmd та model_2.mmd, оновлення spec.md і папка AI

твій результат не підходить, зараз я повернув файли до стану який був до цього. Твої кроки роботи:
1. додай попередній промпт, який я тобі написав і цей промпт як 9 і 10 промпт, та звикай на кожній наступній нашій сесії створювати папочку AI та логувати кожен мій промпт
2. model_1.mmd зверни увагу, що у цій частині  alt Available seats exist on requested route (Inventory available)
               rect rgb(235, 255, 235)
               break [break] Success: Seats available, proceed to seat selection
                   Note over API, DB: Success: Available seats calculated dynamically (Lazy Evaluation - ADR 002)
                   Svc-->>API: Return seat availability map (availableSeats: [1..13, 15..36], price: 45000 коп)
                   API-->>UI: 200 OK (Interactive carriage schema with seat #14 free)
                   UI-->>P: Render interactive seat layout (highlight seat #14 as free)
                   Note over P, UI: [break] Suitable carriage found. Exit loop and proceed to hold reservation.
               end
               end
           else All seats occupied on requested route (Carriage sold out)
               rect rgb(255, 235, 235)
               opt [continue] Retry: Carriage full, inspect another carriage
                   Note over API, DB: Failure: All seats reserved or purchased for interval [1..4)
                   Svc-->>API: Return empty inventory status (availableSeats: [], isSoldOut: true)
                   API-->>UI: 200 OK (Empty seat availability response)
                   UI-->>P: Friendly alert: "No available seats in this carriage. Please pick another carriage."
                   Note over P, UI: [continue] Loop iterates: Passenger selects another carriage to inspect
               end
               end
           end можна обійтись без alt, адже якщо ми приберемо alt, а залишимо лише break то все працюватиме та читатиметься так само ж. Тому, прибери цей alt, залиш зелений alt та червоний break
3. model_2.mmd alt Active hold limit reached (count >= 1)
            rect rgb(255, 235, 235)
            break [break] Stop: User already has an active hold
                Svc->>+DB: Rollback transaction (ROLLBACK)
                DB-->>-Svc: Transaction cancelled (OK)
                Svc-->>API: Hold limit reached error (HoldLimitExceeded)
                API-->>UI: 409 Conflict (Hold limit exceeded: max 1 active hold)
                UI-->>P: Friendly alert: "You already have an active hold. Please complete or cancel it first."
                Note over P, DB: [break] Fatal limit reached. Terminate loop, passenger must clear prior hold.
            end
            end тут можна прибрати alt та всередині break прописати, що у нас зараз щось схоже: [break] Stop: User already has an active hold Active hold limit reached (count >= 1). Наступний alt також прибираємо адже можна просто додати opt(continue) що seat вже забрав хтось інший. Кольори залиш такі ж як і були, адже це візуально допомагає розібратись. 
4. далі можеш виправити spec.md та переглянути чи не потрібні в інших файлах покращення в залежності від того, що ми зробили
