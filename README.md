# Projekt – Functional Programming (PF)

Projekt ma dwie części:

-   backend (serwer + baza danych)
-   frontend (aplikacja web)

Struktura:

-   `backend/`
-   `frontend/`

## Technologie (w skrócie)

Backend:

-   OCaml
-   Dream (web framework)
-   Caqti (baza danych)
-   PostgreSQL
-   Yojson (JSON)

Frontend:

-   Next.js (React)
-   ReScript
-   SCSS (module.scss)
-   fetch do API + token w localStorage

## Wymagania

-   Node.js + npm
-   OCaml (compiler) + ocamlfind (jeśli backend używa builda przez OCaml)
-   PostgreSQL
-   (opcjonalnie) docker, jeśli ktoś woli bazę w dockerze

## Jak odpalić (krok po kroku)

### 1) Klonowanie

Najpierw normalnie klonujesz repo i wchodzisz do katalogu:

-   masz katalogi `backend` i `frontend`

### 2) Backend

Wejdź do `backend/` i odpal serwer (zależy jak masz zrobione build/uruchamianie).
U mnie backend działa na:
dune exec ./bin/main.exe

-   `http://localhost:8080`

Baza danych:

-   PostgreSQL musi działać
-   trzeba mieć utworzone tabele (migracje / init sql zależnie od tego co jest w backendzie)

Jeśli backend ma `.env` albo zmienne:

-   ustaw `DATABASE_URL` albo inne potrzebne zmienne (jak w kodzie)

### 3) Frontend

Wejdź do `frontend/app` (albo tam gdzie jest `package.json`).

Instalacja:

-   `npm install`

Build ReScripta:

-   `npm run res:build`

Dev:

-   `npm run dev`

Frontend zwykle działa na:

-   `http://localhost:3000`

Jeśli API URL jest inne niż localhost:

-   ustaw `NEXT_PUBLIC_API_URL` (w `.env.local`), domyślnie jest `http://localhost:8080`

## Logowanie i token

Po zalogowaniu dostajesz access token i on jest trzymany w:

-   `localStorage` pod kluczem `access_token`

Frontend wysyła token w nagłówku:

-   `Authorization: Bearer <token>`
    albo (w części kodu) jako `authToken` w opcjach requestów.

## Funkcje dla użytkownika

-   lista tematów (Topics)
-   wejście w temat i lista zadań (Tasks) dla tematu
-   wejście w zadanie (Task) i zobaczenie treści + starter_code
-   wysyłanie rozwiązania (submit)
-   sprawdzanie wyniku po testach (status/score/delta/rating)
-   podgląd swoich submissionów dla taska
-   leaderboard (ranking)

## Funkcje dla admina

Admin jest widoczny w headerze tylko jak token ma rolę admin (sprawdzane przez JWT).

Panel admina:

-   Topics (admin):

    -   lista tematów, filter, pokaz/ukryj archived
    -   tworzenie tematu
    -   archive/unarchive tematu
    -   szczegóły tematu (page):
        -   dodawanie paragrafów (sortowanie po sort_key, ale user nie widzi sort_key)
        -   usuwanie paragrafów
        -   lista tasków w temacie (link do taska)

-   Tasks (admin):

    -   tworzenie taska po `topic_id` (title, statement, starter_code)
    -   archive/unarchive taska
    -   zarządzanie testami taska:
        -   lista testów
        -   dodawanie testu (input_json + expected_json)
        -   usuwanie testu

-   Submissions (admin): (na razie planowane / w trakcie)

-   Users (admin): (na razie planowane / w trakcie)

## Co jest ważne w taskach: starter_code / runner / runner_body

-   `starter_code` to kod startowy pokazywany użytkownikowi (szablon rozwiązania).
-   `runner` mówi jak uruchamiać rozwiązanie (np. tryb "json").
-   `runner_body` to fragment, który backend używa do złożenia funkcji `solve` w trybie json.
    W praktyce: user pisze kod Solution, backend robi wrapper i odpala testy na JSON input.

## Notatki

-   Jeśli coś nie działa, najczęściej problem to:
    -   brak bazy / zła konfiguracja
    -   brak `NEXT_PUBLIC_API_URL`
    -   brak tokena w localStorage (trzeba się zalogować)
    -   backend nie odpala się na 8080

Koniec.
