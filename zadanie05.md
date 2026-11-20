#Zadanie1

maksymilianfikus@MacBook-Air-Maksymilian breach-checker % docker compose ps
NAME                        IMAGE                     COMMAND                  SERVICE    CREATED          STATUS                    PORTS
breach-checker-backend-1    breach-checker-backend    "python app.py"          backend    13 seconds ago   Up 7 seconds (healthy)    5000/tcp
breach-checker-db-1         postgres:16-alpine        "docker-entrypoint.s…"   db         13 seconds ago   Up 12 seconds (healthy)   5432/tcp
breach-checker-frontend-1   breach-checker-frontend   "/docker-entrypoint.…"   frontend   13 seconds ago   Up 1 second               0.0.0.0:8080->80/tcp, [::]:8080->80/tcp

#Zadanie2
Skrót przetrwał docker compose down, bo to polecenie usuwa tylko kontenery i sieć. Dane bazy leżą w wolumenie nazwanym pgdata, który zostaje i po up jest ponownie podłączany do nowego kontenera db. docker compose down -v usuwa także wolumeny, czyli cały katalog danych PostgreSQL razem z dopisanym skrótem.

maksymilianfikus@MacBook-Air-Maksymilian breach-checker % curl -X POST http://localhost:8080/api/check -H "Content-Type: application/json" -d '{"hash":"bc45408273d7e1914b741c3407b0b559764f7876"}'
{"found":true}
maksymilianfikus@MacBook-Air-Maksymilian breach-checker % docker compose down -v
[+] down 5/5
 ✔ Container breach-checker-frontend-1 Removed                                                                                                   0.2s
 ✔ Container breach-checker-backend-1  Removed                                                                                                   3.1s
 ✔ Container breach-checker-db-1       Removed                                                                                                   0.1s
 ✔ Volume breach-checker_pgdata        Removed                                                                                                   0.0s
 ✔ Network breach-checker_default      Removed                                                                                                   0.1s
maksymilianfikus@MacBook-Air-Maksymilian breach-checker % docker compose up -d
[+] up 5/5
 ✔ Network breach-checker_default      Created                                                                                                   0.0s
 ✔ Volume breach-checker_pgdata        Created                                                                                                   0.0s
 ✔ Container breach-checker-db-1       Healthy                                                                                                   5.7s
 ✔ Container breach-checker-backend-1  Healthy                                                                                                  11.2s
 ✔ Container breach-checker-frontend-1 Started                                                                                                  11.3s
maksymilianfikus@MacBook-Air-Maksymilian breach-checker % curl -X POST http://localhost:8080/api/check -H "Content-Type: application/json" -d '{"hash":"bc45408273d7e1914b741c3407b0b559764f7876"}'
{"found":false}
maksymilianfikus@MacBook-Air-Maksymilian breach-checker % 

#Zadanie3

maksymilianfikus@MacBook-Air-Maksymilian breach-checker % docker compose ps
NAME                        IMAGE                     COMMAND                  SERVICE    CREATED          STATUS                    PORTS
breach-checker-backend-1    breach-checker-backend    "python app.py"          backend    2 minutes ago    Up 2 minutes (healthy)    5000/tcp
breach-checker-backend-2    breach-checker-backend    "python app.py"          backend    13 seconds ago   Up 12 seconds (healthy)   5000/tcp
breach-checker-backend-3    breach-checker-backend    "python app.py"          backend    13 seconds ago   Up 12 seconds (healthy)   5000/tcp
breach-checker-db-1         postgres:16-alpine        "docker-entrypoint.s…"   db         2 minutes ago    Up 2 minutes (healthy)    5432/tcp
breach-checker-frontend-1   breach-checker-frontend   "/docker-entrypoint.…"   frontend   2 minutes ago    Up 2 minutes              0.0.0.0:8080->80/tcp, [::]:8080->80/tcp
maksymilianfikus@MacBook-Air-Maksymilian breach-checker % docker compose exec frontend nslookup backend
Server:         127.0.0.11
Address:        127.0.0.11:53

Non-authoritative answer:
Name:   backend
Address: 172.18.0.6
Name:   backend
Address: 172.18.0.5
Name:   backend
Address: 172.18.0.3

Non-authoritative answer:

Przed restartem:
maksymilianfikus@MacBook-Air-Maksymilian breach-checker % for i in $(seq 20); do curl -s -X POST http://localhost:8080/api/check -H "Content-Type: application/json" -d '{"hash":"bc45408273d7e1914b741c3407b0b559764f7876"}'; done
{"found":false}
{"found":false}
{"found":false}

maksymilianfikus@MacBook-Air-Maksymilian breach-checker % docker compose logs backend | grep "POST /check"
backend-1  | 172.18.0.4 - - [20/Nov/2026 10:09:58] "POST /check HTTP/1.1" 200 -
backend-1  | 172.18.0.4 - - [20/Nov/2026 10:11:33] "POST /check HTTP/1.1" 200 -

Po restarcie:
maksymilianfikus@MacBook-Air-Maksymilian breach-checker % docker compose logs --since 1m backend | grep "POST /check"
backend-2  | 172.18.0.4 - - [20/Nov/2026 10:16:07] "POST /check HTTP/1.1" 200 -
backend-2  | 172.18.0.4 - - [20/Nov/2026 10:16:07] "POST /check HTTP/1.1" 200 -
backend-3  | 172.18.0.4 - - [20/Nov/2026 10:16:07] "POST /check HTTP/1.1" 200 -

Przed restartem frontendu cały ruch trafiał do jednej repliki, bo nginx tłumaczy nazwę backend na adres IP tylko raz, przy swoim starcie, i potem cały czas używa zapamiętanego adresu. Repliki backend-2 i backend-3 powstały, gdy nginx już działał, więc nic o nich nie wiedział. DNS Dockera zwracał już trzy adresy, co widać w nslookup backend. Dopiero po docker compose restart frontend nginx pobrał wszystkie trzy adresy i zaczął rozdzielać zapytania między repliki.

Skalowanie byłoby niemożliwe przy ports: "5000:5000", bo każda replika próbowałaby zająć ten sam port 5000 na hoście. Port hosta może mieć tylko jeden kontener, więc druga i trzecia replika nie wystartowałyby (błąd port is already allocated). Bez publikowania portu repliki są dostępne tylko w sieci projektu, każda pod własnym adresem IP, a ruch rozdziela nginx.

#dodatkowe

## Zadanie dodatkowe – najmniejsze uprawnienia

Backend łączy się z bazą jako `breach_app`, który ma tylko `CONNECT` do bazy i `SELECT` na tabeli `leaked_hashes`.
Hasło `breach_app` jest w `.env` (`APP_DB_PASSWORD`), a skrypt `db/zz-app-user.sh` tworzy użytkownika przy pierwszym starcie bazy.

```
$ docker compose exec db psql -U breach_app -d breachdb
breachdb=> SELECT count(*) FROM leaked_hashes;
 count
-------
    89
(1 row)

breachdb=> INSERT INTO leaked_hashes VALUES ('bc45408273d7e1914b741c3407b0b559764f7876');
ERROR:  permission denied for table leaked_hashes
breachdb=> DROP TABLE leaked_hashes;
ERROR:  must be owner of table leaked_hashes
```

Gdyby atakujący przejął kontener backendu, znalazłby w zmiennych środowiskowych tylko login i hasło użytkownika `breach_app`. Ten użytkownik może jedynie odczytać tabelę `leaked_hashes`. Nie zmieni ani nie usunie danych (`INSERT`, `UPDATE`, `DELETE`, `DROP TABLE`), nie utworzy nowych tabel ani użytkowników i nie przejmie bazy, jak mógłby z kontem administratora `breach`. Szkoda ogranicza się do odczytu danych, które aplikacja i tak udostępnia.